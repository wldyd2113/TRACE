//
//  PlanDetailViewModel.swift
//  TRACE
//
//  Created by 차지용 on 9/29/25.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift
import CoreLocation

class PlanDetailViewModel: BaseViewModel {

    private let disposeBag = DisposeBag()

    // 국가 타입 (API 분기용)
    private var countryType: String = "국내"

    // MARK: - Input
    struct Input {
        let budgetText: Observable<String>
        let routeText: Observable<String>
        let timeText: Observable<String>
        let locationText: Observable<String>
        let addScheduleButtonTapped: Observable<Void>
        let dayButtonTapped: Observable<Int>
        let saveButtonTapped: Observable<Void>
        let searchQuery: Observable<String>
    }

    // MARK: - Output
    struct Output {
        let isAddScheduleEnabled: Observable<Bool>
        let isAddScheduleButtonEnabled: Observable<Bool>
        let scheduleItems: Observable<[ScheduleItem]>
        let currentDayData: Observable<DayData>
        let navigateToMain: Observable<Void>
        let searchResults: Observable<[KakaoPlace]>
        let saveResult: Observable<(success: Bool, message: String)>
    }

    // MARK: - Properties
    private var currentDay = BehaviorRelay<Int>(value: 1)
    private var dayDataStorage = BehaviorRelay<[Int: DayData]>(value: [:])
    private let saveResult = PublishSubject<(success: Bool, message: String)>()
    private let navigateToMainRelay = PublishRelay<Void>()

    // MARK: - Auto Save Prevention
    var shouldPreventAutoSave = false

    // 현재 일차별 데이터 구조
    struct DayData {
        var budget: String = ""
        var route: String = ""
        var scheduleItems: [ScheduleItem] = []
        var searchedPlaces: [KakaoPlace] = [] // 검색된 장소들 (좌표 포함)

        static let empty = DayData()
    }

