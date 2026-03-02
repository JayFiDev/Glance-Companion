//
//  BLEManager.swift
//  ReminderSync
//
//  Manages BLE communication with the Xteink X4 e-reader.
//  Acts as a CoreBluetooth Central to connect to the X4's BLE peripheral.
//

import Foundation
import CoreBluetooth

struct LogMessage: Identifiable {
    let id = UUID()
    let text: String
}

@Observable
final class BLEManager: NSObject {
    // MARK: - State

    var connectedPeripheral: CBPeripheral?
    var isScanning = false
    var isSending = false
    var logMessages: [LogMessage] = []
    var isInitialized = false
    var completionIDs: [String] = []

    // MARK: - Private

    private var centralManager: CBCentralManager?
    private var targetCharacteristic: CBCharacteristic?
    private var readCompletionHandler: (([String]) -> Void)?
    private let bleQueue = DispatchQueue(label: "com.glance.ble", qos: .userInitiated)
    private var pendingWriteCount = 0

    // Must match ESP32 firmware UUIDs
    private let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789012")
    private let characteristicUUID = CBUUID(string: "87654321-4321-4321-4321-210987654321")

    private let deviceName = "XteinkX4"
    private let chunkSize = 512

    // MARK: - Init

    override init() {
        super.init()
        // Defer BLE initialization to avoid blocking app launch
        DispatchQueue.main.async { [weak self] in
            self?.initializeBluetooth()
        }
    }
    
    private func initializeBluetooth() {
        centralManager = CBCentralManager(delegate: self, queue: bleQueue)
        isInitialized = true
        addLog("BLE Manager initialized")
    }

    // MARK: - Public API

    func startScanning() {
        guard let centralManager, centralManager.state == .poweredOn else {
            addLog("ERROR: Bluetooth not ready")
            return
        }

        addLog("Scanning for X4...")
        isScanning = true

        centralManager.scanForPeripherals(
            withServices: [serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )

        // Timeout after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let self, self.isScanning else { return }
            self.stopScanning()
            self.addLog("Scan timeout - no devices found")
        }
    }

