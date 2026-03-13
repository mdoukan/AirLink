//
//  ScreenShareManager.swift
//  AirLink  
//
//  ReplayKit ile ekran yakalama ve H.264 video streaming 
//  Multipeer Connectivity üzerinden gerçek zamanlı ekran paylaşımı
//

import Foundation
import ReplayKit
import AVFoundation
import VideoToolbox
import MultipeerConnectivity
import Combine

// MARK: - Video Frame Model

struct VideoFrame: Codable {
    let frameData: Data
    let timestamp: Double
    let width: Int32
    let height: Int32
    let isKeyFrame: Bool
}

// MARK: - Ekran Paylaşımı Durumu

enum ScreenShareStatus {
    case idle          // Boşta
    case starting      // Başlatılıyor
    case recording     // Kaydediyor
    case streaming     // Stream ediyor  
    case stopping      // Durduruluyor
    case error(String) // Hata
}

// MARK: - Screen Share Manager

class ScreenShareManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var status: ScreenShareStatus = .idle
    @Published var isSharing = false
    @Published var isReceivingShare = false
    @Published var receivedFrameCount = 0
    @Published var sentFrameCount = 0
    @Published var streamQuality: Float = 0.8 // 0.0-1.0 arası kalite
    
    // MARK: - Private Properties
    private let multipeerManager: MultipeerManager
    private let screenRecorder = RPScreenRecorder.shared()
    private var videoEncoder: VideoEncoder?
    private var videoDecoder: VideoDecoder?
    
    // Video ayarları
    private let targetFPS: Int = 30
    private let videoBitrate: Int = 2000000 // 2 Mbps
    
    // Frame buffer
    private var frameBuffer: [VideoFrame] = []
    private let maxFrameBuffer = 10
    
    // Callback'ler
    var onFrameReceived: ((CVPixelBuffer) -> Void)?
    
    // MARK: - Initialization
    
    init(multipeerManager: MultipeerManager) {
        self.multipeerManager = multipeerManager
        super.init()
        
        setupDataReceiver()
        setupVideoComponents()
        
        print("🎬 ScreenShareManager başlatıldı")
    }
    
    deinit {
        stopScreenShare()
    }
}

// MARK: - Public Methods

extension ScreenShareManager {
    
    /// Ekran paylaşımını başlat
    func startScreenShare() {
        guard status == .idle else {
            print("⚠️ Ekran paylaşımı zaten aktif")
            return
        }
        
        status = .starting
        
        // ReplayKit kullanılabilirlik kontrolü
        guard screenRecorder.isAvailable else {
            status = .error("Screen recording is not available")
            print("❌ Screen recording kullanılamıyor")
            return
        }
        
        // Mikrofonlu ekran kaydetmeyi başlat
        screenRecorder.isMicrophoneEnabled = true
        screenRecorder.startCapture { [weak self] sampleBuffer, bufferType, error in
            
            if let error = error {
                print("❌ Screen capture hatası: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.status = .error(error.localizedDescription)
                }
                return
            }
            
            self?.handleCapturedFrame(sampleBuffer, type: bufferType)
            
        } completionHandler: { [weak self] error in
            
            if let error = error {
                print("❌ Screen recording başlatma hatası: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.status = .error(error.localizedDescription)
                }
            } else {
                print("✅ Screen recording başlatıldı")
                DispatchQueue.main.async {
                    self?.status = .streaming
                    self?.isSharing = true
                }
            }
        }
    }
    
    /// Ekran paylaşımını durdur
    func stopScreenShare() {
        guard isSharing else { return }
        
        status = .stopping
        
        screenRecorder.stopCapture { [weak self] error in
            if let error = error {
                print("❌ Screen recording durdurma hatası: \(error.localizedDescription)")
            } else {
                print("⏹️ Screen recording durduruldu")
            }
            
            DispatchQueue.main.async {
                self?.status = .idle
                self?.isSharing = false
                self?.sentFrameCount = 0
            }
        }
        
        videoEncoder?.invalidate()
        videoEncoder = nil
    }
    
