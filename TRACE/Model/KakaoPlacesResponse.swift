//
//  KakaoPlacesResponse.swift
//  TRACE
//
//  Created by 차지용 on 9/29/25.
//

import Foundation
import CoreLocation

struct KakaoPlacesResponse: Codable {
    let documents: [KakaoPlace]
    let meta: KakaoMeta
}

struct KakaoPlace: Codable {
    let id: String
    let placeName: String
    let categoryName: String
    let categoryGroupCode: String
    let categoryGroupName: String
    let phone: String
    let addressName: String
    let roadAddressName: String
    let x: String // longitude
    let y: String // latitude
    let placeUrl: String
    let distance: String

    enum CodingKeys: String, CodingKey {
        case id
        case placeName = "place_name"
        case categoryName = "category_name"
        case categoryGroupCode = "category_group_code"
        case categoryGroupName = "category_group_name"
        case phone
        case addressName = "address_name"
        case roadAddressName = "road_address_name"
        case x, y
        case placeUrl = "place_url"
        case distance
    }

    var coordinate: CLLocationCoordinate2D {
        let longitude = Double(x) ?? 0.0
        let latitude = Double(y) ?? 0.0
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct KakaoMeta: Codable {
    let totalCount: Int
    let pageableCount: Int
    let isEnd: Bool

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case pageableCount = "pageable_count"
        case isEnd = "is_end"
    }
}