//
//  TravelChannelViewModel.swift
//  TRACE
//
//  Created by 차지용 on 10/10/25.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift

class TravelChannelViewModel: BaseViewModel {

    private let disposeBag = DisposeBag()

    // MARK: - Input
    struct Input {
        let viewDidLoad: Observable<Void>
        let refreshTriggered: Observable<Void>
    }

    // MARK: - Output
    struct Output {
        let currentTravelRoutes: Driver<[TravelRouteData]>
        let isLoading: Driver<Bool>
        let error: Driver<String>
    }

    // MARK: - Data Models
    struct TravelRouteData {
        let planId: String
        let travelName: String
        let currentDay: Int
        let totalDays: Int
        let routes: [RoutePlace]
        let startDate: Date
        let endDate: Date
        let daysRemaining: Int

        init(from travelPlan: TravelPlan, currentDay: Int) {
            self.planId = travelPlan.id.stringValue
            self.travelName = travelPlan.travelName
            self.currentDay = currentDay

            // startDate와 endDate로부터 총 일수 계산
            let calendar = Calendar.current
            let daysDifference = calendar.dateComponents([.day], from: travelPlan.startDate, to: travelPlan.endDate).day ?? 0
            self.totalDays = daysDifference + 1

            self.startDate = travelPlan.startDate
            self.endDate = travelPlan.endDate

            // 현재 날짜와 여행 시작일의 차이 계산
            let today = Date()
            self.daysRemaining = calendar.dateComponents([.day], from: today, to: travelPlan.startDate).day ?? 0

            // 현재 일차의 경로들 가져오기
            if let dayData = travelPlan.travelDays.first(where: { $0.dayNumber == currentDay }) {
                self.routes = dayData.routeCoordinates.map { coordinate in
                    RoutePlace(
                        id: "\(coordinate.order)",
                        name: coordinate.placeName,
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        address: coordinate.placeName
                    )
                }
            } else {
                self.routes = []
            }
        }
    }

    struct RoutePlace {
        let id: String
        let name: String
        let latitude: Double
        let longitude: Double
        let address: String
    }

    // MARK: - Private Properties
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorRelay = PublishRelay<String>()
    private let travelRoutesRelay = BehaviorRelay<[TravelRouteData]>(value: [])

    // MARK: - BaseViewModel Implementation
    func transform(input: Input) -> Output {

        // 화면 로드 시 여행 경로 가져오기
        input.viewDidLoad
            .subscribe(onNext: { [weak self] in
                self?.loadCurrentTravelRoutes()
            })
            .disposed(by: disposeBag)

        // 새로고침 시 여행 경로 가져오기
        input.refreshTriggered
            .subscribe(onNext: { [weak self] in
                self?.loadCurrentTravelRoutes()
            })
            .disposed(by: disposeBag)

        return Output(
            currentTravelRoutes: travelRoutesRelay.asDriver(),
            isLoading: isLoadingRelay.asDriver(),
            error: errorRelay.asDriver(onErrorJustReturn: "")
        )
    }

    // MARK: - Private Methods
    private func loadCurrentTravelRoutes() {
        isLoadingRelay.accept(true)

        // 안전한 Realm 접근
        guard let realm = RealmManager.shared.safeRealm() else {
            print("❌ Realm 초기화 실패")
            errorRelay.accept("데이터베이스 연결에 실패했습니다.")
            isLoadingRelay.accept(false)
            return
        }

        do {
            let today = Date()
            let calendar = Calendar.current

            print("📅 현재 여행 경로 로드 시작")

            // 모든 여행 계획 가져오기 (안전한 접근)
            let allTravelPlans = Array(realm.objects(TravelPlan.self)
                .sorted(byKeyPath: "startDate", ascending: true))

            var currentRoutes: [TravelRouteData] = []

            for travelPlan in allTravelPlans {
                // Realm 객체가 유효한지 확인
                if !travelPlan.isInvalidated {
                    let routeData = getCurrentDayRouteData(for: travelPlan, today: today, calendar: calendar)
                    if let routeData = routeData {
                        currentRoutes.append(routeData)
                    }
                }
            }

            print("📍 현재 활성 여행 경로: \(currentRoutes.count)개")
            for route in currentRoutes {
                print("   • \(route.travelName) - \(route.currentDay)일차 (\(route.routes.count)개 장소)")
            }

            DispatchQueue.main.async { [weak self] in
                self?.travelRoutesRelay.accept(currentRoutes)
                self?.isLoadingRelay.accept(false)
            }

        } catch {
            print("❌ 여행 경로 로드 실패: \(error.localizedDescription)")
            DispatchQueue.main.async { [weak self] in
                self?.errorRelay.accept("여행 경로를 불러오는데 실패했습니다.")
                self?.isLoadingRelay.accept(false)
            }
        }
    }

    private func getCurrentDayRouteData(for travelPlan: TravelPlan, today: Date, calendar: Calendar) -> TravelRouteData? {
        let startDate = travelPlan.startDate
        let endDate = travelPlan.endDate

        // 여행 시작 전
        if today < startDate {
            // 여행 시작일이 가까운 경우 (7일 이내) 1일차 경로 표시
            let daysUntilTravel = calendar.dateComponents([.day], from: today, to: startDate).day ?? 0
            if daysUntilTravel <= 7 {
                return TravelRouteData(from: travelPlan, currentDay: 1)
            }
            return nil
        }

        // 여행 중
        if today >= startDate && today <= endDate {
            let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: today).day ?? 0
            let currentDay = daysSinceStart + 1

            // 현재 일차가 총 일수를 초과하지 않도록 체크
            let totalDays = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0 + 1
            if currentDay <= totalDays {
                return TravelRouteData(from: travelPlan, currentDay: currentDay)
            }
        }

        // 여행 종료 후에는 표시하지 않음 (다음 여행을 위해)
        return nil
    }

    // MARK: - Public Methods
    func getTravelRouteById(_ planId: String) -> TravelRouteData? {
        return travelRoutesRelay.value.first { $0.planId == planId }
    }

    func refreshData() {
        loadCurrentTravelRoutes()
    }
}