//
//  AudioCallManager.swift
//  AirLink
//
//  AVAudioSession ile sesli görüşme yönetimi
//  Multipeer Connectivity üzerinden gerçek zamanlı ses iletimi
//

import Foundation
import AVFoundation
import MultipeerConnectivity
import Combine
import CallKit

// MARK: - Ses Çağrı Durumu

enum AudioCallStatus {
    case idle           // Boşta
    case outgoingCall   // Giden çağrı
    case incomingCall   // Gelen çağrı  
    case connecting     // Bağlanıyor
    case active         // Aktif çağrı
    case ending         // Sonlandırılıyor
    case ended          // Sonlandı
    case error(String)  // Hata
}

// MARK: - Ses Çağrı Modeli

struct AudioCall: Identifiable {
    let id = UUID()
    let peerID: MCPeerID
    let peerName: String
    let startTime: Date
    var duration: TimeInterval = 0
    var isOutgoing: Bool
    var status: AudioCallStatus
}

// MARK: - Ses Ayarları

struct AudioSettings {
    var inputGain: Float = 0.5      // Mikrofon gain (0.0-1.0)
    var outputVolume: Float = 0.8   // Hoparlör ses seviyesi
    var echoCancellation: Bool = true
    var noiseSuppression: Bool = true
    var autoGainControl: Bool = true
    var sampleRate: Double = 44100.0
    var bufferSize: Int = 1024
}

// MARK: - Audio Call Manager

class AudioCallManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentCall: AudioCall?
    @Published var callStatus: AudioCallStatus = .idle
    @Published var isInCall = false
    @Published var isMuted = false
    @Published var isSpeakerOn = false
    @Published var audioSettings = AudioSettings()
    @Published var audioLevel: Float = 0.0  // Ses seviyesi göstergesi
    
    // MARK: - Private Properties
    private let multipeerManager: MultipeerManager
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var outputNode: AVAudioOutputNode?
    private var audioSession: AVAudioSession
    
    // Audio format ayarları
    private let audioFormat: AVAudioFormat
    private var audioBuffer: AVAudioPCMBuffer?
    
    // Timer'lar
    private var callTimer: Timer?
    private var audioLevelTimer: Timer?
    
    // Callback'ler  
    var onIncomingCall: ((MCPeerID, String) -> Void)?
    var onCallEnded: (() -> Void)?
    
    // MARK: - Initialization
    
    init(multipeerManager: MultipeerManager) {
        self.multipeerManager = multipeerManager
        self.audioSession = AVAudioSession.sharedInstance()
        
        // Audio format - 44.1kHz, 16-bit, mono
        self.audioFormat = AVAudioFormat(
            standardFormatWithSampleRate: audioSettings.sampleRate,
            channels: 1
        )!
        
        super.init()
        
        setupAudioSession()
        setupDataReceiver()
        
        print("🔊 AudioCallManager başlatıldı")
    }
    
    deinit {
        endCall()
        stopAudioEngine()
    }
}

// MARK: - Public Methods

extension AudioCallManager {
    
    /// Ses çağrısı başlat
    func startCall(to peer: MCPeerID) {
        guard callStatus == .idle else {
            print("⚠️ Zaten bir çağrı aktif")
            return
        }
        
        let call = AudioCall(
            peerID: peer,
            peerName: peer.displayName,
            startTime: Date(),
            isOutgoing: true,
            status: .outgoingCall
        )
        
        currentCall = call
        callStatus = .outgoingCall
        
        // Çağrı isteği gönder
        let callRequest = ["action": "call_invite", "callerName": UIDevice.current.name]
        if let data = try? JSONSerialization.data(withJSONObject: callRequest) {
            multipeerManager.sendDataToPeer(data, type: .audioData, peer: peer)
        }
        
        print("📞 Ses çağrısı başlatılıyor: \(peer.displayName)")
        
        // 30 saniye timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            if self.callStatus == .outgoingCall {
                self.endCall()
            }
        }
    }
    
    /// Gelen çağrıyı kabul et
    func acceptCall() {
        guard let call = currentCall, 
              call.status == .incomingCall else { return }
        
        callStatus = .connecting
        
        // Kabul mesajı gönder
        let response = ["action": "call_accept"]
        if let data = try? JSONSerialization.data(withJSONObject: response) {
            multipeerManager.sendDataToPeer(data, type: .audioData, peer: call.peerID)
        }
        
        startAudioCall()
        
        print("✅ Çağrı kabul edildi: \(call.peerName)")
    }
    
    /// Gelen çağrıyı reddet
    func declineCall() {
        guard let call = currentCall,
              call.status == .incomingCall else { return }
        
        // Reddetme mesajı gönder
        let response = ["action": "call_decline"]
        if let data = try? JSONSerialization.data(withJSONObject: response) {
            multipeerManager.sendDataToPeer(data, type: .audioData, peer: call.peerID)
        }
        
        resetCall()
        
        print("❌ Çağrı reddedildi: \(call.peerName)")
    }
    
    /// Çağrıyı sonlandır
    func endCall() {
        guard let call = currentCall else { return }
        
        callStatus = .ending
        
        // Sonlandırma mesajı gönder
        let endRequest = ["action": "call_end"]
        if let data = try? JSONSerialization.data(withJSONObject: endRequest) {
            multipeerManager.sendDataToPeer(data, type: .audioData, peer: call.peerID)
        }
        
        stopAudioCall()
        resetCall()
        onCallEnded?()
        
        print("📞 Çağrı sonlandırıldı")
    }
    
    /// Mikrofonu aç/kapa
    func toggleMute() {
        guard isInCall else { return }
        
        isMuted.toggle()
        
        if let inputNode = inputNode {
            inputNode.volume = isMuted ? 0.0 : audioSettings.inputGain
        }
        
        // Mute durumunu karşı tarafa bildir
        let muteStatus = ["action": "mute_status", "isMuted": isMuted]
        if let data = try? JSONSerialization.data(withJSONObject: muteStatus),
           let call = currentCall {
            multipeerManager.sendDataToPeer(data, type: .audioData, peer: call.peerID)
        }
        
        print("🔇 Mikrofon: \(isMuted ? "Kapalı" : "Açık")")
    }
    
    /// Hoparlöre geç
    func toggleSpeaker() {
        guard isInCall else { return }
        
        isSpeakerOn.toggle()
        
        do {
            if isSpeakerOn {
                try audioSession.overrideOutputAudioPort(.speaker)
            } else {
                try audioSession.overrideOutputAudioPort(.none)
            }
            
            print("🔊 Hoparlör: \(isSpeakerOn ? "Açık" : "Kapalı")")
        } catch {
            print("❌ Hoparlör geçiş hatası: \(error.localizedDescription)")
        }
    }
    
    /// Ses ayarlarını güncelle
    func updateAudioSettings(_ newSettings: AudioSettings) {
        audioSettings = newSettings
        
        if let inputNode = inputNode {
            inputNode.volume = isMuted ? 0.0 : audioSettings.inputGain
        }
        
        print("🎛️ Ses ayarları güncellendi")
    }
}

