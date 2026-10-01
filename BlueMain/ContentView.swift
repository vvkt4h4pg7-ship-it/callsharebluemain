import SwiftUI

struct ContentView: View {
    @StateObject private var callKit = CallKitManager()

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 58))
                    .foregroundStyle(.green)

                Text("BLUE MAIN")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("J7Bridge • CallKit TEST")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(callKit.status)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Button {
                    callKit.startTestIncomingCall()
                } label: {
                    Label("TEST INCOMING CALL", systemImage: "phone.badge.plus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    callKit.endTestCall()
                } label: {
                    Label("END TEST CALL", systemImage: "phone.down.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)

                VStack(alignment: .leading, spacing: 8) {
                    Text("V0.2 TEST")
                        .font(.caption)
                        .fontWeight(.bold)

                    Text("Bu sürümde BLE, GSM ve HFP hâlâ yok. CallKit incoming-call zincirini ve ayrıntılı hata kodlarını test ediyoruz. UIBackgroundModes=voip eklendi.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

                Spacer()
            }
            .padding()
            .navigationTitle("J7Bridge")
        }
    }
}

#Preview {
    ContentView()
}
