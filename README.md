# 📱 AirLink - Offline Cihazlar Arası İletişim Uygulaması

AirLink, internet bağlantısı olmadan iOS cihazlar arasında mesajlaşma, ekran paylaşımı ve sesli görüşme imkanı sunan gelişmiş bir peer-to-peer iletişim uygulamasıdır.

## 🚀 Ana Özellikler

### 💬 Gerçek Zamanlı Mesajlaşma
- **Offline mesajlaşma:** Internet bağlantısı olmadan metin iletişimi
- **Anlık bildirimler:** Yazıyor durumu göstergesi 
- **Mesaj durumu:** Gönderildi, teslim edildi durumu takibi
- **Türkçe arayüz:** Tamamen Türkçe kullanıcı deneyimi

### 🖥️ Ekran Paylaşımı  
- **ReplayKit entegrasyonu:** iOS'un yerli ekran kaydetme teknolojisi
- **H.264 sıkıştırma:** Yüksek kaliteli, düşük boyutlu video streaming
- **Kalite kontrolü:** Ayarlanabilir stream kalitesi (10%-100%)
- **Gerçek zamanlı iletim:** Düşük gecikme ile video paylaşımı

### 🔊 Sesli Görüşme
- **VoIP çağrılar:** Yüksek kaliteli ses iletimi
- **Ses kontrolleri:** Mute, hoparlör, ses seviyesi ayarları
- **Eş zamanlı ekran paylaşımı:** Ses görüşmesi sırasında ekran paylaşımı
- **Echo cancellation:** Gelişmiş ses işleme teknolojileri

### 🌐 Mesh Network Bağlantısı
- **Multipeer Connectivity:** Apple'ın peer-to-peer framework'ü
- **Bluetooth + WiFi:** Hibrit bağlantı teknolojisi
- **Çoklu cihaz:** Aynı anda birden fazla cihaza bağlantı
- **Otomatik keşif:** Yakındaki cihazları otomatik bulma

## 🏗️ Teknik Mimari

### 📂 Modüler Yapı

#### 1. MultipeerManager.swift
```swift
// Multipeer Connectivity yönetimi
- Cihaz keşfi (Advertising & Browsing) 
- Bağlantı yönetimi (Connect, Disconnect)
- Veri iletimi (Message, Video, Audio kanalları)
- Session yönetimi (Güvenli bağlantılar)
```

#### 2. MessageModel.swift
```swift  
// Mesajlaşma sistemi
- ChatMessage modeli (Metin, Sistem, Durum mesajları)
- MessageManager (Gönderme, alma, yazma durumu)
- JSON encoding/decoding
- Mesaj geçmişi yönetimi
```

#### 3. ScreenShareManager.swift
```swift
// Ekran paylaşımı sistemi  
- ReplayKit entegrasyonu
- H.264 video encoding/decoding
- VideoFrame modeli ve streaming
- Kalite kontrolü ve optimizasyon
```

#### 4. AudioCallManager.swift
```swift
// Sesli görüşme sistemi
- AVAudioEngine ile ses yakalama/oynatma
- Ses işleme (Echo cancellation, Noise suppression)
- Çağrı yönetimi (Incoming, Outgoing, Active)
- Audio session konfigürasyonu
```  

#### 5. ContentView.swift & UIComponents.swift
```swift
// SwiftUI arayüz sistemi
- TabView tabanlı navigasyon 
- Gerçek zamanlı UI güncellemeleri
- Custom komponetler (MessageBubble, CallView, etc.)
- Responsive tasarım
```

## 🎯 Nasıl Çalışır?

### Bağlantı Kurma Süreci
1. **Advertising:** Cihaz kendini yakındaki diğer cihazlara duyurur
2. **Browsing:** Yakındaki AirLink uygulamalarını arar  
3. **Discovery:** Bulunan cihazlar UI'de listelenir
4. **Connection:** Kullanıcı seçimi veya otomatik bağlantı
5. **Session:** Güvenli MCSession bağlantısı kurulur

### Veri İletim Kanalları
```
MESSAGE_CHANNEL    -> Metin mesajları, sistem bildirileri
VIDEO_CHANNEL      -> H.264 encoded video frame'leri  
AUDIO_CHANNEL      -> PCM ses verisi, çağrı kontrolleri
METADATA_CHANNEL   -> Yazıyor durumu, bağlantı bilgileri
```

### Ekran Paylaşımı Akışı
1. **Capture:** ReplayKit ile ekran yakalama
2. **Encode:** H.264 codec ile video sıkıştırma  
3. **Stream:** Multipeer üzerinden frame iletimi
4. **Decode:** Alıcı cihazda video decode
5. **Display:** SwiftUI'de video oynatma

## 🛠️ Gereksinimler

### Sistem Gereksinimleri
- **iOS 13.0+** (ReplayKit, Multipeer Connectivity)
- **Swift 5.0+** 
- **Xcode 12.0+**
- **Bluetooth ve WiFi** Hardware desteği

### Framework Bağımlılıkları
```swift
import MultipeerConnectivity  // P2P networking
import ReplayKit             // Screen recording
import AVFoundation          // Audio processing  
import VideoToolbox          // H.264 encoding/decoding
import SwiftUI               // Modern arayüz
import Combine               // Reactive programming
```

