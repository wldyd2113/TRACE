//
//  AlertData.swift
//  TRACE
//
//  Created by 차지용 on 10/3/25.
//

import Foundation

/// 알림창 표시용 데이터 모델
struct AlertData {
    let title: String
    let message: String
    let completion: (() -> Void)?

    /// 완료 핸들러가 없는 기본 알림창 생성
    init(title: String, message: String) {
        self.title = title
        self.message = message
        self.completion = nil
    }

    /// 완료 핸들러가 있는 알림창 생성
    init(title: String, message: String, completion: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.completion = completion
    }
}