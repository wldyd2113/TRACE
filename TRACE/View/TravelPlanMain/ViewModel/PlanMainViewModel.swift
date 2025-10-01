//
//  PlanMainViewModel.swift
//  TRACE
//
//  Created by 차지용 on 9/29/25.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift

class PlanMainViewModel: BaseViewModel {

    private let disposeBag = DisposeBag()

    // MARK: - Input
    struct Input {
        let viewDidLoad: Observable<Void>
        let refreshData: Observable<Void>
        let recordButtonTapped: Observable<Void>
    }

    // MARK: - Output
    struct Output {
        let mainTravelData: Observable<MainTravelData?>
        let travelList: Observable<[TravelPlanData]>
        let navigateToDetail: Observable<Void>
        let error: Observable<String>
    }

    // MARK: - Data Models
    struct MainTravelData {
        let country: String
        let nation: String
        let date: String
        let dDay: String
//        let imageUrl: String?

        init(from travelPlan: TravelPlan) {
            self.country = travelPlan.travelName
            self.nation = travelPlan.nation
            self.date = DateManager.shared.formatToStandardString(from: travelPlan.startDate)
            self.dDay = DateManager.shared.daysUntilTravel(travelPlan.startDate)
//            self.imageUrl = travelPlan.imageUrl
        }
    }



    // MARK: - Private Properties
    private let mainTravelData = BehaviorRelay<MainTravelData?>(value: nil)
    private let travelList = BehaviorRelay<[TravelPlanData]>(value: [])
    private let errorRelay = PublishRelay<String>()

    // MARK: - BaseViewModel Implementation
    func transform(input: Input) -> Output {

        // 뷰 로드 및 데이터 새로고침 시 데이터 로드
        Observable.merge(input.viewDidLoad, input.refreshData)
            .subscribe(onNext: { [weak self] in
                self?.loadTravelData()
            })
            .disposed(by: disposeBag)

        return Output(
            mainTravelData: mainTravelData.asObservable(),
            travelList: travelList.asObservable(),
            navigateToDetail: input.recordButtonTapped,
            error: errorRelay.asObservable()
        )
    }

    // MARK: - Private Methods
    private func loadTravelData() {
        print("📊 여행 계획 데이터 로드 시작")

        guard let realm = RealmManager.shared.getRealm() else {
            print("❌ Realm 인스턴스를 가져올 수 없습니다")
            errorRelay.accept("데이터베이스 연결에 실패했습니다")
            return
        }

        do {
            let allPlans = realm.objects(TravelPlan.self).sorted(byKeyPath: "startDate", ascending: true)

            print("📋 Realm에서 찾은 여행 계획: \(allPlans.count)개")

            // 현재 날짜 기준으로 지나지 않은 여행 계획만 필터링
            let today = DateManager.shared.today()
            let upcomingPlans = allPlans.filter { $0.startDate >= today }

            print("📅 오늘 날짜: \(DateManager.shared.formatToStandardString(from: today))")
            print("✈️ 다가오는 여행 계획: \(upcomingPlans.count)개")

            // 가장 가까운 미래 여행 계획을 메인으로 표시
            if let nextPlan = upcomingPlans.first {
                let mainData = MainTravelData(from: nextPlan)
                mainTravelData.accept(mainData)

                print("🏆 메인 여행 계획: \(mainData.country) (\(mainData.dDay))")
            } else {
                print("⚠️ 다가오는 여행 계획이 없습니다")
                mainTravelData.accept(nil)
            }

            // 여행 계획 리스트는 모든 계획 표시 (과거+미래)
            let allTravelPlans = Array(allPlans).map { TravelPlanData(from: $0) }
            travelList.accept(allTravelPlans)

            print("📋 로드된 여행 계획 리스트: \(allTravelPlans.count)개")
            for plan in allTravelPlans {
                print("   • \(plan.location) (\(plan.country)) - \(plan.date)")
            }

            // 지난 여행 계획이 있다면 로그로 표시
            let pastPlans = allPlans.filter { $0.startDate < today }
            if !pastPlans.isEmpty {
                print("📜 지난 여행 계획 (숨김 처리): \(pastPlans.count)개")
                for pastPlan in pastPlans {
                    let pastData = TravelPlanData(from: pastPlan)
                    print("   🗓️ \(pastData.location) (\(pastData.country)) - \(pastData.date) [지남]")
                }
            }

        } catch {
            print("❌ Realm 데이터 로드 실패: \(error.localizedDescription)")
            errorRelay.accept("여행 계획을 불러오는데 실패했습니다.")
        }
    }

    // MARK: - Public Methods
    func refreshData() {
        loadTravelData()
    }
}