    /// Stream kalitesini ayarla (0.1 - 1.0)
    func setStreamQuality(_ quality: Float) {
        streamQuality = max(0.1, min(1.0, quality))
        videoEncoder?.updateQuality(streamQuality)
        
        print("🎛️ Stream kalitesi: \(Int(streamQuality * 100))%")
    }
}

// MARK: - Private Methods

private extension ScreenShareManager {
    
    func setupDataReceiver() {
        multipeerManager.onDataReceived = { [weak self] data, dataType, peerID in
            guard dataType == .videoFrame else { return }
            self?.handleReceivedVideoData(data, from: peerID)
        }
    }
    
    func setupVideoComponents() {
        videoDecoder = VideoDecoder()
        videoDecoder?.onFrameDecoded = { [weak self] pixelBuffer in
            DispatchQueue.main.async {
                self?.onFrameReceived?(pixelBuffer)
                self?.receivedFrameCount += 1
            }
        }
    }
    
    func handleCapturedFrame(_ sampleBuffer: CMSampleBuffer, type: RPSampleBufferType) {
        switch type {
        case .video:
            processVideoFrame(sampleBuffer)
        case .audioApp:
            processAppAudio(sampleBuffer)
        case .audioMic:
            processMicAudio(sampleBuffer)
        @unknown default:
            print("❓ Bilinmeyen sample buffer türü")
        }
    }
    
    func processVideoFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // İlk frame için encoder'ı oluştur
        if videoEncoder == nil {
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            
            videoEncoder = VideoEncoder(width: width, height: height, fps: targetFPS, bitrate: videoBitrate)
            videoEncoder?.quality = streamQuality
            videoEncoder?.onEncodedFrame = { [weak self] encodedData, isKeyFrame in
                self?.sendVideoFrame(encodedData, isKeyFrame: isKeyFrame)
            }
        }
        
        // Frame'i encode et
        videoEncoder?.encode(pixelBuffer)
    }
    
    func processAppAudio(_ sampleBuffer: CMSampleBuffer) {
        // Uygulama sesini işle ve gönder
        guard let audioData = extractAudioData(from: sampleBuffer) else { return }
        multipeerManager.sendData(audioData, type: .audioData)
    }
    
    func processMicAudio(_ sampleBuffer: CMSampleBuffer) {
        // Mikrofon sesini işle ve gönder (sesli görüşme için)
        guard let audioData = extractAudioData(from: sampleBuffer) else { return }
        multipeerManager.sendData(audioData, type: .audioData)
    }
    
    func sendVideoFrame(_ data: Data, isKeyFrame: Bool) {
        let frame = VideoFrame(
            frameData: data,
            timestamp: Date().timeIntervalSince1970,
            width: Int32(videoEncoder?.width ?? 0),
            height: Int32(videoEncoder?.height ?? 0),
            isKeyFrame: isKeyFrame
        )
        
        if let frameData = encodeVideoFrame(frame) {
            multipeerManager.sendData(frameData, type: .videoFrame)
            
            DispatchQueue.main.async {
                self.sentFrameCount += 1
            }
        }
    }
    
    func handleReceivedVideoData(_ data: Data, from peer: MCPeerID) {
        guard let videoFrame = decodeVideoFrame(data) else {
            print("❌ Video frame decode hatası")
            return
        }
        
        // İlk frame alındığında decoder'ı başlat
        if videoDecoder == nil || !isReceivingShare {
            DispatchQueue.main.async {
                self.isReceivingShare = true
            }
        }
        
        // Frame'i decode et
        videoDecoder?.decode(videoFrame.frameData, isKeyFrame: videoFrame.isKeyFrame)
    }
    
    func extractAudioData(from sampleBuffer: CMSampleBuffer) -> Data? {
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return nil }
        
        let length = CMBlockBufferGetDataLength(blockBuffer)
        var data = Data(count: length)
        
        let status = data.withUnsafeMutableBytes { bytes in
            CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: bytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        
        guard status == kCMBlockBufferNoErr else { return nil }
        return data
    }
    
    // MARK: - Encoding/Decoding
    
    func encodeVideoFrame(_ frame: VideoFrame) -> Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(frame)
    }
    
    func decodeVideoFrame(_ data: Data) -> VideoFrame? {
        let decoder = JSONDecoder()
        return try? decoder.decode(VideoFrame.self, from: data)
    }
}