// MARK: - Private Methods

private extension AudioCallManager {
    
    func setupAudioSession() {
        do {
            // Audio session konfigürasyonu
            try audioSession.setCategory(.playAndRecord, 
                                       mode: .voiceChat, 
                                       options: [.allowBluetooth, .defaultToSpeaker])
            try audioSession.setActive(true)
            
            print("✅ Audio session kuruldu")
        } catch {
            print("❌ Audio session hatası: \(error.localizedDescription)")
        }
    }
    
    func setupDataReceiver() {
        multipeerManager.onDataReceived = { [weak self] data, dataType, peerID in
            guard dataType == .audioData else { return }
            self?.handleReceivedAudioData(data, from: peerID)
        }
    }
    
    func startAudioCall() {
        do {
            // Audio engine'i başlat
            audioEngine = AVAudioEngine()
            
            guard let engine = audioEngine else { return }
            
            inputNode = engine.inputNode
            outputNode = engine.outputNode
            
            // Input format
            let inputFormat = inputNode?.inputFormat(forBus: 0)
            
            // Audio buffer oluştur
            audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(audioSettings.bufferSize))
            
            // Mikrofon tap ekle
            inputNode?.installTap(onBus: 0, bufferSize: AVAudioFrameCount(audioSettings.bufferSize), format: inputFormat) { [weak self] buffer, time in
                self?.processInputBuffer(buffer)
            }
            
            // Audio engine'i başlat
            engine.prepare()
            try engine.start()
            
            callStatus = .active
            isInCall = true
            
            // Çağrı timer'ını başlat
            startCallTimer()
            startAudioLevelMonitoring()
            
            print("🎙️ Audio call başlatıldı")
            
        } catch {
            print("❌ Audio engine başlatma hatası: \(error.localizedDescription)")
            callStatus = .error(error.localizedDescription)
        }
    }
    
    func stopAudioCall() {
        stopAudioEngine()
        stopCallTimer()
        stopAudioLevelMonitoring()
        
        callStatus = .ended
        isInCall = false
        isMuted = false
        isSpeakerOn = false
    }
    
    func stopAudioEngine() {
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        audioEngine = nil
        inputNode = nil
        outputNode = nil
    }
    
    func resetCall() {
        currentCall = nil
        callStatus = .idle
        isInCall = false
        
        do {
            try audioSession.setActive(false)
        } catch {
            print("❌ Audio session deaktif hatası: \(error.localizedDescription)")
        }
    }
    
    func processInputBuffer(_ buffer: AVAudioPCMBuffer) {
        guard !isMuted, let call = currentCall else { return }
        
        // PCM verisi olarak ses datasını çıkar
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        
        // Float array'i Data'ya çevir
        let audioData = Data(bytes: channelData, count: frameCount * MemoryLayout<Float>.size)
        
        // Karşı tarafa ses verisi gönder
        let audioPacket = [
            "action": "audio_data", 
            "data": audioData.base64EncodedString(),
            "frameCount": frameCount
        ]
        
        if let packetData = try? JSONSerialization.data(withJSONObject: audioPacket) {
            multipeerManager.sendDataToPeer(packetData, type: .audioData, peer: call.peerID)
        }
        
        // Ses seviyesini hesapla (RMS)
        var sum: Float = 0
        for i in 0..<frameCount {
            sum += channelData[i] * channelData[i]
        }
        let rms = sqrt(sum / Float(frameCount))
        
        DispatchQueue.main.async {
            self.audioLevel = rms
        }
    }
    
    func handleReceivedAudioData(_ data: Data, from peer: MCPeerID) {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let action = jsonObject["action"] as? String else { return }
        
        switch action {
        case "call_invite":
            handleIncomingCall(from: peer, data: jsonObject)
        case "call_accept":
            handleCallAccepted()
        case "call_decline":
            handleCallDeclined()
        case "call_end":
            handleCallEnded()
        case "audio_data":
            handleAudioData(jsonObject)
        case "mute_status":
            handleMuteStatus(jsonObject)
        default:
            print("❓ Bilinmeyen audio action: \(action)")
        }
    }
    
    func handleIncomingCall(from peer: MCPeerID, data: [String: Any]) {
        guard callStatus == .idle else {
            // Meşgul mesajı gönder
            let busyResponse = ["action": "call_busy"]
            if let responseData = try? JSONSerialization.data(withJSONObject: busyResponse) {
                multipeerManager.sendDataToPeer(responseData, type: .audioData, peer: peer)
            }
            return
        }
        
        let callerName = data["callerName"] as? String ?? peer.displayName
        
        let call = AudioCall(
            peerID: peer,
            peerName: callerName,
            startTime: Date(),
            isOutgoing: false,
            status: .incomingCall
        )
        
        currentCall = call
        callStatus = .incomingCall
        
        onIncomingCall?(peer, callerName)
        
        print("📞 Gelen çağrı: \(callerName)")
    }
    
    func handleCallAccepted() {
        guard callStatus == .outgoingCall else { return }
        startAudioCall()
        print("✅ Çağrı kabul edildi")
    }
    
    func handleCallDeclined() {
        guard callStatus == .outgoingCall else { return }
        resetCall()
        print("❌ Çağrı reddedildi")
    }
    
    func handleCallEnded() {
        guard isInCall else { return }
        stopAudioCall()
        resetCall()
        onCallEnded?()
        print("📞 Çağrı sonlandırıldı")
    }
    
    func handleAudioData(_ data: [String: Any]) {
        guard isInCall,
              let base64Data = data["data"] as? String,
              let audioData = Data(base64Encoded: base64Data),
              let frameCount = data["frameCount"] as? Int else { return }
        
        // Audio data'yı player buffer'a çevir ve oynat
        playReceivedAudio(audioData, frameCount: frameCount)
    }
    
    func handleMuteStatus(_ data: [String: Any]) {
        if let remoteMuted = data["isMuted"] as? Bool {
            // Karşı tarafın mute durumunu UI'de göster
            print("🔇 Karşı taraf \(remoteMuted ? "muted" : "unmuted")")
        }
    }
    
    func playReceivedAudio(_ data: Data, frameCount: Int) {
        guard let engine = audioEngine,
              let outputNode = outputNode else { return }
        
        // Float array'e çevir
        let floatArray = data.withUnsafeBytes { bytes in
            return bytes.bindMemory(to: Float.self)
        }
        
        // PCM buffer oluştur
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(frameCount)) else { return }
        
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        if let channelData = buffer.floatChannelData?[0] {
            for i in 0..<frameCount {
                channelData[i] = floatArray[i]
            }
        }
        
        // Buffer'ı oynat
        let playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)
        engine.connect(playerNode, to: outputNode, format: audioFormat)
        
        playerNode.scheduleBuffer(buffer) {
            DispatchQueue.main.async {
                engine.detach(playerNode)
            }
        }
        
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
    
    // MARK: - Timer Methods
    
    func startCallTimer() {
        callTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let call = self.currentCall else { return }
            
            DispatchQueue.main.async {
                self.currentCall?.duration = Date().timeIntervalSince(call.startTime)
            }
        }
    }
    
    func stopCallTimer() {
        callTimer?.invalidate()
        callTimer = nil
    }
    
    func startAudioLevelMonitoring() {
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            // Bu timer audio level güncellemesi için kullanılıyor
            // processInputBuffer içinde audioLevel güncelleniyor
        }
    }
    
    func stopAudioLevelMonitoring() {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
        
        DispatchQueue.main.async {
            self.audioLevel = 0.0
        }
    }
}

// MARK: - Extensions

extension AudioCall {
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var statusText: String {
        switch status {
        case .idle:
            return "Boşta"
        case .outgoingCall:
            return "Aranıyor..."
        case .incomingCall:
            return "Gelen Çağrı"
        case .connecting:
            return "Bağlanıyor..."
        case .active:
            return "Devam Ediyor"
        case .ending:
            return "Sonlandırılıyor..."
        case .ended:
            return "Sonlandı"
        case .error(let message):
            return "Hata: \(message)"
        }
    }
}