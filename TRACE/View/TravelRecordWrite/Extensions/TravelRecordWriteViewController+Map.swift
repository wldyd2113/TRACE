//
//  TravelRecordWriteViewController+Map.swift
//  TRACE
//
//  Created by 차지용 on 9/30/25.
//

import UIKit
import MapKit
import CoreLocation

// MARK: - MapManagerDelegate
extension TravelRecordWriteViewController: MapManagerDelegate {
    func mapManagerDidUpdateLocation(_ coordinate: CLLocationCoordinate2D) {
        print(" TravelRecordWrite: Map updated to location: \(coordinate.latitude), \(coordinate.longitude)")
    }

    func mapManagerDidFailToGetLocation() {
        print(" TravelRecordWrite: Failed to get location, using default")
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

        // ViewModel에 검색된 장소들 전달
        searchedPlacesRelay.accept(places)

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

        alert.addAction(UIAlertAction(title: NSLocalizedString("add_to_route", comment: "Add to route"), style: .default) { [weak self] _ in
            self?.addPlaceToRoute(place: place)
        })

        alert.addAction(UIAlertAction(title: NSLocalizedString("close", comment: "Close"), style: .cancel))

        // iPad 대응
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)

        print("📱 장소 정보 표시: \(place.placeName)")
    }

    private func addPlaceToRoute(place: KakaoPlace) {
        // 선택된 장소 업데이트
        selectedPlace = place
        selectedRouteLabel.text = place.placeName
        selectedRouteLabel.textColor = .label
        selectedRouteLabel.isHidden = false
        routeSearchButton.setTitle(place.placeName, for: .normal)
        routeSearchButton.setTitleColor(.label, for: .normal)

        print("➕ 경로에 장소 추가: \(place.placeName)")
    }

    private func showGooglePlaceInfoAlert(place: PlaceResult) {
        let alert = UIAlertController(title: place.name, message: nil, preferredStyle: .actionSheet)

        let infoMessage = """
         주소: \(place.formattedAddress ?? NSLocalizedString("no_info", comment: "No info"))
        🏢 카테고리: \(place.types.first ?? NSLocalizedString("no_info", comment: "No info"))
         구글맵: Google Maps
        📏 좌표: \(place.geometry.location.lat), \(place.geometry.location.lng)
        """

        alert.message = infoMessage

        alert.addAction(UIAlertAction(title: NSLocalizedString("view_google_map", comment: "View google map"), style: .default) { [weak self] _ in
            self?.openInGoogleMaps(place: place)
        })

        alert.addAction(UIAlertAction(title: NSLocalizedString("add_to_route", comment: "Add to route"), style: .default) { [weak self] _ in
            self?.addGooglePlaceToRoute(place: place)
        })

        alert.addAction(UIAlertAction(title: NSLocalizedString("close", comment: "Close"), style: .cancel))

        // iPad 대응
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)

        print("📱 구글 장소 정보 표시: \(place.name)")
    }

    private func addGooglePlaceToRoute(place: PlaceResult) {
        // 구글 장소를 KakaoPlace로 변환
        let kakaoPlace = KakaoPlace(
            id: place.placeId,
            placeName: place.name,
            categoryName: place.types.first ?? "",
            categoryGroupCode: "",
            categoryGroupName: "",
            phone: "",
            addressName: place.formattedAddress ?? "",
            roadAddressName: place.formattedAddress ?? "",
            x: String(place.geometry.location.lng),
            y: String(place.geometry.location.lat),
            placeUrl: "",
            distance: ""
        )

        selectedPlace = kakaoPlace
        selectedRouteLabel.text = place.name
        selectedRouteLabel.textColor = .label
        selectedRouteLabel.isHidden = false
        routeSearchButton.setTitle(place.name, for: .normal)
        routeSearchButton.setTitleColor(.label, for: .normal)

        print("➕ 경로에 구글 장소 추가: \(place.name)")
    }

    private func openInGoogleMaps(place: PlaceResult) {
        let placeName = place.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let lat = place.geometry.location.lat
        let lng = place.geometry.location.lng

        // 구글맵 URL 생성 (place_id 우선, 좌표 대체)
        var googleMapsURL: URL?

        // 1. Place ID로 구글맵 열기 시도
        if let placeIdURL = URL(string: "https://maps.google.com/?q=place_id:\(place.placeId)") {
            googleMapsURL = placeIdURL
        }
        // 2. Place ID가 실패하면 좌표로 시도
        else if let coordURL = URL(string: "https://maps.google.com/?q=\(lat),\(lng)") {
            googleMapsURL = coordURL
        }
        // 3. 좌표도 실패하면 장소명으로 시도
        else if let nameURL = URL(string: "https://maps.google.com/?q=\(placeName)") {
            googleMapsURL = nameURL
        }

        guard let url = googleMapsURL else {
            print(" 구글맵 URL 생성 실패")
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    print(" 구글맵 앱으로 이동 성공: \(place.name)")
                } else {
                    print(" 구글맵 앱 이동 실패")
                }
            }
        } else {
            print(" 구글맵 URL을 열 수 없음: \(url)")
        }
    }
}