// MARK: - Video Encoder

class VideoEncoder {
    private var compressionSession: VTCompressionSession?
    let width: Int
    let height: Int
    let fps: Int
    let bitrate: Int
    var quality: Float = 0.8
    
    var onEncodedFrame: ((Data, Bool) -> Void)?
    
    init?(width: Int, height: Int, fps: Int, bitrate: Int) {
        self.width = width
        self.height = height
        self.fps = fps
        self.bitrate = bitrate
        
        setupCompressionSession()
    }
    
    deinit {
        invalidate()
    }
    
    private func setupCompressionSession() {
        let status = VTCompressionSessionCreate(
            allocator: nil,
            width: Int32(width),
            height: Int32(height),
            codecType: kCMVideoCodecType_H264,
            encoderSpecification: nil,
            imageBufferAttributes: nil,
            compressedDataAllocator: nil,
            outputCallback: compressionCallback,
            refcon: Unmanaged.passUnretained(self).toOpaque(),
            compressionSessionOut: &compressionSession
        )
        
        guard status == noErr, let session = compressionSession else {
            print("❌ Video compression session oluşturulamadı: \(status)")
            return
        }
        
        // Real-time encoding ayarları
        VTSessionSetProperty(session, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue)
        VTSessionSetProperty(session, kVTCompressionPropertyKey_AverageBitRate, NSNumber(value: bitrate))
        VTSessionSetProperty(session, kVTCompressionPropertyKey_MaxKeyFrameInterval, NSNumber(value: fps * 2))
        VTSessionSetProperty(session, kVTCompressionPropertyKey_Quality, NSNumber(value: quality))
        
        VTCompressionSessionPrepareToEncodeFrames(session)
        
        print("✅ Video encoder başlatıldı - \(width)x\(height) @\(fps)fps")
    }
    
    func encode(_ pixelBuffer: CVPixelBuffer) {
        guard let session = compressionSession else { return }
        
        let timestamp = CMTimeMake(value: Int64(Date().timeIntervalSince1970 * 1000), timescale: 1000)
        
        VTCompressionSessionEncodeFrame(
            session,
            imageBuffer: pixelBuffer,
            presentationTimeStamp: timestamp,
            duration: CMTime.invalid,
            frameProperties: nil,
            sourceFrameRefcon: nil,
            infoFlagsOut: nil
        )
    }
    
    func updateQuality(_ newQuality: Float) {
        guard let session = compressionSession else { return }
        quality = newQuality
        VTSessionSetProperty(session, kVTCompressionPropertyKey_Quality, NSNumber(value: quality))
    }
    
    func invalidate() {
        guard let session = compressionSession else { return }
        VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: CMTime.invalid)
        VTCompressionSessionInvalidate(session)
        compressionSession = nil
    }
}

// Video compression callback
private let compressionCallback: VTCompressionOutputCallback = { refcon, sourceFrameRefcon, status, infoFlags, sampleBuffer in
    guard status == noErr,
          let sampleBuffer = sampleBuffer,
          let refcon = refcon else { return }
    
    let encoder = Unmanaged<VideoEncoder>.fromOpaque(refcon).takeUnretainedValue()
    
    guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
    
    let length = CMBlockBufferGetDataLength(dataBuffer)
    var data = Data(count: length)
    
    data.withUnsafeMutableBytes { bytes in
        CMBlockBufferCopyDataBytes(dataBuffer, atOffset: 0, dataLength: length, destination: bytes.bindMemory(to: UInt8.self).baseAddress!)
    }
    
    let isKeyFrame = sampleBuffer.isKeyFrame
    encoder.onEncodedFrame?(data, isKeyFrame)
}

