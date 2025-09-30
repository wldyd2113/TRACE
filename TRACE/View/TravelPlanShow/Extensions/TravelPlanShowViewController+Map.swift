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
        print("🗑️ 모든 검색 결과 및 루트 삭제")
    }

    func performManualSearch(query: String) {
        print("🔍 ===== 수동 검색 실행 =====")
        print("   • 검색어: '\(query)'")
        print("   • 현재 지도의 장소 수: \(mapManager.searchedPlaces.count)개")

        NetworkManger.shared.searchKakaoPlaces(query: query)
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .success(let response):
                    print("✅ 검색 성공: \(response.documents.count)개 결과")
                    if let bestMatch = self?.selectBestMatch(places: response.documents, query: query) {
                        print("🎯 최적 결과 선택: \(bestMatch.placeName)")
                        print("📍 기존 장소에 누적 추가 시작...")
                        self?.mapManager.displaySearchResults(places: [bestMatch])
                    } else {
                        print("⚠️ 검색 결과 없음")
                    }
                case .failure(let error):
                    print("❌ 검색 실패: \(error.localizedDescription)")
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
        // 읽기 모드와 편집 모드 모두에서 장소 정보 표시
        showPlaceInfoAlert(place: place)
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

    private func addPlaceToSchedule(place: KakaoPlace) {
        // 편집 모드에서만 장소를 일정에 추가
        guard isEditMode else { return }

        locationTextField.text = place.placeName

        print("➕ 일정에 장소 추가: \(place.placeName)")
    }
}