// MARK: - Map Helper Methods
extension TravelRecordWriteViewController {
    func setupMapManager() {
        mapManager.delegate = self
        mapManager.requestInitialLocation()
    }

    @objc func clearSearchResults() {
        mapManager.clearAllSearchResults()
        selectedPlace = nil
        selectedRouteLabel.text = NSLocalizedString("select_destination", comment: "Select destination")
        selectedRouteLabel.textColor = .secondaryLabel
        selectedRouteLabel.isHidden = true
        routeSearchButton.setTitle(NSLocalizedString("search_destination", comment: "Search destination"), for: .normal)
        routeSearchButton.setTitleColor(.label, for: .normal)
        currentSearchedPlaces.removeAll()
        currentGooglePlaces.removeAll()
        countryType = "" // 국가 타입도 초기화 (다시 선택할 수 있도록)
        print(" 모든 검색 결과, 선택된 장소 및 국가 타입 삭제")
    }


    private func selectBestMatch(places: [KakaoPlace], query: String) -> KakaoPlace? {
        guard !places.isEmpty else { return nil }

        // 1. 정확히 일치하는 이름 찾기
        if let exactMatch = places.first(where: { $0.placeName == query }) {
            print("🎯 정확한 이름 매칭: \(exactMatch.placeName)")
            return exactMatch
        }

        // 2. 쿼리를 포함하는 가장 짧은 이름 찾기
        let containingQuery = places.filter { $0.placeName.contains(query) }
        if let shortestMatch = containingQuery.min(by: { $0.placeName.count < $1.placeName.count }) {
            print("🎯 가장 짧은 매칭: \(shortestMatch.placeName)")
            return shortestMatch
        }

        // 3. 첫 번째 결과 반환
        let firstResult = places.first!
        print("🎯 첫 번째 결과 선택: \(firstResult.placeName)")
        return firstResult
    }

    func showRouteOnMap(coordinates: [CLLocationCoordinate2D]) {
        mapManager.showRouteOnMap(coordinates: coordinates)
    }

    // 현재 검색된 장소들의 좌표를 가져오는 메서드
    func getCurrentSearchedPlaces() -> [KakaoPlace] {
        return currentSearchedPlaces
    }

    // MARK: - Alert Methods
    private func showNoSearchResultsAlert(query: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(
                title: NSLocalizedString("no_search_results_title", comment: "No search results title"),
                message: String(format: NSLocalizedString("no_search_results_message", comment: "No search results message"), query),
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: NSLocalizedString("confirm", comment: "Confirm"), style: .default))

            self?.present(alert, animated: true)
        }
    }
}
