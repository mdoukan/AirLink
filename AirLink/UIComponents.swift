//
//  UIComponents.swift
//  AirLink
//
//  Modern UI bileşenleri
//

import SwiftUI
import MultipeerConnectivity

// MARK: - Settings Helpers

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.accent)
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal)
            
            VStack(spacing: 0) {
                content()
            }
            .padding()
            .background(AppTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.cardBorder, lineWidth: 1))
            .padding(.horizontal)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.accent)
                .frame(width: 24)
            Text(title)
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .foregroundColor(.white.opacity(0.4))
                .font(.subheadline)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.accent)
                .frame(width: 24)
            Text(title)
                .foregroundColor(.white)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppTheme.accent)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Bağlantı Durumu Card

struct ConnectionStatusCard: View {
    
    let multipeerManager: MultipeerManager
    let onConnectionTap: () -> Void
    
    var body: some View {
        Button(action: onConnectionTap) {
            HStack(spacing: 14) {
                // Animated status indicator
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: statusIcon)
                        .font(.system(size: 22))
                        .foregroundStyle(statusColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bağlantı Durumu")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text(multipeerManager.connectionStatus)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if !multipeerManager.connectedPeers.isEmpty {
                        Text(connectedDevicesText)
                            .font(.caption)
                            .foregroundColor(AppTheme.accent.opacity(0.8))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding()
            .background(AppTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.cardBorder, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
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

// MARK: - Hızlı Aksiyon Card

struct QuickActionCard: View {
    
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: gradient.map { $0.opacity(0.25) },
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(
                            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 8)
            .background(AppTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.cardBorder, lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Grup Sohbet Header View

struct GroupChatHeaderView: View {
    let peers: [ConnectedPeer]
    
    // Peer adına göre sabit renk oluştur
    private func colorForPeer(_ name: String) -> Color {
        let colors: [Color] = [
            .blue, .green, .orange, .purple, .pink, .mint, .cyan, .indigo, .teal, .yellow
        ]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Katılımcı avatarları (üst üste binen)
            HStack(spacing: -8) {
                ForEach(Array(peers.prefix(5).enumerated()), id: \.element.id) { index, peer in
                    ZStack {
                        Circle()
                            .fill(colorForPeer(peer.displayName))
                            .frame(width: 28, height: 28)
                        Text(String(peer.displayName.prefix(1)).uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .overlay(Circle().stroke(Color(red: 0.1, green: 0.12, blue: 0.22), lineWidth: 2))
                    .zIndex(Double(5 - index))
                }
                
                if peers.count > 5 {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 28, height: 28)
                        Text("+\(peers.count - 5)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .overlay(Circle().stroke(Color(red: 0.1, green: 0.12, blue: 0.22), lineWidth: 2))
                }
            }
            
            Spacer().frame(width: 10)
            
            VStack(alignment: .leading, spacing: 1) {
                Text("Grup Sohbet")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.8))
                Text("\(peers.count) kişi bağlı")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Spacer()
            
            // Çevrimiçi göstergesi
            HStack(spacing: 4) {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
                Text("Aktif")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.12))
            .clipShape(Capsule())
        }
        .padding(10)
        .background(AppTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.cardBorder, lineWidth: 1))
    }
}

// MARK: - Mesaj Bubble View

struct MessageBubbleView: View {
    
    let message: ChatMessage
    
    // Peer adına göre sabit renk oluştur
    private func colorForName(_ name: String) -> Color {
        let colors: [Color] = [
            .blue, .green, .orange, .purple, .pink, .mint, .cyan, .indigo, .teal, .yellow
        ]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromCurrentUser { Spacer(minLength: 60) }
            
            // Gönderen avatarı (sadece başkalarının mesajları için)
            if !message.isFromCurrentUser && message.type == .text {
                ZStack {
                    Circle()
                        .fill(colorForName(message.senderName))
                        .frame(width: 30, height: 30)
                    Text(String(message.senderName.prefix(1)).uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                
                if !message.isFromCurrentUser && message.type == .text {
                    Text(message.senderName)
                        .font(.caption.weight(.medium))
                        .foregroundColor(colorForName(message.senderName).opacity(0.9))
                        .padding(.horizontal, 4)
                }
                
                if message.type == .text {
                    Text(message.content)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            message.isFromCurrentUser ?
                                AnyShapeStyle(LinearGradient(colors: [AppTheme.accent, AppTheme.secondary],
                                                             startPoint: .topLeading, endPoint: .bottomTrailing)) :
                                AnyShapeStyle(Color.white.opacity(0.1))
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: systemMessageIcon)
                            .font(.caption)
                        Text(message.content)
                            .font(.caption)
                            .italic()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(systemMessageColor.opacity(0.12))
                    .foregroundColor(systemMessageColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                if message.type == .text {
                    HStack(spacing: 4) {
                        Text(message.formattedTime)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.3))
                        
                        if message.isFromCurrentUser {
                            Image(systemName: message.messageIcon)
                                .font(.system(size: 10))
                                .foregroundColor(message.status == .failed ? .red : .white.opacity(0.3))
                        }
                    }
                }
            }
            
            if !message.isFromCurrentUser { Spacer(minLength: 60) }
        }
    }
    
    private var systemMessageIcon: String {
        switch message.type {
        case .systemInfo: return "info.circle"
        case .userJoined: return "person.badge.plus"
        case .userLeft: return "person.badge.minus"
        default: return "info.circle"
        }
    }
    
    private var systemMessageColor: Color {
        switch message.type {
        case .systemInfo: return .orange
        case .userJoined: return .green
        case .userLeft: return .red
        default: return .gray
        }
    }
}

// MARK: - Yazma Göstergesi

struct TypingIndicatorView: View {
    
    let typingUsers: [String]
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.5))
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
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            
            Spacer()
        }
        .onAppear { animationOffset = -3 }
        .overlay(
            Text("\(typingUsers.first ?? "Birisi") yazıyor...")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
                .offset(y: -25),
            alignment: .leading
        )
    }
}

// MARK: - Mesaj Giriş

struct MessageInputView: View {
    
