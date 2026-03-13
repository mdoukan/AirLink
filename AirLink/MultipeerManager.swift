//
//  MultipeerManager.swift
//  AirLink
//
//  Multipeer Connectivity Framework ile cihazlar arası P2P bağlantı yönetimi
//  Bu modül Bluetooth + peer-to-peer WiFi kullanarak offline mesh network oluşturur
//

import Foundation
import MultipeerConnectivity
import Combine

// MARK: - Bağlantı Türleri ve Modeller

/// Cihaz durumu enum'u
enum PeerStatus {
    case notConnected
    case connecting
    case connected
}

/// Bağlı cihaz modeli
struct ConnectedPeer: Identifiable, Equatable {
    let id = UUID()
    let peerID: MCPeerID
    let displayName: String
    let status: PeerStatus
    
    static func == (lhs: ConnectedPeer, rhs: ConnectedPeer) -> Bool {
        return lhs.peerID == rhs.peerID
    }
}

/// Veri türleri - Mesaj ve video streaming için ayrı kanallar
enum DataType: String, CaseIterable {
    case message = "message"
    case videoFrame = "videoFrame"
    case audioData = "audioData"
    case metaData = "metaData"
}

// MARK: - Multipeer Connectivity Yöneticisi

class MultipeerManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var connectedPeers: [ConnectedPeer] = []
    @Published var availablePeers: [MCPeerID] = []
    @Published var isAdvertising = false
    @Published var isBrowsing = false
    @Published var connectionStatus = "Bağlantı Yok"
    
    // MARK: - Private Properties
    private let serviceType = "airlink-service"  // Servis türü tanımı
    public let peerID: MCPeerID                  // Bu cihazın ID'si (public yapıldı)
    private var mcSession: MCSession             // Multipeer session
    private var mcAdvertiserAssistant: MCNearbyServiceAdvertiser? // Advertiser
    private var mcBrowser: MCNearbyServiceBrowser? // Browser
    
    // Veri alım callback'i
    var onDataReceived: ((Data, DataType, MCPeerID) -> Void)?
    
    // MARK: - Initialization
    override init() {
        // Cihaz adını al ve peerID oluştur
        let deviceName = UIDevice.current.name
        peerID = MCPeerID(displayName: deviceName)
        
        // Session oluştur - güvenilir mod ve güvenlik ayarları
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        
        super.init()
        
        // Session delegate'i ata
        mcSession.delegate = self
        
        // Başlangıçta browsing'i başlat
        startBrowsing()
        
        print("🔗 MultipeerManager başlatıldı - Cihaz: \(deviceName)")
    }
    
    deinit {
        stopAdvertising()
        stopBrowsing()
        mcSession.disconnect()
    }
}

// MARK: - Public Methods

extension MultipeerManager {
    
    /// Advertising'i başlat (Bu cihaz diğerleri tarafından bulunur)
    func startAdvertising() {
        guard mcAdvertiserAssistant == nil else { return }
        
        // Cihaz bilgilerini discovery info'ya ekle
        let discoveryInfo = ["deviceType": "iOS", "version": "1.0"]
        
        mcAdvertiserAssistant = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: discoveryInfo,
            serviceType: serviceType
        )
        
        mcAdvertiserAssistant?.delegate = self
        mcAdvertiserAssistant?.startAdvertising()
        
        DispatchQueue.main.async {
            self.isAdvertising = true
            self.connectionStatus = "Duyuru Yapılıyor..."
        }
        
        print("📢 Advertising başlatıldı")
    }
    
    /// Advertising'i durdur
    func stopAdvertising() {
        mcAdvertiserAssistant?.stopAdvertising()
        mcAdvertiserAssistant = nil
        
        DispatchQueue.main.async {
            self.isAdvertising = false
            self.updateConnectionStatus()
        }
        
        print("⏹️ Advertising durduruldu")
    }
    
    /// Browsing'i başlat (Diğer cihazları ara)
    func startBrowsing() {
        guard mcBrowser == nil else { return }
        
        mcBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        mcBrowser?.delegate = self
        mcBrowser?.startBrowsingForPeers()
        
        DispatchQueue.main.async {
            self.isBrowsing = true
            self.connectionStatus = "Cihaz Aranıyor..."
        }
        
        print("🔍 Browsing başlatıldı")
    }
    
    /// Browsing'i durdur
    func stopBrowsing() {
        mcBrowser?.stopBrowsingForPeers()
        mcBrowser = nil
        
        DispatchQueue.main.async {
            self.isBrowsing = false
            self.updateConnectionStatus()
        }
        
        print("⏹️ Browsing durduruldu")
    }
    
    /// Belirli bir peer'a bağlanmaya çalış
    func connectToPeer(_ peerID: MCPeerID) {
        guard let browser = mcBrowser else { return }
        
        print("🤝 Bağlantı isteği gönderiliyor: \(peerID.displayName)")
        
        // 30 saniye timeout ile bağlantı isteği gönder
        browser.invitePeer(peerID, to: mcSession, withContext: nil, timeout: 30.0)
        
        DispatchQueue.main.async {
            self.connectionStatus = "Bağlanıyor..."
        }
    }
    
    /// Tüm bağlı cihazlara veri gönder
    func sendData(_ data: Data, type: DataType) {
        guard !connectedPeers.isEmpty else {
            print("⚠️ Bağlı cihaz yok, veri gönderilemiyor")
            return
        }
        
        // Veri tipini metadata olarak ekle
        var dataWithType = type.rawValue.data(using: .utf8) ?? Data()
        dataWithType.append(data)
        
        do {
            try mcSession.send(dataWithType, toPeers: mcSession.connectedPeers, with: .reliable)
            print("📤 Veri gönderildi - Tip: \(type.rawValue), Boyut: \(data.count) bytes")
        } catch {
            print("❌ Veri gönderme hatası: \(error.localizedDescription)")
        }
    }
    
    /// Belirli bir peer'a veri gönder
    func sendDataToPeer(_ data: Data, type: DataType, peer: MCPeerID) {
        guard mcSession.connectedPeers.contains(peer) else {
            print("⚠️ Peer bağlı değil: \(peer.displayName)")
            return
        }
        
        var dataWithType = type.rawValue.data(using: .utf8) ?? Data()
        dataWithType.append(data)
        
        do {
            try mcSession.send(dataWithType, toPeers: [peer], with: .reliable)
            print("📤 Veri gönderildi (\(peer.displayName)) - Tip: \(type.rawValue)")
        } catch {
            print("❌ Veri gönderme hatası: \(error.localizedDescription)")
        }
    }
    
    /// Bağlantıyı kes
    func disconnect() {
        mcSession.disconnect()
        stopAdvertising()
        stopBrowsing()
        
        DispatchQueue.main.async {
            self.connectedPeers.removeAll()
            self.availablePeers.removeAll()
            self.connectionStatus = "Bağlantı Kesildi"
        }
        
        print("🔌 Tüm bağlantılar kesildi")
    }
}

