//
//  PlaceDisplayData.swift
//  TRACE
//
//  Created by 차지용 on 10/3/25.
//

import Foundation
import CoreLocation

/// 장소 표시용 데이터 모델
struct PlaceDisplayData {
    let id: String
    let placeName: String
    let latitude: Double
    let longitude: Double

    /// CoreLocation.CLLocationCoordinate2D로 변환
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}