    @Binding var text: String
    let isTyping: Bool
    let onTextChange: () -> Void
    let onSend: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Mesaj yazın...", text: $text, axis: .vertical)
                .lineLimit(1...5)
                .focused($isTextFieldFocused)
                .onChange(of: text) { _ in onTextChange() }
                .onSubmit { onSend() }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .foregroundColor(.white)
            
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                            LinearGradient(colors: [.gray.opacity(0.4), .gray.opacity(0.3)], startPoint: .top, endPoint: .bottom) :
                            LinearGradient(colors: [AppTheme.accent, AppTheme.secondary], startPoint: .top, endPoint: .bottom)
                    )
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(AppTheme.gradientBottom)
    }
}

// MARK: - Ekran Paylaşımı Grup View

struct ScreenShareGroupView: View {
    let connectedPeers: [ConnectedPeer]
    let activeSharers: [ActiveSharer]
    let isSharing: Bool
    let viewerCount: Int
    
    private func colorForName(_ name: String) -> Color {
        let colors: [Color] = [
            .blue, .green, .orange, .purple, .pink, .mint, .cyan, .indigo, .teal, .yellow
        ]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "person.2.wave.2.fill")
                    .foregroundColor(AppTheme.accent)
                Text("Grup Paylaşımı")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("\(connectedPeers.count) kişi")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            // Katılımcı listesi
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Kendim
                    VStack(spacing: 6) {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(AppTheme.accent)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                )
                            if isSharing {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 14, height: 14)
                                    .overlay(
                                        Image(systemName: "rectangle.inset.filled")
                                            .font(.system(size: 7))
                                            .foregroundColor(.white)
                                    )
                                    .overlay(Circle().stroke(Color(red: 0.1, green: 0.12, blue: 0.22), lineWidth: 2))
                            }
                        }
                        Text("Ben")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        if isSharing {
                            Text("Paylaşıyor")
                                .font(.system(size: 8))
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Diğer katılımcılar
                    ForEach(connectedPeers) { peer in
                        let isSharingScreen = activeSharers.contains { $0.id == peer.peerID.displayName }
                        VStack(spacing: 6) {
                            ZStack(alignment: .bottomTrailing) {
                                Circle()
                                    .fill(colorForName(peer.displayName))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(String(peer.displayName.prefix(1)).uppercased())
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                if isSharingScreen {
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 14, height: 14)
                                        .overlay(
                                            Image(systemName: "rectangle.inset.filled")
                                                .font(.system(size: 7))
                                                .foregroundColor(.white)
                                        )
                                        .overlay(Circle().stroke(Color(red: 0.1, green: 0.12, blue: 0.22), lineWidth: 2))
                                } else {
                                    Circle()
                                        .fill(.green)
                                        .frame(width: 12, height: 12)
                                        .overlay(Circle().stroke(Color(red: 0.1, green: 0.12, blue: 0.22), lineWidth: 2))
                                }
                            }
                            Text(peer.displayName.components(separatedBy: " ").first ?? peer.displayName)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                            if isSharingScreen {
                                Text("Paylaşıyor")
                                    .font(.system(size: 8))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(14)
        .background(AppTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.cardBorder, lineWidth: 1))
    }
}

