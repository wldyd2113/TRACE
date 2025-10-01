//
//  RealmManager.swift
//  TRACE
//
//  Created by 차지용 on 9/30/25.
//

import Foundation
import RealmSwift

class RealmManager {
    static let shared = RealmManager()
    private var realm: Realm?

    private init() {
        initializeRealm()
    }

    private func initializeRealm() {
        do {
            let config = Realm.Configuration(
                schemaVersion: 4,
                migrationBlock: { migration, oldSchemaVersion in
                    if oldSchemaVersion < 2 {
                        migration.enumerateObjects(ofType: TravelRecord.className()) { oldObject, newObject in
                            if let oldLocation = oldObject!["location"] as? DynamicObject {
                                let newLocationsList = List<DynamicObject>()
                                let newLocation = migration.create(RecordPlace.className())
                                newLocation["location"] = oldLocation["location"]
                                newLocation["latitude"] = oldLocation["latitude"]
                                newLocation["longitude"] = oldLocation["longitude"]
                                newLocationsList.append(newLocation)
                                newObject!["locations"] = newLocationsList
                            }
                        }
                    }
                }
            )
            Realm.Configuration.defaultConfiguration = config
            realm = try Realm()
            print("✅ Realm 초기화 성공")
        } catch {
            print("❌ Realm 초기화 실패: \(error)")
            print("❌ Realm 경로: \(Realm.Configuration.defaultConfiguration.fileURL?.path ?? "Unknown")")
        }
    }

    func getRealm() -> Realm? {
        if realm == nil {
            initializeRealm()
        }
        return realm
    }

    func safeRealm() -> Realm? {
        do {
            return try Realm()
        } catch {
            print("❌ Realm 생성 실패: \(error)")
            return nil
        }
    }
}