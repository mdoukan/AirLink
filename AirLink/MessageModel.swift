//
//  MessageModel.swift  
//  AirLink
//
//  Mesajlaşma için veri modelleri ve mesaj yönetimi
//  Gerçek zamanlı metin mesajlaşması destekler
//

import Foundation
import MultipeerConnectivity
import Combine

// MARK: - Mesaj Modelleri

/// Mesaj türleri
enum MessageType: String, CaseIterable, Codable {
    case text = "text"
    case systemInfo = "systemInfo"
    case userJoined = "userJoined"  
    case userLeft = "userLeft"
    case typing = "typing"
}

/// Mesaj durumu
enum MessageStatus: String, CaseIterable, Codable {
    case sending = "sending"
    case sent = "sent"
    case delivered = "delivered"
    case failed = "failed"
}

/// Ana mesaj modeli
struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let senderName: String
    let senderID: String
    let timestamp: Date
    let type: MessageType
    var status: MessageStatus
    let isFromCurrentUser: Bool
    
    init(content: String, 
         senderName: String, 
         senderID: String, 
         type: MessageType = .text, 
         isFromCurrentUser: Bool = false) {
        self.id = UUID()
        self.content = content
        self.senderName = senderName
        self.senderID = senderID
        self.timestamp = Date()
        self.type = type
        self.status = isFromCurrentUser ? .sending : .delivered
        self.isFromCurrentUser = isFromCurrentUser
    }
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Yazma durumu modeli
struct TypingStatus: Codable {
    let senderName: String
    let senderID: String
    let isTyping: Bool
    let timestamp: Date
}

// MARK: - Mesaj Yöneticisi

class MessageManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var messages: [ChatMessage] = []
    @Published var typingUsers: [String] = [] // Yazanların isimleri
    @Published var unreadCount: Int = 0
    @Published var isUserTyping: Bool = false
    
    // MARK: - Private Properties
    private var multipeerManager: MultipeerManager
    private var cancellables = Set<AnyCancellable>()
    private var typingTimer: Timer?
    private let currentUserName: String
    private let currentUserID: String
    
    // MARK: - Initialization
    init(multipeerManager: MultipeerManager) {
        self.multipeerManager = multipeerManager
        self.currentUserName = UIDevice.current.name
        self.currentUserID = multipeerManager.peerID.displayName
        
        setupDataReceiver()
        observeConnections()
        
        // Hoş geldin mesajı
        addSystemMessage("AirLink'e hoş geldiniz! Yakındaki cihazları arıyoruz...")
    }
}

// MARK: - Public Methods

extension MessageManager {
    
    /// Metin mesajı gönder
    func sendMessage(_ content: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Kendi mesajımızı ekle
        let message = ChatMessage(
            content: content,
            senderName: currentUserName,
            senderID: currentUserID,
            type: .text,
            isFromCurrentUser: true
        )
        
        messages.append(message)
        stopTyping()
        
        // Veriyi encode et ve gönder
        if let data = encodeMessage(message) {
            multipeerManager.sendData(data, type: .message)
            
            // Mesaj durumunu güncelle
            updateMessageStatus(message.id, status: .sent)
            
            print("📤 Mesaj gönderildi: \(content)")
        }
    }
    
    /// Yazma durumunu başlat
    func startTyping() {
        guard !isUserTyping else { return }
        
        isUserTyping = true
        
        let typingStatus = TypingStatus(
            senderName: currentUserName,
            senderID: currentUserID,
            isTyping: true,
            timestamp: Date()
        )
        
        if let data = encodeTypingStatus(typingStatus) {
            multipeerManager.sendData(data, type: .metaData)
        }
        
        // 3 saniye sonra otomatik olarak durdur
        typingTimer?.invalidate()
        typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            self.stopTyping()
        }
    }
    
    /// Yazma durumunu durdur
    func stopTyping() {
        guard isUserTyping else { return }
        
        isUserTyping = false
        typingTimer?.invalidate()
        
        let typingStatus = TypingStatus(
            senderName: currentUserName,
            senderID: currentUserID,
            isTyping: false,
            timestamp: Date()
        )
        
        if let data = encodeTypingStatus(typingStatus) {
            multipeerManager.sendData(data, type: .metaData)
        }
    }
    
    /// Mesajları temizle
    func clearMessages() {
        messages.removeAll()
        addSystemMessage("Sohbet geçmişi temizlendi")
    }
    
    /// Okunmamış mesaj sayısını sıfırla
    func markAllAsRead() {
        unreadCount = 0
    }
    
    /// Sistem mesajı ekle
    func addSystemMessage(_ content: String) {
        let message = ChatMessage(
            content: content,
            senderName: "Sistem",
            senderID: "system",
            type: .systemInfo,
            isFromCurrentUser: false
        )
        messages.append(message)
    }
}

