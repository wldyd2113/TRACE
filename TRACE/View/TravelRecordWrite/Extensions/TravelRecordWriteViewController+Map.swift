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
        print("📍 TravelRecordWrite: Map updated to location: \(coordinate.latitude), \(coordinate.longitude)")
    }

    func mapManagerDidFailToGetLocation() {
        print("📍 TravelRecordWrite: Failed to get location, using default")
    }

    func mapManagerDidSelectPlace(_ place: KakaoPlace) {
        // 해외 선택 시 구글 장소 정보 alert 표시, 국내는 카카오 alert 표시
        if countryType == "해외" {
            // 구글 검색 결과에서 해당 장소 찾기
            if let googlePlace = currentGooglePlaces.first(where: { $0.name == place.placeName }) {
                print("🌍 구글 장소 정보 표시: \(place.placeName)")
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

        alert.addAction(UIAlertAction(title: "경로에 추가", style: .default) { [weak self] _ in
            self?.addPlaceToRoute(place: place)
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

    private func addPlaceToRoute(place: KakaoPlace) {
        // 기존 검색바 텍스트에 장소 추가
        let currentText = routeSearchBar.text ?? ""
        let newText = currentText.isEmpty ? place.placeName : "\(currentText) -> \(place.placeName)"
        routeSearchBar.text = newText

        print("➕ 경로에 장소 추가: \(place.placeName)")
        print("🗺️ 현재 경로: \(newText)")
    }

    private func showGooglePlaceInfoAlert(place: PlaceResult) {
        let alert = UIAlertController(title: place.name, message: nil, preferredStyle: .actionSheet)

        let infoMessage = """
        📍 주소: \(place.formattedAddress ?? "정보 없음")
        🏢 카테고리: \(place.types.first ?? "정보 없음")
        🌐 구글맵: Google Maps
        📏 좌표: \(place.geometry.location.lat), \(place.geometry.location.lng)
        """

        alert.message = infoMessage

        alert.addAction(UIAlertAction(title: "구글맵에서 보기", style: .default) { [weak self] _ in
            self?.openInGoogleMaps(place: place)
        })

        alert.addAction(UIAlertAction(title: "경로에 추가", style: .default) { [weak self] _ in
            self?.addGooglePlaceToRoute(place: place)
        })

        alert.addAction(UIAlertAction(title: "닫기", style: .cancel))

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
        // 기존 검색바 텍스트에 장소 추가
        let currentText = routeSearchBar.text ?? ""
        let newText = currentText.isEmpty ? place.name : "\(currentText) -> \(place.name)"
        routeSearchBar.text = newText

        print("➕ 경로에 구글 장소 추가: \(place.name)")
        print("🗺️ 현재 경로: \(newText)")
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
            print("❌ 구글맵 URL 생성 실패")
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    print("✅ 구글맵 앱으로 이동 성공: \(place.name)")
                } else {
                    print("❌ 구글맵 앱 이동 실패")
                }
            }
        } else {
            print("❌ 구글맵 URL을 열 수 없음: \(url)")
        }
    }
}

// MARK: - UISearchBarDelegate
extension TravelRecordWriteViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // 이미 국가 타입이 선택되었으면 alert를 표시하지 않음
        if countryType.isEmpty {
            showCountrySelectionAlert()
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()

        // 수동 검색 실행
        guard let query = searchBar.text, !query.isEmpty else { return }
        print("🔍 수동 검색 시작: '\(query)'")
        performManualSearch(query: query)
    }
}

// MARK: - Map Helper Methods
extension TravelRecordWriteViewController {
    func setupMapManager() {
        mapManager.delegate = self
        mapManager.requestInitialLocation()

        // SearchBar delegate 설정
        routeSearchBar.delegate = self
    }

    @objc func clearSearchResults() {
        mapManager.clearAllSearchResults()
        routeSearchBar.text = ""
        currentSearchedPlaces.removeAll()
        currentGooglePlaces.removeAll()
        countryType = "" // 국가 타입도 초기화 (다시 선택할 수 있도록)
        print("🗑️ 모든 검색 결과, 루트 및 국가 타입 삭제")
    }

    // performManualSearch 메서드는 메인 파일에서 구현됨 (국내/해외 API 분기 로직 포함)
    // func performManualSearch(query: String) {
    //     print("🔍 수동 검색 실행: \(query)")
    //
    //     NetworkManger.shared.searchKakaoPlaces(query: query)
    //         .subscribe(onNext: { [weak self] result in
    //             switch result {
    //             case .success(let response):
    //                 print("✅ 검색 성공: \(response.documents.count)개 결과")
    //                 if let bestMatch = self?.selectBestMatch(places: response.documents, query: query) {
    //                     self?.mapManager.displaySearchResults(places: [bestMatch])
    //                     print("🎯 최적 결과 선택: \(bestMatch.placeName)")
    //                 } else {
    //                     print("⚠️ 검색 결과 없음")
    //                     self?.showNoSearchResultsAlert(query: query)
    //                 }
    //             case .failure(let error):
    //                 print("❌ 검색 실패: \(error.localizedDescription)")
    //             }
    //         })
    //         .disposed(by: disposeBag)
    // }

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
                title: "검색 결과 없음",
                message: "'\(query)'에 대한 검색 결과가 없습니다.\n다른 키워드로 검색해보세요.",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "확인", style: .default))

            self?.present(alert, animated: true)
        }
    }
}
