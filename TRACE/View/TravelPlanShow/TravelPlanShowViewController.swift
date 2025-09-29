//
//  TravelPlanShowViewController.swift
//  TRACE
//
//  Created by 차지용 on 9/29/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Then
import MapKit
import CoreLocation
import RealmSwift

class TravelPlanShowViewController: UIViewController {

    let disposeBag = DisposeBag()
    let mapManager = MapManger()
    let viewModel = PlanShowViewModel()

    // MARK: - Data
    var travelPlanId: String?
    var currentDay = 1
    var totalDays = 1
    var selectedDayIndex = 0
    var isEditMode = false

    // MARK: - UI Components
    let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }

    let contentView = UIView()

    // 날짜 선택 영역
    lazy var dateCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(TravelDayCell.self, forCellWithReuseIdentifier: "TravelDayCell")
        collectionView.delegate = self
        collectionView.dataSource = self

        return collectionView
    }()

    // 예상 경비 섹션
    let budgetTitleLabel = UILabel().then {
        $0.applySectionTitleStyle(text: "예상 경비")
    }

    let budgetTextField = UITextField().then {
        $0.applyTravelStyle(placeholder: "예: 20,000원", fontSize: 16)
    }

    let budgetDescriptionLabel = UILabel().then {
        $0.applyDescriptionStyle(text: "예상 경비를 확인하고 수정할 수 있습니다.")
    }

    // 여행 일정 섹션
    let scheduleTitleLabel = UILabel().then {
        $0.applySectionTitleStyle(text: "여행 일정")
    }

    let timeTextField = UITextField().then {
        $0.applyTravelStyle(placeholder: "시간 선택")
        $0.isUserInteractionEnabled = true
    }

    let locationTextField = UITextField().then {
        $0.applyTravelStyle(placeholder: "여행지 입력")
    }

    let addScheduleItemButton = UIButton(type: .system).then {
        $0.applyMainActionStyle(title: "일정 추가하기")
        $0.isEnabled = false
        $0.backgroundColor = .systemGray4
    }

    let timePicker = UIDatePicker().then {
        $0.datePickerMode = .time
        $0.preferredDatePickerStyle = .wheels
        $0.locale = Locale(identifier: "ko_KR")
    }

    let scheduleDescriptionLabel = UILabel().then {
        $0.applyDescriptionStyle(text: "각 시간대 일정을 추가하거나 수정할 수 있습니다.")
    }

    // 여행 경로 섹션
    let routeTitleLabel = UILabel().then {
        $0.applySectionTitleStyle(text: "여행 경로")
    }

    let routeSearchBar = UISearchBar().then {
        $0.placeholder = "예: 서울 -> 부산"
        $0.searchBarStyle = .minimal
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
        $0.searchTextField.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.searchTextField.backgroundColor = .systemGray6
        $0.isUserInteractionEnabled = true
        $0.searchTextField.isUserInteractionEnabled = true
    }

    let routeDescriptionLabel = UILabel().then {
        $0.applyDescriptionStyle(text: "여행 경로를 확인하고 수정할 수 있습니다.")
    }

    // 동적으로 추가될 일정 컨테이너
    let scheduleStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 12
    }

    // 하단 버튼들
    let editButton = UIButton(type: .system).then {
        $0.applyMainActionStyle(title: "수정하기")
        $0.layer.cornerRadius = 25
        $0.backgroundColor = .systemBlue
        $0.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
    }

    let saveButton = UIButton(type: .system).then {
        $0.applyMainActionStyle(title: "저장하기")
        $0.layer.cornerRadius = 25
        $0.backgroundColor = .darkBlue
        $0.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        $0.isHidden = true
    }

    let cancelButton = UIButton(type: .system).then {
        $0.applyMainActionStyle(title: "취소")
        $0.layer.cornerRadius = 25
        $0.backgroundColor = .systemGray
        $0.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        $0.isHidden = true
    }

    // MapKit 관련
    var mapView: MKMapView {
        return mapManager.mapView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background

        configureHierarchy()
        configureUI()
        configureLayout()
        bind()
        bindViewModel()

        // 전달받은 여행 계획 ID로 데이터 로드
        if let planId = travelPlanId {
            viewModel.loadTravelPlan(id: planId)
        }

        // 맵 관리자 설정
        setupMapManager()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 데이터 새로고침
        if let planId = travelPlanId {
            viewModel.loadTravelPlan(id: planId)
        }
    }
}

