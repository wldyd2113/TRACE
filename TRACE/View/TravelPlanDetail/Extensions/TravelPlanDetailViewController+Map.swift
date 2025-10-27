//
//  TravelPlanDetailViewController+Map.swift
//  TRACE
//
//  Created by 차지용 on 9/29/25.
//

import UIKit
import MapKit
import CoreLocation


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
        📞 전화번호: \(place.phone.isEmpty ? NSLocalizedString("no_info", comment: "No info") : place.phone)
        🌐 카카오맵: \(place.placeUrl)
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

        alert.addAction(UIAlertAction(title: NSLocalizedString("add_to_schedule", comment: "Add to schedule"), style: .default) { [weak self] _ in
            self?.addPlaceToSchedule(place: place)
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

    private func addPlaceToSchedule(place: KakaoPlace) {
        selectedPlace = place
        selectedLocationLabel.text = place.placeName
        selectedLocationLabel.textColor = .label
        selectedLocationLabel.isHidden = false
        locationSearchButton.setTitle(place.placeName, for: .normal)
        locationSearchButton.setTitleColor(.label, for: .normal)

        print("➕ 일정에 장소 추가: \(place.placeName)")
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
        currentGooglePlaces.removeAll()
        print("🗑️ 모든 검색 결과 삭제")
    }

    @objc func clearCurrentDayData() {
        // 확인 alert 표시
        let alert = UIAlertController(
            title: String(format: NSLocalizedString("day_data_delete", comment: "Day data delete"), currentDay),
            message: NSLocalizedString("day_data_delete_message", comment: "Day data delete message"),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: "Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("delete", comment: "Delete"), style: .destructive) { [weak self] _ in
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
            title: NSLocalizedString("delete_complete", comment: "Delete complete"),
            message: String(format: NSLocalizedString("day_data_deleted", comment: "Day data deleted"), currentDay),
            preferredStyle: .alert
        )
        successAlert.addAction(UIAlertAction(title: NSLocalizedString("confirm", comment: "Confirm"), style: .default))
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

                    // 검색된 장소들을 currentSearchedPlaces에 누적 저장
                    self?.currentSearchedPlaces.append(contentsOf: response.documents)

                    if let bestMatch = self?.selectBestMatch(places: response.documents, query: query) {
                        self?.mapManager.displaySearchResults(places: response.documents)
                        print("🎯 검색 결과 지도에 표시: \(response.documents.count)개 POI")
                    } else {
                        print("⚠️ 검색 결과 없음")
                        self?.showNoSearchResultsAlert(query: query)
                    }
                case .failure(let error):
                    print("❌ 카카오 검색 실패: \(error.localizedDescription)")
                    self?.showErrorAlert(title: "검색 실패", message: "카카오 검색에 실패했습니다: \(error.localizedDescription)")
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

                    // 검색된 장소들을 currentSearchedPlaces에 누적 저장
                    self?.currentSearchedPlaces.append(contentsOf: kakaoPlaces)

                    if !kakaoPlaces.isEmpty {
                        self?.mapManager.displaySearchResults(places: kakaoPlaces)
                        print("🎯 검색 결과 지도에 표시: \(kakaoPlaces.count)개 POI")
                    } else {
                        print("⚠️ 검색 결과 없음")
                        self?.showNoSearchResultsAlert(query: query)
                    }
                case .failure(let error):
                    print("❌ 구글 검색 실패: \(error.localizedDescription)")
                    self?.showErrorAlert(title: "검색 실패", message: "구글 검색에 실패했습니다: \(error.localizedDescription)")
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
        📍 주소: \(place.formattedAddress ?? NSLocalizedString("no_info", comment: "No info"))
        🏢 카테고리: \(place.types.first ?? NSLocalizedString("no_info", comment: "No info"))
        🌐 구글맵: Google Maps
        📏 좌표: \(place.geometry.location.lat), \(place.geometry.location.lng)
        """

        alert.message = infoMessage

        alert.addAction(UIAlertAction(title: NSLocalizedString("view_google_map", comment: "View google map"), style: .default) { [weak self] _ in
            self?.openInGoogleMaps(place: place)
        })

        alert.addAction(UIAlertAction(title: NSLocalizedString("add_to_schedule", comment: "Add to schedule"), style: .default) { [weak self] _ in
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

            self?.selectedPlace = kakaoPlace
            self?.selectedLocationLabel.text = place.name
            self?.selectedLocationLabel.textColor = .label
            self?.selectedLocationLabel.isHidden = false
            self?.locationSearchButton.setTitle(place.name, for: .normal)
            self?.locationSearchButton.setTitleColor(.label, for: .normal)
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
                title: NSLocalizedString("no_search_results_title", comment: "No search results title"),
                message: String(format: NSLocalizedString("no_search_results_message", comment: "No search results message"), query),
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: NSLocalizedString("confirm", comment: "Confirm"), style: .default))

            self?.present(alert, animated: true)
        }
    }

    private func showErrorAlert(title: String, message: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: NSLocalizedString("confirm", comment: "Confirm"), style: .default))

            self?.present(alert, animated: true)
        }
    }
}

// MARK: - MapSearch Delegate Protocol
protocol MapSearchDelegate: AnyObject {
    func didSelectRoute(_ route: String, coordinates: [CLLocationCoordinate2D])
}
