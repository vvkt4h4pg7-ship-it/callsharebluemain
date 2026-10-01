import Foundation
import CallKit
import AVFAudio

final class CallKitManager: NSObject, ObservableObject {
    @Published var status = "Hazır"
    private let provider: CXProvider
    private var currentCallUUID: UUID?

    override init() {
        let c = CXProviderConfiguration()
        c.localizedName = "Blue Main"
        c.supportsVideo = false
        c.maximumCallGroups = 1
        c.maximumCallsPerCallGroup = 1
        c.supportedHandleTypes = [.phoneNumber]
        c.includesCallsInRecents = true
        provider = CXProvider(configuration: c)
        super.init()
        provider.setDelegate(self, queue: nil)
    }

    func startTestIncomingCall() {
        guard currentCallUUID == nil else { status = "Zaten aktif"; return }
        let uuid = UUID()
        currentCallUUID = uuid
        let u = CXCallUpdate()
        u.remoteHandle = CXHandle(type: .phoneNumber, value: "05320000000")
        u.localizedCallerName = "BLUE MAIN TEST"
        u.hasVideo = false
        status = "CallKit'e gelen çağrı bildiriliyor..."
        provider.reportNewIncomingCall(with: uuid, update: u) { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    self?.status = "HATA: \(error.localizedDescription)"
                    self?.currentCallUUID = nil
                } else {
                    self?.status = "📞 Test çağrısı bildirildi"
                }
            }
        }
    }

    func endTestCall() {
        guard let uuid = currentCallUUID else { status = "Aktif çağrı yok"; return }
        provider.reportCall(with: uuid, endedAt: Date(), reason: .remoteEnded)
        currentCallUUID = nil
        status = "Test çağrısı sonlandırıldı"
    }
}

extension CallKitManager: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        currentCallUUID = nil
        status = "Provider reset"
    }
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        status = "✅ Çağrı cevaplandı"
        action.fulfill()
    }
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        currentCallUUID = nil
        status = "📴 Çağrı kapatıldı"
        action.fulfill()
    }
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        status = "🎤🔊 Audio session aktif"
        print("🎤🔊 CallKit audio session AKTİF")
    }
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        status = "Audio session kapandı"
        print("🔇 CallKit audio session DEAKTİF")
    }
}
