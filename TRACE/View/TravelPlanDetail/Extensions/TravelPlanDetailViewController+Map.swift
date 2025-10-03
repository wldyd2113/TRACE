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
        showPlaceInfoAlert(place: place)
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
                        self?.showNoSearchResultsAlert(query: query)
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