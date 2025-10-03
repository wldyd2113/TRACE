//
//  RecordDisplayData.swift
//  TRACE
//
//  Created by 차지용 on 10/3/25.
//

import Foundation

/// 여행 기록 표시용 데이터 모델
struct RecordDisplayData {
    let travelName: String
    let recordLog: String
    let photos: [Data]
    let places: [PlaceDisplayData]
    let hasPlaceholder: Bool

    var hasContent: Bool {
        return !recordLog.isEmpty
    }
}