// MARK: - Ekran Paylaşımı Durum

struct ScreenShareStatusView: View {
    
    @ObservedObject var screenShareManager: ScreenShareManager
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 90, height: 90)
                
                Image(systemName: statusIcon)
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(statusColor)
            }
            
            VStack(spacing: 6) {
                Text(statusTitle)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(statusSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            if screenShareManager.isSharing || screenShareManager.isReceivingShare {
                HStack(spacing: 24) {
                    if screenShareManager.isSharing {
                        VStack(spacing: 4) {
                            Text("\(screenShareManager.sentFrameCount)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.accent)
                            Text("Gönderilen")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    if screenShareManager.isReceivingShare {
                        VStack(spacing: 4) {
                            Text("\(screenShareManager.receivedFrameCount)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                            Text("Alınan")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
                .padding()
                .background(AppTheme.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding()
    }
    
    private var statusIcon: String {
        switch screenShareManager.status {
        case .idle: return "rectangle.on.rectangle"
        case .starting: return "play.circle"
        case .recording, .streaming: return "record.circle.fill"
        case .stopping: return "stop.circle"
        case .error(_): return "exclamationmark.triangle.fill"
        }
    }
    
    private var statusColor: Color {
        switch screenShareManager.status {
        case .idle: return .white.opacity(0.5)
        case .starting: return .orange
        case .recording, .streaming: return .green
        case .stopping: return .orange
        case .error(_): return .red
        }
    }
    
    private var statusTitle: String {
        switch screenShareManager.status {
        case .idle: return "Hazır"
        case .starting: return "Başlatılıyor..."
        case .recording: return "Kaydediliyor"
        case .streaming: return "Paylaşılıyor"
        case .stopping: return "Durduruluyor..."
        case .error(_): return "Hata"
        }
    }
    
    private var statusSubtitle: String {
        switch screenShareManager.status {
        case .idle: return "Ekranınızı paylaşmaya başlamak için butona basın"
        case .starting: return "Lütfen ekran kaydı izni verin"
        case .recording: return "Ekran kaydediliyor, stream bekleniyor"
        case .streaming: return "Ekranınız aktarılıyor"
        case .stopping: return "Paylaşım sonlandırılıyor"
        case .error(let message): return message
        }
    }
}

// MARK: - Ekran Paylaşımı İstatistik

struct ScreenShareStatsView: View {
    
    @ObservedObject var screenShareManager: ScreenShareManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(AppTheme.accent)
                Text("İstatistikler")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            VStack(spacing: 10) {
                if screenShareManager.isSharing {
                    StatRow(title: "Gönderilen Frame", value: "\(screenShareManager.sentFrameCount)")
                    Divider().overlay(Color.white.opacity(0.08))
                    StatRow(title: "Stream Kalitesi", value: "\(Int(screenShareManager.streamQuality * 100))%")
                }
                if screenShareManager.isReceivingShare {
                    StatRow(title: "Alınan Frame", value: "\(screenShareManager.receivedFrameCount)")
                }
            }
            .padding()
            .background(AppTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.cardBorder, lineWidth: 1))
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.white.opacity(0.5))
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Aktif Çağrı View

struct ActiveCallView: View {
    
    @ObservedObject var audioCallManager: AudioCallManager
    
    var body: some View {
        VStack(spacing: 14) {
            
            HStack(spacing: 10) {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                Text(audioCallManager.currentCall?.peerName ?? "Bilinmiyor")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text(audioCallManager.currentCall?.formattedDuration ?? "00:00")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            if audioCallManager.audioLevel > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.1))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(audioCallManager.audioLevel))
                    }
                }
                .frame(height: 4)
            }
            
            HStack(spacing: 16) {
                CallControlButton(
                    icon: audioCallManager.isMuted ? "mic.slash.fill" : "mic.fill",
                    color: audioCallManager.isMuted ? .red : .white.opacity(0.2),
                    action: { audioCallManager.toggleMute() }
                )
                
                CallControlButton(
                    icon: audioCallManager.isSpeakerOn ? "speaker.wave.3.fill" : "speaker.fill",
                    color: audioCallManager.isSpeakerOn ? AppTheme.accent : .white.opacity(0.2),
                    action: { audioCallManager.toggleSpeaker() }
                )
                
                Spacer()
                
                Button(action: { audioCallManager.endCall() }) {
                    Image(systemName: "phone.down.fill")
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(AppTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.cardBorder, lineWidth: 1))
    }
}

struct CallControlButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(color)
                .clipShape(Circle())
        }
    }
}

// MARK: - QR Kod Gösterme View

struct QRCodeDisplayView: View {
    let connectionInfo: QRConnectionInfo
    
    var body: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "QR Kodunuz", icon: "qrcode", color: AppTheme.accent)
            
            VStack(spacing: 14) {
                if let qrImage = QRCodeManager.generateQRCode(from: connectionInfo) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: AppTheme.accent.opacity(0.3), radius: 12)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .overlay(
                            Text("QR kod oluşturulamadı")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        )
                }
                
                Text(connectionInfo.deviceName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                
                Text("Diğer cihaz bu kodu tarayarak bağlanabilir")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(AppTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.cardBorder, lineWidth: 1))
        }
        .padding(.horizontal)
    }
}

