//
//  TravelShowRecordViewController+Map.swift
//  TRACE
//
//  Created by 차지용 on 9/30/25.
//

import UIKit
import MapKit
import CoreLocation

// MARK: - MapManagerDelegate
extension TravelShowRecordViewController: MapManagerDelegate {
    func mapManagerDidUpdateLocation(_ coordinate: CLLocationCoordinate2D) {
        print("📍 TravelShowRecord: Map updated to location: \(coordinate.latitude), \(coordinate.longitude)")
    }

    func mapManagerDidFailToGetLocation() {
        print("📍 TravelShowRecord: Failed to get location, using default")
    }

    func mapManagerDidSelectPlace(_ place: KakaoPlace) {
        showPlaceInfoAlert(place: place)
    }

    func mapManagerDidUpdateSearchedPlaces(_ places: [KakaoPlace]) {
        // currentSearchedPlaces 업데이트
        currentSearchedPlaces = places

        print("📍 검색된 장소들 업데이트: \(places.count)개")
        for (index, place) in places.enumerated() {
            print("   \(index + 1). \(place.placeName) (\(place.coordinate.latitude), \(place.coordinate.longitude))")
        }
    }

    private func showPlaceInfoAlert(place: KakaoPlace) {
        let alert = UIAlertController(title: place.placeName, message: nil, preferredStyle: .actionSheet)

        let infoMessage = """
        📍 주소: \(place.addressName)
        🏢 카테고리: \(place.categoryName)
        📞 전화번호: \(place.phone.isEmpty ? "정보 없음" : place.phone)
        🌐 카카오맵: \(place.placeUrl)
        📏 거리: \(place.distance)m
        """

        alert.message = infoMessage

        alert.addAction(UIAlertAction(title: "카카오맵에서 보기", style: .default) { _ in
            if let url = URL(string: place.placeUrl) {
                UIApplication.shared.open(url)
            }
        })

        alert.addAction(UIAlertAction(title: "닫기", style: .cancel))

        // iPad 대응
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)

        print("📱 장소 정보 표시: \(place.placeName)")
    }
}

// MARK: - Map Helper Methods
extension TravelShowRecordViewController {
    func setupMapManager() {
        mapManager.delegate = self
        mapManager.requestInitialLocation()
    }

    @objc func clearSearchResults() {
        mapManager.clearAllSearchResults()
        currentSearchedPlaces.removeAll()
        print("🗑️ 모든 검색 결과 및 루트 삭제")
    }

    func showRouteOnMap(coordinates: [CLLocationCoordinate2D]) {
        mapManager.showRouteOnMap(coordinates: coordinates)
    }

    // 현재 검색된 장소들의 좌표를 가져오는 메서드
    func getCurrentSearchedPlaces() -> [KakaoPlace] {
        return currentSearchedPlaces
    }

    // 여행 기록에 저장된 장소들을 지도에 표시
    func displayRecordPlaces() {
        if !currentSearchedPlaces.isEmpty {
            mapManager.displaySearchResults(places: currentSearchedPlaces)
            print("📍 여행 기록 장소들 지도에 표시: \(currentSearchedPlaces.count)개")
        }
    }

    // 지도를 전체화면으로 보기
    func showFullScreenMap() {
        print("🗺️ 전체화면 지도 보기")
        // TODO: 전체화면 지도 뷰컨트롤러 구현

        // 임시로 지도 중심 이동
        if let firstPlace = currentSearchedPlaces.first {
            let region = MKCoordinateRegion(
                center: firstPlace.coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            mapManager.mapView.setRegion(region, animated: true)
        }
    }
}

// MARK: - Map Interaction Methods
extension TravelShowRecordViewController {
    func handleRouteButtonTapped() {
        // 경로보러가기 버튼 클릭 시 지도 관련 동작
        if !currentSearchedPlaces.isEmpty {
            showFullScreenMap()
        } else {
            let alert = UIAlertController(
                title: "경로 정보 없음",
                message: "표시할 여행 경로가 없습니다.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
        }
    }
}