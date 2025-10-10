//
//  TravelChannelViewController+Map.swift
//  TRACE
//
//  Created by 차지용 on 10/10/25.
//

import UIKit
import MapKit
import CoreLocation

// MARK: - MapManagerDelegate
extension TravelChannelViewController: MapManagerDelegate {
    func mapManagerDidUpdateLocation(_ coordinate: CLLocationCoordinate2D) {
        print("📍 TravelChannel: Map updated to location: \(coordinate.latitude), \(coordinate.longitude)")
    }

    func mapManagerDidFailToGetLocation() {
        print("📍 TravelChannel: Failed to get location")
        showLocationPermissionAlert()
    }

    func mapManagerDidSelectPlace(_ place: KakaoPlace) {
        print("📍 TravelChannel: Place selected: \(place.placeName)")
    }

    func mapManagerDidUpdateSearchedPlaces(_ places: [KakaoPlace]) {
        print("📍 TravelChannel: Searched places updated: \(places.count)개")
    }
}

// MARK: - Map Helper Methods
extension TravelChannelViewController {
    func setupMapManager() {
        mapManager.delegate = self
        mapManager.requestInitialLocation()
    }

    func moveToCurrentLocation() {
        print("📍 현재 위치로 이동 요청")
        mapManager.requestCurrentLocation()
    }

    func showLocationPermissionAlert() {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(
                title: "위치 권한 필요",
                message: "현재 위치를 확인하려면 위치 권한이 필요합니다.\n설정에서 위치 권한을 허용해주세요.",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            })

            alert.addAction(UIAlertAction(title: "취소", style: .cancel))

            self?.present(alert, animated: true)
        }
    }
}