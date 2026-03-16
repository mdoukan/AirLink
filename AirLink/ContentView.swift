//
//  ContentView.swift
//  AirLink
//
//  Ana kullanıcı arayüzü - Modern tasarım
//

import SwiftUI
import MultipeerConnectivity
import AVFoundation
import ReplayKit

// MARK: - Theme

struct AppTheme {
    static let accent = Color(red: 0.35, green: 0.5, blue: 1.0)
    static let secondary = Color(red: 0.55, green: 0.4, blue: 1.0)
    static let gradientTop = Color(red: 0.1, green: 0.12, blue: 0.22)
    static let gradientBottom = Color(red: 0.05, green: 0.06, blue: 0.14)
    static let cardBg = Color.white.opacity(0.07)
    static let cardBorder = Color.white.opacity(0.1)
    
    static var backgroundGradient: LinearGradient {
        LinearGradient(colors: [gradientTop, gradientBottom],
                       startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Ana View

struct ContentView: View {
    
    @StateObject private var multipeerManager = MultipeerManager()
    @StateObject private var messageManager: MessageManager
    @StateObject private var screenShareManager: ScreenShareManager
    @StateObject private var audioCallManager: AudioCallManager
    
    @State private var selectedTab = 0
    @State private var messageText = ""
    @State private var showingConnectionSheet = false
    @State private var showingIncomingCallAlert = false
    @State private var incomingCallPeer: MCPeerID?
    @State private var incomingCallerName = ""
    @State private var voiceWithScreenShare = true
    
    init() {
        let multipeerManager = MultipeerManager()
        let messageManager = MessageManager(multipeerManager: multipeerManager)
        let screenShareManager = ScreenShareManager(multipeerManager: multipeerManager)
        let audioCallManager = AudioCallManager(multipeerManager: multipeerManager)
        
        _multipeerManager = StateObject(wrappedValue: multipeerManager)
        _messageManager = StateObject(wrappedValue: messageManager)
        _screenShareManager = StateObject(wrappedValue: screenShareManager)
        _audioCallManager = StateObject(wrappedValue: audioCallManager)
        
        // Tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(AppTheme.gradientBottom)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().unselectedItemTintColor = UIColor.lightGray.withAlphaComponent(0.5)
        
        // Nav bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(AppTheme.gradientTop)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                homeView
                    .tabItem {
                        Label("Anasayfa", systemImage: "house.fill")
                    }
                    .tag(0)
                
                messagesView
                    .tabItem {
                        Label("Mesajlar", systemImage: "bubble.left.and.bubble.right.fill")
                    }
                    .tag(1)
                
                screenShareView
                    .tabItem {
                        Label("Ekran", systemImage: "rectangle.on.rectangle.angled")
                    }
                    .tag(2)
                
                settingsView
                    .tabItem {
                        Label("Ayarlar", systemImage: "gearshape.fill")
                    }
                    .tag(3)
            }
            .tint(AppTheme.accent)
            .onChange(of: selectedTab) { newValue in
                if newValue == 1 {
                    messageManager.markAllAsRead()
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            setupCallbacks()
            multipeerManager.startAdvertising()
        }
        .alert("Gelen Çağrı", isPresented: $showingIncomingCallAlert) {
            Button("Kabul Et") {
                audioCallManager.acceptCall()
            }
            Button("Reddet", role: .destructive) {
                audioCallManager.declineCall()
            }
        } message: {
            Text("\(incomingCallerName) sizi arıyor...")
        }
        .sheet(isPresented: $showingConnectionSheet) {
            ConnectionView(multipeerManager: multipeerManager)
        }
    }
}

// MARK: - Ana Sayfa View

private extension ContentView {
    
    var homeView: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // MARK: - Hero Header
                    VStack(spacing: 12) {
                        ZStack {
                            // Glow effect
                            Circle()
                                .fill(AppTheme.accent.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .blur(radius: 30)
                            
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 50, weight: .light))
                                .foregroundStyle(
                                    LinearGradient(colors: [AppTheme.accent, AppTheme.secondary],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .shadow(color: AppTheme.accent.opacity(0.5), radius: 10)
                        }
                        
                        Text("AirLink")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(colors: [.white, Color.white.opacity(0.8)],
                                               startPoint: .top, endPoint: .bottom)
                            )
                        
                        Text("Çevrimdışı Peer-to-Peer İletişim")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.top, 10)
                    
                    // MARK: - Bağlantı Durumu
                    ConnectionStatusCard(
                        multipeerManager: multipeerManager,
                        onConnectionTap: { showingConnectionSheet = true }
                    )
                    .padding(.horizontal)
                    
                    // MARK: - Hızlı Aksiyonlar
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Hızlı Aksiyonlar")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 2), spacing: 14) {
                            
                            QuickActionCard(
                                icon: "bubble.left.and.bubble.right.fill",
                                title: "Mesaj Gönder",
                                subtitle: "\(messageManager.messages.count) mesaj",
                                gradient: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.3, green: 0.35, blue: 0.9)]
                            ) {
                                selectedTab = 1
                            }
                            
                            QuickActionCard(
                                icon: "rectangle.on.rectangle.angled",
                                title: "Ekran Paylaş",
                                subtitle: screenShareManager.isSharing ? "Aktif" : "Başlat",
                                gradient: [Color(red: 0.2, green: 0.8, blue: 0.5), Color(red: 0.1, green: 0.6, blue: 0.45)]
                            ) {
                                selectedTab = 2
                            }
                            
                            QuickActionCard(
                                icon: "phone.fill",
                                title: "Sesli Arama",
                                subtitle: audioCallManager.isInCall ? "Devam Ediyor" : "Başlat",
                                gradient: [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 0.9, green: 0.4, blue: 0.2)]
                            ) {
                                if audioCallManager.isInCall {
                                    audioCallManager.endCall()
                                } else {
                                    startVoiceCall()
                                }
                            }
                            
