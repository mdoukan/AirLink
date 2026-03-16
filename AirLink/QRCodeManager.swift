//
//  QRCodeManager.swift
//  AirLink
//
//  QR Kod ile hızlı cihaz eşleştirme yöneticisi
//  CoreImage ile QR oluşturma, AVFoundation ile QR okuma
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import AVFoundation
import MultipeerConnectivity

// MARK: - QR Kod Veri Modeli

struct QRConnectionInfo: Codable {
    let deviceName: String
    let serviceType: String
    let timestamp: Date
    
    /// QR kod verisi oluştur
    func encode() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(self)
    }
    
    /// QR kod verisini çöz
    static func decode(from data: Data) -> QRConnectionInfo? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(QRConnectionInfo.self, from: data)
    }
}

// MARK: - QR Kod Yöneticisi

class QRCodeManager: ObservableObject {
    
    @Published var scannedConnectionInfo: QRConnectionInfo?
    @Published var isScanning = false
    @Published var scanStatus: String = ""
    
    private let multipeerManager: MultipeerManager
    
    init(multipeerManager: MultipeerManager) {
        self.multipeerManager = multipeerManager
    }
    
    /// Bu cihaz için QR kod bilgisi oluştur
    func generateConnectionInfo() -> QRConnectionInfo {
        QRConnectionInfo(
            deviceName: multipeerManager.peerID.displayName,
            serviceType: "airlink-service",
            timestamp: Date()
        )
    }
    
    /// QR kod tarandıktan sonra bağlantı kur
    func handleScannedCode(_ string: String) {
        guard let data = string.data(using: .utf8),
              let info = QRConnectionInfo.decode(from: data) else {
            DispatchQueue.main.async {
                self.scanStatus = "Geçersiz QR kod"
            }
            return
        }
        
        DispatchQueue.main.async {
            self.scannedConnectionInfo = info
            self.scanStatus = "\(info.deviceName) bulundu!"
            self.isScanning = false
        }
        
        // Advertising ve browsing'i başlat (eğer aktif değilse)
        if !multipeerManager.isAdvertising {
            multipeerManager.startAdvertising()
        }
        if !multipeerManager.isBrowsing {
            multipeerManager.startBrowsing()
        }
    }
    
    /// QR kod görüntüsü oluştur
    static func generateQRCode(from info: QRConnectionInfo) -> UIImage? {
        guard let data = info.encode(),
              let jsonString = String(data: data, encoding: .utf8) else { return nil }
        
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(jsonString.utf8)
        filter.correctionLevel = "M"
        
        guard let outputImage = filter.outputImage else { return nil }
        
        // QR kodu büyüt (pixelated olmaması için)
        let scale = 10.0
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - QR Kod Tarayıcı (AVFoundation Camera)

struct QRScannerView: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void
    @Binding var isScanning: Bool
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.onCodeScanned = onCodeScanned
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {
        if isScanning {
            uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var onCodeScanned: ((String) -> Void)?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    private func setupCamera() {
        let session = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            showNoCameraAlert()
            return
        }
        
        guard session.canAddInput(videoInput) else { return }
        session.addInput(videoInput)
        
        let metadataOutput = AVCaptureMetadataOutput()
        guard session.canAddOutput(metadataOutput) else { return }
        session.addOutput(metadataOutput)
        
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        self.captureSession = session
        self.previewLayer = previewLayer
    }
    
    private func showNoCameraAlert() {
        let label = UILabel()
        label.text = "Kamera kullanılamıyor\n(Simülatörde desteklenmiyor)"
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    func startScanning() {
        hasScanned = false
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    func stopScanning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard !hasScanned,
              let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else { return }
        
        hasScanned = true
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        stopScanning()
        onCodeScanned?(stringValue)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }
}