// MARK: - DesiginProtocolBind Implementation
extension TravelPlanShowViewController: DesiginProtocolBind {
    func bind() {
        // 수정 모드 토글
        editButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.toggleEditMode()
            })
            .disposed(by: disposeBag)

        // 저장 버튼
        saveButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.saveChanges()
            })
            .disposed(by: disposeBag)

        // 취소 버튼
        cancelButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.cancelEdit()
            })
            .disposed(by: disposeBag)

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

        // 일정 추가 버튼
        addScheduleItemButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.addScheduleItem()
            })
            .disposed(by: disposeBag)
    }

    func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [dateCollectionView, budgetTitleLabel, budgetTextField, budgetDescriptionLabel,
         scheduleTitleLabel, timeTextField, locationTextField, addScheduleItemButton, scheduleDescriptionLabel,
         scheduleStackView, routeTitleLabel, routeSearchBar, routeDescriptionLabel,
         mapView, editButton, saveButton, cancelButton].forEach {
            contentView.addSubview($0)
        }
    }

    func configureUI() {
        // Navigation Bar 설정
        navigationItem.title = "여행 계획 보기"
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

        // 초기에는 읽기 전용 모드로 설정
        setReadOnlyMode()
    }

    func configureLayout() {
        // 레이아웃 구성은 TravelPlanDetailViewController와 동일하게 구현
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        dateCollectionView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(60)
        }

        budgetTitleLabel.snp.makeConstraints {
            $0.top.equalTo(dateCollectionView.snp.bottom).offset(30)
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

        editButton.snp.makeConstraints {
            $0.top.equalTo(mapView.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(50)
        }

        saveButton.snp.makeConstraints {
            $0.top.equalTo(mapView.snp.bottom).offset(30)
            $0.leading.equalToSuperview().inset(20)
            $0.trailing.equalTo(contentView.snp.centerX).offset(-6)
            $0.height.equalTo(50)
            $0.bottom.equalToSuperview().offset(-30)
        }

        cancelButton.snp.makeConstraints {
            $0.top.equalTo(mapView.snp.bottom).offset(30)
            $0.leading.equalTo(contentView.snp.centerX).offset(6)
            $0.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(50)
            $0.bottom.equalToSuperview().offset(-30)
        }
    }

    func bindViewModel() {
        guard let planId = travelPlanId else { return }

        let loadPlanSubject = PublishSubject<String>()
        let daySelectedSubject = PublishSubject<Int>()
        let budgetChangedSubject = PublishSubject<String>()
        let routeChangedSubject = PublishSubject<String>()
        let addScheduleSubject = PublishSubject<(time: String, location: String)>()
        let saveChangesSubject = PublishSubject<Void>()

        let input = PlanShowViewModel.Input(
            loadPlan: loadPlanSubject.asObservable(),
            daySelected: daySelectedSubject.asObservable(),
            budgetChanged: budgetChangedSubject.asObservable(),
            routeChanged: routeChangedSubject.asObservable(),
            addSchedule: addScheduleSubject.asObservable(),
            saveChanges: saveChangesSubject.asObservable()
        )

        let output = viewModel.transform(input: input)

        // 여행 계획 데이터 바인딩
        output.travelPlanData
            .subscribe(onNext: { [weak self] planData in
                self?.updateTravelPlanUI(with: planData)
            })
            .disposed(by: disposeBag)

        // 현재 일차 데이터 바인딩
        output.currentDayData
            .subscribe(onNext: { [weak self] dayData in
                self?.updateDayUI(with: dayData)
            })
            .disposed(by: disposeBag)

        // 일정 아이템 바인딩
        output.scheduleItems
            .subscribe(onNext: { [weak self] scheduleItems in
                self?.updateScheduleUI(with: scheduleItems)
            })
            .disposed(by: disposeBag)

        // 저장 결과 바인딩
        output.saveResult
            .subscribe(onNext: { [weak self] success, message in
                self?.showSaveAlert(success: success, message: message)
            })
            .disposed(by: disposeBag)

        // 에러 처리
        output.error
            .subscribe(onNext: { [weak self] errorMessage in
                self?.showErrorAlert(message: errorMessage)
            })
            .disposed(by: disposeBag)

        // 예산 텍스트 필드 변경 감지
        budgetTextField.rx.text.orEmpty
            .skip(1) // 초기값 스킵
            .bind(to: budgetChangedSubject)
            .disposed(by: disposeBag)

        // 경로 검색바 변경 감지
        routeSearchBar.rx.text.orEmpty
            .skip(1) // 초기값 스킵
            .bind(to: routeChangedSubject)
            .disposed(by: disposeBag)

        // 일정 추가 버튼
        addScheduleItemButton.rx.tap
            .withLatestFrom(Observable.combineLatest(
                timeTextField.rx.text.orEmpty,
                locationTextField.rx.text.orEmpty
            ))
            .bind(to: addScheduleSubject)
            .disposed(by: disposeBag)

        // 저장 버튼
        saveButton.rx.tap
            .bind(to: saveChangesSubject)
            .disposed(by: disposeBag)

        // 일차 선택 (CollectionView에서 처리)
        // daySelectedSubject는 selectDay 메서드에서 호출

        // 초기 데이터 로드
        DispatchQueue.main.async {
            loadPlanSubject.onNext(planId)
        }

        // 인스턴스 변수로 저장하여 다른 메서드에서 사용할 수 있도록 함
        self.daySelectedSubject = daySelectedSubject
    }

    // Helper property to store subjects
    private var daySelectedSubject: PublishSubject<Int>?
}

