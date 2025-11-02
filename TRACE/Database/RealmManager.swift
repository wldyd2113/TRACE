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
            // App Groups를 사용하여 위젯과 메인 앱이 같은 Realm 데이터베이스를 공유
            let appGroupIdentifier = "group.com.jiyong.TRACE"
            let realmURL: URL

            if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
                realmURL = groupURL.appendingPathComponent("default.realm")
                print("✅ App Groups 경로 사용: \(realmURL.path)")
            } else {
                // App Groups가 설정되지 않은 경우 기본 Documents 경로 사용
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                realmURL = documentsURL.appendingPathComponent("default.realm")
                print("⚠️ App Groups가 설정되지 않아 기본 Documents 경로를 사용합니다: \(realmURL.path)")
            }

            let config = Realm.Configuration(
                fileURL: realmURL,
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
            realm = try Realm(configuration: config)
            print("✅ Realm 초기화 성공")
            print("✅ Realm 경로: \(realmURL.path)")
        } catch {
            print("❌ Realm 초기화 실패: \(error)")
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