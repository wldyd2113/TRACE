//
//  TravelPlanDetailWriteViewController.swift
//  TRACE
//
//  Created by 차지용 on 9/27/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Then
import MapKit
import CoreLocation
import Alamofire
import RealmSwift

class TravelPlanDetailViewController: UIViewController {

    private let disposeBag = DisposeBag()
    private let mapManager = MapManger()
    private let viewModel = PlanDetailViewModel()

    // 검색된 장소들을 저장 (좌표 정보 포함)
    private var currentSearchedPlaces: [KakaoPlace] = []
    
    // MARK: - Data
    private var currentDay = 1
    private var dayDataStorage: [Int: DayData] = [:]

    // 현재 일차별 데이터 구조
    private struct DayData {
        var budget: String = ""
        var route: String = ""
        var scheduleItems: [ScheduleItem] = []
    }
    
    // MARK: - UI Components
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }
    
    private let contentView = UIView()
    
    // 날짜 선택 영역
    private let dateStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.distribution = .fillEqually
        $0.spacing = 10
    }
    
    private let day1Button = DayButton(day: 1, isSelected: true)
    private let day2Button = DayButton(day: 2)
    private let day3Button = DayButton(day: 3)
    
    // 예상 경비 섹션
    private let budgetTitleLabel = UILabel().then {
        $0.applySectionTitleStyle(text: "예상 경비")
    }

    private let budgetTextField = UITextField().then {
        $0.applyTravelStyle(placeholder: "예: 20,000원", fontSize: 16)
    }

    private let budgetDescriptionLabel = UILabel().then {
        $0.applyDescriptionStyle(text: "예상 경비를 입력해주세요.")
    }
    
    // 여행 일정 추가 섹션
    private let scheduleTitleLabel = UILabel().then {
        $0.applySectionTitleStyle(text: "여행 일정 추가")
    }
    
    // 시간 입력 필드
    private let timeTextField = UITextField().then {
        $0.applyTravelStyle(placeholder: "시간 선택")
        $0.isUserInteractionEnabled = true
    }

    // 여행지 입력 필드
    private let locationTextField = UITextField().then {
        $0.applyTravelStyle(placeholder: "여행지 입력")
    }

    // 일정 추가 버튼
    private let addScheduleItemButton = UIButton(type: .system).then {
        $0.applyMainActionStyle(title: "일정 추가하기")
        $0.isEnabled = false
        $0.backgroundColor = .systemGray4
    }

    // 시간 피커
    private let timePicker = UIDatePicker().then {
        $0.datePickerMode = .time
        $0.preferredDatePickerStyle = .wheels
        $0.locale = Locale(identifier: "ko_KR")
    }
    
    private let scheduleDescriptionLabel = UILabel().then {
        $0.applyDescriptionStyle(text: "각 시간대 일정 추가")
    }
    
    // 여행 경로 섹션
    private let routeTitleLabel = UILabel().then {
        $0.applySectionTitleStyle(text: "여행 경로")
    }
    
    private let routeSearchBar = UISearchBar().then {
        $0.placeholder = "예: 서울 -> 부산"
        $0.searchBarStyle = .minimal
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
        $0.searchTextField.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.searchTextField.backgroundColor = .systemGray6
    }
    
    private let routeDescriptionLabel = UILabel().then {
        $0.applyDescriptionStyle(text: "여행 경로를 누르면 맵 선택 일정이 나옵니다.")
    }
    
    // 동적으로 추가될 일정 컨테이너
    private let scheduleStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 12
    }
    
    // 하단 버튼들
    private let saveButton = UIButton(type: .system).then {
        $0.applyMainActionStyle(title: "💾 여행 계획 저장하기")
        $0.layer.cornerRadius = 25
        $0.backgroundColor = UIColor.systemBlue
        $0.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
    }
    
    private let startTravelButton = UIButton(type: .system).then {
        $0.applyMainActionStyle(title: "여행 시작하기")
        $0.layer.cornerRadius = 25
    }
    
    // MapKit 관련 (MapManger에서 관리)
    private var mapView: MKMapView {
        return mapManager.mapView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background

        configureHierarchy()
        configureUI()
        configureLayout()
        bind()

        // 초기 데이터 로드 (1일차)
        loadDayData(day: currentDay)

        // 맵 관리자 설정
        setupMapManager()

        // ViewModel 바인딩
        bindViewModel()
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func clearSearchResults() {
        mapManager.clearAllSearchResults()
        routeSearchBar.text = ""
        print("🗑️ 모든 검색 결과 및 루트 삭제")
    }
    
    private func showMapSearch() {
        // 지도 검색 화면으로 이동
//        let mapSearchVC = MapSearchViewController()
//        mapSearchVC.delegate = self
//        let navVC = UINavigationController(rootViewController: mapSearchVC)
//        present(navVC, animated: true)
    }

    private func setupMapManager() {
        mapManager.delegate = self
        mapManager.requestInitialLocation()
    }

    @objc private func timePickerDone() {
        timeTextField.resignFirstResponder()
    }

    private func createScheduleItemView(item: ScheduleItem, index: Int) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 8
        
        let timeLabel = UILabel()
        timeLabel.text = item.time.isEmpty ? "시간 미정" : item.time
        timeLabel.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 14)
        timeLabel.textColor = .labelLight
        
        let locationLabel = UILabel()
        locationLabel.text = item.location.isEmpty ? "장소 미정" : item.location
        locationLabel.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 14)
        locationLabel.textColor = .systemGray
        
        let deleteButton = UIButton(type: .system)
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.tintColor = .systemRed
        
        containerView.addSubview(timeLabel)
        containerView.addSubview(locationLabel)
        containerView.addSubview(deleteButton)
        
        timeLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(12)
        }
        
        locationLabel.snp.makeConstraints {
            $0.top.equalTo(timeLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview().offset(12)
            $0.bottom.equalToSuperview().offset(-12)
        }
        
        deleteButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-12)
            $0.width.height.equalTo(24)
        }

        // 삭제 버튼 액션 추가 - ViewModel을 통해 처리
        deleteButton.addTarget(self, action: #selector(deleteScheduleItem(_:)), for: .touchUpInside)
        deleteButton.tag = index

        containerView.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(60)
        }

        return containerView
    }

    @objc private func deleteScheduleItem(_ sender: UIButton) {
        let index = sender.tag
        viewModel.removeScheduleItem(at: index)
        print("🗑️ 일정 삭제 요청: index \(index)")
    }

    // MARK: - Save Methods
    private func saveAllDataToRealm() {
        print("💾 ===== 수동 저장 시작 =====")

        // 현재 입력된 데이터 확인
        let currentBudget = budgetTextField.text ?? ""
        let currentRoute = routeSearchBar.text ?? ""

        print("📝 현재 UI 데이터:")
        print("   💰 예산: '\(currentBudget)'")
        print("   🚗 경로: '\(currentRoute)'")
        print("   📅 현재 일차: \(currentDay)")

        // ViewModel에 현재 데이터 업데이트
        viewModel.updateBudget(currentBudget, forDay: currentDay)
        viewModel.updateRoute(currentRoute, forDay: currentDay)
        viewModel.updateSearchedPlaces(currentSearchedPlaces, forDay: currentDay)

        // ViewModel의 현재 데이터 상태 확인
        let currentDayData = viewModel.getDayData(for: currentDay)
        print("📊 ViewModel 데이터 확인:")
        print("   📋 일정: \(currentDayData.scheduleItems.count)개")
        print("   📍 좌표: \(currentDayData.searchedPlaces.count)개")

        // 모든 일차 데이터 수집
        var allDaysData: [Int: PlanDetailViewModel.DayData] = [:]
        for day in 1...3 {
            let data = viewModel.getDayData(for: day)
            if !data.budget.isEmpty || !data.route.isEmpty || !data.scheduleItems.isEmpty || !data.searchedPlaces.isEmpty {
                allDaysData[day] = data
                print("   Day \(day): 일정 \(data.scheduleItems.count)개, 좌표 \(data.searchedPlaces.count)개")
            }
        }

        // ViewModel을 통해 Realm 저장
        saveTravelPlanToRealm(storage: allDaysData)
    }

    private func saveTravelPlanToRealm(storage: [Int: PlanDetailViewModel.DayData]) {
        print("💾 Realm 저장 실행 - \(storage.count)개 일차")

        // ViewModel의 saveTravelPlan 메서드를 직접 호출할 수 없으므로
        // 여기서 직접 Realm 저장 로직 구현
        do {
            let realm = try Realm()
            print("📁 Realm 파일 경로: \(realm.configuration.fileURL?.path ?? "경로를 찾을 수 없음")")

            // 가장 최근에 생성된 TravelPlan 찾기
            let allPlans = realm.objects(TravelPlan.self)
            let currentPlan = allPlans.last ?? createNewTravelPlan(in: realm)

            try realm.write {
                // 기존 일차별 데이터 삭제
                currentPlan.travelDays.removeAll()

                // 새로운 일차별 데이터 추가
                for (day, data) in storage.sorted(by: { $0.key < $1.key }) {
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

                    currentPlan.travelDays.append(dayDetail)

                    print("✅ Day \(day) 저장:")
                    print("   💰 예산: \(data.budget.isEmpty ? "미설정" : data.budget)")
                    print("   🚗 경로: \(data.route.isEmpty ? "미설정" : data.route)")
                    print("   📋 일정: \(data.scheduleItems.count)개")

                    // 일정 상세 내역
                    for (idx, item) in data.scheduleItems.enumerated() {
                        print("     [\(idx+1)] \(item.time) - \(item.location)")
                    }

                    print("   📍 좌표: \(dayDetail.routeCoordinates.count)개")

                    // 좌표 상세 내역
                    for coordinate in dayDetail.routeCoordinates {
                        print("     📍 \(coordinate.placeName): (\(coordinate.latitude), \(coordinate.longitude))")
                    }
                }
            }

            print("✅ Realm 저장 완료!")
            print("🗄️ 총 저장된 일차: \(currentPlan.travelDays.count)개")

            // 저장된 데이터 최종 확인
            print("📊 ===== 저장된 데이터 최종 확인 =====")
            let allSavedPlans = realm.objects(TravelPlan.self)
            print("📁 전체 TravelPlan 수: \(allSavedPlans.count)")

            if let lastPlan = allSavedPlans.last {
                print("🎯 마지막 저장된 계획 (ID: \(lastPlan.id)):")
                print("   📝 여행지: \(lastPlan.travelName)")
                print("   🌍 국가: \(lastPlan.nation)")
                print("   📅 일차별 데이터: \(lastPlan.travelDays.count)개")

                for dayDetail in lastPlan.travelDays {
                    let totalSchedules = dayDetail.schedules.count
                    let totalCoordinates = dayDetail.routeCoordinates.count
                    print("     🗓️ Day \(dayDetail.dayNumber): 일정 \(totalSchedules)개, 좌표 \(totalCoordinates)개")
                    print("        💰 예산: '\(dayDetail.budget)'")
                    print("        🚗 경로: '\(dayDetail.route)'")

                    for schedule in dayDetail.schedules {
                        print("        📋 \(schedule.time) - \(schedule.location)")
                    }

                    for coord in dayDetail.routeCoordinates {
                        print("        📍 \(coord.placeName): (\(coord.latitude), \(coord.longitude))")
                    }
                }
            }
            print("==========================================")

            // 성공 알림 표시
            showSaveSuccessAlert()

        } catch {
            print("❌ Realm 저장 실패: \(error.localizedDescription)")
            showSaveErrorAlert()
        }
    }

    private func createNewTravelPlan(in realm: Realm) -> TravelPlan {
        let newPlan = TravelPlan()
        newPlan.nation = "여행"
        newPlan.travelName = "여행 계획"
        newPlan.startDate = Date()
        newPlan.endDate = Date()

        try! realm.write {
            realm.add(newPlan)
        }

        print("🆕 새로운 TravelPlan 생성: \(newPlan.id)")
        return newPlan
    }

    private func showSaveSuccessAlert() {
        let alert = UIAlertController(
            title: "저장 완료",
            message: "여행 계획이 성공적으로 저장되었습니다!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func showSaveErrorAlert() {
        let alert = UIAlertController(
            title: "저장 실패",
            message: "여행 계획 저장에 실패했습니다. 다시 시도해주세요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func selectDay(_ selectedButton: DayButton) {
        // 현재 일차의 데이터 저장 (검색된 장소들도 포함)
        saveCurrentDayData()

        // 버튼 상태 업데이트
        [day1Button, day2Button, day3Button].forEach { $0.isSelected = false }
        selectedButton.isSelected = true

        // 새로운 일차로 변경
        currentDay = selectedButton.dayNumber

        // 선택된 일차의 데이터 불러오기
        loadDayData(day: currentDay)

        // 선택된 일차의 검색된 장소들을 ViewModel에서 가져와서 MapManager에 표시
        let dayData = viewModel.getDayData(for: currentDay)
        mapManager.clearAllSearchResults()
        if !dayData.searchedPlaces.isEmpty {
            mapManager.displaySearchResults(places: dayData.searchedPlaces)
        }
    }

    private func saveCurrentDayData() {
        let currentData = DayData(
            budget: budgetTextField.text ?? "",
            route: routeSearchBar.text ?? "",
            scheduleItems: getCurrentScheduleItems()
        )
        dayDataStorage[currentDay] = currentData

        // ViewModel에도 현재 일차의 예산과 경로 업데이트
        viewModel.updateBudget(budgetTextField.text ?? "", forDay: currentDay)
        viewModel.updateRoute(routeSearchBar.text ?? "", forDay: currentDay)

        // 현재 검색된 장소들도 ViewModel에 저장
        viewModel.updateSearchedPlaces(currentSearchedPlaces, forDay: currentDay)
    }

    private func loadDayData(day: Int) {
        // ViewModel에서 일차 데이터 가져오기
        let dayData = viewModel.getDayData(for: day)

        // UI 업데이트는 ViewModel의 currentDayData 옵저버블이 처리함
        print("📅 Day \(day) 데이터 로드 요청")
    }

    private func getCurrentScheduleItems() -> [ScheduleItem] {
        return viewModel.getDayData(for: currentDay).scheduleItems
    }

    // MARK: - UI Update Methods
    private func updateScheduleUI(items: [ScheduleItem]) {
        // 기존 스케줄 아이템들 제거
        scheduleStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 새로운 스케줄 아이템들 추가 (인덱스와 함께)
        items.enumerated().forEach { index, item in
            let scheduleView = createScheduleItemView(item: item, index: index)
            scheduleStackView.addArrangedSubview(scheduleView)
        }

        print("🔄 Schedule UI 업데이트: \(items.count)개 일정")
    }

    private func updateDayUI(dayData: PlanDetailViewModel.DayData) {
        // 텍스트 필드 업데이트 (ViewModel 데이터 기준)
        budgetTextField.text = dayData.budget
        routeSearchBar.text = dayData.route

        print("🔄 Day UI 업데이트: Day \(viewModel.getCurrentDay())")
        print("   💰 예산: '\(dayData.budget)'")
        print("   🚗 경로: '\(dayData.route)'")
        print("   📋 일정: \(dayData.scheduleItems.count)개")
    }
}

extension TravelPlanDetailViewController: DesiginProtocolBind {
    func bind() {
        // 시간 피커 값 변경 감지
        timePicker.rx.date
            .map { date in
                let formatter = DateFormatter()
                formatter.dateFormat = "a h:mm"
                formatter.locale = Locale(identifier: "ko_KR")
                return formatter.string(from: date)
            }
            .bind(to: timeTextField.rx.text)
            .disposed(by: disposeBag)

        // 일정 추가 버튼은 ViewModel에서 처리됨 (bindViewModel()에서 바인딩)

        // 텍스트필드 입력 감지 (둘 다 입력되어야 버튼 활성화)
        Observable.combineLatest(
            timeTextField.rx.text.orEmpty,
            locationTextField.rx.text.orEmpty
        )
        .map { !$0.isEmpty && !$1.isEmpty }
        .bind(to: addScheduleItemButton.rx.isEnabled)
        .disposed(by: disposeBag)

        // 버튼 활성/비활성 상태에 따른 색상 변경
        Observable.combineLatest(
            timeTextField.rx.text.orEmpty,
            locationTextField.rx.text.orEmpty
        )
        .map { !$0.isEmpty && !$1.isEmpty }
        .map { $0 ? UIColor.buttonDark : UIColor.systemGray4 }
        .bind(to: addScheduleItemButton.rx.backgroundColor)
        .disposed(by: disposeBag)

        // 저장 버튼 - 직접 액션과 ViewModel 바인딩 모두 사용
        saveButton.rx.tap
            .subscribe(onNext: { [weak self] in
                print("💾 저장 버튼 직접 탭 감지!")
                self?.saveAllDataToRealm()
            })
            .disposed(by: disposeBag)

        // 여행 시작하기 버튼 (현재는 숨김 처리)
        startTravelButton.isHidden = true

        // 날짜 버튼들
        [day1Button, day2Button, day3Button].forEach { button in
            button.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.selectDay(button)
                })
                .disposed(by: disposeBag)
        }
    }

    func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [dateStackView, budgetTitleLabel, budgetTextField, budgetDescriptionLabel,
         scheduleTitleLabel, timeTextField, locationTextField, addScheduleItemButton, scheduleDescriptionLabel,
         scheduleStackView, routeTitleLabel, routeSearchBar, routeDescriptionLabel,
         mapView, saveButton, startTravelButton].forEach {
            contentView.addSubview($0)
        }

        [day1Button, day2Button, day3Button].forEach {
            dateStackView.addArrangedSubview($0)
        }
    }

    func configureUI() {
        // Navigation Bar 설정
        navigationItem.title = "여행 계획"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(clearSearchResults)
        )

        // RouteSearchBar 설정
        routeSearchBar.delegate = self

        // 시간 피커 설정
        timeTextField.inputView = timePicker

        // 키보드 툴바 설정
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(timePickerDone))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [flexSpace, doneButton]
        timeTextField.inputAccessoryView = toolbar
    }

    func configureLayout() {
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        dateStackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(80)
        }

        budgetTitleLabel.snp.makeConstraints {
            $0.top.equalTo(dateStackView.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        budgetTextField.snp.makeConstraints {
            $0.top.equalTo(budgetTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        budgetDescriptionLabel.snp.makeConstraints {
            $0.top.equalTo(budgetTextField.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        scheduleTitleLabel.snp.makeConstraints {
            $0.top.equalTo(budgetDescriptionLabel.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        timeTextField.snp.makeConstraints {
            $0.top.equalTo(scheduleTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        locationTextField.snp.makeConstraints {
            $0.top.equalTo(timeTextField.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        addScheduleItemButton.snp.makeConstraints {
            $0.top.equalTo(locationTextField.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        scheduleDescriptionLabel.snp.makeConstraints {
            $0.top.equalTo(addScheduleItemButton.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        scheduleStackView.snp.makeConstraints {
            $0.top.equalTo(scheduleDescriptionLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        routeTitleLabel.snp.makeConstraints {
            $0.top.equalTo(scheduleStackView.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        routeSearchBar.snp.makeConstraints {
            $0.top.equalTo(routeTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        routeDescriptionLabel.snp.makeConstraints {
            $0.top.equalTo(routeSearchBar.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        mapView.snp.makeConstraints {
            $0.top.equalTo(routeDescriptionLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(200)
        }

        saveButton.snp.makeConstraints {
            $0.top.equalTo(mapView.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(50)
            $0.bottom.equalToSuperview().offset(-30) // ScrollView content 영역 설정
        }

        // startTravelButton은 숨겨져 있으므로 제약조건 제거
        startTravelButton.snp.makeConstraints {
            $0.top.equalTo(saveButton.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(0) // 높이를 0으로 설정
        }
    }
}

// MARK: - MapSearchDelegate
extension TravelPlanDetailViewController: MapSearchDelegate {
    func didSelectRoute(_ route: String, coordinates: [CLLocationCoordinate2D]) {
        routeSearchBar.text = route
        showRouteOnMap(coordinates: coordinates)
    }
    
    private func showRouteOnMap(coordinates: [CLLocationCoordinate2D]) {
        mapManager.showRouteOnMap(coordinates: coordinates)
    }

    // MARK: - ViewModel Binding
    private func bindViewModel() {
        let searchQuery = routeSearchBar.rx.text.orEmpty
            .filter { !$0.isEmpty }
            .distinctUntilChanged()

        let input = PlanDetailViewModel.Input(
            budgetText: budgetTextField.rx.text.orEmpty.asObservable(),
            routeText: routeSearchBar.rx.text.orEmpty.asObservable(),
            timeText: timeTextField.rx.text.orEmpty.asObservable(),
            locationText: locationTextField.rx.text.orEmpty.asObservable(),
            addScheduleButtonTapped: addScheduleItemButton.rx.tap.asObservable(),
            dayButtonTapped: Observable.merge(
                day1Button.rx.tap.map { 1 },
                day2Button.rx.tap.map { 2 },
                day3Button.rx.tap.map { 3 }
            ),
            saveButtonTapped: Observable.never(), // 사용하지 않음
            searchQuery: searchQuery
        )

        let output = viewModel.transform(input: input)

        // 검색 결과를 MapManager로 전달
        output.searchResults
            .subscribe(onNext: { [weak self] places in
                self?.mapManager.displaySearchResults(places: places)
            })
            .disposed(by: disposeBag)

        // 기타 바인딩들
        output.isAddScheduleEnabled
            .bind(to: addScheduleItemButton.rx.isEnabled)
            .disposed(by: disposeBag)

        output.addScheduleButtonColor
            .bind(to: addScheduleItemButton.rx.backgroundColor)
            .disposed(by: disposeBag)

        // 일정 아이템 변화 감지 및 UI 업데이트
        output.scheduleItems
            .subscribe(onNext: { [weak self] items in
                self?.updateScheduleUI(items: items)
            })
            .disposed(by: disposeBag)

        // 일정 추가 성공 시 입력 필드 초기화
        input.addScheduleButtonTapped
            .subscribe(onNext: { [weak self] in
                self?.timeTextField.text = ""
                self?.locationTextField.text = ""
                print("✅ 입력 필드 초기화 완료")
            })
            .disposed(by: disposeBag)

        // 현재 일차 데이터 변화 감지
        output.currentDayData
            .subscribe(onNext: { [weak self] dayData in
                self?.updateDayUI(dayData: dayData)
            })
            .disposed(by: disposeBag)

        // navigateBack은 사용하지 않음 - 저장 후 수동으로 화면 제어

        // 저장 버튼은 위의 직접 액션으로 처리됨
    }
}

// MARK: - MapMangerDelegate
extension TravelPlanDetailViewController: MapMangerDelegate {
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
        currentSearchedPlaces = places

        // ViewModel에 검색된 장소들 업데이트 (현재 일차에 대해)
        viewModel.updateSearchedPlaces(places, forDay: currentDay)

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

// MARK: - UISearchBarDelegate
extension TravelPlanDetailViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - MapSearch Delegate Protocol
protocol MapSearchDelegate: AnyObject {
    func didSelectRoute(_ route: String, coordinates: [CLLocationCoordinate2D])
}

