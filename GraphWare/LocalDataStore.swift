//
//  LocalDataStore.swift
//  GraphWare
//
//  Created by Shashi on 4/20/25.
//


import SQLite
import Foundation

class LocalDataStore {
    private var db: Connection?
    private let bufferTable = Table("lactate_buffer")

    private let id = Expression<Int64>("id")
    private let timestamp = Expression<Double>("timestamp")
    private let value = Expression<Double>("value")
    private let userId = Expression<String>("user_id")
    private let sensorId = Expression<String>("sensor_id")

    init() {
        setupDatabase()
    }

    private func setupDatabase() {
        do {
            let path = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)
                .first!
                .appendingPathComponent("lactate_buffer.sqlite3")
                .path

            db = try Connection(path)
            try db?.run(bufferTable.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(timestamp)
                t.column(value)
                t.column(userId)
                t.column(sensorId)
            })
        } catch {
            print("❌ Failed to set up SQLite DB: \(error)")
        }
    }

    func insertBufferRecord(_ record: [String: Any]) {
        guard let db = db,
              let ts = record["timestamp"] as? Double,
              let val = record["value"] as? Double,
              let uid = record["user_id"] as? String,
              let sid = record["sensor_id"] as? String else { return }

        do {
            try db.run(bufferTable.insert(timestamp <- ts, value <- val, userId <- uid, sensorId <- sid))
            print("💾 Buffered record inserted into SQLite")
        } catch {
            print("❌ Failed to insert buffer record: \(error)")
        }
    }

    func fetchBufferedRecords() -> [[String: Any]] {
        guard let db = db else { return [] }

        var records: [[String: Any]] = []
        do {
            for row in try db.prepare(bufferTable) {
                records.append([
                    "id": row[id],
                    "timestamp": row[timestamp],
                    "value": row[value],
                    "user_id": row[userId],
                    "sensor_id": row[sensorId]
                ])
            }
        } catch {
            print("❌ Failed to fetch buffered records: \(error)")
        }
        return records
    }

    func deleteRecordById(_ recordId: Int64) {
        guard let db = db else { return }
        do {
            let row = bufferTable.filter(id == recordId)
            try db.run(row.delete())
        } catch {
            print("❌ Failed to delete buffered record: \(error)")
        }
    }
}
