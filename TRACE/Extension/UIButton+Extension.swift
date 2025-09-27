//
//  UIButton+Extension.swift
//  TRACE
//
//  Created by 차지용 on 9/27/25.
//

import UIKit

extension UIButton {

    /// 메인 액션 버튼 스타일 설정
    func applyMainActionStyle(title: String, fontSize: CGFloat = 16) {
        self.setTitle(title, for: .normal)
        self.titleLabel?.font = FontManager.onglapFont(fontSize)
        self.setTitleColor(.white, for: .normal)
        self.backgroundColor = .buttonDark
        self.layer.cornerRadius = 25
    }

    /// 서브 액션 버튼 스타일 설정
    func applySubActionStyle(title: String, fontSize: CGFloat = 16) {
        self.setTitle(title, for: .normal)
        self.titleLabel?.font = FontManager.onglapFont(fontSize)
        self.setTitleColor(.labelLight, for: .normal)
        self.backgroundColor = .background
        self.layer.cornerRadius = 10
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.systemGray4.cgColor
    }

    /// 작은 관리 버튼 스타일 설정
    func applyManageButtonStyle(title: String, fontSize: CGFloat = 12) {
        self.setTitle(title, for: .normal)
        self.titleLabel?.font = FontManager.onglapFont(fontSize)
        self.setTitleColor(.labelLight, for: .normal)
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.buttonDark.cgColor
        self.layer.cornerRadius = 5

        // iOS 15+ 지원
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.title = title
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = FontManager.onglapFont(fontSize)
                return outgoing
            }
            config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            self.configuration = config
        } else {
            self.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        }
    }

    /// 라이트 액션 버튼 스타일 설정
    func applyLightActionStyle(title: String, fontSize: CGFloat = 16) {
        self.setTitle(title, for: .normal)
        self.titleLabel?.font = FontManager.onglapFont(fontSize)
        self.setTitleColor(.white, for: .normal)
        self.backgroundColor = .buttonLight
        self.layer.cornerRadius = 25
    }
}