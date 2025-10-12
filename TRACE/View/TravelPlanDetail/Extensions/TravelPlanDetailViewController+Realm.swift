//
//  TravelPlanDetailViewController+Realm.swift
//  TRACE
//
//  Created by 차지용 on 9/29/25.
//

import UIKit
import RealmSwift

// MARK: - ViewModel Save Methods
extension TravelPlanDetailViewController {

    func saveAllDataToRealm() {
        print("💾 ===== UI에서 저장 요청 =====")

        // 자동 저장 방지 플래그 확인
        if shouldPreventAutoSave {
            print("🚫 UI: 자동 저장 방지로 인해 Realm 저장을 건너뜁니다")
            return
        }

        // 임시 여행 정보가 있는 경우 먼저 TravelPlan을 생성
        if let tempInfo = tempTravelInfo {
            print("📝 임시 여행 정보로 TravelPlan 생성:")
            print("   🌍 국가: \(tempInfo.country)")
            print("   📍 여행지: \(tempInfo.destination)")
            print("   📅 기간: \(DateManager.shared.formatToKoreanString(from: tempInfo.startDate)) ~ \(DateManager.shared.formatToKoreanString(from: tempInfo.endDate))")

            // TravelDay 초기값 생성
            let travelDay = TravelDay()
            travelDay.price = 0
            travelDay.place = ""
            travelDay.traffic = ""
            travelDay.location = ""
            travelDay.date = tempInfo.startDate
            travelDay.latitude = 0.0
            travelDay.longitude = 0.0

            // TravelPlan 생성
            let travelPlan = TravelPlan(
                nation: tempInfo.country,
                travelName: tempInfo.destination,
                startDate: tempInfo.startDate,
                endDate: tempInfo.endDate,
                day: travelDay
            )

            // Realm에 TravelPlan 저장
            do {
                let realm = try Realm()
                try realm.write {
                    realm.add(travelPlan)
                }
                print("✅ TravelPlan 생성 및 저장 완료")

                // 임시 정보 제거 (이제 정식으로 저장됨)
                self.tempTravelInfo = nil

            } catch {
                print("❌ TravelPlan 저장 실패: \(error.localizedDescription)")
                showSaveAlert(success: false, message: "여행 계획 저장에 실패했습니다.")
                return
            }
        }

        // 현재 입력된 데이터를 ViewModel에 업데이트
        let currentBudget = budgetTextField.text ?? ""

        print("📝 현재 UI 데이터:")
        print("   💰 예산: '\(currentBudget)'")
        print("   📅 현재 일차: \(currentDay)")

        // ViewModel에 현재 데이터 업데이트
        viewModel.updateBudget(currentBudget, forDay: currentDay)
        viewModel.updateSearchedPlaces(currentSearchedPlaces, forDay: currentDay)

        // ViewModel을 통해 저장 실행
        viewModel.saveAllDataToRealm()
    }

    func showSaveAlert(success: Bool, message: String) {
        let title = success ? "저장 완료" : "저장 실패"
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
