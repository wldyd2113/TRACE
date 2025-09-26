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
            return "온글잎 의연체"
        }
    }
}


