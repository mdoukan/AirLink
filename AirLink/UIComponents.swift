//
//  UIComponents.swift
//  AirLink
//
//  Kullanıcı arayüzü için yardımcı SwiftUI bileşenleri
//  ContentView'de kullanılan tüm özel UI komponetleri
//

import SwiftUI
import MultipeerConnectivity

// MARK: - Bağlantı Durumu Card'ı

struct ConnectionStatusCard: View {
    
    let multipeerManager: MultipeerManager
    let onConnectionTap: () -> Void
    
    var body: some View {
        Button(action: onConnectionTap) {
            HStack {
                // Durum ikonu
                Image(systemName: statusIcon)
                    .font(.title2)
                    .foregroundColor(statusColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bağlantı Durumu")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(multipeerManager.connectionStatus)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !multipeerManager.connectedPeers.isEmpty {
                        Text(connectedDevicesText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
    
    private var statusIcon: String {
        if multipeerManager.connectedPeers.count > 0 {
            return "wifi.circle.fill"
        } else if multipeerManager.isBrowsing || multipeerManager.isAdvertising {
            return "magnifyingglass.circle.fill"
        } else {
            return "wifi.slash.circle.fill"
        }
    }
    
    private var statusColor: Color {
        if multipeerManager.connectedPeers.count > 0 {
            return .green
        } else if multipeerManager.isBrowsing || multipeerManager.isAdvertising {
            return .orange
        } else {
            return .red
        }
    }
    
    private var connectedDevicesText: String {
        let devices = multipeerManager.connectedPeers.map { $0.displayName }.joined(separator: ", ")
        return "Bağlı: \(devices)"
    }
}

// MARK: - Hızlı Aksiyon Card'ı

struct QuickActionCard: View {
    
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(color.opacity(0.1))
                    )
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Mesaj Bubble View

struct MessageBubbleView: View {
    
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                
                // Gönderen adı (sadece başkalarının mesajları için)
                if !message.isFromCurrentUser && message.type == .text {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                }
                
                // Mesaj içeriği
                HStack {
                    
                    if message.type == .text {
                        Text(message.content)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(message.isFromCurrentUser ? Color.accentColor : Color(UIColor.systemGray5))
                            )
                            .foregroundColor(message.isFromCurrentUser ? .white : .primary)
                    } else {
                        // Sistem mesajları
                        HStack(spacing: 6) {
                            Image(systemName: systemMessageIcon)
                                .font(.caption)
                                .foregroundColor(systemMessageColor)
                            
                            Text(message.content)
                                .font(.caption)
                                .italic()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(systemMessageColor.opacity(0.1))
                        )
                        .foregroundColor(systemMessageColor)
                    }
                }
                
                // Zaman damgası ve durum
                if message.type == .text {
                    HStack(spacing: 4) {
                        Text(message.formattedTime)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if message.isFromCurrentUser {
                            Image(systemName: message.messageIcon)
                                .font(.caption2)
                                .foregroundColor(message.status == .failed ? .red : .secondary)
                        }
                    }
                }
            }
            
            if !message.isFromCurrentUser {
                Spacer(minLength: 50)
            }
        }
    }
    
    private var systemMessageIcon: String {
        switch message.type {
        case .systemInfo:
            return "info.circle"
        case .userJoined:
            return "person.badge.plus"
        case .userLeft:
            return "person.badge.minus"
        default:
            return "info.circle"
        }
    }
    
    private var systemMessageColor: Color {
        switch message.type {
        case .systemInfo:
            return .orange
        case .userJoined:
            return .green
        case .userLeft:
            return .red
        default:
            return .gray
        }
    }
}

// MARK: - Yazma Durumu Göstergesi

struct TypingIndicatorView: View {
    
    let typingUsers: [String]
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack {
            
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 6, height: 6)
                        .offset(y: animationOffset)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animationOffset
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemGray5))
            )
            
            Spacer()
        }
        .onAppear {
            animationOffset = -3
        }
        .overlay(
            Text("\(typingUsers.first ?? "Birisi") yazıyor...")
                .font(.caption)
                .foregroundColor(.secondary)
                .offset(y: -25),
            alignment: .leading
        )
    }
}