### Yetkiler (Info.plist)
```xml
<key>NSLocalNetworkUsageDescription</key>
<string>AirLink yakın cihazlar ile peer-to-peer bağlantı kurmak için yerel ağ erişimi gerektirir.</string>

<key>NSMicrophoneUsageDescription</key>
<string>AirLink sesli sohbet için mikrofon erişimi gerektirir.</string> 

<key>NSBonjourServices</key>
<array>
    <string>_airlink._tcp</string>
    <string>_airlink._udp</string>
</array>
```

## 🚀 Kurulum ve Çalıştırma

### 1. Projeyi Klonlayın
```bash
git clone [repository-url]
cd AirLink
```

### 2. Xcode'da Açın
```bash
open AirLink.xcodeproj
```

### 3. Gerekli Ayarlar
- **Bundle Identifier:** Unique bir identifier ayarlayın
- **Team:** Development team seçin
- **Signing:** Code signing konfigürasyonu
- **Target Device:** iOS 13.0+ minimum deployment target

### 4. Fiziksel Cihazda Test
```
NOT: Multipeer Connectivity simülatörde çalışmaz!
En az 2 fiziksel iOS cihazı gereklidir.
```

### 5. Build ve Run
- Product > Run veya ⌘+R
- Her iki cihazda da uygulamayı başlatın
- Otomatik keşif başlayacak ve cihazlar birbirine bağlanacak

## 💻 Kullanım Kılavuzu

### İlk Çalıştırma
1. **Uygulama başlatıldığında** otomatik olarak browsing ve advertising başlar
2. **Anasayfa'da** bağlantı durumunu görüntüleyin
3. **Yakındaki cihazlar** otomatik olarak keşfedilir ve bağlantı kurulur

### Mesajlaşma 
1. **Mesajlar tab'ına** geçin
2. **Alt kısımda** mesaj yazın
3. **Enter** veya **gönder** butonunu kullanın
4. **Time stamp** ve **delivery status** otomatik görünür

### Ekran Paylaşımı
1. **Ekran Paylaşımı tab'ına** geçin
2. **"Ekran Paylaşımını Başlat"** butonuna basın
3. **iOS system prompt'ında** izin verin
4. **Ekranınız** diğer cihazlara streaming edilmeye başlar
5. **Kalite slider'ı** ile stream kalitesini ayarlayın

### Sesli Görüşme
1. **Anasayfa'da** "Sesli Arama" kartına tıklayın
2. **Gelen çağrı** için açılan alert'te "Kabul Et" seçin
3. **Çağrı sırasında:** Mute, Speaker, End Call kontrolleri
4. **Eş zamanlı** ekran paylaşımı yapabilirsiniz

## 🔧 Konfigürasyon

### Ses Ayarları (AudioCallManager)
```swift
struct AudioSettings {
    var inputGain: Float = 0.5        // Mikrofon gain
    var outputVolume: Float = 0.8     // Hoparlör ses seviyesi  
    var echoCancellation: Bool = true // Echo cancellation
    var noiseSuppression: Bool = true // Noise suppression
    var sampleRate: Double = 44100.0  // 44.1kHz audio
}
```

### Video Ayarları (ScreenShareManager) 
```swift
private let targetFPS: Int = 30           // Frame rate
private let videoBitrate: Int = 2000000   // 2 Mbps bitrate
var streamQuality: Float = 0.8            // Kalite %80
```

### Multipeer Ayarları (MultipeerManager)
```swift
private let serviceType = "airlink-service"  // Bonjour service
encryptionPreference: .required              // Şifreleme gerekli
timeout: 30.0                               // Bağlantı timeout
```

## 🐛 Bilinen Sınırlamalar

1. **Simülatör desteği yok:** Multipeer Connectivity fiziksel cihaz gerektirir
2. **Bluetooth menzil:** ~30 metre (açık alanda)
3. **WiFi Direct menzil:** ~100 metre (açık alanda)  
4. **Maximum peers:** iOS 8 eş zamanlı bağlantı limiti
5. **Video kalitesi:** Cihaz performansına bağlı

## 📈 Geliştirme Yol Haritası

### v1.1 Planlanan Özellikler
- [ ] Dosya paylaşımı (Resim, Doküman)
- [ ] Grup sohbet rooms
- [ ] Push-to-talk mod
- [ ] Dark mode desteği

### v1.2 İleri Seviye
- [ ] Message encryption (E2E)
- [ ] Background app refresh
- [ ] Apple Watch entegrasyonu
- [ ] macOS companion app

## 🤝 Katkıda Bulunma

1. **Fork** edin
2. **Feature branch** oluşturun (`git checkout -b feature/amazing-feature`)
3. **Commit** edin (`git commit -m 'Add amazing feature'`)
4. **Push** edin (`git push origin feature/amazing-feature`)
5. **Pull Request** açın

## 📞 Destek

Herhangi bir sorun veya öneri için:
- **GitHub Issues** bölümünü kullanın
- **Technical Documentation** klasörüne bakın
- **Debug logs** ile birlikte detaylı rapor verin

## 📄 Lisans

Bu proje MIT lisansı altında dağıtılmaktadır. Detaylar için `LICENSE` dosyasına bakın.

---

**⚡ AirLink - Connect Without Internet!**

*Developed with ❤️ for the iOS community*