// MARK: - Private Methods

private extension MessageManager {
    
    func setupDataReceiver() {
        multipeerManager.onDataReceived = { [weak self] data, dataType, peerID in
            guard let self = self else { return }
            
            switch dataType {
            case .message:
                self.handleReceivedMessage(data, from: peerID)
            case .metaData:
                self.handleReceivedMetaData(data, from: peerID)
            default:
                break
            }
        }
    }
    
    func observeConnections() {
        multipeerManager.$connectedPeers
            .sink { [weak self] peers in
                self?.handlePeerChanges(peers)
            }
            .store(in: &cancellables)
    }
    
    func handleReceivedMessage(_ data: Data, from peer: MCPeerID) {
        guard let message = decodeMessage(data) else {
            print("❌ Mesaj decode hatası")
            return
        }
        
        var receivedMessage = message
        receivedMessage.status = .delivered
        
        DispatchQueue.main.async {
            self.messages.append(receivedMessage)
            self.unreadCount += 1
            
            print("📥 Mesaj alındı (\(peer.displayName)): \(message.content)")
        }
    }
    
    func handleReceivedMetaData(_ data: Data, from peer: MCPeerID) {
        guard let typingStatus = decodeTypingStatus(data) else { return }
        
        DispatchQueue.main.async {
            if typingStatus.isTyping {
                if !self.typingUsers.contains(typingStatus.senderName) {
                    self.typingUsers.append(typingStatus.senderName)
                }
            } else {
                self.typingUsers.removeAll { $0 == typingStatus.senderName }
            }
        }
    }
    
    func handlePeerChanges(_ peers: [ConnectedPeer]) {
        // Yeni bağlanan kullanıcılar için mesaj ekle
        let currentPeerNames = Set(messages.compactMap { message in
            message.type == .userJoined ? message.senderName : nil
        })
        
        for peer in peers {
            if !currentPeerNames.contains(peer.displayName) && peer.displayName != currentUserName {
                let joinMessage = ChatMessage(
                    content: "\(peer.displayName) sohbete katıldı",
                    senderName: peer.displayName,
                    senderID: peer.peerID.displayName,
                    type: .userJoined,
                    isFromCurrentUser: false
                )
                messages.append(joinMessage)
            }
        }
    }
    
    func updateMessageStatus(_ messageID: UUID, status: MessageStatus) {
        if let index = messages.firstIndex(where: { $0.id == messageID }) {
            messages[index].status = status
        }
    }
    
    // MARK: - Encoding/Decoding
    
    func encodeMessage(_ message: ChatMessage) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(message)
    }
    
    func decodeMessage(_ data: Data) -> ChatMessage? {
        let decoder = JSONDecoder()  
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(ChatMessage.self, from: data)
    }
    
    func encodeTypingStatus(_ status: TypingStatus) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(status)
    }
    
    func decodeTypingStatus(_ data: Data) -> TypingStatus? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(TypingStatus.self, from: data)
    }
}

// MARK: - Message Extensions

extension ChatMessage {
    
    /// Zaman damgası formatı
    var formattedTime: String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(timestamp) {
            formatter.timeStyle = .short
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .short
        }
        
        return formatter.string(from: timestamp)
    }
    
    /// Mesaj rengi
    var messageColor: String {
        switch type {
        case .text:
            return isFromCurrentUser ? "blue" : "gray"
        case .systemInfo:
            return "orange"
        case .userJoined:
            return "green"
        case .userLeft:
            return "red"
        case .typing:
            return "purple"
        }
    }
    
    /// Mesaj ikonu
    var messageIcon: String {
        switch status {
        case .sending:
            return "clock"
        case .sent:
            return "checkmark"
        case .delivered:
            return "checkmark.circle"
        case .failed:
            return "exclamationmark.triangle"
        }
    }
}