// MARK: - QR Tarayıcı Sheet View

struct QRScannerSheetView: View {
    @ObservedObject var qrManager: QRCodeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Kamera alanı
                    ZStack {
                        QRScannerView(
                            onCodeScanned: { code in
                                qrManager.handleScannedCode(code)
                            },
                            isScanning: $qrManager.isScanning
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        
                        // Tarama çerçevesi
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppTheme.accent.opacity(0.5), lineWidth: 2)
                        
                        // Tarama hedefi
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.accent, lineWidth: 3)
                            .frame(width: 220, height: 220)
                    }
                    .frame(height: 350)
                    .padding(.horizontal)
                    
                    // Durum mesajı
                    if !qrManager.scanStatus.isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: qrManager.scannedConnectionInfo != nil ? "checkmark.circle.fill" : "info.circle.fill")
                                .foregroundColor(qrManager.scannedConnectionInfo != nil ? .green : .orange)
                            Text(qrManager.scanStatus)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            (qrManager.scannedConnectionInfo != nil ? Color.green : Color.orange).opacity(0.15)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                    }
                    
                    // Talimat
                    VStack(spacing: 8) {
                        Text("QR Kodu Tarayın")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Diğer cihazın QR kodunu kameranızla tarayın")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top, 10)
            }
            .navigationTitle("QR Tarayıcı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        qrManager.isScanning = false
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accent)
                }
            }
        }
        .onAppear {
            qrManager.isScanning = true
        }
    }
}

// MARK: - Bağlantı View

struct ConnectionView: View {
    
    @ObservedObject var multipeerManager: MultipeerManager
    @StateObject private var qrManager: QRCodeManager
    @State private var showingQRScanner = false
    @State private var showingMyQR = false
    @Environment(\.dismiss) private var dismiss
    
    init(multipeerManager: MultipeerManager) {
        self.multipeerManager = multipeerManager
        _qrManager = StateObject(wrappedValue: QRCodeManager(multipeerManager: multipeerManager))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        
                        // QR Kod Butonları
                        HStack(spacing: 12) {
                            Button(action: { showingMyQR.toggle() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "qrcode")
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("QR Kodumu Göster")
                                            .font(.subheadline.weight(.semibold))
                                        Text("Diğer cihaz tarasın")
                                            .font(.caption2)
                                            .opacity(0.6)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(
                                    LinearGradient(colors: [AppTheme.accent.opacity(0.2), AppTheme.secondary.opacity(0.15)],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.accent.opacity(0.3), lineWidth: 1))
                            }
                            
                            Button(action: { showingQRScanner = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "camera.viewfinder")
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("QR Kod Tara")
                                            .font(.subheadline.weight(.semibold))
                                        Text("Kamera ile tara")
                                            .font(.caption2)
                                            .opacity(0.6)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(
                                    LinearGradient(colors: [Color.green.opacity(0.2), Color.mint.opacity(0.15)],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.3), lineWidth: 1))
                            }
                        }
                        .padding(.horizontal)
                        
