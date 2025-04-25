import CoreBluetooth
import Foundation
import FirebaseFirestore

class BluetoothSimulator: NSObject, ObservableObject, CBCentralManagerDelegate {
    
    private var centralManager: CBCentralManager?
    private let localStore = LocalDataStore()
    private var dispatchTimer: DispatchSourceTimer?
    
    @Published var sensor1Channel1: Double = 0.0
    @Published var sensor1Channel2: Double = 0.0
    @Published var sensor1Channel3: Double = 0.0
    
    @Published var sensor2Channel1: Double = 0.0
    @Published var sensor2Channel2: Double = 0.0
    @Published var sensor2Channel3: Double = 0.0
    
    private let db = Firestore.firestore()
    private let userIdKey = "bluetooth_user_id"
    private let userNameKey = "user_name"
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // bluetooth central scanning for devices, ideally should not start the startSimulation()
    // function and implement peripherals connecting to this central
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("📡 Central Manager state: \(central.state.rawValue)")
        print(central.state)
        if central.state == .poweredOn {
            print("✅ Central Bluetooth is powered on — simulating sensor data reception")
            centralManager?.scanForPeripherals(withServices: nil, options: nil)
            startSimulation()
        } else {
            print("⚠️ Central Bluetooth not ready or unavailable")
        }
    }

    // simulating bluetooth device incoming data
    private func startSimulation() {
        print("hre")
        print("✅ Starting Bluetooth simulation")
        beginTimer()
    }

    private func beginTimer() {
        let queue = DispatchQueue(label: "com.graphware.simulation", qos: .background)
        dispatchTimer = DispatchSource.makeTimerSource(queue: queue)
        dispatchTimer?.schedule(deadline: .now(), repeating: 30)
        dispatchTimer?.setEventHandler { [weak self] in
            self?.pushSimulatedData()
        }
        dispatchTimer?.resume()
    }

    // check localstorage in sqlite to push any data
    private func flushBufferedRecordsToFirestore() {
        let buffered = localStore.fetchBufferedRecords()
        
        for record in buffered {
            guard let recordId = record["id"] as? Int64 else { continue }
            
            db.collection("lactate_data").addDocument(data: record) { error in
                if error == nil {
                    self.localStore.deleteRecordById(recordId)
                    print("✅ Flushed buffered record to Firestore: \(record)")
                } else {
                    print("❌ Still failed to push buffered record: \(error!)")
                }
            }
        }
    }
    
    // push to firebase
    private func pushSimulatedData() {
        let userId = UserDefaults.standard.string(forKey: userIdKey) ?? ""
        let userName = UserDefaults.standard.string(forKey: userNameKey) ?? ""

        guard !userId.isEmpty, !userName.isEmpty else {
            print("Missing userId or userName")
            return
        }

        let result1 = parseHexPacketToJSON()
        let result2 = parseHexPacketToJSON()

        let sensors = ["Sensor 1", "Sensor 2"]
        let results = [result1, result2]

        for (index, sensor) in sensors.enumerated() {
            let result = results[index]

            guard let jsonData = result.data(using: .utf8),
                  var jsonDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                print("❌ Failed to convert JSON string to dictionary for \(sensor)")
                continue
            }

            jsonDict["user_id"] = Int(userId)
            jsonDict["user_name"] = userName
            jsonDict["sensor_id"] = sensor

            db.collection("lactate_data").addDocument(data: jsonDict) { error in
                if let error = error {
                    print("📴 Push failed for \(sensor), storing locally.")
                    print("❌ Error: \(error)")
                    self.localStore.insertBufferRecord(jsonDict)
                } else {
                    print("✅ Data for \(sensor) pushed successfully")
                     self.flushBufferedRecordsToFirestore()
                }
            }

            DispatchQueue.main.async {
                if sensor == "Sensor 1" {
                    self.sensor1Channel1 = jsonDict["ohm1"] as? Double ?? 0.0
                    self.sensor1Channel2 = jsonDict["ohm2"] as? Double ?? 0.0
                    self.sensor1Channel3 = jsonDict["ohm3"] as? Double ?? 0.0
                } else {
                    self.sensor2Channel1 = jsonDict["ohm1"] as? Double ?? 0.0
                    self.sensor2Channel2 = jsonDict["ohm2"] as? Double ?? 0.0
                    self.sensor2Channel3 = jsonDict["ohm3"] as? Double ?? 0.0
                }
            }
        }
    }

}
