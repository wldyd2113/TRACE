//
//  TravelPlanDetailViewController+Realm.swift
//  TRACE
//
//  Created by 차지용 on 9/29/25.
//

import UIKit

// MARK: - ViewModel Save Methods
extension TravelPlanDetailViewController {

    func saveAllDataToRealm() {
        print("💾 ===== UI에서 저장 요청 =====")

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