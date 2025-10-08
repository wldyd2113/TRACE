//
//  TravelPlanShowViewController+Map.swift
//  TRACE
//
//  Created by 차지용 on 9/29/25.
//

import UIKit
import MapKit
import CoreLocation
import RxSwift

// MARK: - Map Helper Methods
extension TravelPlanShowViewController {
    func setupMapManager() {
        mapManager.delegate = self
        mapManager.requestInitialLocation()
    }

    // MARK: - Map Search Methods
    @objc func clearSearchResults() {
        mapManager.clearAllSearchResults()
        routeSearchBar.text = ""
        currentSearchedPlaces.removeAll()
        currentGooglePlaces.removeAll()
        print("🗑️ 모든 검색 결과 및 루트 삭제")
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
                        print("🎯 최적 결과 선택: \(bestMatch.placeName)")
                        self?.mapManager.displaySearchResults(places: [bestMatch])
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

        // 3. 주요 카테고리 우선순위
        let priorityCategories = [
            "지하철,전철",
            "교통,수송 > 기차",
            "교통,수송 > 버스",
            "여행 > 관광,명소",
            "음식점"
        ]

        for category in priorityCategories {
            if let priorityMatch = places.first(where: { $0.categoryName.contains(category) }) {
                print("🎯 카테고리 우선순위 매칭: \(priorityMatch.placeName) (\(priorityMatch.categoryName))")
                return priorityMatch
            }
        }

        // 4. 첫 번째 결과 반환
        let firstResult = places.first!
        print("🎯 첫 번째 결과 선택: \(firstResult.placeName)")
        return firstResult
    }
}

// MARK: - MapManagerDelegate
extension TravelPlanShowViewController: MapManagerDelegate {
    func mapManagerDidUpdateLocation(_ coordinate: CLLocationCoordinate2D) {
        print("📍 TravelPlanShow: Map updated to location: \(coordinate.latitude), \(coordinate.longitude)")
    }

    func mapManagerDidFailToGetLocation() {
        print("📍 TravelPlanShow: Failed to get location, using default")
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
        print("📍 TravelPlanShow: Place selected: \(place.placeName)")
    }

    func mapManagerDidUpdateSearchedPlaces(_ places: [KakaoPlace]) {
        print("📍 ===== MapManager에서 검색된 장소들 업데이트 =====")
        print("   • 편집모드: \(isEditMode)")
        print("   • ViewModel 업데이트 중: \(isUpdatingFromViewModel)")
        print("   • 검색 업데이트 중: \(isUpdatingSearchFromMap)")
        print("   • 받은 장소 수: \(places.count)개")

        // 검색된 장소들 업데이트 (편집 모드에서만, 무한 루프 방지)
        if isEditMode && !isUpdatingFromViewModel && !isUpdatingSearchFromMap {
            // 기존 장소와 새 장소가 다를 때만 업데이트
            let currentPlaceNames = currentSearchedPlaces.map { $0.placeName }.sorted()
            let newPlaceNames = places.map { $0.placeName }.sorted()

            if currentPlaceNames != newPlaceNames {
                print("📍 새로운 검색 결과 감지: \(currentPlaceNames) → \(newPlaceNames)")

                // 검색 업데이트 플래그 설정
                isUpdatingSearchFromMap = true

                currentSearchedPlaces = places

                // ViewModel 업데이트 (지연 처리로 무한 루프 방지)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    self?.viewModel.updateSearchedPlaces(places, forDay: self?.currentDay ?? 1)

                    // 플래그 해제는 더 늦게
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self?.isUpdatingSearchFromMap = false
                        print("📍 ViewModel 검색 장소 업데이트 완료")
                    }
                }

                print("📍 검색된 장소들 로컬 업데이트 완료")
            } else {
                print("📍 동일한 검색 결과이므로 업데이트 스킵")
            }
        } else {
            print("📍 검색 업데이트 스킵 (조건 불충족)")
        }

        print("📍 TravelPlanShow: Searched places updated: \(places.count)개")
        for (index, place) in places.enumerated() {
            print("   \(index + 1). \(place.placeName) (\(place.coordinate.latitude), \(place.coordinate.longitude))")
        }
        print("================================================")
    }

    private func showPlaceInfoAlert(place: KakaoPlace) {
        print("📱 ===== 장소 정보 Alert 표시 시작 =====")
        print("   • 장소명: '\(place.placeName)'")
        print("   • 편집모드: \(isEditMode)")

        let alert = UIAlertController(title: place.placeName.isEmpty ? "장소 정보" : place.placeName, message: nil, preferredStyle: .actionSheet)

        let infoMessage = """
        📍 위치: \(String(format: "%.6f, %.6f", place.coordinate.latitude, place.coordinate.longitude))
        📍 주소: \(place.addressName.isEmpty ? "정보 없음" : place.addressName)
        🏢 카테고리: \(place.categoryName.isEmpty ? "정보 없음" : place.categoryName)
        📞 전화번호: \(place.phone.isEmpty ? "정보 없음" : place.phone)
        """

        alert.message = infoMessage

        // 카카오맵에서 좌표로 검색하는 버튼 추가
        alert.addAction(UIAlertAction(title: "카카오맵에서 위치 보기", style: .default) { _ in
            let kakaoMapURL = "kakaomap://look?p=\(place.coordinate.latitude),\(place.coordinate.longitude)"
            let webURL = "https://map.kakao.com/link/map/\(place.placeName),\(place.coordinate.latitude),\(place.coordinate.longitude)"

            if let url = URL(string: kakaoMapURL), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else if let url = URL(string: webURL) {
                UIApplication.shared.open(url)
            }
        })

        // 편집 모드에서만 일정 추가 버튼 표시
        if isEditMode {
            alert.addAction(UIAlertAction(title: "일정에 추가", style: .default) { [weak self] _ in
                self?.addPlaceToSchedule(place: place)
            })
        }

        alert.addAction(UIAlertAction(title: "닫기", style: .cancel))

        // iPad 대응
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)

        print("📱 ===== Alert 표시 완료 =====")
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

        // 편집 모드에서만 일정 추가 버튼 표시
        if isEditMode {
            alert.addAction(UIAlertAction(title: "일정에 추가", style: .default) { [weak self] _ in
                self?.locationTextField.text = place.name
            })
        }

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

    private func addPlaceToSchedule(place: KakaoPlace) {
        // 편집 모드에서만 장소를 일정에 추가
        guard isEditMode else { return }

        locationTextField.text = place.placeName

        print("➕ 일정에 장소 추가: \(place.placeName)")
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

