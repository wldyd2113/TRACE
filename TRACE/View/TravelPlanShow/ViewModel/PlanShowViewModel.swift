//
//  PlanShowViewModel.swift
//  TRACE
//
//  Created by 차지용 on 9/29/25.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift
import CoreLocation

class PlanShowViewModel: BaseViewModel {

    private let disposeBag = DisposeBag()

    // MARK: - Input
    struct Input {
        let loadPlan: Observable<String>
        let daySelected: Observable<Int>
        let budgetChanged: Observable<String>
        let routeChanged: Observable<String>
        let addSchedule: Observable<(time: String, location: String)>
        let saveChanges: Observable<Void>
        let timeText: Observable<String>
        let locationText: Observable<String>
    }

    // MARK: - Output
    struct Output {
        let travelPlanData: Observable<TravelPlanData>
        let currentDayData: Observable<DayData>
        let scheduleItems: Observable<[ScheduleItem]>
        let saveResult: Observable<(success: Bool, message: String)>
        let error: Observable<String>
        let isAddScheduleEnabled: Observable<Bool>
        let isAddScheduleButtonEnabled: Observable<Bool>
    }

    // MARK: - Data Models
    struct TravelPlanData {
        let id: String
        let travelName: String
        let nation: String
        let startDate: Date
        let endDate: Date
        let totalDays: Int

        init(from travelPlan: TravelPlan) {
            self.id = travelPlan.id.stringValue
            self.travelName = travelPlan.travelName
            self.nation = travelPlan.nation
            self.startDate = travelPlan.startDate
            self.endDate = travelPlan.endDate

            let calendar = Calendar.current
            let daysDifference = calendar.dateComponents([.day], from: travelPlan.startDate, to: travelPlan.endDate).day ?? 0
            self.totalDays = max(1, daysDifference + 1)
        }
    }

    struct DayData {
        var budget: String = ""
        var route: String = ""
        var scheduleItems: [ScheduleItem] = []
        var searchedPlaces: [KakaoPlace] = []

        static let empty = DayData()
    }

    // MARK: - Private Properties
    private let travelPlanData = BehaviorRelay<TravelPlanData?>(value: nil)
    private let currentDay = BehaviorRelay<Int>(value: 1)
    private let dayDataStorage = BehaviorRelay<[Int: DayData]>(value: [:])
    private let saveResult = PublishSubject<(success: Bool, message: String)>()
    private let errorRelay = PublishRelay<String>()

    private var currentTravelPlan: TravelPlan?
    private var saveWorkItem: DispatchWorkItem?

    // MARK: - BaseViewModel Implementation
    func transform(input: Input) -> Output {

        // 여행 계획 로드
        input.loadPlan
            .subscribe(onNext: { [weak self] planId in
                self?.loadTravelPlan(id: planId)
            })
            .disposed(by: disposeBag)

        // 일차 변경
        input.daySelected
            .bind(to: currentDay)
            .disposed(by: disposeBag)

        // 예산 변경
        input.budgetChanged
            .withLatestFrom(currentDay.asObservable()) { (budget: $0, day: $1) }
            .subscribe(onNext: { [weak self] data in
                self?.updateBudget(data.budget, forDay: data.day)
            })
            .disposed(by: disposeBag)

        // 경로 변경
        input.routeChanged
            .withLatestFrom(currentDay.asObservable()) { (route: $0, day: $1) }
            .subscribe(onNext: { [weak self] data in
                self?.updateRoute(data.route, forDay: data.day)
            })
            .disposed(by: disposeBag)

        // 일정 추가
        input.addSchedule
            .withLatestFrom(currentDay.asObservable()) { (scheduleData: $0, day: $1) }
            .subscribe(onNext: { [weak self] data in
                let scheduleItem = ScheduleItem(time: data.scheduleData.time, location: data.scheduleData.location)
                self?.addScheduleItem(scheduleItem, forDay: data.day)
            })
            .disposed(by: disposeBag)

        // 변경사항 저장 (수동 저장)
        input.saveChanges
            .subscribe(onNext: { [weak self] in
                self?.saveAllChangesToRealm(isManualSave: true)
            })
            .disposed(by: disposeBag)

        // 현재 일차의 데이터
        let currentDayData = Observable.combineLatest(
            dayDataStorage.asObservable(),
            currentDay.asObservable()
        ) { storage, day in
            return storage[day] ?? DayData.empty
        }

        // 현재 일차의 일정 아이템들
        let scheduleItems = currentDayData
            .map { $0.scheduleItems }

        // 일정 추가 버튼 활성화 여부
        let isAddScheduleEnabled = Observable.combineLatest(
            input.timeText,
            input.locationText
        ) { time, location in
            return !time.isEmpty && !location.isEmpty
        }

        // 일정 추가 버튼 활성화 상태 (UI 색상은 View에서 처리)
        let isAddScheduleButtonEnabled = isAddScheduleEnabled

        return Output(
            travelPlanData: travelPlanData.compactMap { $0 }.asObservable(),
            currentDayData: currentDayData,
            scheduleItems: scheduleItems,
            saveResult: saveResult.asObservable(),
            error: errorRelay.asObservable(),
            isAddScheduleEnabled: isAddScheduleEnabled,
            isAddScheduleButtonEnabled: isAddScheduleButtonEnabled
        )
    }

