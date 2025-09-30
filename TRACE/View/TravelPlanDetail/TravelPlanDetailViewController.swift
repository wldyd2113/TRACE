//
//  TravelPlanDetailViewController.swift
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

    let disposeBag = DisposeBag()
    let mapManager = MapManger()
    let viewModel = PlanDetailViewModel()

    // 검색된 장소들을 저장 (좌표 정보 포함)
    var currentSearchedPlaces: [KakaoPlace] = []

    // MARK: - Data
    var currentDay = 1
    var totalDays = 3 // 기본값, Realm에서 계산하여 업데이트
    var startDate: Date?
    var endDate: Date?
    var selectedDayIndex = 0 // 현재 선택된 일차 인덱스 (0-based)

    // MARK: - UI Components
    let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }

    let contentView = UIView()

    // 날짜 선택 영역 - CollectionView로 변경
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
        $0.applyDescriptionStyle(text: "예상 경비를 입력해주세요.")
    }

    // 여행 일정 추가 섹션
    let scheduleTitleLabel = UILabel().then {
        $0.applySectionTitleStyle(text: "여행 일정 추가")
    }

    // 시간 입력 필드
    let timeTextField = UITextField().then {
        $0.applyTravelStyle(placeholder: "시간 선택")
        $0.isUserInteractionEnabled = true
    }

    // 여행지 입력 필드
    let locationTextField = UITextField().then {
        $0.applyTravelStyle(placeholder: "여행지 입력")
    }

    // 일정 추가 버튼
    let addScheduleItemButton = UIButton(type: .system).then {
        $0.applyMainActionStyle(title: "일정 추가하기")
        $0.isEnabled = false
        $0.backgroundColor = .systemGray4
    }

    // 시간 피커
    let timePicker = UIDatePicker().then {
        $0.datePickerMode = .time
        $0.preferredDatePickerStyle = .wheels
        $0.locale = Locale(identifier: "ko_KR")
    }

    let scheduleDescriptionLabel = UILabel().then {
        $0.applyDescriptionStyle(text: "각 시간대 일정 추가")
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
        $0.applyDescriptionStyle(text: "여행 경로를 누르면 맵 선택 일정이 나옵니다.")
    }

    // 동적으로 추가될 일정 컨테이너
    let scheduleStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 12
    }

    // 하단 버튼들
    let saveButton = UIButton(type: .system).then {
        $0.applyMainActionStyle(title: "여행 계획 저장하기")
        $0.layer.cornerRadius = 25
        $0.backgroundColor = .darkBlue
        $0.titleLabel?.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 18)
    }

    let startTravelButton = UIButton(type: .system).then {
        $0.applyMainActionStyle(title: "여행 시작하기")
        $0.layer.cornerRadius = 25
    }

    // MapKit 관련 (MapManger에서 관리)
    var mapView: MKMapView {
        return mapManager.mapView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background

        // 여행 계획 데이터 로드 및 일차 계산
        loadTravelPlanAndCalculateDays()

        configureHierarchy()
        configureUI()
        configureLayout()
        bind()

        // ViewModel currentDay 초기 동기화
        viewModel.setCurrentDay(currentDay)

        // 초기 데이터 로드 (1일차)
        loadDayData(day: currentDay)

        // 맵 관리자 설정
        setupMapManager()

        // ViewModel 바인딩
        bindViewModel()
    }

    // MARK: - Travel Plan Loading and Day Calculation
    private func loadTravelPlanAndCalculateDays() {
        do {
            let realm = try Realm()
            let allPlans = realm.objects(TravelPlan.self)

            guard let latestPlan = allPlans.last else {
                print("⚠️ Realm에 저장된 여행 계획이 없습니다. 기본 3일차로 설정됩니다.")
                setupDefaultDays()
                return
            }

            startDate = latestPlan.startDate
            endDate = latestPlan.endDate

            // 시작일과 종료일 사이의 일차 계산
            let calendar = Calendar.current
            let daysDifference = calendar.dateComponents([.day], from: startDate!, to: endDate!).day ?? 0
            totalDays = max(1, daysDifference + 1) // 최소 1일, 당일 여행도 1일로 계산

            print("📅 여행 계획 로드:")
            print("   📍 여행지: \(latestPlan.travelName)")
            print("   🗓️ 시작일: \(DateManager.shared.formatToKoreanString(from: startDate!))")
            print("   🗓️ 종료일: \(DateManager.shared.formatToKoreanString(from: endDate!))")
            print("   📊 총 일차: \(totalDays)일")

            // Navigation title 업데이트
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d"
            let startDateStr = dateFormatter.string(from: startDate!)
            let endDateStr = dateFormatter.string(from: endDate!)
            navigationItem.title = "\(latestPlan.travelName) (\(startDateStr)~\(endDateStr), \(totalDays)일)"

            // CollectionView 리액티브 업데이트
            updateCollectionViewReactively()

        } catch {
            print("❌ Realm 데이터 로드 실패: \(error.localizedDescription)")
            setupDefaultDays()
        }
    }

    private func setupDefaultDays() {
        totalDays = 3
        print("📅 기본 3일차로 설정됨")
        updateCollectionViewReactively()
    }

    func selectDay(at index: Int) {
        // 현재 일차의 데이터 저장 (검색된 장소들도 포함)
        saveCurrentDayData()

        // 선택 상태 업데이트
        let previousIndex = selectedDayIndex
        selectedDayIndex = index
        currentDay = index + 1 // 1-based

        // ViewModel의 currentDay도 동기화
        viewModel.setCurrentDay(currentDay)

        // CollectionView 셀 업데이트
        DispatchQueue.main.async { [weak self] in
            self?.dateCollectionView.reloadItems(at: [
                IndexPath(item: previousIndex, section: 0),
                IndexPath(item: index, section: 0)
            ])
        }

        // 선택된 일차의 데이터 불러오기 (UI 완전 초기화)
        loadDayData(day: currentDay)

        print("📅 일차 선택됨: \(currentDay)일차 (index: \(index))")
        print("🔄 ViewController와 ViewModel currentDay 동기화 완료")
    }

    func saveCurrentDayData() {
        // ViewModel에 현재 일차의 모든 데이터 업데이트
        viewModel.updateBudget(budgetTextField.text ?? "", forDay: currentDay)
        viewModel.updateRoute(routeSearchBar.text ?? "", forDay: currentDay)
        viewModel.updateSearchedPlaces(currentSearchedPlaces, forDay: currentDay)

        // ViewController의 로컬 저장소는 제거하고 ViewModel만 사용
        print("💾 Day \(currentDay) 데이터 저장됨 - ViewModel에만 저장")
    }

    func loadDayData(day: Int) {
        print("📅 Day \(day) 데이터 로드 시작")

        // ViewModel에서 일차 데이터 가져오기
        let dayData = viewModel.getDayData(for: day)

        // UI 완전 초기화 및 업데이트
        DispatchQueue.main.async { [weak self] in
            // 1. 텍스트 필드 완전 초기화 후 새 데이터 설정
            self?.budgetTextField.text = ""
            self?.routeSearchBar.text = ""

            // 약간의 지연 후 새 데이터 설정 (UI 업데이트 보장)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.budgetTextField.text = dayData.budget
                self?.routeSearchBar.text = dayData.route
            }

            // 2. 일정 UI 완전 초기화 후 업데이트
            self?.updateScheduleUI(items: dayData.scheduleItems)

            // 3. 검색된 장소들 완전 초기화 후 업데이트
            self?.currentSearchedPlaces.removeAll()
            self?.mapManager.clearAllSearchResults()

            if !dayData.searchedPlaces.isEmpty {
                self?.currentSearchedPlaces = dayData.searchedPlaces
                self?.mapManager.displaySearchResults(places: dayData.searchedPlaces)
            }

            print("📅 Day \(day) UI 업데이트 완료:")
            print("   💰 예산: '\(dayData.budget.isEmpty ? "빈 값" : dayData.budget)'")
            print("   🚗 경로: '\(dayData.route.isEmpty ? "빈 값" : dayData.route)'")
            print("   📋 일정: \(dayData.scheduleItems.count)개")
            print("   📍 좌표: \(dayData.searchedPlaces.count)개")
        }
    }

    private func getCurrentScheduleItems() -> [ScheduleItem] {
        return viewModel.getDayData(for: currentDay).scheduleItems
    }

}
