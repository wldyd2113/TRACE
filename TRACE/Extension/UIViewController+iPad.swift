//
//  UIViewController+iPad.swift
//  TRACE
//
//  Created by 차지용 on 10/3/25.
//

import UIKit

extension UIViewController {

    /// iPad에서 ActionSheet를 안전하게 표시하는 메서드
    /// - Parameters:
    ///   - alert: 표시할 UIAlertController
    ///   - sourceView: Popover의 기준이 될 뷰 (기본값: self.view)
    ///   - sourceRect: Popover의 기준 영역 (기본값: 화면 중앙)
    ///   - barButtonItem: Popover의 기준이 될 바 버튼 아이템 (옵셔널)
    func presentActionSheet(
        _ alert: UIAlertController,
        sourceView: UIView? = nil,
        sourceRect: CGRect? = nil,
        barButtonItem: UIBarButtonItem? = nil
    ) {
        // ActionSheet가 아닌 경우 일반적으로 표시
        guard alert.preferredStyle == .actionSheet else {
            present(alert, animated: true)
            return
        }

        // iPad 대응
        if let popover = alert.popoverPresentationController {
            if let barButtonItem = barButtonItem {
                // 바 버튼 아이템이 제공된 경우
                popover.barButtonItem = barButtonItem
            } else {
                // 뷰와 영역이 제공된 경우
                let targetView = sourceView ?? view
                let targetRect = sourceRect ?? CGRect(
                    x: targetView?.bounds.midX ?? view.bounds.midX,
                    y: targetView?.bounds.midY ?? view.bounds.midY,
                    width: 0,
                    height: 0
                )

                popover.sourceView = targetView
                popover.sourceRect = targetRect
            }

            // 화살표 방향 설정
            popover.permittedArrowDirections = [.up, .down, .left, .right]
        }

        present(alert, animated: true)
    }
}
