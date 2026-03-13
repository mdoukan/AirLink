//
//  ContentView.swift
//  AirLink
//
//  Ana kullanıcı arayüzü - Tüm özelliklerin birleştirildiği SwiftUI view
//  Mesajlaşma, ekran paylaşımı ve sesli görüşme için unified interface
//

import SwiftUI
import MultipeerConnectivity
import AVFoundation
import ReplayKit

// MARK: - Ana View

struct ContentView: View {
    
    // MARK: - Managers
    @StateObject private var multipeerManager = MultipeerManager()
    @StateObject private var messageManager: MessageManager
    @StateObject private var screenShareManager: ScreenShareManager
    @StateObject private var audioCallManager: AudioCallManager
    
    // MARK: - View State
    @State private var selectedTab = 0
    @State private var messageText = ""
    @State private var showingConnectionSheet = false
    @State private var showingIncomingCallAlert = false
    @State private var incomingCallPeer: MCPeerID?
    @State private var incomingCallerName = ""
    
    // MARK: - Initialization
    
    init() {
        let multipeerManager = MultipeerManager()
        let messageManager = MessageManager(multipeerManager: multipeerManager)
        let screenShareManager = ScreenShareManager(multipeerManager: multipeerManager)
        let audioCallManager = AudioCallManager(multipeerManager: multipeerManager)
        
        _multipeerManager = StateObject(wrappedValue: multipeerManager)
        _messageManager = StateObject(wrappedValue: messageManager)
        _screenShareManager = StateObject(wrappedValue: screenShareManager)
        _audioCallManager = StateObject(wrappedValue: audioCallManager)
    }
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                
                // MARK: - Anasayfa Tab
                homeView
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Anasayfa")
                    }
                    .tag(0)
                
                // MARK: - Mesajlar Tab  
                messagesView
                    .tabItem {
                        Image(systemName: "message.fill")
                        Text("Mesajlar")
                        if messageManager.unreadCount > 0 {
                            Text("\(messageManager.unreadCount)")
                        }
                    }
                    .tag(1)
                
                // MARK: - Ekran Paylaşımı Tab
                screenShareView
                    .tabItem {
                        Image(systemName: "tv.fill")
                        Text("Ekran Paylaşımı")
                    }
                    .tag(2)
                
                // MARK: - Ayarlar Tab
                settingsView
                    .tabItem {
                        Image(systemName: "gear.fill") 
                        Text("Ayarlar")
                    }
                    .tag(3)
            }
            .onChange(of: selectedTab) { newValue in
                if newValue == 1 { // Mesajlar tab'ı
                    messageManager.markAllAsRead()
                }
            }
        }
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
        VStack(spacing: 20) {
            
            // MARK: - Header
            VStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("AirLink")
                    .font(.largeTitle)
                    .bold()
                
                Text("Offline Cihazlar Arası İletişim")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            // MARK: - Bağlantı Durumu
            ConnectionStatusCard(
                multipeerManager: multipeerManager,
                onConnectionTap: { showingConnectionSheet = true }
            )
            
            // MARK: - Hızlı Aksiyonlar
            VStack(alignment: .leading, spacing: 15) {
                Text("Hızlı Aksiyonlar")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                    
                    // Mesaj gönder
                    QuickActionCard(
                        icon: "message.fill",
                        title: "Mesaj Gönder", 
                        subtitle: "\(messageManager.messages.count) mesaj",
                        color: .blue
                    ) {
                        selectedTab = 1
                    }
                    
                    // Ekran paylaş
                    QuickActionCard(
                        icon: "tv.fill",
                        title: "Ekran Paylaş",
                        subtitle: screenShareManager.isSharing ? "Paylaşılıyor" : "Başlat",
                        color: .green
                    ) {
                        if screenShareManager.isSharing {
                            screenShareManager.stopScreenShare()
                        } else {
                            selectedTab = 2
                        }
                    }
                    
                    // Sesli arama
                    QuickActionCard(
                        icon: "phone.fill",
                        title: "Sesli Arama",
                        subtitle: audioCallManager.isInCall ? "Devam Ediyor" : "Başlat",
                        color: .orange
                    ) {
                        if audioCallManager.isInCall {
                            audioCallManager.endCall()
                        } else {
                            startVoiceCall()
                        }
                    }
                    
                    // Bağlı cihazlar
                    QuickActionCard(
                        icon: "antenna.radiowaves.left.and.right",
                        title: "Cihaz Bağlantısı",
                        subtitle: "\(multipeerManager.connectedPeers.count) cihaz",
                        color: .purple
                    ) {
                        showingConnectionSheet = true
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // MARK: - Çağrı Durumu (Eğer varsa)
            if audioCallManager.isInCall {
                ActiveCallView(audioCallManager: audioCallManager)
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}

// MARK: - Mesajlar View

private extension ContentView {
    
    var messagesView: some View {
        VStack {
            // MARK: - Mesaj Listesi
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messageManager.messages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }
                        
                        // Yazma durumu göstergesi
                        if !messageManager.typingUsers.isEmpty {
                            TypingIndicatorView(typingUsers: messageManager.typingUsers)
                        }
                    }
                    .padding(.horizontal)
                }
                .onChange(of: messageManager.messages.count) { _ in
                    if let lastMessage = messageManager.messages.last {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // MARK: - Mesaj Giriş Alanı
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
        .navigationTitle("Mesajlar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Mesajları Temizle", role: .destructive) {
                        messageManager.clearMessages()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

// MARK: - Ekran Paylaşımı View

private extension ContentView {
    
    var screenShareView: some View {
        VStack(spacing: 20) {
            
            // MARK: - Durum Göstergesi
            ScreenShareStatusView(screenShareManager: screenShareManager)
            
            // MARK: - Kontroller
            VStack(spacing: 15) {
                
                if !screenShareManager.isSharing && !screenShareManager.isReceivingShare {
                    // Paylaşım başlatma
                    Button(action: {
                        screenShareManager.startScreenShare()
                    }) {
                        Label("Ekran Paylaşımını Başlat", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                } else if screenShareManager.isSharing {
                    // Paylaşım durdurma
                    Button(action: {
                        screenShareManager.stopScreenShare()
                    }) {
                        Label("Paylaşımı Durdur", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                
                // MARK: - Kalite Ayarı
                if screenShareManager.isSharing {
                    VStack(alignment: .leading, spacing: 8) {
                    Text("Stream Kalitesi: \(Int(screenShareManager.streamQuality * 100))%")
                            .foregroundColor(.secondary)
                        
                        Slider(value: .constant(screenShareManager.streamQuality), 
                               in: 0.1...1.0,
                               step: 0.1) { _ in
                            // Kalite güncellemesi
                            screenShareManager.setStreamQuality(screenShareManager.streamQuality)
                        }
                        .accentColor(.blue)
                    }
                }
            }
            .padding(.horizontal)
            
            // MARK: - İstatistikler
            if screenShareManager.isSharing || screenShareManager.isReceivingShare {
                ScreenShareStatsView(screenShareManager: screenShareManager)
            }
            
            Spacer()
            
            // MARK: - Gelen Video (Eğer varsa)
            if screenShareManager.isReceivingShare {
                Text("Ekran paylaşımı alınıyor...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Ekran Paylaşımı") 
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Ayarlar View

private extension ContentView {
    
    var settingsView: some View {
        Form {
            
            // MARK: - Cihaz Bilgileri
            Section("Cihaz Bilgileri") {
                HStack {
                    Text("Cihaz Adı")
                    Spacer()
                    Text(UIDevice.current.name)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Peer ID")
                    Spacer()
                    Text(multipeerManager.peerID.displayName)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            
            // MARK: - Bağlantı Ayarları
            Section("Bağlantı") {
                HStack {
                    Text("Advertising")
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
                    Text("Browsing")
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
            
            // MARK: - Ses Ayarları
            Section("Ses Ayarları") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mikrofon Gain: \(Int(audioCallManager.audioSettings.inputGain * 100))%")
                        .font(.subheadline)
                    
                    Slider(value: .constant(audioCallManager.audioSettings.inputGain), in: 0...1) { _ in
                        var settings = audioCallManager.audioSettings
                        settings.inputGain = audioCallManager.audioSettings.inputGain  
                        audioCallManager.updateAudioSettings(settings)
                    }
                }
                
                Toggle("Echo Cancellation", isOn: .constant(audioCallManager.audioSettings.echoCancellation))
                Toggle("Noise Suppression", isOn: .constant(audioCallManager.audioSettings.noiseSuppression))
                Toggle("Auto Gain Control", isOn: .constant(audioCallManager.audioSettings.autoGainControl))
            }
            
            // MARK: - Video Ayarları
            Section("Video Ayarları") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Varsayılan Kalite: \(Int(screenShareManager.streamQuality * 100))%")
                        .font(.subheadline)
                    
                    Slider(value: .constant(screenShareManager.streamQuality), in: 0.1...1.0) { _ in
                        screenShareManager.setStreamQuality(screenShareManager.streamQuality)
                    }
                }
            }
            
            // MARK: - Hakkında
            Section("Hakkında") {
                HStack {
                    Text("Versiyon")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Yapım")
                    Spacer()  
                    Text("2026")
                        .foregroundColor(.secondary)
                }
            }
            
            // MARK: - Tehlikeli Aksiyonlar
            Section("Tehlikeli Aksiyonlar") {
                Button("Tüm Bağlantıları Kes", role: .destructive) {
                    multipeerManager.disconnect()
                    audioCallManager.endCall()
                    screenShareManager.stopScreenShare()
                }
                
                Button("Mesaj Geçmişini Temizle", role: .destructive) {
                    messageManager.clearMessages()
                }
            }
        }
        .navigationTitle("Ayarlar")
        .navigationBarTitleDisplayMode(.inline)
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