                            QuickActionCard(
                                icon: "link.circle.fill",
                                title: "Cihaz Bağlantısı",
                                subtitle: "\(multipeerManager.connectedPeers.count) cihaz",
                                gradient: [Color(red: 0.7, green: 0.3, blue: 1.0), Color(red: 0.5, green: 0.2, blue: 0.9)]
                            ) {
                                showingConnectionSheet = true
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // MARK: - Aktif Çağrı
                    if audioCallManager.isInCall {
                        ActiveCallView(audioCallManager: audioCallManager)
                            .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 20)
                }
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}

// MARK: - Mesajlar View

private extension ContentView {
    
    var messagesView: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Text("Mesajlar")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        Menu {
                            Button(role: .destructive) {
                                messageManager.clearMessages()
                            } label: {
                                Label("Mesajları Temizle", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    
                    // Grup bilgisi
                    if !multipeerManager.connectedPeers.isEmpty {
                        GroupChatHeaderView(peers: multipeerManager.connectedPeers)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                // Mesaj Listesi
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(messageManager.messages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }
                            
                            if !messageManager.typingUsers.isEmpty {
                                TypingIndicatorView(typingUsers: messageManager.typingUsers)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .onChange(of: messageManager.messages.count) { _ in
                        if let lastMessage = messageManager.messages.last {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Mesaj Giriş
                MessageInputView(
                    text: $messageText,
                    isTyping: messageManager.isUserTyping,
                    onTextChange: {
                        if !messageText.isEmpty && !messageManager.isUserTyping {
                            messageManager.startTyping()
                        } else if messageText.isEmpty && messageManager.isUserTyping {
                            messageManager.stopTyping()
                        }
                    },
                    onSend: {
                        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        messageManager.sendMessage(messageText)
                        messageText = ""
                    }
                )
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}

// MARK: - Ekran Paylaşımı View

private extension ContentView {
    
    var screenShareView: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // Header
                    Text("Ekran Paylaşımı")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // Durum
                    ScreenShareStatusView(screenShareManager: screenShareManager)
                        .padding(.horizontal)
                    
                    // Kontroller
                    VStack(spacing: 14) {
                        
                        if !screenShareManager.isSharing && !screenShareManager.isReceivingShare {
                            
                            // Paylaşım Modu Seçici
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Paylaşım Modu")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                HStack(spacing: 10) {
                                    ForEach(ShareMode.allCases) { mode in
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                screenShareManager.shareMode = mode
                                                if mode == .fullScreen {
                                                    screenShareManager.selectedApp = nil
                                                }
                                            }
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: mode.icon)
                                                    .font(.subheadline)
                                                Text(mode.rawValue)
                                                    .font(.subheadline.weight(.medium))
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                screenShareManager.shareMode == mode ?
                                                    AnyShapeStyle(LinearGradient(colors: [AppTheme.accent, AppTheme.secondary],
                                                                                 startPoint: .leading, endPoint: .trailing)) :
                                                    AnyShapeStyle(Color.white.opacity(0.08))
                                            )
                                            .foregroundColor(.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(AppTheme.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.cardBorder, lineWidth: 1))
                            
                            // Uygulama Seçici Grid (sadece appSelect modunda)
                            if screenShareManager.shareMode == .appSelect {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.grid.2x2")
                                            .foregroundColor(AppTheme.accent)
                                        Text("Paylaşılacak Uygulama")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    
                                    Text("Ekran kaydı başlayacak ve seçtiğiniz uygulama açılacak")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.35))
                                    
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                                        ForEach(ShareableApp.availableApps) { app in
                                            AppPickerCard(
                                                app: app,
                                                isSelected: screenShareManager.selectedApp?.name == app.name,
                                                onTap: {
                                                    withAnimation(.easeInOut(duration: 0.15)) {
                                                        screenShareManager.selectedApp = app
                                                    }
                                                }
                                            )
                                        }
                                    }
                                }
                                .padding()
                                .background(AppTheme.cardBg)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.cardBorder, lineWidth: 1))
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            
                            // Sesli arama toggle
                            HStack(spacing: 12) {
                                Image(systemName: voiceWithScreenShare ? "mic.circle.fill" : "mic.slash.circle")
                                    .font(.title2)
                                    .foregroundStyle(voiceWithScreenShare ?
                                        LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom) :
                                        LinearGradient(colors: [.gray, .gray], startPoint: .top, endPoint: .bottom))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Sesli Arama ile Paylaş")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.white)
                                    Text("Discord tarzı ses + ekran")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $voiceWithScreenShare)
                                    .labelsHidden()
                                    .tint(.green)
                            }
                            .padding()
                            .background(AppTheme.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.cardBorder, lineWidth: 1))
                            
                            // Başlat butonu
                            Button(action: {
                                if screenShareManager.shareMode == .appSelect,
                                   let app = screenShareManager.selectedApp {
                                    screenShareManager.startScreenShareWithApp(app)
                                } else {
                                    screenShareManager.startScreenShare()
                                }
                                if voiceWithScreenShare {
                                    startVoiceCall()
                                }
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "play.fill")
                                    if screenShareManager.shareMode == .appSelect,
                                       let app = screenShareManager.selectedApp {
                                        Text("\(app.name) Paylaş")
                                            .fontWeight(.semibold)
                                    } else {
                                        Text("Ekran Paylaşımını Başlat")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    (screenShareManager.shareMode == .appSelect && screenShareManager.selectedApp == nil) ?
                                        LinearGradient(colors: [.gray.opacity(0.5), .gray.opacity(0.4)],
                                                       startPoint: .leading, endPoint: .trailing) :
                                        LinearGradient(colors: [AppTheme.accent, AppTheme.secondary],
                                                       startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: AppTheme.accent.opacity(0.4), radius: 8, y: 4)
                            }
                            .disabled(screenShareManager.shareMode == .appSelect && screenShareManager.selectedApp == nil)
                            
                        } else if screenShareManager.isSharing {
                            
                            // Paylaşılan uygulama bilgisi
                            if let app = screenShareManager.selectedApp {
                                HStack(spacing: 12) {
                                    Image(systemName: app.icon)
                                        .font(.title3)
                                        .foregroundStyle(
                                            LinearGradient(colors: app.gradient, startPoint: .top, endPoint: .bottom)
                                        )
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(app.name) paylaşılıyor")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(.white)
                                        Text("Uygulamaya geri dönmek için dokunun")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                    Spacer()
                                    Button(action: {
                                        if let url = URL(string: app.urlScheme) {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        Image(systemName: "arrow.up.forward.square")
                                            .font(.body)
                                            .foregroundColor(AppTheme.accent)
                                    }
                                }
                                .padding()
                                .background(AppTheme.cardBg)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.cardBorder, lineWidth: 1))
                            }
                            
                            // Aktif ses göstergesi
                            if audioCallManager.isInCall {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(.green)
                                        .frame(width: 10, height: 10)
                                    Text("Sesli Arama Aktif")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Button(action: { audioCallManager.toggleMute() }) {
                                        Image(systemName: audioCallManager.isMuted ? "mic.slash.fill" : "mic.fill")
                                            .font(.body)
                                            .foregroundColor(.white)
                                            .frame(width: 36, height: 36)
                                            .background(audioCallManager.isMuted ? Color.red.opacity(0.8) : Color.green.opacity(0.6))
                                            .clipShape(Circle())
                                    }
                                }
                                .padding()
                                .background(Color.green.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.green.opacity(0.3), lineWidth: 1))
                            } else {
                                Button(action: { startVoiceCall() }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "mic.fill")
                                        Text("Sesli Aramayı Başlat")
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.green.opacity(0.8))
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                            }
                            
                            // Durdur
                            Button(action: {
                                screenShareManager.stopScreenShare()
                                screenShareManager.selectedApp = nil
                                if audioCallManager.isInCall { audioCallManager.endCall() }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "stop.fill")
                                    Text("Paylaşımı Durdur")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        
                        // Kalite Ayarı
                        if screenShareManager.isSharing {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "slider.horizontal.3")
                                        .foregroundColor(AppTheme.accent)
                                    Text("Stream Kalitesi")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(Int(screenShareManager.streamQuality * 100))%")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(AppTheme.accent)
                                }
                                
                                Slider(value: $screenShareManager.streamQuality, in: 0.1...1.0, step: 0.1)
                                    .tint(AppTheme.accent)
                                    .onChange(of: screenShareManager.streamQuality) { newValue in
                                        screenShareManager.setStreamQuality(newValue)
                                    }
                            }
                            .padding()
                            .background(AppTheme.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppTheme.cardBorder, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal)
                    
                    // İstatistikler
                    if screenShareManager.isSharing || screenShareManager.isReceivingShare {
                        ScreenShareStatsView(screenShareManager: screenShareManager)
                            .padding(.horizontal)
                    }
                    
                    if screenShareManager.isReceivingShare {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(AppTheme.accent)
                            Text("Ekran paylaşımı alınıyor...")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}

