import Foundation

func parseHexPacketToJSON() -> String {
    
    let hex = createHexPacket(from : Date().timeIntervalSince1970)
//    let hex = "06AB00174A0188B0F56703FFC67A49B92AC4BC2B8080808080807B5F99728AE601794F029999BABA"
    
    var bytes: [UInt8] = []
    var i = hex.startIndex
    while i < hex.endIndex {
        let nextIndex = hex.index(i, offsetBy: 2)
        let byteString = hex[i..<nextIndex]
        if let byte = UInt8(byteString, radix: 16) {
            bytes.append(byte)
        }
        i = nextIndex
    }

    guard bytes.count == 40 else {
        return "{\"error\": \"Invalid packet length. Expected 40 bytes\"}"
    }

    var index = 0

    let version = bytes[index]
    index += 1

    let header1 = bytes[index]
    let header2 = bytes[index + 1]
    index += 2

    let serialNumber = UInt16(bytes[index]) << 8 | UInt16(bytes[index + 1])
    index += 2

    let recordCount = bytes[index]
    index += 1

    let timestamp = UInt32(bytes[index]) |
                    UInt32(bytes[index+1]) << 8 |
                    UInt32(bytes[index+2]) << 16 |
                    UInt32(bytes[index+3]) << 24
    index += 4

    let flagsByte = bytes[index]
    index += 1

    let wearingStatus = (flagsByte & 0b00000001) != 0
    let insertionStatus = (flagsByte & 0b00000010) != 0
    let touchStatus = (flagsByte & 0b00000100) != 0
    let chargingStatus = (flagsByte & 0b00001000) != 0
    let flag4 = (flagsByte & 0b00010000) != 0
    let flag5 = (flagsByte & 0b00100000) != 0
    let flag6 = (flagsByte & 0b01000000) != 0
    let connectionStatus = (flagsByte & 0b10000000) != 0

    func read24BitIntLE(start: Int) -> Int32 {
        let b0 = Int32(bytes[start])
        let b1 = Int32(bytes[start + 1])
        let b2 = Int32(bytes[start + 2])
        let value = (b2 << 16) | (b1 << 8) | b0
        return value >= 0x800000 ? value - 0x1000000 : value
    }

    func read24BitUIntLE(start: Int) -> UInt32 {
        return UInt32(bytes[start]) |
               UInt32(bytes[start + 1]) << 8 |
               UInt32(bytes[start + 2]) << 16
    }

    let raw1 = read24BitIntLE(start: index)
    index += 3
    let raw2 = read24BitIntLE(start: index)
    index += 3
    let raw3 = read24BitIntLE(start: index)
    index += 3

    let gain0 = bytes[index]
    let gain1 = bytes[index + 1]
    let gain2 = bytes[index + 2]
    index += 3

    let offset0 = bytes[index]
    let offset1 = bytes[index + 1]
    let offset2 = bytes[index + 2]
    index += 3

    let temperature = bytes[index]
    index += 1

    let ohm1 = Double(read24BitUIntLE(start: index)) / 100.0 / 1000.0
    index += 3
    let ohm2 = Double(read24BitUIntLE(start: index)) / 100.0 / 1000.0
    index += 3
    let ohm3 = Double(read24BitUIntLE(start: index)) / 100.0 / 1000.0
    index += 3

    index += 4 // Skip CRC + tail

    let result: [String: Any] = [
        "version": version,
        "header1": header1,
        "header2": header2,
        "serial_number": serialNumber,
        "record_count": recordCount,
        "timestamp": timestamp,
        "wearing_status_flag": wearingStatus,
        "insertion_status_flag": insertionStatus,
        "touch_status_flag": touchStatus,
        "charging_status_flag": chargingStatus,
        "flag4": flag4,
        "flag5": flag5,
        "flag6": flag6,
        "connection_status_flag": connectionStatus,
        "raw1": raw1,
        "raw2": raw2,
        "raw3": raw3,
        "gain0": gain0,
        "gain1": gain1,
        "gain2": gain2,
        "offset0": offset0,
        "offset1": offset1,
        "offset2": offset2,
        "temperature": temperature,
        "ohm1": ohm1,
        "ohm2": ohm2,
        "ohm3": ohm3
    ]

    if let jsonData = try? JSONSerialization.data(withJSONObject: result, options: .prettyPrinted),
       let jsonString = String(data: jsonData, encoding: .utf8) {
        return jsonString
    } else {
        return "{\"error\": \"Failed to serialize JSON\"}"
    }
}


func createHexPacket(from timestamp: TimeInterval) -> String {
    var bytes: [UInt8] = []

    let version: UInt8 = 1
    let header1: UInt8 = 0xAA
    let header2: UInt8 = 0x55
    let serialNumber: UInt16 = 0x1234
    let recordCount: UInt8 = 1

    bytes.append(version)
    bytes.append(header1)
    bytes.append(header2)
    bytes.append(UInt8((serialNumber >> 8) & 0xFF))
    bytes.append(UInt8(serialNumber & 0xFF))
    bytes.append(recordCount)

    let timestampUInt32 = UInt32(timestamp)
    bytes.append(UInt8(timestampUInt32 & 0xFF))
    bytes.append(UInt8((timestampUInt32 >> 8) & 0xFF))
    bytes.append(UInt8((timestampUInt32 >> 16) & 0xFF))
    bytes.append(UInt8((timestampUInt32 >> 24) & 0xFF))

    let flags: UInt8 = 0b00001001
    bytes.append(flags)

    // lactate
    for _ in 0..<3 {
        let raw = Int32(Int.random(in: 0...99))
        let val = raw < 0 ? UInt32(0x1000000 + raw) : UInt32(raw)
        bytes.append(UInt8(val & 0xFF))
        bytes.append(UInt8((val >> 8) & 0xFF))
        bytes.append(UInt8((val >> 16) & 0xFF))
    }

    bytes.append(contentsOf: [1, 2, 3])
    bytes.append(contentsOf: [4, 5, 6])
    bytes.append(36)

    for _ in 0..<3 {
        let ohmValue = Double.random(in: 0..<99.99)
        let scaled = UInt32(ohmValue * 100 * 1000)
        bytes.append(UInt8(scaled & 0xFF))
        bytes.append(UInt8((scaled >> 8) & 0xFF))
        bytes.append(UInt8((scaled >> 16) & 0xFF))
    }

    bytes.append(contentsOf: [0x00, 0x00, 0x00, 0x00])

    return bytes.map { String(format: "%02X", $0) }.joined()
}
