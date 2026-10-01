import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @StateObject private var callKit = CallKitManager()
    @StateObject private var ble = BLEManager()

    var body: some View {
        NavigationStack {
            List {
                Section("BLUE MAIN V0.3 — BLE CONTROL LAB") {
                    HStack {
                        Text("Bluetooth")
                        Spacer()
                        Text(ble.bluetoothState)
                            .foregroundStyle(ble.bluetoothState == "Powered On" ? .green : .orange)
                    }
                    HStack {
                        Text("Gateway")
                        Spacer()
                        Text(ble.isConnected ? "CONNECTED" : "Disconnected")
                            .foregroundStyle(ble.isConnected ? .green : .secondary)
                    }
                    HStack {
                        Button(ble.isScanning ? "STOP SCAN" : "SCAN") {
                            ble.isScanning ? ble.stopScan() : ble.scan()
                        }.buttonStyle(.borderedProminent)
                        if ble.isConnected {
                            Button("DISCONNECT") { ble.disconnect() }.buttonStyle(.bordered)
                        }
                    }
                }

                Section("DISCOVERED DEVICES") {
                    if ble.devices.isEmpty {
                        Text("Henüz BLE cihazı bulunmadı.").foregroundStyle(.secondary)
                    } else {
                        ForEach(ble.devices, id: \.identifier) { p in
                            Button { ble.connect(p) } label: {
                                HStack {
                                    Image(systemName:"dot.radiowaves.left.and.right").foregroundStyle(.blue)
                                    VStack(alignment:.leading) {
                                        Text(p.name?.isEmpty == false ? p.name! : "(Unnamed BLE)")
                                        Text(p.identifier.uuidString).font(.caption2).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName:"chevron.right").foregroundStyle(.secondary)
                                }
                            }.buttonStyle(.plain)
                        }
                    }
                }

                if ble.isConnected {
                    Section("GATT SERVICES") {
                        ForEach(ble.services, id:\.uuid) { s in
                            Text(s.uuid.uuidString).font(.system(.body, design:.monospaced))
                        }
                        if ble.services.isEmpty { Text("Service discovery bekleniyor...").foregroundStyle(.secondary) }
                    }

                    Section("CHARACTERISTICS") {
                        if ble.characteristics.isEmpty {
                            Text("Characteristic discovery bekleniyor...").foregroundStyle(.secondary)
                        } else {
                            ForEach(ble.characteristics) { info in
                                let c = ble.characteristic(info)
                                VStack(alignment:.leading, spacing:8) {
                                    Text(info.uuid).font(.system(.caption, design:.monospaced)).textSelection(.enabled)
                                    HStack {
                                        if let c, c.properties.contains(.read) {
                                            Button("READ") { ble.read(c) }.buttonStyle(.bordered)
                                        }
                                        if let c, c.properties.contains(.notify) || c.properties.contains(.indicate) {
                                            Button(c.isNotifying ? "NOTIFY OFF" : "NOTIFY ON") {
                                                ble.notify(!c.isNotifying, c)
                                            }.buttonStyle(.bordered)
                                        }
                                        if let c, c.properties.contains(.write) || c.properties.contains(.writeWithoutResponse) {
                                            Button("WRITE PING") { ble.writePing(c) }.buttonStyle(.bordered)
                                        }
                                    }
                                }.padding(.vertical,5)
                            }
                        }
                    }
                }

                Section("CALLKIT V0.2") {
                    Text(callKit.status).font(.caption)
                    Button("TEST INCOMING CALL") { callKit.startTestIncomingCall() }
                    Button("END TEST CALL") { callKit.endTestCall() }
                }

                Section("BLE EVENT LOG") {
                    ForEach(Array(ble.log.enumerated()), id:\.offset) { _, s in
                        Text(s).font(.system(size:12, design:.monospaced)).textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("Blue Main")
        }
    }
}
