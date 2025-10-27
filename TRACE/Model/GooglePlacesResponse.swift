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
    let photos: [PlacePhoto]?

    enum CodingKeys: String, CodingKey {
        case name
        case geometry
        case placeId = "place_id"
        case formattedAddress = "formatted_address"
        case types
        case photos
    }
}

struct PlacePhoto: Codable {
    let photoReference: String
    let height: Int
    let width: Int

    enum CodingKeys: String, CodingKey {
        case photoReference = "photo_reference"
        case height
        case width
    }

    // Google Places Photo API URL 생성
    func getPhotoURL(maxWidth: Int = 400) -> String {
        return "https://maps.googleapis.com/maps/api/place/photo?maxwidth=\(maxWidth)&photo_reference=\(photoReference)&key=\(APIKey.googleKey)"
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