// MARK: - Helper Methods
extension TravelPlanShowViewController {
    @objc func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc func timePickerDone() {
        timeTextField.resignFirstResponder()
    }

    private func toggleEditMode() {
        isEditMode.toggle()

        if isEditMode {
            setEditMode()
        } else {
            setReadOnlyMode()
        }
    }

    private func setReadOnlyMode() {
        budgetTextField.isUserInteractionEnabled = false
        timeTextField.isUserInteractionEnabled = false
        locationTextField.isUserInteractionEnabled = false
        routeSearchBar.isUserInteractionEnabled = false
        addScheduleItemButton.isHidden = true

        editButton.isHidden = false
        saveButton.isHidden = true
        cancelButton.isHidden = true

        editButton.snp.remakeConstraints {
            $0.top.equalTo(mapView.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(50)
            $0.bottom.equalToSuperview().offset(-30)
        }
    }

    private func setEditMode() {
        budgetTextField.isUserInteractionEnabled = true
        timeTextField.isUserInteractionEnabled = true
        locationTextField.isUserInteractionEnabled = true
        routeSearchBar.isUserInteractionEnabled = true
        addScheduleItemButton.isHidden = false

        editButton.isHidden = true
        saveButton.isHidden = false
        cancelButton.isHidden = false
    }

    private func saveChanges() {
        // ViewModel을 통해 변경사항 저장
        print("💾 변경사항 저장")
        setReadOnlyMode()
    }

    private func cancelEdit() {
        // 변경사항 취소하고 원래 데이터로 복원
        print("❌ 편집 취소")
        setReadOnlyMode()
        // 원래 데이터로 UI 복원
    }

    private func addScheduleItem() {
        // 일정 추가 로직
        print("➕ 일정 추가")
    }

    // MARK: - UI Update Methods
    private func updateTravelPlanUI(with planData: PlanShowViewModel.TravelPlanData) {
        DispatchQueue.main.async { [weak self] in
            self?.navigationItem.title = planData.travelName
            self?.totalDays = planData.totalDays

            // CollectionView 업데이트
            self?.dateCollectionView.reloadData()

            print("🔄 여행 계획 UI 업데이트:")
            print("   🏝️ 여행지: \(planData.travelName)")
            print("   🌍 국가: \(planData.nation)")
            print("   📅 기간: \(DateManager.shared.formatToKoreanString(from: planData.startDate)) ~ \(DateManager.shared.formatToKoreanString(from: planData.endDate))")
            print("   📊 총 일차: \(planData.totalDays)일")
        }
    }

    private func updateDayUI(with dayData: PlanShowViewModel.DayData) {
        DispatchQueue.main.async { [weak self] in
            self?.budgetTextField.text = dayData.budget
            self?.routeSearchBar.text = dayData.route

            // 지도에 검색된 장소들 표시
            if !dayData.searchedPlaces.isEmpty {
                self?.mapManager.clearAllSearchResults()
                self?.mapManager.displaySearchResults(places: dayData.searchedPlaces)
            }

            print("🔄 Day \(self?.currentDay ?? 0) UI 업데이트:")
            print("   💰 예산: '\(dayData.budget.isEmpty ? "미설정" : dayData.budget)'")
            print("   🚗 경로: '\(dayData.route.isEmpty ? "미설정" : dayData.route)'")
            print("   📋 일정: \(dayData.scheduleItems.count)개")
            print("   📍 장소: \(dayData.searchedPlaces.count)개")
        }
    }

    private func updateScheduleUI(with scheduleItems: [ScheduleItem]) {
        DispatchQueue.main.async { [weak self] in
            // 기존 스케줄 아이템들 제거
            self?.scheduleStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

            // 새로운 스케줄 아이템들 추가
            scheduleItems.enumerated().forEach { index, item in
                let scheduleView = self?.createScheduleItemView(item: item, index: index)
                if let view = scheduleView {
                    self?.scheduleStackView.addArrangedSubview(view)
                }
            }

            print("🔄 Schedule UI 업데이트: \(scheduleItems.count)개 일정")
        }
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
        deleteButton.tag = index
        deleteButton.addTarget(self, action: #selector(deleteScheduleItem(_:)), for: .touchUpInside)

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

        containerView.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(60)
        }

        return containerView
    }

    @objc private func deleteScheduleItem(_ sender: UIButton) {
        let index = sender.tag
        viewModel.removeScheduleItem(at: index, forDay: currentDay)
        print("🗑️ 일정 삭제 요청: index \(index)")
    }

    private func showSaveAlert(success: Bool, message: String) {
        DispatchQueue.main.async { [weak self] in
            let title = success ? "저장 완료" : "저장 실패"
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            self?.present(alert, animated: true)

            if success {
                self?.setReadOnlyMode()
            }
        }
    }

    private func showErrorAlert(message: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            self?.present(alert, animated: true)
        }
    }