    func stopScanning() {
        centralManager?.stopScan()
        isScanning = false
    }

    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        addLog("Disconnecting...")
        centralManager?.cancelPeripheralConnection(peripheral)
    }

    func sendData(_ data: Data) {
        guard let peripheral = connectedPeripheral,
              let characteristic = targetCharacteristic else {
            addLog("ERROR: Not connected or characteristic unavailable")
            return
        }

        isSending = true
        pendingWriteCount = 0
        addLog("Sending \(data.count) bytes...")

        var offset = 0
        while offset < data.count {
            let end = min(offset + chunkSize, data.count)
            let chunk = data.subdata(in: offset..<end)
            peripheral.writeValue(chunk, for: characteristic, type: .withResponse)
            pendingWriteCount += 1
            offset = end
        }
        // isSending cleared in didWriteValueFor once all chunks are acknowledged
    }

    /// Scans for the X4, connects, and sends data — for use from Shortcuts/AppIntents.
    /// Waits up to 5 s for Bluetooth, 15 s for connection, 15 s for transfer.
    @MainActor
    func connectAndSend(_ data: Data) async throws {
        // Wait for Bluetooth to be powered on (CBCentralManager initialises asynchronously)
        let btDeadline = Date().addingTimeInterval(5)
        while centralManager?.state != .poweredOn {
            if Date() >= btDeadline { throw BLEError.bluetoothUnavailable }
            try await Task.sleep(nanoseconds: 200_000_000)
        }

        // Start scanning if not already connected
        if connectedPeripheral == nil {
            startScanning()
        }

        // Wait for characteristic to be ready (connected + services + characteristics discovered)
        let connDeadline = Date().addingTimeInterval(15)
        while targetCharacteristic == nil {
            if Date() >= connDeadline { throw BLEError.connectionTimeout }
            try await Task.sleep(nanoseconds: 200_000_000)
        }

        sendData(data)

        // Wait for all chunks to be acknowledged
        let sendDeadline = Date().addingTimeInterval(15)
        while isSending {
            if Date() >= sendDeadline { throw BLEError.sendTimeout }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    func readCompletions(completion: @escaping ([String]) -> Void) {
        guard let peripheral = connectedPeripheral,
              let characteristic = targetCharacteristic else {
            addLog("ERROR: Cannot read - not connected")
            completion([])
            return
        }

        readCompletionHandler = completion
        addLog("Reading completions from X4...")
        peripheral.readValue(for: characteristic)
    }

    func addLog(_ message: String) {
        let time = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let entry = "[\(time)] \(message)"
        DispatchQueue.main.async {
            self.logMessages.append(LogMessage(text: entry))
            if self.logMessages.count > 50 {
                self.logMessages.removeFirst()
            }
        }
        print(entry)
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let msg: String
        switch central.state {
        case .poweredOn:    msg = "Bluetooth powered on"
        case .poweredOff:   msg = "ERROR: Bluetooth powered off"
        case .unauthorized: msg = "ERROR: Bluetooth unauthorized"
        case .unsupported:  msg = "ERROR: Bluetooth unsupported"
        default:            msg = "Bluetooth state: \(central.state.rawValue)"
        }
        DispatchQueue.main.async { self.addLog(msg) }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        DispatchQueue.main.async {
            self.addLog("Found: \(peripheral.name ?? "Unknown") (RSSI: \(RSSI))")

            if peripheral.name == self.deviceName {
                self.addLog("Connecting to X4...")
                self.stopScanning()
                self.connectedPeripheral = peripheral
                peripheral.delegate = self
                self.centralManager?.connect(peripheral)
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.addLog("Connected to \(peripheral.name ?? "device")")
            peripheral.discoverServices([self.serviceUUID])
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        DispatchQueue.main.async {
            if let error {
                self.addLog("Disconnected: \(error.localizedDescription)")
            } else {
                self.addLog("Disconnected")
            }
            self.connectedPeripheral = nil
            self.targetCharacteristic = nil
            self.isSending = false
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.addLog("Connection failed: \(error?.localizedDescription ?? "unknown")")
            self.connectedPeripheral = nil
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLEManager: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        DispatchQueue.main.async {
            if let error {
                self.addLog("Service error: \(error.localizedDescription)")
                return
            }
            guard let services = peripheral.services else {
                self.addLog("No services found")
                return
            }
            for service in services where service.uuid == self.serviceUUID {
                self.addLog("Found service, discovering characteristics...")
                peripheral.discoverCharacteristics([self.characteristicUUID], for: service)
            }
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        DispatchQueue.main.async {
            if let error {
                self.addLog("Characteristic error: \(error.localizedDescription)")
                return
            }
            guard let chars = service.characteristics else { return }
            for char in chars where char.uuid == self.characteristicUUID {
                self.targetCharacteristic = char
                self.addLog("Ready to sync!")
            }
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        DispatchQueue.main.async {
            if let error {
                self.addLog("Write error: \(error.localizedDescription)")
                self.isSending = false
                self.pendingWriteCount = 0
                return
            }
            self.pendingWriteCount -= 1
            if self.pendingWriteCount <= 0 {
                self.isSending = false
                self.addLog("Data sent successfully")
            }
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        DispatchQueue.main.async {
            if let error {
                self.addLog("Read error: \(error.localizedDescription)")
                self.readCompletionHandler?([])
                self.readCompletionHandler = nil
                return
            }

            if let data = characteristic.value,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let ids = json["completedIds"] as? [String] {
                self.addLog("Received \(ids.count) completion(s) from X4")
                self.completionIDs = ids
                self.readCompletionHandler?(ids)
            } else {
                if let data = characteristic.value,
                   let response = String(data: data, encoding: .utf8) {
                    self.addLog("X4 says: \(response)")
                }
                self.readCompletionHandler?([])
            }
            self.readCompletionHandler = nil
        }
    }
}

// MARK: - Errors

enum BLEError: Error, LocalizedError {
    case bluetoothUnavailable
    case connectionTimeout
    case sendTimeout

    var errorDescription: String? {
        switch self {
        case .bluetoothUnavailable: return "Bluetooth is not available or powered off."
        case .connectionTimeout:    return "Could not find or connect to Glance X4."
        case .sendTimeout:          return "Data transfer timed out."
        }
    }
}