    // MARK: - Public Methods
    func loadTravelPlan(id: String) {
        print("📊 여행 계획 로드 시작: ID \(id)")

        do {
            let realm = try Realm()
            let objectId = try ObjectId(string: id)

            guard let travelPlan = realm.object(ofType: TravelPlan.self, forPrimaryKey: objectId) else {
                print("❌ 여행 계획을 찾을 수 없습니다: ID \(id)")
                errorRelay.accept("여행 계획을 찾을 수 없습니다.")
                return
            }

            currentTravelPlan = travelPlan
            let planData = TravelPlanData(from: travelPlan)
            travelPlanData.accept(planData)

            // 저장된 일차별 데이터 로드
            loadDayDataFromRealm(travelPlan: travelPlan)

            print("✅ 여행 계획 로드 완료: \(planData.travelName)")
            print("   • 기간: \(DateManager.shared.formatToKoreanString(from: planData.startDate)) ~ \(DateManager.shared.formatToKoreanString(from: planData.endDate))")
            print("   • 총 일차: \(planData.totalDays)일")

        } catch {
            print("❌ 여행 계획 로드 실패: \(error.localizedDescription)")
            errorRelay.accept("여행 계획을 불러오는데 실패했습니다.")
        }
    }

    private func loadDayDataFromRealm(travelPlan: TravelPlan) {
        var storage: [Int: DayData] = [:]

        print("📋 ===== Realm 데이터 로드 시작 =====")
        print("   • 전체 일차 개수: \(travelPlan.travelDays.count)개")

        for dayDetail in travelPlan.travelDays {
            var dayData = DayData()
            dayData.budget = dayDetail.budget
            dayData.route = dayDetail.route

            print("📋 Day \(dayDetail.dayNumber) 로드 중...")
            print("   💰 예산: '\(dayDetail.budget)'")
            print("   🚗 경로: '\(dayDetail.route)'")
            print("   📍 저장된 좌표 개수: \(dayDetail.routeCoordinates.count)개")
            print("   📋 일정 개수: \(dayDetail.schedules.count)개")

            // 일정 아이템 로드
            let scheduleItems = dayDetail.schedules.map { schedule in
                ScheduleItem(time: schedule.time, location: schedule.location)
            }
            dayData.scheduleItems = Array(scheduleItems)

            // 좌표 데이터를 KakaoPlace로 변환 (모든 좌표 출력)
            var places: [KakaoPlace] = []
            for (index, coordinate) in dayDetail.routeCoordinates.enumerated() {
                print("   📍 좌표 \(index + 1): \(coordinate.placeName) (\(coordinate.latitude), \(coordinate.longitude))")

                let place = KakaoPlace(
                    id: coordinate.placeName,
                    placeName: coordinate.placeName,
                    categoryName: "",
                    categoryGroupCode: "",
                    categoryGroupName: "",
                    phone: "",
                    addressName: "",
                    roadAddressName: "",
                    x: String(coordinate.longitude),
                    y: String(coordinate.latitude),
                    placeUrl: "",
                    distance: "0"
                )
                places.append(place)
            }
            dayData.searchedPlaces = places

            storage[dayDetail.dayNumber] = dayData
            print("   ✅ Day \(dayDetail.dayNumber) 로드 완료: \(places.count)개 좌표")
        }

        dayDataStorage.accept(storage)
        print("📋 ===== 일차별 데이터 로드 완료: \(storage.count)개 일차 =====")

        // 전체 저장된 좌표 개수 요약
        let totalCoordinates = storage.values.reduce(0) { $0 + $1.searchedPlaces.count }
        print("📍 전체 저장된 좌표: \(totalCoordinates)개")
    }

    func getCurrentDay() -> Int {
        return currentDay.value
    }

    func getDayData(for day: Int) -> DayData {
        return dayDataStorage.value[day] ?? DayData.empty
    }

    func updateBudget(_ budget: String, forDay day: Int) {
        var currentStorage = dayDataStorage.value
        if currentStorage[day] == nil {
            currentStorage[day] = DayData()
        }
        currentStorage[day]?.budget = budget
        dayDataStorage.accept(currentStorage)
    }

