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

// MARK: - Mesaj Bubble View

struct MessageBubbleView: View {
    
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser { Spacer(minLength: 60) }
            
            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                
                if !message.isFromCurrentUser && message.type == .text {
                    Text(message.senderName)
                        .font(.caption.weight(.medium))
                        .foregroundColor(AppTheme.accent.opacity(0.7))
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

// MARK: - Bağlantı View

struct ConnectionView: View {
    
    @ObservedObject var multipeerManager: MultipeerManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        
                        // Bağlı Cihazlar
                        if !multipeerManager.connectedPeers.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Bağlı Cihazlar", icon: "checkmark.circle.fill", color: .green)
                                
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
                                
                                Text("Yakındaki AirLink cihazları aranıyor")
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