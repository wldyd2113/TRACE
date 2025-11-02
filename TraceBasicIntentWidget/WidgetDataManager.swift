//
//  WidgetDataManager.swift
//  TraceBasicIntentWidget
//
//  Created by 차지용 on 10/30/25.
//

import Foundation

struct WidgetTravelData: Codable {
    let destination: String
    let location: String
    let nation: String
    let startDate: Date
    let hasUpcomingTravel: Bool

    var daysUntil: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let travelDate = calendar.startOfDay(for: startDate)

        let components = calendar.dateComponents([.day], from: today, to: travelDate)
        return components.day ?? 0
    }
}

class WidgetDataManager {
    static let shared = WidgetDataManager()

    private let appGroupIdentifier = "group.trace.jiyong"
    private let userDefaultsKey = "UpcomingTravelData"

    private var sharedUserDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    // 메인 앱에서 호출하여 위젯용 데이터 저장
    func saveUpcomingTravelData(_ data: WidgetTravelData?) {
        guard let userDefaults = sharedUserDefaults else {
            print("❌ App Groups UserDefaults를 찾을 수 없습니다")
            return
        }

        if let data = data {
            do {
                let encodedData = try JSONEncoder().encode(data)
                userDefaults.set(encodedData, forKey: userDefaultsKey)
                print("✅ 위젯용 여행 데이터 저장 완료: \(data.destination)")
            } catch {
                print("❌ 위젯용 데이터 인코딩 실패: \(error)")
            }
        } else {
            userDefaults.removeObject(forKey: userDefaultsKey)
            print("✅ 위젯용 여행 데이터 삭제 완료")
        }
    }

    // 위젯에서 호출하여 여행 데이터 로드
    func loadUpcomingTravelData() -> WidgetTravelData? {
        print("🔍 위젯에서 데이터 로드 시도...")
        print("   App Group ID: \(appGroupIdentifier)")

        guard let userDefaults = sharedUserDefaults else {
            print("❌ 위젯에서 App Groups UserDefaults를 찾을 수 없습니다")
            print("   위젯 타겟에도 App Groups가 설정되어 있는지 확인하세요")
            return nil
        }

        // UserDefaults에 저장된 모든 키 확인
        let allKeys = userDefaults.dictionaryRepresentation().keys
        print("📋 UserDefaults에 저장된 키들: \(Array(allKeys))")

        guard let data = userDefaults.data(forKey: userDefaultsKey) else {
            print("📭 저장된 여행 데이터가 없습니다 (키: \(userDefaultsKey))")
            print("   메인 앱에서 여행 계획을 추가하고 앱을 새로고침해보세요")
            return nil
        }

        do {
            let travelData = try JSONDecoder().decode(WidgetTravelData.self, from: data)
            print("✅ 위젯용 여행 데이터 로드 완료: \(travelData.destination)")
            print("   D-\(travelData.daysUntil) (\(travelData.startDate))")
            return travelData
        } catch {
            print("❌ 위젯용 데이터 디코딩 실패: \(error)")
            return nil
        }
    }
}
