//
//  UIViewController+iPad.swift
//  TRACE
//
//  Created by 차지용 on 10/3/25.
//

import UIKit

extension UIViewController {
    func presentActionSheet(_ alertController: UIAlertController, sourceView: UIView) {
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
            popover.permittedArrowDirections = [.up, .down]
        }
        present(alertController, animated: true)
    }
}