// MARK: - Video Decoder

class VideoDecoder {
    private var decompressionSession: VTDecompressionSession?
    var onFrameDecoded: ((CVPixelBuffer) -> Void)?
    
    init() {
        setupDecompressionSession()
    }
    
    deinit {
        invalidate()
    }
    
    private func setupDecompressionSession() {
        var formatDescription: CMFormatDescription?
        
        // H.264 format description oluştur
        let status = CMVideoFormatDescriptionCreate(
            allocator: nil,
            codecType: kCMVideoCodecType_H264,
            width: 1920, // Varsayılan boyut
            height: 1080,
            extensions: nil,
            formatDescriptionOut: &formatDescription
        )
        
        guard status == noErr, let format = formatDescription else {
            print("❌ Video format description oluşturulamadı")
            return
        }
        
        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        VTDecompressionSessionCreate(
            allocator: nil,
            formatDescription: format,
            decoderSpecification: nil,
            imageBufferAttributes: attributes as CFDictionary,
            outputCallback: decompressionCallback,
            decompressionSessionOut: &decompressionSession
        )
    }
    
    func decode(_ data: Data, isKeyFrame: Bool) {
        guard let session = decompressionSession else { return }
        
        var blockBuffer: CMBlockBuffer?
        let status = CMBlockBufferCreateWithMemoryBlock(
            allocator: nil,
            memoryBlock: nil,
            blockLength: data.count,
            blockAllocator: nil,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: data.count,
            flags: 0,
            blockBufferOut: &blockBuffer
        )
        
        guard status == noErr, let buffer = blockBuffer else { return }
        
        data.withUnsafeBytes { bytes in
            CMBlockBufferReplaceDataBytes(with: bytes.bindMemory(to: UInt8.self).baseAddress!, blockBuffer: buffer, offsetIntoDestination: 0, dataLength: data.count)
        }
        
        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreate(
            allocator: nil,
            dataBuffer: buffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            makeDataReadyRefcon: nil,
            formatDescription: nil,
            sampleCount: 1,
            sampleTimingEntryCount: 0,
            sampleTimingArray: nil,
            sampleSizeEntryCount: 1,
            sampleSizeArray: [data.count],
            sampleBufferOut: &sampleBuffer
        )
        
        guard let sample = sampleBuffer else { return }
        
        VTDecompressionSessionDecodeFrame(
            session,
            sampleBuffer: sample,
            flags: [],
            frameRefcon: Unmanaged.passUnretained(self).toOpaque(),
            infoFlagsOut: nil
        )
    }
    
    func invalidate() {
        guard let session = decompressionSession else { return }
        VTDecompressionSessionInvalidate(session)
        decompressionSession = nil
    }
}

// Video decompression callback  
private let decompressionCallback: VTDecompressionOutputCallback = { refcon, sourceFrameRefcon, status, infoFlags, imageBuffer, presentationTimeStamp, presentationDuration in
    guard status == noErr,
          let imageBuffer = imageBuffer,
          let sourceFrameRefcon = sourceFrameRefcon else { return }
    
    let decoder = Unmanaged<VideoDecoder>.fromOpaque(sourceFrameRefcon).takeUnretainedValue()
    decoder.onFrameDecoded?(imageBuffer)
}

// MARK: - Extensions

extension CMSampleBuffer {
    var isKeyFrame: Bool {
        guard let attachments = CMSampleBufferGetSampleAttachmentsArray(self, createIfNecessary: false) else { return false }
        let attachment = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFDictionary.self)
        return !CFDictionaryContainsKey(attachment, Unmanaged.passUnretained(kCMSampleAttachmentKey_NotSync).toOpaque())
    }
}