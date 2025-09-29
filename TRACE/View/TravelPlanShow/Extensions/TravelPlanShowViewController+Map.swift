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
        print("🔍 수동 검색 실행: \(query)")

        NetworkManger.shared.searchKakaoPlaces(query: query)
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .success(let response):
                    print("✅ 검색 성공: \(response.documents.count)개 결과")
                    if let bestMatch = self?.selectBestMatch(places: response.documents, query: query) {
                        self?.mapManager.displaySearchResults(places: [bestMatch])
                        print("🎯 최적 결과 선택: \(bestMatch.placeName)")
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

// MARK: - MapMangerDelegate
extension TravelPlanShowViewController: MapMangerDelegate {
    func mapManagerDidUpdateLocation(_ coordinate: CLLocationCoordinate2D) {
        print("📍 TravelPlanShow: Map updated to location: \(coordinate.latitude), \(coordinate.longitude)")
    }

    func mapManagerDidFailToGetLocation() {
        print("📍 TravelPlanShow: Failed to get location, using default")
    }

    func mapManagerDidSelectPlace(_ place: KakaoPlace) {
        // 편집 모드에서만 장소 정보 표시
        if isEditMode {
            showPlaceInfoAlert(place: place)
        }
        print("📍 TravelPlanShow: Place selected: \(place.placeName)")
    }

    func mapManagerDidUpdateSearchedPlaces(_ places: [KakaoPlace]) {
        // 검색된 장소들 업데이트 (편집 모드에서만)
        if isEditMode {
            currentSearchedPlaces = places
            // 즉시 ViewModel 업데이트 (무한 루프 방지를 위해 저장 시점에 처리)
            viewModel.updateSearchedPlaces(places, forDay: currentDay)
        }

        print("📍 TravelPlanShow: Searched places updated: \(places.count)개")
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
        // 편집 모드에서만 장소를 일정에 추가
        guard isEditMode else { return }

        locationTextField.text = place.placeName

        print("➕ 일정에 장소 추가: \(place.placeName)")
    }
}