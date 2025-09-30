//
//  MapManagerDelegate.swift
//  TRACE
//
//  Created by 차지용 on 9/30/25.
//

import Foundation
import CoreLocation
protocol MapManagerDelegate: AnyObject {
    func mapManagerDidUpdateLocation(_ coordinate: CLLocationCoordinate2D)
    func mapManagerDidFailToGetLocation()
    func mapManagerDidSelectPlace(_ place: KakaoPlace)
    func mapManagerDidUpdateSearchedPlaces(_ places: [KakaoPlace])
}
