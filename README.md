# Blue Main iOS — V0.1 CallKit Test

İlk prototipin amacı yalnızca fiziksel iPhone üzerinde CallKit incoming-call zincirini doğrulamaktır.

## Bu sürümde

- SwiftUI arayüzü
- CallKit `CXProvider`
- `reportNewIncomingCall`
- Answer / End action callback'leri
- CallKit audio session activation callback'i
- BLE / GSM / HFP / gerçek ses YOK

## Test

1. `BlueMain.xcodeproj` dosyasını Xcode ile açın.
2. Signing & Capabilities bölümünde kendi Apple hesabınızı / Team'inizi seçin.
3. Bundle Identifier değerini benzersiz yapın (ör. `com.ugur.bluemain`).
4. Gerçek iPhone 16 Pro'yu seçip Run yapın.
5. Uygulamada `TEST INCOMING CALL` butonuna basın.
6. Beklenen sonuç: iOS'un sistem CallKit gelen çağrı arayüzü açılır.
7. `Kabul Et` sonrası Xcode console'da `ANSWER` ve audio-session loglarını kontrol edin.

> Not: İlk test fiziksel cihaz içindir. Simulator davranışı bu prototip için referans kabul edilmemelidir.

## GitHub

```bash
git init
git add .
git commit -m "Blue Main iOS v0.1 CallKit test"
git branch -M main
git remote add origin <YENI_GITHUB_REPO_URL>
git push -u origin main
```

## Sonraki sürüm

V0.2: CoreBluetooth ile BLE discovery / control channel.
V0.3: J7 `RINGING + NUMBER` → CallKit.
V0.4: Answer / End round-trip.
V0.5: BLE Audio Lab.
