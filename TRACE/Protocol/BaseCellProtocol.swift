//
//  BaseCellProtocol.swift
//  TRACE
//
//  Created by 차지용 on 9/25/25.
//

import Foundation
protocol BaseCellProtocol {
    static var identifier: String { get }
}

extension BaseCellProtocol {
    static var identifier: String {
        return String(describing: self)
    }
}