    // MARK: - BaseViewModel Implementation
    func transform(input: Input) -> Output {

        // 일정 추가 버튼 활성화 여부
        let isAddScheduleEnabled = Observable.combineLatest(
            input.timeText,
            input.locationText
        ) { time, location in
            return !time.isEmpty && !location.isEmpty
        }

        // 일정 추가 버튼 활성화 상태 (UI 색상은 View에서 처리)
        let isAddScheduleButtonEnabled = isAddScheduleEnabled

        // 일정 추가 처리
        input.addScheduleButtonTapped
            .withLatestFrom(Observable.combineLatest(
                input.timeText,
                input.locationText,
                currentDay.asObservable()
            ))
            .subscribe(onNext: { [weak self] time, location, day in
                guard !time.isEmpty, !location.isEmpty else { return }
                let newItem = ScheduleItem(time: time, location: location)
                self?.addScheduleItem(newItem, forDay: day)
            })
            .disposed(by: disposeBag)

        // 현재 일차의 일정 아이템들
        let scheduleItems = Observable.combineLatest(
            dayDataStorage.asObservable(),
            currentDay.asObservable()
        ) { storage, day in
            return storage[day]?.scheduleItems ?? []
        }

        // 일차 변경 처리
        input.dayButtonTapped
            .withLatestFrom(Observable.combineLatest(
                input.budgetText,
                input.routeText,
                currentDay.asObservable()
            )) { selectedDay, currentData in
                return (selectedDay: selectedDay, budget: currentData.0, route: currentData.1, currentDay: currentData.2)
            }
            .subscribe(onNext: { [weak self] data in
                // 자동 저장 방지 플래그 확인
                if !(self?.shouldPreventAutoSave ?? false) {
                    // 현재 일차 데이터 저장
                    self?.saveCurrentDayData(budget: data.budget, route: data.route, day: data.currentDay)
                } else {
                    print("🚫 ViewModel: 일차 변경 시 자동 저장 방지됨")
                }
                // 새로운 일차로 변경
                self?.currentDay.accept(data.selectedDay)
            })
            .disposed(by: disposeBag)

        // 현재 일차 데이터
        let currentDayData = Observable.combineLatest(
            dayDataStorage.asObservable(),
            currentDay.asObservable()
        ) { storage, day in
            return storage[day] ?? DayData.empty
        }

        // 저장 버튼 처리
        let navigateBack = input.saveButtonTapped
            .withLatestFrom(Observable.combineLatest(
                input.budgetText,
                input.routeText,
                currentDay.asObservable(),
                dayDataStorage.asObservable()
            ))
            .do(onNext: { [weak self] budget, route, day, storage in
                print("🚀 저장 버튼 탭됨 - 현재 일차: \(day)")
                print("📝 현재 입력된 데이터:")
                print("   💰 예산: '\(budget)'")
                print("   🚗 경로: '\(route)'")
                print("   📊 현재 storage: \(storage.count)개 일차")

                // 현재 dayDataStorage 상태 확인
                let currentStorage = self?.dayDataStorage.value ?? [:]
                print("📊 현재 ViewModel storage 상태: \(currentStorage.count)개 일차")
                for (dayNum, data) in currentStorage {
                    print("   Day \(dayNum): 일정 \(data.scheduleItems.count)개, 예산 '\(data.budget)', 경로 '\(data.route)'")
                }

                // 현재 일차의 최신 데이터 저장
                self?.saveCurrentDayData(budget: budget, route: route, day: day)

                // 업데이트된 storage로 Realm에 저장
                let updatedStorage = self?.dayDataStorage.value ?? storage
                self?.saveTravelPlan(storage: updatedStorage)
            })
            .map { _ in () }

        // 검색 기능
        let searchResults = input.searchQuery
            .filter { !$0.isEmpty }
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .flatMapLatest { [weak self] query -> Observable<[KakaoPlace]> in
                return self?.searchPlaces(query: query) ?? Observable.just([])
            }
            .share(replay: 1)

        return Output(
            isAddScheduleEnabled: isAddScheduleEnabled,
            isAddScheduleButtonEnabled: isAddScheduleButtonEnabled,
            scheduleItems: scheduleItems,
            currentDayData: currentDayData,
            navigateToMain: navigateToMainRelay.asObservable(),
            searchResults: searchResults,
            saveResult: saveResult.asObservable()
        )
    }

    // MARK: - Private Methods
    private func addScheduleItem(_ item: ScheduleItem, forDay day: Int) {
        print("➕ ViewModel: 일정 추가 시작 - Day \(day): \(item.time) \(item.location)")

        var currentStorage = dayDataStorage.value
        print("📊 추가 전 storage 상태: \(currentStorage.count)개 일차")

        if currentStorage[day] == nil {
            currentStorage[day] = DayData()
            print("🆕 Day \(day) 새로 생성")
        }

        let beforeCount = currentStorage[day]?.scheduleItems.count ?? 0
        currentStorage[day]?.scheduleItems.append(item)
        let afterCount = currentStorage[day]?.scheduleItems.count ?? 0

        dayDataStorage.accept(currentStorage)

        print("✅ 일정 추가 완료 - Day \(day): \(item.time) \(item.location)")
        print("📈 일정 개수: \(beforeCount) → \(afterCount)")
        print("📊 추가 후 전체 storage: \(dayDataStorage.value.count)개 일차")
    }

