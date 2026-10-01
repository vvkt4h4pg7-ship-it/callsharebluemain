import Foundation
import CallKit
import AVFAudio

@MainActor
final class CallKitManager: NSObject, ObservableObject {
    @Published private(set) var status = "Hazır"

    private let provider: CXProvider
    private var currentCallUUID: UUID?

    override init() {
        let configuration = CXProviderConfiguration(localizedName: "Blue Main")
        configuration.supportsVideo = false
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportedHandleTypes = [.phoneNumber]
        configuration.includesCallsInRecents = true

        self.provider = CXProvider(configuration: configuration)

        super.init()
        provider.setDelegate(self, queue: nil)
    }

    func startTestIncomingCall() {
        guard currentCallUUID == nil else {
            status = "Zaten bir test çağrısı aktif."
            return
        }

        let uuid = UUID()
        currentCallUUID = uuid

        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .phoneNumber, value: "05320000000")
        update.localizedCallerName = "BLUE MAIN TEST"
        update.hasVideo = false

        status = "CallKit'e gelen çağrı bildiriliyor..."

        provider.reportNewIncomingCall(with: uuid, update: update) { [weak self] error in
            Task { @MainActor in
                guard let self else { return }

                if let error {
                    self.currentCallUUID = nil
                    self.status = "CallKit HATA: \(error.localizedDescription)"
                    print("❌ CallKit report error: \(error)")
                } else {
                    self.status = "📞 Test çağrısı bildirildi"
                    print("✅ Incoming call reported: \(uuid.uuidString)")
                }
            }
        }
    }

    func endTestCall() {
        guard let uuid = currentCallUUID else {
            status = "Aktif test çağrısı yok."
            return
        }

        provider.reportCall(with: uuid, endedAt: Date(), reason: .remoteEnded)
        currentCallUUID = nil
        status = "📴 Test çağrısı sonlandırıldı"
    }
}

extension CallKitManager: CXProviderDelegate {
    nonisolated func providerDidReset(_ provider: CXProvider) {
        Task { @MainActor in
            self.currentCallUUID = nil
            self.status = "Provider reset"
        }
    }

    nonisolated func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("📞 ANSWER action geldi")
        action.fulfill()

        Task { @MainActor in
            self.status = "✅ Çağrı cevaplandı — audio session bekleniyor"
        }
    }

    nonisolated func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("📴 END action geldi")
        action.fulfill()

        Task { @MainActor in
            self.currentCallUUID = nil
            self.status = "📴 Çağrı kapatıldı"
        }
    }

    nonisolated func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("🎤🔊 CallKit audio session AKTİF")

        Task { @MainActor in
            self.status = "🎤🔊 Audio session aktif"
        }
    }

    nonisolated func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("🔇 CallKit audio session DEAKTİF")

        Task { @MainActor in
            self.status = "🔇 Audio session kapandı"
        }
    }
}
