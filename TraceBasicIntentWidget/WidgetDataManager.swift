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

    private let appGroupIdentifier = "group.jiyong.TRACE"
    private let userDefaultsKey = "UpcomingTravelData"

    private var sharedUserDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    // 메인 앱에서 호출하여 위젯용 데이터 저장
    func saveUpcomingTravelData(_ data: WidgetTravelData?) {
        // 기기별 고유 키 생성 (사용자 데이터 격리를 위해)
        let deviceKey = getDeviceSpecificKey()

        guard let userDefaults = sharedUserDefaults else {
            print("❌ App Groups UserDefaults를 찾을 수 없습니다")
            return
        }

        if let data = data {
            do {
                let encodedData = try JSONEncoder().encode(data)
                userDefaults.set(encodedData, forKey: deviceKey)
                userDefaults.synchronize()
                print("✅ 위젯용 여행 데이터 저장 완료: \(data.destination) (키: \(deviceKey))")
            } catch {
                print("❌ 위젯용 데이터 인코딩 실패: \(error)")
            }
        } else {
            userDefaults.removeObject(forKey: deviceKey)
            userDefaults.synchronize()
            print("✅ 위젯용 여행 데이터 삭제 완료 (키: \(deviceKey))")
        }
    }

    // 위젯에서 호출하여 여행 데이터 로드
    func loadUpcomingTravelData() -> WidgetTravelData? {
        // 기기별 고유 키 생성
        let deviceKey = getDeviceSpecificKey()

        print("🔍 위젯에서 데이터 로드 시도...")
        print("   App Group ID: \(appGroupIdentifier)")
        print("   기기별 키: \(deviceKey)")

        guard let userDefaults = sharedUserDefaults else {
            print("❌ 위젯에서 App Groups UserDefaults를 찾을 수 없습니다")
            print("   위젯 타겟에도 App Groups가 설정되어 있는지 확인하세요")
            return nil
        }

        guard let data = userDefaults.data(forKey: deviceKey) else {
            print("📭 저장된 여행 데이터가 없습니다 (키: \(deviceKey))")
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

    // 기기별 고유 키 생성 메서드
    private func getDeviceSpecificKey() -> String {
        // 위젯에서는 UIDevice를 직접 사용할 수 없으므로 다른 방법 사용
        let deviceID: String

        // UserDefaults에 저장된 기기 ID 확인
        if let savedDeviceID = UserDefaults.standard.string(forKey: "TRACE_DEVICE_ID") {
            deviceID = savedDeviceID
        } else {
            // 새로운 기기 ID 생성 및 저장
            deviceID = UUID().uuidString
            UserDefaults.standard.set(deviceID, forKey: "TRACE_DEVICE_ID")
        }

        return "\(userDefaultsKey)_\(deviceID)"
    }
}