// MARK: - Mesaj Giriş Alanı

struct MessageInputView: View {
    
    @Binding var text: String
    let isTyping: Bool
    let onTextChange: () -> Void
    let onSend: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            
            // Metin giriş alanı
            TextField("Mesaj yazın...", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .focused($isTextFieldFocused)
                .onChange(of: text) { _ in
                    onTextChange()
                }
                .onSubmit {
                    onSend()
                }
            
            // Gönder butonu
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .accentColor)
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Ekran Paylaşımı Durum View

struct ScreenShareStatusView: View {
    
    @ObservedObject var screenShareManager: ScreenShareManager
    
    var body: some View {
        VStack(spacing: 16) {
            
            // Durum ikonu ve başlık
            VStack(spacing: 8) {
                Image(systemName: statusIcon)
                    .font(.system(size: 50))
                    .foregroundColor(statusColor)
                
                Text(statusTitle)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)
                
                Text(statusSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Durum detayları
            if screenShareManager.isSharing || screenShareManager.isReceivingShare {
                VStack(spacing: 8) {
                    
                    if screenShareManager.isSharing {
                        HStack {
                            Text("Gönderilen Frame:").foregroundColor(.secondary)
                            Spacer()
                            Text("\(screenShareManager.sentFrameCount)")
                                .bold()
                        }
                    }
                    
                    if screenShareManager.isReceivingShare {
                        HStack {
                            Text("Alınan Frame:").foregroundColor(.secondary)
                            Spacer()
                            Text("\(screenShareManager.receivedFrameCount)")
                                .bold()
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
            }
        }
        .padding()
    }
    
    private var statusIcon: String {
        switch screenShareManager.status {
        case .idle:
            return "tv"
        case .starting:
            return "play.circle"
        case .recording, .streaming:
            return "record.circle.fill"
        case .stopping:
            return "stop.circle"
        case .error(_):
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var statusColor: Color {
        switch screenShareManager.status {
        case .idle:
            return .gray
        case .starting:
            return .orange
        case .recording, .streaming:
            return .green
        case .stopping:
            return .orange
        case .error(_):
            return .red
        }
    }
    
    private var statusTitle: String {
        switch screenShareManager.status {
        case .idle:
            return "Ekran Paylaşımı Hazır"
        case .starting:
            return "Başlatılıyor..."
        case .recording:
            return "Kaydediliyor"
        case .streaming:
            return "Paylaşılıyor"
        case .stopping:
            return "Durduruluyor..."
        case .error(_):
            return "Hata Oluştu"
        }
    }
    
    private var statusSubtitle: String {
        switch screenShareManager.status {
        case .idle:
            return "Ekranınızı diğer cihazlara paylaşmaya başlamak için butona basın"
        case .starting:
            return "Lütfen ekran kaydı izni verin"
        case .recording:
            return "Ekran kaydediliyor, stream bekleniyor"
        case .streaming:
            return "Ekranınız diğer cihazlara aktarılıyor"
        case .stopping:
            return "Paylaşım sonlandırılıyor"
        case .error(let message):
            return message
        }
    }
}

// MARK: - Ekran Paylaşımı İstatistik View

struct ScreenShareStatsView: View {
    
    @ObservedObject var screenShareManager: ScreenShareManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Text("İstatistikler")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                
                if screenShareManager.isSharing {
                    StatRow(title: "Gönderilen Frame", value: "\(screenShareManager.sentFrameCount)")
                    StatRow(title: "Stream Kalitesi", value: "\(Int(screenShareManager.streamQuality * 100))%")
                }
                
                if screenShareManager.isReceivingShare {
                    StatRow(title: "Alınan Frame", value: "\(screenShareManager.receivedFrameCount)")
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .padding(.horizontal)
        }
    }
}

// MARK: - İstatistik Satırı

struct StatRow: View {
    
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}

// MARK: - Aktif Çağrı View

struct ActiveCallView: View {
    
    @ObservedObject var audioCallManager: AudioCallManager
    
    var body: some View {
        VStack(spacing: 12) {
            
            // Çağrı bilgileri
            VStack(spacing: 4) {
                Text(audioCallManager.currentCall?.peerName ?? "Bilinmiyor")
                    .font(.headline)
                    .bold()
                
                Text(audioCallManager.currentCall?.formattedDuration ?? "00:00")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Ses seviyesi göstergesi
            if audioCallManager.audioLevel > 0 {
                VStack(spacing: 4) {
                    Text("Ses Seviyesi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: audioCallManager.audioLevel, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        .frame(height: 4)
                }
            }
            
            // Çağrı kontrolleri
            HStack(spacing: 20) {
                
                // Mute butonu
                Button(action: {
                    audioCallManager.toggleMute()
                }) {
                    Image(systemName: audioCallManager.isMuted ? "mic.slash.fill" : "mic.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(audioCallManager.isMuted ? Color.red : Color.gray)
                        .clipShape(Circle())
                }
                
                // Speaker butonu
                Button(action: {
                    audioCallManager.toggleSpeaker()
                }) {
                    Image(systemName: audioCallManager.isSpeakerOn ? "speaker.wave.3.fill" : "speaker.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(audioCallManager.isSpeakerOn ? Color.blue : Color.gray)
                        .clipShape(Circle())
                }
                
                // Çağrıyı bitir butonu
                Button(action: {
                    audioCallManager.endCall()
                }) {
                    Image(systemName: "phone.down.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(radius: 5)
        )
        .padding(.horizontal)
    }
}

// MARK: - Bağlantı View

struct ConnectionView: View {
    
    @ObservedObject var multipeerManager: MultipeerManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // Mevcut bağlantılar
                if !multipeerManager.connectedPeers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Bağlı Cihazlar")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(multipeerManager.connectedPeers) { peer in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                
                                VStack(alignment: .leading) {
                                    Text(peer.displayName)
                                        .font(.subheadline)
                                        .bold()
                                    
                                    Text("Bağlı")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Bulunan cihazlar
                if !multipeerManager.availablePeers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Bulunan Cihazlar")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(multipeerManager.availablePeers, id: \.self) { peer in
                            HStack {
                                Image(systemName: "wifi.circle")
                                    .foregroundColor(.orange)
                                
                                VStack(alignment: .leading) {
                                    Text(peer.displayName)
                                        .font(.subheadline)
                                        .bold()
                                    
                                    Text("Bağlanabilir")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("Bağlan") {
                                    multipeerManager.connectToPeer(peer)
                                }
                                .buttonStyle(.borderless)
                                .foregroundColor(.accentColor)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Durum bilgisi
                if multipeerManager.connectedPeers.isEmpty && multipeerManager.availablePeers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("Cihaz aranıyor...")
                            .font(.title2)
                            .bold()
                        
                        Text("Yakında başka AirLink uygulaması olan cihazları arayacağız")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                
                Spacer()
                
                // Bağlantı kontrolleri
                VStack(spacing: 12) {
                    
                    HStack {
                        Text("Advertising:")
                        Spacer()
                        Toggle("", isOn: .constant(multipeerManager.isAdvertising))
                            .onChange(of: multipeerManager.isAdvertising) { value in
                                if value {
                                    multipeerManager.startAdvertising()
                                } else {
                                    multipeerManager.stopAdvertising()
                                }
                            }
                    }
                    
                    HStack {
                        Text("Browsing:")
                        Spacer()
                        Toggle("", isOn: .constant(multipeerManager.isBrowsing))
                            .onChange(of: multipeerManager.isBrowsing) { value in
                                if value {
                                    multipeerManager.startBrowsing()
                                } else {
                                    multipeerManager.stopBrowsing()
                                }
                            }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .padding(.horizontal)
            }
            .navigationTitle("Bağlantılar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}