                        // QR Kod Gösterimi
                        if showingMyQR {
                            QRCodeDisplayView(connectionInfo: qrManager.generateConnectionInfo())
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Bağlı Cihazlar
                        if !multipeerManager.connectedPeers.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Bağlı Cihazlar (\(multipeerManager.connectedPeers.count))", icon: "checkmark.circle.fill", color: .green)
                                
                                ForEach(multipeerManager.connectedPeers) { peer in
                                    HStack(spacing: 12) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(peer.displayName)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(.white)
                                            Text("Bağlı")
                                                .font(.caption)
                                                .foregroundColor(.green.opacity(0.7))
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                    .background(AppTheme.cardBg)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.2), lineWidth: 1))
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Bulunan Cihazlar
                        if !multipeerManager.availablePeers.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Bulunan Cihazlar", icon: "wifi.circle", color: .orange)
                                
                                ForEach(multipeerManager.availablePeers, id: \.self) { peer in
                                    HStack(spacing: 12) {
                                        Image(systemName: "wifi.circle")
                                            .foregroundColor(.orange)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(peer.displayName)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(.white)
                                            Text("Bağlanabilir")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.4))
                                        }
                                        Spacer()
                                        Button("Bağlan") {
                                            multipeerManager.connectToPeer(peer)
                                        }
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(AppTheme.accent)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(AppTheme.accent.opacity(0.15))
                                        .clipShape(Capsule())
                                    }
                                    .padding()
                                    .background(AppTheme.cardBg)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.cardBorder, lineWidth: 1))
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Boş durum
                        if multipeerManager.connectedPeers.isEmpty && multipeerManager.availablePeers.isEmpty {
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.accent.opacity(0.1))
                                        .frame(width: 80, height: 80)
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .font(.system(size: 32, weight: .light))
                                        .foregroundColor(AppTheme.accent)
                                }
                                
                                Text("Cihaz Aranıyor...")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("Yakındaki AirLink cihazları aranıyor\nveya QR kod ile hızlıca eşleştirin")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.4))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 40)
                        }
                        
                        // Kontroller
                        VStack(spacing: 0) {
                            SettingsToggleRow(icon: "antenna.radiowaves.left.and.right", title: "Advertising",
                                isOn: Binding(
                                    get: { multipeerManager.isAdvertising },
                                    set: { newValue in
                                        if newValue { multipeerManager.startAdvertising() }
                                        else { multipeerManager.stopAdvertising() }
                                    }
                                ))
                            Divider().overlay(Color.white.opacity(0.1)).padding(.vertical, 4)
                            SettingsToggleRow(icon: "magnifyingglass", title: "Browsing",
                                isOn: Binding(
                                    get: { multipeerManager.isBrowsing },
                                    set: { newValue in
                                        if newValue { multipeerManager.startBrowsing() }
                                        else { multipeerManager.stopBrowsing() }
                                    }
                                ))
                        }
                        .padding()
                        .background(AppTheme.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.cardBorder, lineWidth: 1))
                        .padding(.horizontal)
                        
                        Spacer(minLength: 30)
                    }
                    .padding(.top, 10)
                    .animation(.easeInOut(duration: 0.25), value: showingMyQR)
                }
            }
            .navigationTitle("Bağlantılar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(AppTheme.accent)
                }
            }
            .sheet(isPresented: $showingQRScanner) {
                QRScannerSheetView(qrManager: qrManager)
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.subheadline)
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

// MARK: - Uygulama Seçici Card

struct AppPickerCard: View {
    let app: ShareableApp
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(colors: app.gradient.map { $0.opacity(isSelected ? 0.4 : 0.15) },
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: app.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(
                            LinearGradient(colors: app.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }
                
                Text(app.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(isSelected ? 1.0 : 0.6))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? AppTheme.accent.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? AppTheme.accent.opacity(0.6) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}