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
        print("📍 지도에 여행 경로 업데이트: \(routes.count)개")

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
            mapManager.displaySearchResults(places: allPlaces)
            // 첫 번째 장소로 지도 중심 이동
            if let firstPlace = allPlaces.first {
                let region = MKCoordinateRegion(
                    center: firstPlace.coordinate,
                    latitudinalMeters: 2000,
                    longitudinalMeters: 2000
                )
                mapManager.mapView.setRegion(region, animated: true)
            }
        }
    }

    private func updateLoadingState(_ isLoading: Bool) {
        DispatchQueue.main.async { [weak self] in
            if isLoading {
                print("🔄 데이터 로딩 중...")
                // TODO: 로딩 인디케이터 표시
            } else {
                print("✅ 데이터 로딩 완료")
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
}