// MARK: - Ayarlar View

private extension ContentView {
    
    var settingsView: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // Header
                    Text("Ayarlar")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // Cihaz Bilgileri
                    SettingsSection(title: "Cihaz Bilgileri", icon: "iphone") {
                        SettingsRow(icon: "person.crop.circle", title: "Cihaz Adı", value: UIDevice.current.name)
                        Divider().overlay(Color.white.opacity(0.1))
                        SettingsRow(icon: "number", title: "Peer ID", value: multipeerManager.peerID.displayName)
                    }
                    
                    // Bağlantı
                    SettingsSection(title: "Bağlantı", icon: "wifi") {
                        SettingsToggleRow(icon: "antenna.radiowaves.left.and.right", title: "Advertising",
                            isOn: Binding(
                                get: { multipeerManager.isAdvertising },
                                set: { newValue in
                                    if newValue { multipeerManager.startAdvertising() }
                                    else { multipeerManager.stopAdvertising() }
                                }
                            ))
                        Divider().overlay(Color.white.opacity(0.1))
                        SettingsToggleRow(icon: "magnifyingglass", title: "Browsing",
                            isOn: Binding(
                                get: { multipeerManager.isBrowsing },
                                set: { newValue in
                                    if newValue { multipeerManager.startBrowsing() }
                                    else { multipeerManager.stopBrowsing() }
                                }
                            ))
                    }
                    
