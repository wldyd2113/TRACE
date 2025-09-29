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

class TravelPlanDetailViewController: UIViewController {

    private let disposeBag = DisposeBag()
    private let mapManager = MapManger()
    
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
        $0.applyLightActionStyle(title: "일정 저장")
        $0.layer.cornerRadius = 25
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
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
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

    private func addScheduleItem() {
        guard let time = timeTextField.text, !time.isEmpty,
              let location = locationTextField.text, !location.isEmpty else {
            return
        }

        let scheduleItem = ScheduleItem(time: time, location: location)

        // 현재 일차의 데이터에 스케줄 추가
        if dayDataStorage[currentDay] == nil {
            dayDataStorage[currentDay] = DayData()
        }
        dayDataStorage[currentDay]?.scheduleItems.append(scheduleItem)

        let scheduleView = createScheduleItemView(item: scheduleItem)
        scheduleStackView.addArrangedSubview(scheduleView)

        // 입력 필드 초기화
        timeTextField.text = ""
        locationTextField.text = ""
    }

    private func createScheduleItemView(item: ScheduleItem) -> UIView {
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

        // 삭제 버튼 액션 추가
        deleteButton.addTarget(self, action: #selector(deleteScheduleItem(_:)), for: .touchUpInside)
        deleteButton.tag = dayDataStorage[currentDay]?.scheduleItems.count ?? 0

        containerView.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(60)
        }

        return containerView
    }

    @objc private func deleteScheduleItem(_ sender: UIButton) {
        guard let containerView = sender.superview else { return }

        // UI에서 제거
        containerView.removeFromSuperview()

        // 데이터에서도 제거 (현재 구현에서는 UI를 다시 로드하는 방식으로 처리)
        if let currentData = dayDataStorage[currentDay] {
            // 스케줄 아이템을 시간과 장소로 식별해서 제거
            if let timeLabel = containerView.subviews.first(where: { $0 is UILabel }) as? UILabel,
               let locationLabel = containerView.subviews.dropFirst().first(where: { $0 is UILabel }) as? UILabel {

                let timeText = timeLabel.text ?? ""
                let locationText = locationLabel.text ?? ""

                dayDataStorage[currentDay]?.scheduleItems.removeAll { item in
                    item.time == timeText && item.location == locationText
                }
            }
        }
    }

    private func selectDay(_ selectedButton: DayButton) {
        // 현재 일차의 데이터 저장
        saveCurrentDayData()

        // 버튼 상태 업데이트
        [day1Button, day2Button, day3Button].forEach { $0.isSelected = false }
        selectedButton.isSelected = true

        // 새로운 일차로 변경
        currentDay = selectedButton.dayNumber

        // 선택된 일차의 데이터 불러오기
        loadDayData(day: currentDay)
    }

    private func saveCurrentDayData() {
        let currentData = DayData(
            budget: budgetTextField.text ?? "",
            route: routeSearchBar.text ?? "",
            scheduleItems: getCurrentScheduleItems()
        )
        dayDataStorage[currentDay] = currentData
    }

    private func loadDayData(day: Int) {
        let dayData = dayDataStorage[day] ?? DayData()

        // UI 업데이트
        budgetTextField.text = dayData.budget
        routeSearchBar.text = dayData.route

        // 기존 스케줄 아이템들 제거
        scheduleStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 새로운 스케줄 아이템들 추가
        dayData.scheduleItems.forEach { item in
            let scheduleView = createScheduleItemView(item: item)
            scheduleStackView.addArrangedSubview(scheduleView)
        }
    }

    private func getCurrentScheduleItems() -> [ScheduleItem] {
        return dayDataStorage[currentDay]?.scheduleItems ?? []
    }
    
    private func saveTravelPlan() {
        print("여행 계획 저장")
        navigationController?.popViewController(animated: true)
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

        // 일정 추가 버튼
        addScheduleItemButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.addScheduleItem()
            })
            .disposed(by: disposeBag)

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

        // 저장 버튼
        saveButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.saveTravelPlan()
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
        }

        startTravelButton.snp.makeConstraints {
            $0.top.equalTo(saveButton.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(50)
            $0.bottom.equalToSuperview().offset(-30)
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
}

// MARK: - MapMangerDelegate
extension TravelPlanDetailViewController: MapMangerDelegate {
    func mapManagerDidUpdateLocation(_ coordinate: CLLocationCoordinate2D) {
        print("📍 TravelPlanDetail: Map updated to location: \(coordinate.latitude), \(coordinate.longitude)")
    }

    func mapManagerDidFailToGetLocation() {
        print("📍 TravelPlanDetail: Failed to get location, using default")
    }
}

// MARK: - UISearchBarDelegate
extension TravelPlanDetailViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // 검색 시작 시 지도 검색 화면으로 이동
        showMapSearch()
        searchBar.resignFirstResponder()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        showMapSearch()
    }
}

// MARK: - MapSearch Delegate Protocol
protocol MapSearchDelegate: AnyObject {
    func didSelectRoute(_ route: String, coordinates: [CLLocationCoordinate2D])
}

