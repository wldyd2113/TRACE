//
//  CalendarViewModel.swift
//  TRACE
//
//  Created by 차지용 on 10/21/25.
//

import Foundation
import RealmSwift
import RxSwift
import RxCocoa


final class CalendarViewModel {

    // MARK: - Properties
    private let disposeBag = DisposeBag()

    // MARK: - Outputs
    let travelPlans = BehaviorRelay<[TravelPlan]>(value: [])
    let travelDates = BehaviorRelay<Set<String>>(value: [])
    let travelCalendarData = BehaviorRelay<[String: TravelCalendarData]>(value: [:])
    let selectedDateInfo = BehaviorRelay<TravelPlan?>(value: nil)
    let isLoading = BehaviorRelay<Bool>(value: false)
    let errorMessage = BehaviorRelay<String?>(value: nil)

    // MARK: - Private Properties
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    // MARK: - Initialization
    init() {
        setupBindings()
    }

    // MARK: - Public Methods
    func loadTravelPlans() {
        isLoading.accept(true)
        errorMessage.accept(nil)

        guard let realm = RealmManager.shared.getRealm() else {
            handleError("Realm 연결에 실패했습니다")
            return
        }

        do {
            let allPlans = realm.objects(TravelPlan.self)
            let plansArray = Array(allPlans)

            travelPlans.accept(plansArray)
            processTravelDates(from: plansArray)

            isLoading.accept(false)

            print("📊 [CalendarViewModel] 여행 계획 로드 완료: \(plansArray.count)개")

        } catch {
            handleError("여행 계획 로드 중 오류 발생: \(error.localizedDescription)")
        }
    }

    func selectDate(_ date: Date) {
        let dateString = dateFormatter.string(from: date)

        // 해당 날짜에 해당하는 여행 계획 찾기
        let travelPlan = travelPlans.value.first { plan in
            return date >= plan.startDate && date <= plan.endDate
        }

        selectedDateInfo.accept(travelPlan)

        if let plan = travelPlan {
            print("📅 [CalendarViewModel] 선택된 날짜 \(dateString)의 여행: \(plan.travelName)")
        } else {
            print("📅 [CalendarViewModel] 선택된 날짜 \(dateString)에 여행 계획 없음")
        }
    }

    func hasTravelPlan(for date: Date) -> Bool {
        let dateString = dateFormatter.string(from: date)
        return travelDates.value.contains(dateString)
    }

    func getTravelInfo(for date: Date) -> TravelCalendarData? {
        let dateString = dateFormatter.string(from: date)
        return travelCalendarData.value[dateString]
    }

    // MARK: - Private Methods
    private func setupBindings() {
        // 여행 계획이 업데이트될 때마다 날짜 데이터 처리
        travelPlans
            .subscribe(onNext: { [weak self] plans in
                self?.processTravelDates(from: plans)
            })
            .disposed(by: disposeBag)
    }

    private func processTravelDates(from plans: [TravelPlan]) {
        var travelDatesSet: Set<String> = []
        var calendarDataDict: [String: TravelCalendarData] = [:]

        for plan in plans {
            var currentDate = plan.startDate

            while currentDate <= plan.endDate {
                let dateString = dateFormatter.string(from: currentDate)
                travelDatesSet.insert(dateString)

                let calendarData = TravelCalendarData(
                    date: currentDate,
                    travelName: plan.travelName,
                    nation: plan.nation,
                    isStartDate: Calendar.current.isDate(currentDate, inSameDayAs: plan.startDate),
                    isEndDate: Calendar.current.isDate(currentDate, inSameDayAs: plan.endDate)
                )

                calendarDataDict[dateString] = calendarData

                // 다음 날로 이동
                currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
        }

        travelDates.accept(travelDatesSet)
        travelCalendarData.accept(calendarDataDict)

        print("🎯 [CalendarViewModel] 처리된 여행 날짜: \(travelDatesSet.count)개")
        print("🎯 [CalendarViewModel] 여행 날짜들: \(Array(travelDatesSet).sorted())")
    }

    private func handleError(_ message: String) {
        isLoading.accept(false)
        errorMessage.accept(message)
        print("❌ [CalendarViewModel] 오류: \(message)")
    }
}
