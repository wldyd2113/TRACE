//
//  UIView+Extension.swift
//  TRACE
//
//  Created by 차지용 on 9/27/25.
//

import UIKit

extension UIView {

    /// 카드 스타일 뷰 설정
    func applyCardStyle(cornerRadius: CGFloat = 12, backgroundColor: UIColor = .systemGray6) {
        self.backgroundColor = backgroundColor
        self.layer.cornerRadius = cornerRadius
        self.clipsToBounds = true
    }

    /// 컨테이너 뷰 스타일 설정
    func applyContainerStyle(cornerRadius: CGFloat = 8, backgroundColor: UIColor = .background) {
        self.backgroundColor = backgroundColor
        self.layer.cornerRadius = cornerRadius
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.systemGray5.cgColor
    }

    /// 그림자 효과 추가
    func applyShadow(opacity: Float = 0.1, radius: CGFloat = 4, offset: CGSize = CGSize(width: 0, height: 2)) {
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = opacity
        self.layer.shadowRadius = radius
        self.layer.shadowOffset = offset
        self.layer.masksToBounds = false
    }

    /// 둥근 모서리 설정
    func applyRoundedCorners(radius: CGFloat = 8) {
        self.layer.cornerRadius = radius
        self.clipsToBounds = true
    }
}