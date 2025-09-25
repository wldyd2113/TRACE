//
//  KaKaoPlace.swift
//  TRACE
//
//  Created by 차지용 on 9/25/25.
//

import Foundation
import RealmSwift

class KaKaoPlace: Object, Codable {
    @Persisted var id: String = ""
    @Persisted var placeName: String = ""
    @Persisted var categoryName: String = ""
    @Persisted var addressName: String = ""
    @Persisted var roadAddressName: String = ""
    @Persisted var phone: String = ""
    @Persisted var placeUrl: String = ""
    @Persisted var distance: String = ""
    @Persisted var x: String = ""  // longitude
    @Persisted var y: String = ""  // latitude

    override static func primaryKey() -> String? {
        return "id"
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case placeName = "place_name"
        case categoryName = "category_name"
        case addressName = "address_name"
        case roadAddressName = "road_address_name"
        case phone
        case placeUrl = "place_url"
        case distance
        case x, y
    }
}