// MARK: - Private Methods

private extension MultipeerManager {
    
    func updateConnectionStatus() {
        DispatchQueue.main.async {
            let connectedCount = self.connectedPeers.count
            if connectedCount > 0 {
                self.connectionStatus = "\(connectedCount) Cihaz Bağlı"
            } else if self.isBrowsing || self.isAdvertising {
                self.connectionStatus = "Aramaya Devam..."
            } else {
                self.connectionStatus = "Bağlantı Yok"
            }
        }
    }
    
    func updateConnectedPeers() {
        DispatchQueue.main.async {
            self.connectedPeers = self.mcSession.connectedPeers.map { peerID in
                ConnectedPeer(
                    peerID: peerID,
                    displayName: peerID.displayName,
                    status: .connected
                )
            }
            self.updateConnectionStatus()
        }
    }
}

// MARK: - MCSessionDelegate

extension MultipeerManager: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("🔄 Peer durumu değişti: \(peerID.displayName) - \(state)")
        
        DispatchQueue.main.async {
            switch state {
            case .connected:
                print("✅ Bağlandı: \(peerID.displayName)")
                
            case .connecting:
                print("🔄 Bağlanıyor: \(peerID.displayName)")
                
            case .notConnected:
                print("❌ Bağlantı kesildi: \(peerID.displayName)")
                
            @unknown default:
                print("❓ Bilinmeyen durum: \(peerID.displayName)")
            }
            
            self.updateConnectedPeers()
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Veri tipini ayıkla
        guard let typeData = data.prefix(while: { $0 != 0 }),
              let typeString = String(data: typeData, encoding: .utf8),
              let dataType = DataType(rawValue: typeString) else {
            print("❌ Geçersiz veri formatı alındı")
            return
        }
        
        // Asıl veriyi ayıkla
        let actualData = data.dropFirst(typeData.count)
        
        print("📥 Veri alındı (\(peerID.displayName)) - Tip: \(dataType.rawValue), Boyut: \(actualData.count) bytes")
        
        // Callback'i çağır
        DispatchQueue.main.async {
            self.onDataReceived?(Data(actualData), dataType, peerID)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Stream alındığında - video veya audio streaming için kullanılabilir
        print("📺 Stream alındı: \(streamName) - \(peerID.displayName)")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Büyük dosya transferi başladığında
        print("📁 Dosya transferi başladı: \(resourceName) - \(peerID.displayName)")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Dosya transferi tamamlandığında
        if let error = error {
            print("❌ Dosya transferi hatası: \(error.localizedDescription)")
        } else {
            print("✅ Dosya transferi tamamlandı: \(resourceName)")
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        print("🔔 Bağlantı isteği alındı: \(peerID.displayName)")
        
        // Otomatik olarak kabul et - Gerçek uygulamada kullanıcıya sorulabilir
        invitationHandler(true, mcSession)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("❌ Advertising hatası: \(error.localizedDescription)")
        
        DispatchQueue.main.async {
            self.connectionStatus = "Duyuru Hatası"
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("🔍 Cihaz bulundu: \(peerID.displayName)")
        
        DispatchQueue.main.async {
            if !self.availablePeers.contains(peerID) {
                self.availablePeers.append(peerID)
            }
        }
        
        // Otomatik bağlantı - Gerçek uygulamada kullanıcı seçimi yapılabilir
        connectToPeer(peerID)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("❌ Cihaz kayboldu: \(peerID.displayName)")
        
        DispatchQueue.main.async {
            self.availablePeers.removeAll { $0 == peerID }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("❌ Browsing hatası: \(error.localizedDescription)")
        
        DispatchQueue.main.async {
            self.connectionStatus = "Arama Hatası"
        }
    }
}