    private func setupMapManager() {
        mapManager.delegate = self
        mapManager.requestInitialLocation()
    }
}

// MARK: - CollectionView DataSource & Delegate
extension TravelPlanShowViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalDays
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TravelDayCell", for: indexPath) as! TravelDayCell
        cell.configure(day: indexPath.item + 1, isSelected: indexPath.item == selectedDayIndex)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedDayIndex = indexPath.item
        currentDay = indexPath.item + 1
        collectionView.reloadData()

        // ViewModel에 일차 선택 알림
        daySelectedSubject?.onNext(currentDay)

        print("📅 \(currentDay)일차 선택됨")
    }
}

// MARK: - UISearchBarDelegate
extension TravelPlanShowViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        // 검색 로직 구현
        print("🔍 경로 검색: \(searchBar.text ?? "")")
    }
}

// MARK: - MapMangerDelegate
extension TravelPlanShowViewController: MapMangerDelegate {
    func mapManagerDidUpdateLocation(_ coordinate: CLLocationCoordinate2D) {
        print("📍 TravelPlanShow: Map updated to location: \(coordinate.latitude), \(coordinate.longitude)")
    }

    func mapManagerDidFailToGetLocation() {
        print("📍 TravelPlanShow: Failed to get location, using default")
    }

    func mapManagerDidSelectPlace(_ place: KakaoPlace) {
        print("📍 TravelPlanShow: Place selected: \(place.placeName)")
    }

    func mapManagerDidUpdateSearchedPlaces(_ places: [KakaoPlace]) {
        print("📍 TravelPlanShow: Searched places updated: \(places.count)개")
    }
}
