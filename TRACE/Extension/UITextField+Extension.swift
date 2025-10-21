//
//  UITextField+Extension.swift
//  TRACE
//
//  Created by 차지용 on 9/27/25.
//

import UIKit

extension UITextField {

    /// 기본 여행 앱 스타일의 텍스트필드 설정
    func applyTravelStyle(placeholder: String, fontSize: CGFloat = 14) {
        self.placeholder = placeholder
        self.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: fontSize)
        self.borderStyle = .roundedRect
        self.backgroundColor = .systemGray6
        self.layer.cornerRadius = 8
    }

    /// 검색용 텍스트필드 스타일 설정
    func applySearchStyle(placeholder: String) {
        self.placeholder = placeholder
        self.font = FontManager.onglapFont(22) // applyDescriptionStyle 크기
        self.backgroundColor = .systemGray6
        self.layer.cornerRadius = 12
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.systemGray4.cgColor

        // 좌측 패딩 추가
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: self.frame.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }

    /// 폼 입력용 텍스트필드 스타일 설정
    func applyFormStyle(placeholder: String, fontSize: CGFloat = 22) {
        self.placeholder = placeholder
        self.font = FontManager.onglapFont(fontSize) // applyDescriptionStyle 크기 기본값
        self.borderStyle = .none
        self.backgroundColor = .systemGray6
        self.layer.cornerRadius = 8

        // 패딩 추가
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: self.frame.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}