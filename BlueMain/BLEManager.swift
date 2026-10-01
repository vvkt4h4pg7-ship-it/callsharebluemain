import Foundation
import CoreBluetooth

struct BLECharacteristicInfo: Identifiable {
    let id: CBUUID
    let uuid: String
    let properties: CBCharacteristicProperties
    let serviceUUID: CBUUID
}

final class BLEManager: NSObject, ObservableObject {
    @Published private(set) var bluetoothState = "Bluetooth başlatılıyor..."
    @Published private(set) var isScanning = false
    @Published private(set) var isConnected = false
    @Published private(set) var connectedName = ""
    @Published private(set) var devices: [CBPeripheral] = []
    @Published private(set) var services: [CBService] = []
    @Published private(set) var characteristics: [BLECharacteristicInfo] = []
    @Published private(set) var log: [String] = []

    private var central: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    func scan() {
        guard central.state == .poweredOn else { addLog("⚠️ Bluetooth hazır değil"); return }
        devices.removeAll()
        services.removeAll()
        characteristics.removeAll()
        isScanning = true
        addLog("🔎 Scan başladı — tüm BLE cihazları")
        central.scanForPeripherals(withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func stopScan() {
        central.stopScan()
        isScanning = false
        addLog("⏹️ Scan durdu")
    }

    func connect(_ p: CBPeripheral) {
        stopScan()
        connectedPeripheral = p
        p.delegate = self
        addLog("🔗 Connect → \(p.name ?? "(Unnamed BLE)")")
        central.connect(p)
    }

    func disconnect() {
        if let p = connectedPeripheral { central.cancelPeripheralConnection(p) }
    }

    func read(_ c: CBCharacteristic) {
        connectedPeripheral?.readValue(for: c)
        addLog("📥 READ → \(c.uuid)")
    }

    func notify(_ enabled: Bool, _ c: CBCharacteristic) {
        connectedPeripheral?.setNotifyValue(enabled, for: c)
        addLog("\(enabled ? "🔔" : "🔕") NOTIFY → \(c.uuid)")
    }

    func writePing(_ c: CBCharacteristic) {
        guard let p = connectedPeripheral else { return }
        let data = Data("PING".utf8)
        let type: CBCharacteristicWriteType = c.properties.contains(.write) ? .withResponse : .withoutResponse
        p.writeValue(data, for: c, type: type)
        addLog("📤 WRITE PING → \(c.uuid)")
    }

    func characteristic(_ info: BLECharacteristicInfo) -> CBCharacteristic? {
        services.first(where: {$0.uuid == info.serviceUUID})?.characteristics?.first(where: {$0.uuid == info.id})
    }

    private func addLog(_ s: String) {
        log.insert(s, at: 0)
        if log.count > 80 { log.removeLast() }
        print(s)
    }

    private func props(_ p: CBCharacteristicProperties) -> String {
        var a:[String] = []
        if p.contains(.read) { a.append("READ") }
        if p.contains(.write) { a.append("WRITE") }
        if p.contains(.writeWithoutResponse) { a.append("WRITE_NR") }
        if p.contains(.notify) { a.append("NOTIFY") }
        if p.contains(.indicate) { a.append("INDICATE") }
        return a.isEmpty ? "—" : a.joined(separator: " • ")
    }
}

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn: bluetoothState = "Powered On"
        case .poweredOff: bluetoothState = "Powered Off"
        case .unauthorized: bluetoothState = "Unauthorized"
        case .unsupported: bluetoothState = "Unsupported"
        case .resetting: bluetoothState = "Resetting"
        default: bluetoothState = "Unknown"
        }
        addLog("📡 Bluetooth → \(bluetoothState)")
    }

    func centralManager(_ central: CBCentralManager, didDiscover p: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if !devices.contains(where: {$0.identifier == p.identifier}) { devices.append(p) }
        let adv = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?
            .map {$0.uuidString}.joined(separator: ", ") ?? "none"
        addLog("📡 DISCOVER → \(p.name ?? "(Unnamed)") | RSSI \(RSSI) | ADV: \(adv)")
    }

    func centralManager(_ central: CBCentralManager, didConnect p: CBPeripheral) {
        connectedPeripheral = p
        isConnected = true
        connectedName = p.name ?? "(Unnamed BLE)"
        services.removeAll()
        characteristics.removeAll()
        addLog("✅ CONNECTED → \(connectedName)")
        p.delegate = self
        p.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect p: CBPeripheral, error: Error?) {
        isConnected = false
        addLog("❌ CONNECT FAILED → \(error?.localizedDescription ?? "unknown")")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral p: CBPeripheral, error: Error?) {
        isConnected = false
        connectedName = ""
        services.removeAll()
        characteristics.removeAll()
        addLog("🔌 DISCONNECTED → \(error?.localizedDescription ?? "normal")")
    }
}

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ p: CBPeripheral, didDiscoverServices error: Error?) {
        if let error { addLog("❌ SERVICES → \(error.localizedDescription)"); return }
        services = p.services ?? []
        addLog("🧩 SERVICES → \(services.count)")
        for s in services {
            addLog("SERVICE → \(s.uuid)")
            p.discoverCharacteristics(nil, for: s)
        }
    }

    func peripheral(_ p: CBPeripheral, didDiscoverCharacteristicsFor s: CBService, error: Error?) {
        if let error { addLog("❌ CHARS → \(error.localizedDescription)"); return }
        for c in s.characteristics ?? [] {
            addLog("CHAR → \(c.uuid) | \(props(c.properties))")
        }
        characteristics = services.flatMap { service in
            (service.characteristics ?? []).map {
                BLECharacteristicInfo(id: $0.uuid, uuid: $0.uuid.uuidString,
                                      properties: $0.properties, serviceUUID: service.uuid)
            }
        }
    }

    func peripheral(_ p: CBPeripheral, didUpdateValueFor c: CBCharacteristic, error: Error?) {
        if let error { addLog("❌ VALUE → \(error.localizedDescription)"); return }
        let data = c.value ?? Data()
        let hex = data.map { String(format:"%02X", $0) }.joined(separator:" ")
        let text = String(data:data, encoding:.utf8) ?? ""
        addLog("📥 VALUE \(c.uuid) → [\(hex)]\(text.isEmpty ? "" : " | \(text)")")
    }

    func peripheral(_ p: CBPeripheral, didWriteValueFor c: CBCharacteristic, error: Error?) {
        addLog(error == nil ? "✅ WRITE OK → \(c.uuid)" : "❌ WRITE → \(error!.localizedDescription)")
    }

    func peripheral(_ p: CBPeripheral, didUpdateNotificationStateFor c: CBCharacteristic, error: Error?) {
        addLog(error == nil ? "🔔 NOTIFY STATE → \(c.uuid) = \(c.isNotifying)" :
               "❌ NOTIFY → \(error!.localizedDescription)")
    }
}
