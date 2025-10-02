//
//  UILabel+Extension.swift
//  TRACE
//
//  Created by 차지용 on 9/27/25.
//

import UIKit

extension UILabel {

    /// 제목용 라벨 스타일 설정
    func applyTitleStyle(text: String, fontSize: CGFloat = 24, isBold: Bool = true) {
        self.text = text
        self.font = isBold ? FontManager.onglapBoldFont(fontSize) : FontManager.onglapFont(fontSize)
        self.textColor = .labelLight
    }

    /// 섹션 제목용 라벨 스타일 설정
    func applySectionTitleStyle(text: String, fontSize: CGFloat = 22) {
        self.text = text
        self.font = FontManager.onglapFont(fontSize)
        self.textColor = .labelLight
    }

    /// 부제목용 라벨 스타일 설정
    func applySubtitleStyle(text: String, fontSize: CGFloat = 20) {
        self.text = text
        self.font = FontManager.onglapFont(fontSize)
        self.textColor = .systemGray
    }

    /// 설명용 라벨 스타일 설정
    func applyDescriptionStyle(text: String, fontSize: CGFloat = 18) {
        self.text = text
        self.font = FontManager.onglapFont(fontSize)
        self.textColor = .systemGray
    }

    /// 캡션용 라벨 스타일 설정
    func applyCaptionStyle(text: String, fontSize: CGFloat = 16) {
        self.text = text
        self.font = FontManager.onglapFont(fontSize)
        self.textColor = .systemGray2
    }

    /// 날짜 표시용 라벨 스타일 설정
    func applyDateStyle(text: String, fontSize: CGFloat = 18) {
        self.text = text
        self.font = FontManager.onglapFont(fontSize)
        self.textColor = .systemGray
        self.textAlignment = .right
    }
}