    func updateRoute(_ route: String, forDay day: Int) {
        var currentStorage = dayDataStorage.value
        if currentStorage[day] == nil {
            currentStorage[day] = DayData()
        }
        currentStorage[day]?.route = route
        dayDataStorage.accept(currentStorage)
    }

    func updateSearchedPlaces(_ places: [KakaoPlace], forDay day: Int) {
        var currentStorage = dayDataStorage.value
        if currentStorage[day] == nil {
            currentStorage[day] = DayData()
        }
        currentStorage[day]?.searchedPlaces = places
        dayDataStorage.accept(currentStorage)

        print("📍 검색된 장소 업데이트됨 - Day \(day): \(places.count)개")

        // 검색된 장소 업데이트 후 지연된 자동 저장 (디바운싱)
        scheduleAutoSave()
        print("💾 검색된 장소 업데이트 후 자동 저장 예약")
    }

    func addScheduleItem(_ item: ScheduleItem, forDay day: Int) {
        var currentStorage = dayDataStorage.value
        if currentStorage[day] == nil {
            currentStorage[day] = DayData()
        }
        currentStorage[day]?.scheduleItems.append(item)
        dayDataStorage.accept(currentStorage)

        print("➕ 일정 추가됨 - Day \(day): \(item.time) \(item.location)")

        // 추가 후 지연된 자동 저장 (디바운싱)
        scheduleAutoSave()
        print("💾 일정 추가 후 자동 저장 예약")
    }

    func removeScheduleItem(at index: Int, forDay day: Int) {
        var currentStorage = dayDataStorage.value
        guard var dayData = currentStorage[day],
              index < dayData.scheduleItems.count else { return }

        let removedItem = dayData.scheduleItems.remove(at: index)
        currentStorage[day] = dayData
        dayDataStorage.accept(currentStorage)

        print("🗑️ 일정 삭제됨 - Day \(day): \(removedItem.time) \(removedItem.location)")

        // 삭제 후 지연된 자동 저장 (디바운싱)
        scheduleAutoSave()
        print("💾 일정 삭제 후 자동 저장 예약")
    }

    // MARK: - Auto Save with Debouncing
    private func scheduleAutoSave() {
        // 기존 저장 작업 취소
        saveWorkItem?.cancel()

        // 새로운 저장 작업 예약 (1초 지연)
        saveWorkItem = DispatchWorkItem { [weak self] in
            self?.saveAllChangesToRealm()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: saveWorkItem!)
        print("📅 자동 저장 예약됨 (1초 후 실행)")
    }

    private func saveAllChangesToRealm(isManualSave: Bool = false) {
        guard let travelPlan = currentTravelPlan else {
            print("❌ 저장할 여행 계획이 없습니다")
            if isManualSave {
                saveResult.onNext((success: false, message: "저장할 여행 계획이 없습니다."))
            }
            return
        }

        print("💾 ===== 여행 계획 변경사항 저장 시작 =====")

        do {
            let realm = try Realm()
            let currentStorage = dayDataStorage.value

            try realm.write {
                // 기존 일차별 데이터 삭제
                travelPlan.travelDays.removeAll()

                // 새로운 일차별 데이터 추가
                for (day, data) in currentStorage.sorted(by: { $0.key < $1.key }) {
                    let dayDetail = TravelDayDetail()
                    dayDetail.dayNumber = day
                    dayDetail.budget = data.budget
                    dayDetail.route = data.route

                    // 일정 데이터 추가
                    for item in data.scheduleItems {
                        let schedule = TravelSchedule()
                        schedule.time = item.time
                        schedule.location = item.location
                        dayDetail.schedules.append(schedule)
                    }

                    // 경로 좌표 데이터 추가
                    for (index, place) in data.searchedPlaces.enumerated() {
                        let coordinate = RouteCoordinate()
                        coordinate.placeName = place.placeName
                        coordinate.latitude = place.coordinate.latitude
                        coordinate.longitude = place.coordinate.longitude
                        coordinate.order = index + 1
                        dayDetail.routeCoordinates.append(coordinate)
                    }

                    travelPlan.travelDays.append(dayDetail)

                    print("📅 Day \(day) 저장: 예산 '\(data.budget)', 경로 '\(data.route)', 일정 \(data.scheduleItems.count)개")
                }
            }

            print("✅ 여행 계획 변경사항 저장 완료!")
            if isManualSave {
                saveResult.onNext((success: true, message: "여행 계획이 성공적으로 저장되었습니다!"))
            }

        } catch {
            print("❌ 여행 계획 저장 실패: \(error.localizedDescription)")
            if isManualSave {
                saveResult.onNext((success: false, message: "여행 계획 저장에 실패했습니다. 다시 시도해주세요."))
            }
        }
    }
}
