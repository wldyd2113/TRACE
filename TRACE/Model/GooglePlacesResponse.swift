//
//  GooglePlacesResponse.swift
//  TRACE
//
//  Created by 차지용 on 9/29/25.
//

import Foundation
import CoreLocation

struct GooglePlacesResponse: Codable {
    let results: [PlaceResult]
    let status: String
}

struct PlaceResult: Codable {
    let name: String
    let geometry: PlaceGeometry
    let placeId: String
    let formattedAddress: String?
    let types: [String]

    enum CodingKeys: String, CodingKey {
        case name
        case geometry
        case placeId = "place_id"
        case formattedAddress = "formatted_address"
        case types
    }
}

struct PlaceGeometry: Codable {
    let location: PlaceLocation
}

struct PlaceLocation: Codable {
    let lat: Double
    let lng: Double

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}