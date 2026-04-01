//
//  TravelShowRecordViewController+Map.swift
//  TRACE
//
//  Created by 차지용 on 9/30/25.
//

import UIKit
import MapKit
import CoreLocation
import RxSwift

// MARK: - MapManagerDelegate
extension TravelShowRecordViewController: MapManagerDelegate {
    func mapManagerDidUpdateLocation(_ coordinate: CLLocationCoordinate2D) {
        print(" TravelShowRecord: Map updated to location: \(coordinate.latitude), \(coordinate.longitude)")
    }

    func mapManagerDidFailToGetLocation() {
        print(" TravelShowRecord: Failed to get location, using default")
    }

    func mapManagerDidSelectPlace(_ place: KakaoPlace) {
        // 해외 선택 시 구글 장소 정보 alert 표시, 국내는 카카오 alert 표시
        if countryType == "해외" {
            // 구글 검색 결과에서 해당 장소 찾기
            if let googlePlace = currentGooglePlaces.first(where: { $0.name == place.placeName }) {
                print(" 구글 장소 정보 표시: \(place.placeName)")
                showGooglePlaceInfoAlert(place: googlePlace)
            } else {
                // 구글 장소를 찾을 수 없는 경우 기본 alert 표시
                showPlaceInfoAlert(place: place)
            }
        } else {
            // 국내인 경우 기존 카카오 alert 표시
            showPlaceInfoAlert(place: place)
        }
    }

    func mapManagerDidUpdateSearchedPlaces(_ places: [KakaoPlace]) {
        // currentSearchedPlaces 업데이트
        currentSearchedPlaces = places

        print(" 검색된 장소들 업데이트: \(places.count)개")
        for (index, place) in places.enumerated() {
            print("   \(index + 1). \(place.placeName) (\(place.coordinate.latitude), \(place.coordinate.longitude))")
        }
    }

    private func showPlaceInfoAlert(place: KakaoPlace) {
        let alert = UIAlertController(title: place.placeName, message: nil, preferredStyle: .actionSheet)

        let infoMessage = """
         주소: \(place.addressName)
        🏢 카테고리: \(place.categoryName)
        📞 전화번호: \(place.phone.isEmpty ? NSLocalizedString("no_info", comment: "No info") : place.phone)
         카카오맵: \(place.placeUrl)
        📏 거리: \(place.distance)m
        """

        alert.message = infoMessage

        // countryType에 따라 다른 맵 연결
        if countryType == "해외" {
            // 해외인 경우 구글맵 연결
            alert.addAction(UIAlertAction(title: NSLocalizedString("view_google_map", comment: "View google map"), style: .default) { _ in
                let lat = place.coordinate.latitude
                let lng = place.coordinate.longitude
                let placeName = place.placeName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

                if let url = URL(string: "https://maps.google.com/?q=\(lat),\(lng)") {
                    UIApplication.shared.open(url)
                } else if let url = URL(string: "https://maps.google.com/?q=\(placeName)") {
                    UIApplication.shared.open(url)
                }
            })
        } else {
            // 국내인 경우 카카오맵 연결
            alert.addAction(UIAlertAction(title: NSLocalizedString("view_kakao_map", comment: "View kakao map"), style: .default) { _ in
                if let url = URL(string: place.placeUrl) {
                    UIApplication.shared.open(url)
                }
            })
        }

        alert.addAction(UIAlertAction(title: NSLocalizedString("close", comment: "Close"), style: .cancel))

        // iPad 대응
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)

        print(" 장소 정보 표시: \(place.placeName)")
    }

    private func showGooglePlaceInfoAlert(place: PlaceResult) {
        let alert = UIAlertController(title: place.name, message: nil, preferredStyle: .actionSheet)

        let infoMessage = """
         주소: \(place.formattedAddress ?? NSLocalizedString("no_info", comment: "No info"))
         종류: \(place.types.first ?? NSLocalizedString("no_info", comment: "No info"))
        🆔 장소 ID: \(place.placeId)
        """

        alert.message = infoMessage

        alert.addAction(UIAlertAction(title: NSLocalizedString("view_google_map", comment: "View google map"), style: .default) { _ in
            let coordinate = place.geometry.location.coordinate
            if let url = URL(string: "https://www.google.com/maps/search/?api=1&query=\(coordinate.latitude),\(coordinate.longitude)") {
                UIApplication.shared.open(url)
            }
        })

        alert.addAction(UIAlertAction(title: NSLocalizedString("close", comment: "Close"), style: .cancel))

        // iPad 대응
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)

        print(" 구글 장소 정보 표시: \(place.name)")
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
        selectedPlace = nil
        selectedRouteLabel.text = NSLocalizedString("edit_mode_add_destination", comment: "Edit mode add destination")
        selectedRouteLabel.textColor = .secondaryLabel
        routeSearchButton.setTitle(NSLocalizedString("search_destination", comment: "Search destination"), for: .normal)
        routeSearchButton.setTitleColor(.label, for: .normal)
        currentSearchedPlaces.removeAll()
        currentGooglePlaces.removeAll()
        print(" 모든 검색 결과, 선택된 장소 삭제")
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
            print(" 여행 기록 장소들 지도에 표시: \(currentSearchedPlaces.count)개")
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