                    // Ses Ayarları
                    SettingsSection(title: "Ses Ayarları", icon: "speaker.wave.3") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "mic.fill")
                                    .foregroundColor(AppTheme.accent)
                                    .frame(width: 24)
                                Text("Mikrofon Gain")
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(Int(audioCallManager.audioSettings.inputGain * 100))%")
                                    .foregroundColor(AppTheme.accent)
                                    .font(.subheadline.weight(.bold))
                            }
                            Slider(value: Binding(
                                get: { audioCallManager.audioSettings.inputGain },
                                set: { newValue in
                                    var settings = audioCallManager.audioSettings
                                    settings.inputGain = newValue
                                    audioCallManager.updateAudioSettings(settings)
                                }
                            ), in: 0...1)
                            .tint(AppTheme.accent)
                        }
                        Divider().overlay(Color.white.opacity(0.1))
                        SettingsToggleRow(icon: "waveform.path.ecg", title: "Echo Cancellation",
                            isOn: Binding(
                                get: { audioCallManager.audioSettings.echoCancellation },
                                set: { newValue in
                                    var settings = audioCallManager.audioSettings
                                    settings.echoCancellation = newValue
                                    audioCallManager.updateAudioSettings(settings)
                                }
                            ))
                        Divider().overlay(Color.white.opacity(0.1))
                        SettingsToggleRow(icon: "waveform.slash", title: "Noise Suppression",
                            isOn: Binding(
                                get: { audioCallManager.audioSettings.noiseSuppression },
                                set: { newValue in
                                    var settings = audioCallManager.audioSettings
                                    settings.noiseSuppression = newValue
                                    audioCallManager.updateAudioSettings(settings)
                                }
                            ))
                        Divider().overlay(Color.white.opacity(0.1))
                        SettingsToggleRow(icon: "dial.low", title: "Auto Gain Control",
                            isOn: Binding(
                                get: { audioCallManager.audioSettings.autoGainControl },
                                set: { newValue in
                                    var settings = audioCallManager.audioSettings
                                    settings.autoGainControl = newValue
                                    audioCallManager.updateAudioSettings(settings)
                                }
                            ))
                    }
                    
                    // Video Ayarları
                    SettingsSection(title: "Video Ayarları", icon: "video") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                    .foregroundColor(AppTheme.accent)
                                    .frame(width: 24)
                                Text("Varsayılan Kalite")
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(Int(screenShareManager.streamQuality * 100))%")
                                    .foregroundColor(AppTheme.accent)
                                    .font(.subheadline.weight(.bold))
                            }
                            Slider(value: $screenShareManager.streamQuality, in: 0.1...1.0, step: 0.1)
                                .tint(AppTheme.accent)
                                .onChange(of: screenShareManager.streamQuality) { newValue in
                                    screenShareManager.setStreamQuality(newValue)
                                }
                        }
                    }
                    
                    // Hakkında
                    SettingsSection(title: "Hakkında", icon: "info.circle") {
                        SettingsRow(icon: "tag", title: "Versiyon", value: "1.0.0")
                        Divider().overlay(Color.white.opacity(0.1))
                        SettingsRow(icon: "calendar", title: "Yapım", value: "2026")
                    }
                    
                    // Tehlikeli Aksiyonlar
                    VStack(spacing: 12) {
                        Button(action: {
                            multipeerManager.disconnect()
                            audioCallManager.endCall()
                            screenShareManager.stopScreenShare()
                        }) {
                            HStack {
                                Image(systemName: "wifi.slash")
                                Text("Tüm Bağlantıları Kes")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.3), lineWidth: 1))
                        }
                        
                        Button(action: { messageManager.clearMessages() }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Mesaj Geçmişini Temizle")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.3), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 30)
                }
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}

// MARK: - Helper Methods

private extension ContentView {
    
    func setupCallbacks() {
        // Gelen çağrı callback'i
        audioCallManager.onIncomingCall = { peer, callerName in
            incomingCallPeer = peer
            incomingCallerName = callerName
            showingIncomingCallAlert = true
        }
        
        // Çağrı bitiş callback'i
        audioCallManager.onCallEnded = {
            // UI güncellemeleri
        }
    }
    
    func startVoiceCall() {
        guard let peer = multipeerManager.connectedPeers.first?.peerID else {
            messageManager.addSystemMessage("Arama yapabilmek için önce bir cihaza bağlanın")
            return
        }
        
        audioCallManager.startCall(to: peer)
    }
}

// MARK: - Content View Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}