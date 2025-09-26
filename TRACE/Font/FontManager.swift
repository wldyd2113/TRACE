//
//  FontManager.swift
//  TRACE
//
//  Created by 차지용 on 9/25/25.
//

import UIKit

enum FontManager {
    case onglapUIyeon

    var fontName: String {
        switch self {
        case .onglapUIyeon:
            // 실제 폰트 이름들을 시도해보기
            let possibleNames = ["온글잎 의연체", "OngleafUiyeon", "Ongleaf-Uiyeon"]
            for name in possibleNames {
                if UIFont(name: name, size: 12) != nil {
                    return name
                }
            }
            // 모든 폰트 이름을 출력해서 디버깅
            print("Available fonts:")
            for family in UIFont.familyNames {
                print("Family: \(family)")
                for font in UIFont.fontNames(forFamilyName: family) {
                    print("  Font: \(font)")
                }
            }
            return "온글잎 의연체"
        }
    }

    func font(size: CGFloat) -> UIFont {
        let font = UIFont(name: fontName, size: size)
        if font == nil {
            print("⚠️ Font '\(fontName)' not found, using system font")
        }
        return font ?? UIFont.systemFont(ofSize: size)
    }

    func boldFont(size: CGFloat) -> UIFont {
        // 커스텀 폰트에 bold가 없으면 시스템 bold 폰트 사용
        if let customFont = UIFont(name: fontName, size: size) {
            // 커스텀 폰트의 bold 버전을 시도
            let boldNames = ["\(fontName)-Bold", "\(fontName)Bold", "\(fontName)-Regular", fontName]
            for boldName in boldNames {
                if let boldFont = UIFont(name: boldName, size: size) {
                    return boldFont
                }
            }
            // bold 버전이 없으면 원본 폰트 반환
            return customFont
        }
        print("⚠️ Font '\(fontName)' not found for bold, using system bold font")
        return UIFont.boldSystemFont(ofSize: size)
    }
}

// MARK: - Convenience Methods
extension FontManager {
    static func onglapFont(_ size: CGFloat) -> UIFont {
        return FontManager.onglapUIyeon.font(size: size)
    }

    static func onglapBoldFont(_ size: CGFloat) -> UIFont {
        return FontManager.onglapUIyeon.boldFont(size: size)
    }
}


