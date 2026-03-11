//
//  TravelChannelViewController+ViewModel.swift
//  TRACE
//
//  Created by 차지용 on 10/10/25.
//

import UIKit
import RxSwift
import RxCocoa
import MapKit

// MARK: - ViewModel Binding
extension TravelChannelViewController {
    func bindViewModel() {
        let viewDidLoadSubject = PublishSubject<Void>()
        let refreshSubject = PublishSubject<Void>()

        let input = TravelChannelViewModel.Input(
            viewDidLoad: viewDidLoadSubject.asObservable(),
            refreshTriggered: refreshSubject.asObservable()
        )

        let output = viewModel.transform(input: input)

        // 여행 경로 데이터 바인딩
        output.currentTravelRoutes
            .drive(onNext: { [weak self] routes in
                self?.updateMapWithRoutes(routes)
                self?.currentTravelRoutes = routes

                // 여행 경로가 있고 아직 추적 중이 아니면 추적 시작
                if !routes.isEmpty && !(self?.isTrackingRoute ?? false) {
                    // 현재 여행 중인 경로가 있는지 확인
                    if let currentRoute = routes.first(where: { self?.isCurrentlyTraveling(route: $0) ?? false }) {
                        print(" 현재 여행 중인 경로 발견: \(currentRoute.travelName) \(currentRoute.currentDay)일차")
                        self?.startRouteTracking()
                    } else {
                        print(" 현재 여행 중인 경로가 없음 - 추적하지 않음")
                    }
                }
            })
            .disposed(by: disposeBag)

        // 로딩 상태 바인딩
        output.isLoading
            .drive(onNext: { [weak self] isLoading in
                self?.updateLoadingState(isLoading)
            })
            .disposed(by: disposeBag)

        // 에러 처리
        output.error
            .drive(onNext: { [weak self] errorMessage in
                self?.showErrorAlert(message: errorMessage)
            })
            .disposed(by: disposeBag)

        // 초기 데이터 로드
        DispatchQueue.main.async {
            viewDidLoadSubject.onNext(())
        }
    }

    private func updateMapWithRoutes(_ routes: [TravelChannelViewModel.TravelRouteData]) {
        print(" 지도에 여행 경로 업데이트: \(routes.count)개")

        // 기존 마커 제거
        mapManager.clearAllSearchResults()

        // 모든 경로의 장소들을 KakaoPlace로 변환하여 지도에 표시
        var allPlaces: [KakaoPlace] = []

        for route in routes {
            let places = route.routes.map { routePlace in
                KakaoPlace(
                    id: routePlace.id,
                    placeName: routePlace.name,
                    categoryName: "",
                    categoryGroupCode: "",
                    categoryGroupName: "",
                    phone: "",
                    addressName: routePlace.address,
                    roadAddressName: routePlace.address,
                    x: String(routePlace.longitude),
                    y: String(routePlace.latitude),
                    placeUrl: "",
                    distance: ""
                )
            }
            allPlaces.append(contentsOf: places)
        }

        if !allPlaces.isEmpty {
            // MapManager의 displaySearchResults 사용하여 루트 그리기 포함
            mapManager.displaySearchResults(places: allPlaces)
        }
    }

    private func updateLoadingState(_ isLoading: Bool) {
        DispatchQueue.main.async { [weak self] in
            if isLoading {
                print(" 데이터 로딩 중...")
                // TODO: 로딩 인디케이터 표시
            } else {
                print(" 데이터 로딩 완료")
                // TODO: 로딩 인디케이터 숨김
            }
        }
    }

    private func showErrorAlert(message: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(
                title: "오류",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            self?.present(alert, animated: true)
        }
    }

    func refreshTravelRoutes() {
        viewModel.refreshData()
    }

    private func isCurrentlyTraveling(route: TravelChannelViewModel.TravelRouteData) -> Bool {
        let today = Date()
        let calendar = Calendar.current

        // 여행 시작일과 종료일 사이에 있는지 확인
        if today >= route.startDate && today <= route.endDate {
            print(" 현재 여행 중: \(route.travelName) (\(route.startDate) ~ \(route.endDate))")
            return true
        }

        print(" 여행 기간이 아님: \(route.travelName) (오늘: \(today), 여행: \(route.startDate) ~ \(route.endDate))")
        return false
    }
}
