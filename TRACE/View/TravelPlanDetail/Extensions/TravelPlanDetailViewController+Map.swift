//
//  TravelPlanDetailViewController+Map.swift
//  TRACE
//
//  Created by 차지용 on 9/29/25.
//

import UIKit
import MapKit
import CoreLocation

// MARK: - MapSearchDelegate
extension TravelPlanDetailViewController: MapSearchDelegate {
    func didSelectRoute(_ route: String, coordinates: [CLLocationCoordinate2D]) {
        routeSearchBar.text = route
        showRouteOnMap(coordinates: coordinates)
    }

    private func showRouteOnMap(coordinates: [CLLocationCoordinate2D]) {
        mapManager.showRouteOnMap(coordinates: coordinates)
    }
}

// MARK: - MapManagerDelegate
extension TravelPlanDetailViewController: MapManagerDelegate {
    func mapManagerDidUpdateLocation(_ coordinate: CLLocationCoordinate2D) {
        print("📍 TravelPlanDetail: Map updated to location: \(coordinate.latitude), \(coordinate.longitude)")
    }

    func mapManagerDidFailToGetLocation() {
        print("📍 TravelPlanDetail: Failed to get location, using default")
    }

    func mapManagerDidSelectPlace(_ place: KakaoPlace) {
        // 해외 선택 시 구글 장소 정보 alert 표시, 국내는 카카오 alert 표시
        if countryType == "해외" {
            // 구글 검색 결과에서 해당 장소 찾기
            if let googlePlace = currentGooglePlaces.first(where: { $0.name == place.placeName }) {
                print("🌍 구글 장소 정보 표시: \(place.placeName)")
                showGooglePlaceInfo(place: googlePlace)
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
        // currentSearchedPlaces만 업데이트하고 ViewModel 업데이트는 나중에
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

        alert.addAction(UIAlertAction(title: "일정에 추가", style: .default) { [weak self] _ in
            self?.addPlaceToSchedule(place: place)
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

    private func addPlaceToSchedule(place: KakaoPlace) {
        locationTextField.text = place.placeName

        print("➕ 일정에 장소 추가: \(place.placeName)")
    }
}

// MARK: - UISearchBarDelegate (수동 검색을 위해 활성화)
extension TravelPlanDetailViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()

        // 수동 검색 실행
        guard let query = searchBar.text, !query.isEmpty else { return }
        print("🔍 수동 검색 시작: '\(query)'")
        performManualSearch(query: query)
    }
}

// MARK: - Map Helper Methods
extension TravelPlanDetailViewController {
    func setupMapManager() {
        mapManager.delegate = self
        mapManager.requestInitialLocation()
    }

    @objc func clearSearchResults() {
        mapManager.clearAllSearchResults()
        routeSearchBar.text = ""
        currentGooglePlaces.removeAll()
        print("🗑️ 모든 검색 결과 및 루트 삭제")
    }

    @objc func clearCurrentDayData() {
        // 확인 alert 표시
        let alert = UIAlertController(
            title: "Day \(currentDay) 데이터 삭제",
            message: "해당 일차의 모든 데이터(예산, 일정, 경로)를 삭제하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.performClearCurrentDayData()
        })

        present(alert, animated: true)
    }

    private func performClearCurrentDayData() {
        print("🗑️ ===== Day \(currentDay) 전체 데이터 삭제 시작 =====")

        // ViewModel을 통해 해당 일차 데이터 초기화
        viewModel.clearDayData(for: currentDay)

        // UI 초기화
        budgetTextField.text = ""
        routeSearchBar.text = ""

        // 일정 목록 UI 초기화 (스케줄 스택뷰 초기화)
        scheduleStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 지도 검색 결과 초기화
        mapManager.clearAllSearchResults()

        // 검색된 장소들 초기화
        currentSearchedPlaces.removeAll()
        currentGooglePlaces.removeAll()

        print("✅ Day \(currentDay) 전체 데이터 삭제 완료")

        // 성공 메시지 표시
        let successAlert = UIAlertController(
            title: "삭제 완료",
            message: "Day \(currentDay)의 모든 데이터가 삭제되었습니다.",
            preferredStyle: .alert
        )
        successAlert.addAction(UIAlertAction(title: "확인", style: .default))
        present(successAlert, animated: true)
    }

    func performManualSearch(query: String) {
        print("🔍 수동 검색 실행: \(query)")
        print("🔍 현재 countryType: \(countryType)")

        if countryType == "국내" {
            print("🇰🇷 [수동검색] 카카오 API 사용")
            performKakaoSearch(query: query)
        } else {
            print("🌍 [수동검색] 구글 API 사용")
            performGoogleSearch(query: query)
        }
    }

    private func performKakaoSearch(query: String) {
        NetworkManger.shared.searchKakaoPlaces(query: query)
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .success(let response):
                    print("✅ 카카오 검색 성공: \(response.documents.count)개 결과")
                    // 카카오 검색 시 구글 장소 정보 초기화
                    self?.currentGooglePlaces.removeAll()
                    if let bestMatch = self?.selectBestMatch(places: response.documents, query: query) {
                        self?.mapManager.displaySearchResults(places: [bestMatch])
                        print("🎯 최적 결과 선택: \(bestMatch.placeName)")
                    } else {
                        print("⚠️ 검색 결과 없음")
                        self?.showNoSearchResultsAlert(query: query)
                    }
                case .failure(let error):
                    print("❌ 카카오 검색 실패: \(error.localizedDescription)")
                }
            })
            .disposed(by: disposeBag)
    }

    private func performGoogleSearch(query: String) {
        NetworkManger.shared.searchGooglePlaces(query: query)
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .success(let response):
                    print("✅ 구글 검색 성공: \(response.results.count)개 결과")

                    // 원본 구글 장소 정보 저장 (마커 클릭 시 사용)
                    self?.currentGooglePlaces = response.results

                    // GooglePlace를 KakaoPlace로 변환
                    let kakaoPlaces = response.results.map { place in
                        KakaoPlace(
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
                    }

                    if let bestMatch = response.results.first {
                        // 맵에 표시용으로는 변환된 KakaoPlace 사용
                        let kakaoPlace = KakaoPlace(
                            id: bestMatch.placeId,
                            placeName: bestMatch.name,
                            categoryName: bestMatch.types.first ?? "",
                            categoryGroupCode: "",
                            categoryGroupName: "",
                            phone: "",
                            addressName: bestMatch.formattedAddress ?? "",
                            roadAddressName: bestMatch.formattedAddress ?? "",
                            x: String(bestMatch.geometry.location.lng),
                            y: String(bestMatch.geometry.location.lat),
                            placeUrl: "",
                            distance: ""
                        )
                        self?.mapManager.displaySearchResults(places: [kakaoPlace])
                    } else {
                        print("⚠️ 검색 결과 없음")
                        self?.showNoSearchResultsAlert(query: query)
                    }
                case .failure(let error):
                    print("❌ 구글 검색 실패: \(error.localizedDescription)")
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Google Maps Integration
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

    // MARK: - Google Place Info Display
    private func showGooglePlaceInfo(place: PlaceResult) {
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

        alert.addAction(UIAlertAction(title: "일정에 추가", style: .default) { [weak self] _ in
            self?.locationTextField.text = place.name
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

// MARK: - MapSearch Delegate Protocol
protocol MapSearchDelegate: AnyObject {
    func didSelectRoute(_ route: String, coordinates: [CLLocationCoordinate2D])
}