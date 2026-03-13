# 🚀 AirLink - Hızlı Başlangıç Kılavuzu

## ⚡ 5 Dakikada AirLink'i Çalıştırın!

### 1️⃣ Proje Kurulumu (2 dakika)

```bash
# Projeyi aç
cd /path/to/AirLink
open AirLink.xcodeproj
```

**Xcode'da:**
- Target: AirLink
- iOS Deployment Target: 13.0 
- Bundle Identifier: `com.yourcompany.airlink` (Unique yapın)
- Signing Team: Developer team seçin

### 2️⃣ İzinleri Kontrol Et (30 saniye)

`Info.plist` dosyasında bu keys'lerin var olduğunu doğrulayın:
```xml
<key>NSLocalNetworkUsageDescription</key>
<key>NSMicrophoneUsageDescription</key>  
<key>NSBonjourServices</key>
```

### 3️⃣ Cihازlara Yükleme (2 dakika)

**ÖNEMLİ:** En az 2 fiziksel iOS cihazı gereklidir!

- iPhone/iPad'leri Lightning/USB-C ile Mac'e bağlayın
- Xcode'da cihazı seçin  
- ⌘+R ile build edin ve çalıştırın
- Her iki cihazda da uygulamayı başlatın

### 4️⃣ İlk Test (30 saniye)

1. **Her iki cihazda da** AirLink'i açın
2. **Anasayfa'da** bağlantı durumunu kontrol edin
3. **"Cihaz Aranıyor..."** yazısını görmelisiniz
4. **10-15 saniye** içinde cihazlar birbirini bulacak
5. **"X Cihaz Bağlı"** yazısını görünce hazır!

---

## 📱 Temel Kullanım

### 💬 İlk Mesajınızı Gönderin
```
Mesajlar Tab → Metin girin → Enter
```

### 🖥️ Ekran Paylaşımını Test Edin  
```
Ekran Paylaşımı Tab → "Ekran Paylaşımını Başlat" → İzin Ver
```

### 🔊 Sesli Arama Yapın
```
Anasayfa → "Sesli Arama" → Karşı taraf "Kabul Et"
```

---

## 🐛 Sorun Giderme

### Cihazlar Birbirini Bulamıyor
- **WiFi/Bluetooth** her iki cihazda da açık olsun
- **Aynı WiFi ağında** olduklarından emin olun 
- **Uygulamayı restart** edin
- **Cihazları yaklaştırın** (2-3 metre)

### Ekran Paylaşımı Çalışmıyor
- **iOS 13+** versiyonu kontrol edin
- **ReplayKit izni** verin
- **Control Center'dan** screen recording'i test edin

### Sesli Arama Problemi
- **Mikrofon izni** kontrol edin
- **Sessiz mod** kapalı olsun
- **Ses seviyesi** yeterli olsun

---

## 💡 Hızlı İpuçları

- **Otomatik bağlantı:** Normal şartlarda manuel bir şey yapmanıza gerek yok
- **Çoklu cihaz:** Aynı anda 8 cihaza kadar bağlanabilirsiniz  
- **Offline:** Tam offline çalışır, internet gerekmez
- **Güvenlik:** Tüm iletişim şifrelidir
- **Performans:** Cihaz performansına göre kalite ayarları optimize edilir

---

## 🚨 Kritik Notlar

⚠️ **Simülatörde çalışmaz** - Fiziksel cihaz şart!
⚠️ **Bluetooth + WiFi** her ikisi de açık olmalı  
⚠️ **Minimum iOS 13.0** gerekli
⚠️ **Code signing** düzgün yapılandırılmalı

---

## 🎯 İlk Başarılı Test Senaryosu

1. ✅ İki cihazda da uygulama açık
2. ✅ "X Cihaz Bağlı" yazıyor
3. ✅ Mesaj gönderip alabiliyorsunuz
4. ✅ Ekran paylaşımı çalışıyor
5. ✅ Sesli görüşme aktif

**Tebrikler! AirLink başarıyla çalışıyor! 🎉**

---

**Daha detaylı bilgi için `README.md` dosyasına bakın.**