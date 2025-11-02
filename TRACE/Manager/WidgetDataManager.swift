//
//  WidgetDataManager.swift
//  TRACE
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
        print("🔄 위젯 데이터 저장 시도...")
        print("   App Group ID: \(appGroupIdentifier)")

        guard let userDefaults = sharedUserDefaults else {
            print("❌ App Groups UserDefaults를 찾을 수 없습니다")
            print("   App Groups가 Xcode에서 설정되어 있는지 확인하세요")

            // fallback으로 일반 UserDefaults 사용
            print("⚠️ 일반 UserDefaults를 사용합니다 (위젯에서 접근 불가)")
            if let data = data {
                do {
                    let encodedData = try JSONEncoder().encode(data)
                    UserDefaults.standard.set(encodedData, forKey: userDefaultsKey)
                    print("✅ 일반 UserDefaults에 저장 완료: \(data.destination)")
                } catch {
                    print("❌ 데이터 인코딩 실패: \(error)")
                }
            }
            return
        }

        if let data = data {
            do {
                let encodedData = try JSONEncoder().encode(data)
                userDefaults.set(encodedData, forKey: userDefaultsKey)
                userDefaults.synchronize() // 즉시 동기화
                print("✅ 위젯용 여행 데이터 저장 완료: \(data.destination)")
                print("   D-\(data.daysUntil) (\(data.startDate))")
            } catch {
                print("❌ 위젯용 데이터 인코딩 실패: \(error)")
            }
        } else {
            userDefaults.removeObject(forKey: userDefaultsKey)
            userDefaults.synchronize()
            print("✅ 위젯용 여행 데이터 삭제 완료")
        }
    }

    // 위젯에서 호출하여 여행 데이터 로드
    func loadUpcomingTravelData() -> WidgetTravelData? {
        guard let userDefaults = sharedUserDefaults else {
            print("❌ App Groups UserDefaults를 찾을 수 없습니다")
            return nil
        }

        guard let data = userDefaults.data(forKey: userDefaultsKey) else {
            print("📭 저장된 여행 데이터가 없습니다")
            return nil
        }

        do {
            let travelData = try JSONDecoder().decode(WidgetTravelData.self, from: data)
            print("✅ 위젯용 여행 데이터 로드 완료: \(travelData.destination)")
            return travelData
        } catch {
            print("❌ 위젯용 데이터 디코딩 실패: \(error)")
            return nil
        }
    }
}
