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
        moveToPlace(place)
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

    func zoomIn() {
        print("🔍 지도 확대")
        let currentRegion = mapManager.mapView.region
        let newSpan = MKCoordinateSpan(
            latitudeDelta: currentRegion.span.latitudeDelta * 0.5,
            longitudeDelta: currentRegion.span.longitudeDelta * 0.5
        )
        let newRegion = MKCoordinateRegion(
            center: currentRegion.center,
            span: newSpan
        )
        mapManager.mapView.setRegion(newRegion, animated: true)
    }

    func zoomOut() {
        print("🔍 지도 축소")
        let currentRegion = mapManager.mapView.region
        let newSpan = MKCoordinateSpan(
            latitudeDelta: currentRegion.span.latitudeDelta * 2.0,
            longitudeDelta: currentRegion.span.longitudeDelta * 2.0
        )
        let newRegion = MKCoordinateRegion(
            center: currentRegion.center,
            span: newSpan
        )
        mapManager.mapView.setRegion(newRegion, animated: true)
    }

    func moveToPlace(_ place: KakaoPlace) {
        print("📍 선택된 장소로 이동: \(place.placeName)")
        let coordinate = place.coordinate
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        mapManager.mapView.setRegion(region, animated: true)

        // 선택된 마커를 강조하기 위해 잠깐 확대했다가 적절한 크기로 조정
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            let finalRegion = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 800,
                longitudinalMeters: 800
            )
            self?.mapManager.mapView.setRegion(finalRegion, animated: true)
        }
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