    private func saveCurrentDayData(budget: String, route: String, day: Int) {
        var currentStorage = dayDataStorage.value

        if currentStorage[day] == nil {
            currentStorage[day] = DayData()
        }

        // 기존 일정과 검색된 장소들은 유지하면서 예산과 경로만 업데이트
        let existingScheduleItems = currentStorage[day]?.scheduleItems ?? []
        let existingSearchedPlaces = currentStorage[day]?.searchedPlaces ?? []

        currentStorage[day]?.budget = budget
        currentStorage[day]?.route = route
        currentStorage[day]?.scheduleItems = existingScheduleItems
        currentStorage[day]?.searchedPlaces = existingSearchedPlaces

        dayDataStorage.accept(currentStorage)

        print("💾 ViewModel: Day \(day) 데이터 저장 완료")
        print("   💰 예산: '\(budget)'")
        print("   🚗 경로: '\(route)'")
        print("   📋 일정: \(existingScheduleItems.count)개 (기존 유지)")
        print("   📍 좌표: \(existingSearchedPlaces.count)개 (기존 유지)")
    }

    private func saveTravelPlan(storage: [Int: DayData]) {
        // 자동 저장 방지 플래그 확인
        if shouldPreventAutoSave {
            print("🚫 ViewModel: saveTravelPlan - 자동 저장이 방지되어 Realm 저장을 건너뜁니다")
            return
        }

        print("✅ ===== 여행 계획 저장 시작 =====")
        print("📊 새로 저장할 데이터 개수: \(storage.count)개 일차")

        for (day, data) in storage {
            print("📅 Day \(day) 미리보기:")
            print("   💰 예산: '\(data.budget)'")
            print("   🚗 경로: '\(data.route)'")
            print("   📋 일정: \(data.scheduleItems.count)개")
            print("   📍 좌표: \(data.searchedPlaces.count)개")
        }

        do {
            let realm = try Realm()

            // Realm 파일 경로 출력
            print("📁 Realm 파일 경로: \(realm.configuration.fileURL?.path ?? "경로를 찾을 수 없음")")

            // 가장 최근에 생성된 TravelPlan 찾기 (또는 새로 생성)
            let allPlans = realm.objects(TravelPlan.self)
            let currentPlan = allPlans.last ?? createNewTravelPlan(in: realm)

            // 기존 데이터를 먼저 로드하여 병합
            var allDaysStorage: [Int: DayData] = [:]

            // 기존 Realm 데이터 로드
            print("📋 기존 저장된 일차: \(currentPlan.travelDays.count)개")
            for dayDetail in currentPlan.travelDays {
                var dayData = DayData()
                dayData.budget = dayDetail.budget
                dayData.route = dayDetail.route

                // 일정 아이템 로드
                let scheduleItems = dayDetail.schedules.map { schedule in
                    ScheduleItem(time: schedule.time, location: schedule.location)
                }
                dayData.scheduleItems = Array(scheduleItems)

                // 좌표 데이터 로드
                let places = dayDetail.routeCoordinates.map { coordinate in
                    KakaoPlace(
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
                }
                dayData.searchedPlaces = Array(places)

                allDaysStorage[dayDetail.dayNumber] = dayData
                print("📋 기존 데이터 복원: Day \(dayDetail.dayNumber)")
            }

            // 새로운 데이터로 업데이트 (기존 데이터 덮어쓰기)
            for (day, data) in storage {
                allDaysStorage[day] = data
                print("📝 새 데이터 추가/업데이트: Day \(day)")
            }

            // Realm write 직전에도 한번 더 확인
            if shouldPreventAutoSave {
                print("🚫 ViewModel: realm.write 직전 - 자동 저장이 방지되어 Realm 저장을 건너뜁니다")
                return
            }

            try realm.write {
                // 기존 일차별 데이터 삭제
                currentPlan.travelDays.removeAll()

                // 병합된 모든 일차별 데이터 추가
                for (day, data) in allDaysStorage.sorted(by: { $0.key < $1.key }) {
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

                    // 경로 좌표 데이터 추가 (MapManager에서 가져온 검색된 장소들)
                    addRouteCoordinates(to: dayDetail, from: data)

                    currentPlan.travelDays.append(dayDetail)

                    print("📅 Day \(day) 저장:")
                    print("   💰 예산: \(data.budget.isEmpty ? "미설정" : data.budget)")
                    print("   🚗 경로: \(data.route.isEmpty ? "미설정" : data.route)")
                    print("   📋 일정 수: \(data.scheduleItems.count)개")
                    print("   📍 경로 좌표: \(dayDetail.routeCoordinates.count)개")
                }
            }

            print("✅ Realm 저장 완료!")
            print("🗄️ 총 저장된 일차: \(currentPlan.travelDays.count)개")

            // 저장된 데이터 확인
            let savedPlans = realm.objects(TravelPlan.self)
            print("📊 Realm 내 전체 TravelPlan 수: \(savedPlans.count)")
            if let lastPlan = savedPlans.last {
                print("📋 마지막 저장된 계획:")
                print("   • ID: \(lastPlan.id)")
                print("   • 여행지: \(lastPlan.travelName)")
                print("   • 일차 수: \(lastPlan.travelDays.count)")
                for dayDetail in lastPlan.travelDays {
                    print("     - Day \(dayDetail.dayNumber): 일정 \(dayDetail.schedules.count)개, 좌표 \(dayDetail.routeCoordinates.count)개")
                }
            }
            print("==============================")

            // 저장 완료 후 메인 화면으로 이동
            navigateToMainRelay.accept(())

        } catch {
            print("❌ Realm 저장 실패: \(error.localizedDescription)")
            // 실패 결과 emit
            saveResult.onNext((success: false, message: NSLocalizedString("travel_plan_save_retry", comment: "Travel plan save retry")))
        }
    }

    private func createNewTravelPlan(in realm: Realm) -> TravelPlan {
        let newPlan = TravelPlan()
        newPlan.nation = "임시"
        newPlan.travelName = NSLocalizedString("travel_plan", comment: "Travel plan")
        newPlan.startDate = Date()
        newPlan.endDate = Date()

        try! realm.write {
            realm.add(newPlan)
        }

        print("🆕 새로운 TravelPlan 생성: \(newPlan.id)")
        return newPlan
    }

    private func addRouteCoordinates(to dayDetail: TravelDayDetail, from data: DayData) {
        // 검색된 장소들의 실제 좌표를 저장
        for (index, place) in data.searchedPlaces.enumerated() {
            let coordinate = RouteCoordinate()
            coordinate.placeName = place.placeName
            coordinate.latitude = place.coordinate.latitude
            coordinate.longitude = place.coordinate.longitude
            coordinate.order = index + 1
            dayDetail.routeCoordinates.append(coordinate)

            print("📍 좌표 저장: \(place.placeName) (\(place.coordinate.latitude), \(place.coordinate.longitude))")
        }
    }

    // MARK: - Public Save Method
    func saveAllDataToRealm() {
        // 자동 저장 방지 플래그 확인
        if shouldPreventAutoSave {
            print("🚫 ViewModel: 자동 저장이 방지되어 Realm 저장을 건너뜁니다")
            return
        }

        print("💾 ===== ViewModel 저장 시작 =====")

        let currentStorage = dayDataStorage.value
        print("📊 저장할 데이터 개수: \(currentStorage.count)개 일차")

        // 빈 데이터 제외하고 저장
        let filteredStorage = currentStorage.filter { (day, data) in
            return !data.budget.isEmpty || !data.route.isEmpty || !data.scheduleItems.isEmpty || !data.searchedPlaces.isEmpty
        }

        saveTravelPlan(storage: filteredStorage)
    }

    // MARK: - CountryType Methods
    func setCountryType(_ type: String) {
        countryType = type
        print("🌍 PlanDetailViewModel: countryType 설정됨 - \(type)")
    }

    // MARK: - Public Methods
    func removeScheduleItem(at index: Int) {
        let day = currentDay.value
        var currentStorage = dayDataStorage.value

        guard var dayData = currentStorage[day],
              index < dayData.scheduleItems.count else { return }

        let removedItem = dayData.scheduleItems.remove(at: index)
        currentStorage[day] = dayData
        dayDataStorage.accept(currentStorage)

        print("🗑️ 일정 삭제됨 - Day \(day): \(removedItem.time) \(removedItem.location)")
    }

    func getCurrentDay() -> Int {
        return currentDay.value
    }

    func setCurrentDay(_ day: Int) {
        currentDay.accept(day)
        print("🔄 ViewModel: currentDay 업데이트 - \(day)")
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

        print("🔄 Day \(day) 검색된 장소 업데이트: \(places.count)개")
    }

    private func searchPlaces(query: String) -> Observable<[KakaoPlace]> {
        print("🔍 ViewModel: 검색 시작 - \(query) (countryType: \(countryType))")

        // countryType에 따라 API 분기
        if countryType == "해외" {
            // 해외 검색: Google Places API 사용
            return NetworkManger.shared.searchGooglePlaces(query: query)
                .map { [weak self] result in
                    switch result {
                    case .success(let response):
                        print("🔍 ViewModel: Google 검색 성공 - \(response.results.count)개 결과")
                        // Google Places 결과를 KakaoPlace 형식으로 변환
                        let kakaoPlaces = response.results.map { googlePlace in
                            return KakaoPlace(
                                id: googlePlace.placeId,
                                placeName: googlePlace.name,
                                categoryName: googlePlace.types.joined(separator: ", "),
                                categoryGroupCode: "",
                                categoryGroupName: "",
                                phone: "",
                                addressName: googlePlace.formattedAddress ?? "",
                                roadAddressName: googlePlace.formattedAddress ?? "",
                                x: String(googlePlace.geometry.location.lng),
                                y: String(googlePlace.geometry.location.lat),
                                placeUrl: "",
                                distance: "0"
                            )
                        }
                        return kakaoPlaces
                    case .failure(let error):
                        print("🔍 ViewModel: Google 검색 실패 - \(error.localizedDescription)")
                        return []
                    }
                }
                .catchAndReturn([])
        } else {
            // 국내 검색: Kakao Places API 사용
            return NetworkManger.shared.searchKakaoPlaces(query: query)
                .map { [weak self] result in
                    switch result {
                    case .success(let response):
                        print("🔍 ViewModel: Kakao 검색 성공 - \(response.documents.count)개 결과")
                        let filteredPlace = self?.selectBestMatch(places: response.documents, query: query)
                        return filteredPlace != nil ? [filteredPlace!] : []
                    case .failure(let error):
                        print("🔍 ViewModel: Kakao 검색 실패 - \(error.localizedDescription)")
                        return []
                    }
                }
                .catchAndReturn([])
        }
    }

    private func selectBestMatch(places: [KakaoPlace], query: String) -> KakaoPlace? {
        guard !places.isEmpty else { return nil }

        // 1. 정확히 일치하는 이름 찾기
        if let exactMatch = places.first(where: { $0.placeName == query }) {
            print("🎯 정확한 이름 매칭: \(exactMatch.placeName)")
            return exactMatch
        }

        // 2. 쿼리를 포함하는 가장 짧은 이름 찾기 (서울역 -> "서울역"이 "서울역 4호선"보다 우선)
        let containingQuery = places.filter { $0.placeName.contains(query) }
        if let shortestMatch = containingQuery.min(by: { $0.placeName.count < $1.placeName.count }) {
            print("🎯 가장 짧은 매칭: \(shortestMatch.placeName)")
            return shortestMatch
        }

        // 3. 주요 카테고리 우선순위 (역, 공항, 관광지 등)
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

    // MARK: - Clear Day Data
    func clearDayData(for day: Int) {
        print("🗑️ ViewModel: Day \(day) 데이터 초기화 시작")

        var currentStorage = dayDataStorage.value
        currentStorage[day] = DayData.empty
        dayDataStorage.accept(currentStorage)

        print("✅ ViewModel: Day \(day) 데이터 초기화 완료")
    }
}
