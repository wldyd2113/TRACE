//
//  TravelPlanMainViewController+Notification.swift
//  TRACE
//
//  Created by 차지용 on 10/14/25.
//

import UIKit

extension TravelPlanMainViewController {

    // MARK: - 알림 권한 확인 및 요청
    func requestNotificationPermissionIfNeeded() {
        NotificationManager.shared.checkNotificationPermission { [weak self] isAuthorized in
            if !isAuthorized {
                self?.showNotificationPermissionAlert()
            }
        }
    }

    private func showNotificationPermissionAlert() {
        let alert = UIAlertController(
            title: "알림 권한 요청",
            message: "여행 하루 전에 미리 알림을 받으시겠어요? 설정에서 언제든 변경할 수 있습니다.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "나중에", style: .cancel))
        alert.addAction(UIAlertAction(title: "허용", style: .default) { _ in
            NotificationManager.shared.requestNotificationPermission { granted in
                if granted {
                    print("✅ 알림 권한이 허용되었습니다.")
                } else {
                    print("❌ 알림 권한이 거부되었습니다.")
                }
            }
        })

        present(alert, animated: true)
    }


    // MARK: - 모든 여행 알림 취소 (설정 화면 등에서 사용)
    func cancelAllTravelNotifications() {
        let alert = UIAlertController(
            title: "알림 취소",
            message: "모든 여행 알림을 취소하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "확인", style: .destructive) { _ in
            NotificationManager.shared.cancelAllTravelReminders()
        })

        present(alert, animated: true)
    }
}
