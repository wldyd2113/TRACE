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

class TravelPlanDetailViewController: UIViewController, UINavigationControllerDelegate {

    let disposeBag = DisposeBag()
    let mapManager = MapManager()
    let viewModel = PlanDetailViewModel()

    // 검색된 장소들을 저장 (좌표 정보 포함)
    var currentSearchedPlaces: [KakaoPlace] = []
    var currentGooglePlaces: [PlaceResult] = []

    // MARK: - Data
    var currentDay = 1
    var totalDays = 3 // 기본값, Realm에서 계산하여 업데이트
    var startDate: Date?
    var endDate: Date?
    var selectedDayIndex = 0 // 현재 선택된 일차 인덱스 (0-based)
    var shouldPreventAutoSave = false // 자동 저장 방지 플래그

    // 국내/해외 구분
    var countryType: String = "국내" // 기본값

    // 검색 구독 관리
    private var searchDisposeBag = DisposeBag()

    // 선택된 장소 저장
    var selectedPlace: KakaoPlace?

    // 임시 여행 정보 (저장되지 않은 상태)
    var tempTravelInfo: (country: String, destination: String, startDate: Date, endDate: Date)?

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
        $0.applySectionTitleStyle(text: NSLocalizedString("estimated_budget", comment: "Estimated budget"))
    }

    let budgetTextField = UITextField().then {
        $0.applyTravelStyle(placeholder: NSLocalizedString("estimated_budget", comment: "Estimated budget"), fontSize: 16)
    }

    let budgetDescriptionLabel = UILabel().then {
        $0.applyDescriptionStyle(text: NSLocalizedString("estimated_budget", comment: "Estimated budget description"))
    }

    // 여행 일정 추가 섹션
    let scheduleTitleLabel = UILabel().then {
        $0.applySectionTitleStyle(text: NSLocalizedString("add_travel_schedule", comment: "Add travel schedule"))
    }

    // 시간 입력 필드
    let timeTextField = UITextField().then {
        $0.applyTravelStyle(placeholder: NSLocalizedString("time_selection", comment: "Time selection"))
        $0.isUserInteractionEnabled = true
    }

    // 여행지 검색 버튼
    let locationSearchButton = UIButton(type: .system).then {
        $0.setTitle(NSLocalizedString("search_destination", comment: "Search destination"), for: .normal)
        $0.titleLabel?.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.backgroundColor = .systemGray6
        $0.setTitleColor(.label, for: .normal)
        $0.layer.cornerRadius = 8
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.systemGray4.cgColor
        $0.contentHorizontalAlignment = .left
        $0.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
    }

    // 선택된 장소 표시 라벨
    let selectedLocationLabel = UILabel().then {
        $0.text = NSLocalizedString("select_place", comment: "Select place")
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 14)
        $0.textColor = .secondaryLabel
        $0.isHidden = true
    }

    // 일정 추가 버튼
    let addScheduleItemButton = UIButton(type: .system).then {
        $0.applyMainActionStyle(title: NSLocalizedString("add_schedule", comment: "Add schedule"))
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
        $0.applyDescriptionStyle(text: NSLocalizedString("each_time_schedule", comment: "Add schedule for each time"))
    }


    // 동적으로 추가될 일정 컨테이너
    let scheduleStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 12
    }

    // 하단 버튼들
    let saveButton = UIButton(type: .system).then {
        $0.applyMainActionStyle(title: NSLocalizedString("save_travel_plan", comment: "Save travel plan"))
        $0.layer.cornerRadius = 25
        $0.backgroundColor = .skyBlue
        $0.titleLabel?.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 18)
    }

    let startTravelButton = UIButton(type: .system).then {
        $0.applyMainActionStyle(title: NSLocalizedString("start_travel", comment: "Start travel"))
        $0.layer.cornerRadius = 25
    }

    // MapKit 관련 (MapManager에서 관리)
    var mapView: MKMapView {
        return mapManager.mapView
    }

    deinit {
        print(" TravelPlanDetailViewController deinit - 자동 저장 방지 활성화")
        shouldPreventAutoSave = true
        viewModel.shouldPreventAutoSave = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background

        print("🏁 TravelPlanDetail viewDidLoad 시작 - 현재 countryType: \(countryType)")

        // 여행 계획 데이터 로드 및 일차 계산
        loadTravelPlanAndCalculateDays()

        configureHierarchy()
        configureUI()
        configureLayout()
        bind()

        // ViewModel currentDay 초기 동기화
        viewModel.setCurrentDay(currentDay)

        // ViewModel countryType 설정
        viewModel.setCountryType(countryType)

        // 초기 데이터 로드 (1일차)
        loadDayData(day: currentDay)

        // 맵 관리자 설정
        setupMapManager()

        // 초기 검색 설정 (기본값: 국내)
        setupLocationSearch()

        // 키보드 해제 설정
        setupKeyboardDismissal()

        // ViewModel 바인딩
        bindViewModel()

        // 커스텀 뒤로가기 버튼 설정
        setupCustomBackButton()

        // 네비게이션 컨트롤러 델리게이트 설정
        navigationController?.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print(" TravelPlanDetail viewWillAppear - 현재 countryType: \(countryType)")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print(" TravelPlanDetail: viewWillDisappear")

        // 자동 저장 방지 플래그 확인
        if shouldPreventAutoSave {
            print(" viewWillDisappear: 자동 저장 방지로 인해 데이터 저장 생략")
            return
        }

        // 정상적인 경우에만 현재 일차 데이터 저장
        saveCurrentDayData()
    }

    // MARK: - Travel Plan Loading and Day Calculation
    private func loadTravelPlanAndCalculateDays() {
        // 임시 여행 정보가 있는 경우 (아직 저장되지 않은 새로운 여행 계획)
        if let tempInfo = tempTravelInfo {
            print(" 임시 여행 정보 사용:")
            print("    여행지: \(tempInfo.destination)")
            print("   시작일: \(DateManager.shared.formatToKoreanString(from: tempInfo.startDate))")
            print("    종료일: \(DateManager.shared.formatToKoreanString(from: tempInfo.endDate))")

            startDate = tempInfo.startDate
            endDate = tempInfo.endDate

            // 시작일과 종료일 사이의 일차 계산
            let calendar = Calendar.current
            let daysDifference = calendar.dateComponents([.day], from: startDate!, to: endDate!).day ?? 0
            totalDays = max(1, daysDifference + 1) // 최소 1일, 당일 여행도 1일로 계산

            // Navigation title 업데이트
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d"
            let startDateStr = dateFormatter.string(from: startDate!)
            let endDateStr = dateFormatter.string(from: endDate!)
            navigationItem.title = "\(tempInfo.destination) (\(startDateStr)~\(endDateStr), \(totalDays)일)"

            print("    총 일차: \(totalDays)일")

            // CollectionView 리액티브 업데이트
            updateCollectionViewReactively()
            return
        }

        // 기존 저장된 여행 계획 로드
        do {
            let realm = try Realm()
            let allPlans = realm.objects(TravelPlan.self)

            guard let latestPlan = allPlans.last else {
                print(" Realm에 저장된 여행 계획이 없습니다. 기본 3일차로 설정됩니다.")
                setupDefaultDays()
                return
            }

            startDate = latestPlan.startDate
            endDate = latestPlan.endDate

            // 시작일과 종료일 사이의 일차 계산
            let calendar = Calendar.current
            let daysDifference = calendar.dateComponents([.day], from: startDate!, to: endDate!).day ?? 0
            totalDays = max(1, daysDifference + 1) // 최소 1일, 당일 여행도 1일로 계산

            print(" 저장된 여행 계획 로드:")
            print("    여행지: \(latestPlan.travelName)")
            print("    국가: \(latestPlan.nation)")
            print("    시작일: \(DateManager.shared.formatToKoreanString(from: startDate!))")
            print("    종료일: \(DateManager.shared.formatToKoreanString(from: endDate!))")
            print("    총 일차: \(totalDays)일")

            // countryType 설정 (해외면 Google API, 국내면 Kakao API 사용)
            let planCountryType = latestPlan.nation == "해외" ? "해외" : "국내"
            setCountryType(planCountryType)
            print(" 저장된 여행 계획에서 countryType 설정됨: \(planCountryType)")

            // Navigation title 업데이트
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "M/d"
            let startDateStr = dateFormatter.string(from: startDate!)
            let endDateStr = dateFormatter.string(from: endDate!)
            navigationItem.title = "\(latestPlan.travelName) (\(startDateStr)~\(endDateStr), \(totalDays)일)"

            // CollectionView 리액티브 업데이트
            updateCollectionViewReactively()

        } catch {
            print(" Realm 데이터 로드 실패: \(error.localizedDescription)")
            setupDefaultDays()
        }
    }

    private func setupDefaultDays() {
        totalDays = 3
        print(" 기본 3일차로 설정됨")
        updateCollectionViewReactively()
    }

    func selectDay(at index: Int) {
        // 자동 저장 방지 플래그 확인 후 저장
        if !shouldPreventAutoSave {
            // 현재 일차의 데이터 저장 (검색된 장소들도 포함)
            saveCurrentDayData()
        } else {
            print(" 일차 선택 시 자동 저장 방지됨")
        }

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

        print(" 일차 선택됨: \(currentDay)일차 (index: \(index))")
        print(" ViewController와 ViewModel currentDay 동기화 완료")
    }

    func saveCurrentDayData() {
        // 자동 저장 방지 플래그 확인
        if shouldPreventAutoSave {
            print(" 자동 저장이 방지되어 데이터 저장을 건너뜁니다")
            return
        }

        // ViewModel에 현재 일차의 모든 데이터 업데이트
        viewModel.updateBudget(budgetTextField.text ?? "", forDay: currentDay)
        viewModel.updateSearchedPlaces(currentSearchedPlaces, forDay: currentDay)

        // ViewController의 로컬 저장소는 제거하고 ViewModel만 사용
        print("💾 Day \(currentDay) 데이터 저장됨 - ViewModel에만 저장")
    }

    func loadDayData(day: Int) {
        print(" Day \(day) 데이터 로드 시작")

        // ViewModel에서 일차 데이터 가져오기
        let dayData = viewModel.getDayData(for: day)

        // UI 완전 초기화 및 업데이트
        DispatchQueue.main.async { [weak self] in
            // 1. 텍스트 필드 완전 초기화 후 새 데이터 설정
            self?.budgetTextField.text = ""

            // 약간의 지연 후 새 데이터 설정 (UI 업데이트 보장)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.budgetTextField.text = dayData.budget
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

            print(" Day \(day) UI 업데이트 완료:")
            print("    예산: '\(dayData.budget.isEmpty ? "빈 값" : dayData.budget)'")
            print("    경로: '\(dayData.route.isEmpty ? "빈 값" : dayData.route)'")
            print("    일정: \(dayData.scheduleItems.count)개")
            print("    좌표: \(dayData.searchedPlaces.count)개")
        }
    }

    private func getCurrentScheduleItems() -> [ScheduleItem] {
        return viewModel.getDayData(for: currentDay).scheduleItems
    }


    func navigateToTravelPlanMain() {
        // TravelPlanMainViewController로 이동
        if let navigationController = navigationController {
            for viewController in navigationController.viewControllers {
                if viewController is TravelPlanMainViewController {
                    navigationController.popToViewController(viewController, animated: true)
                    return
                }
            }
        }

        // 만약 스택에 없다면 새로 생성해서 이동
        navigationController?.popToRootViewController(animated: true)
    }

    // MARK: - Public Methods
    func setCountryType(_ type: String) {
        countryType = type
        viewModel.setCountryType(type)
        print(" 여행 타입 설정: \(type)")
        setupLocationSearch()
    }

    // MARK: - Location Search Methods
    private func setupLocationSearch() {
        print("🔧 모달 검색 사용으로 기존 검색 로직 비활성화")
        // 모달 검색을 사용하므로 기존 자동 검색 로직 제거
    }

    private func searchLocation(query: String) {
        print(" 검색 시작 - 쿼리: \(query), 국가타입: \(countryType)")

        if countryType == "국내" {
            print(" 카카오 API 사용")
            searchWithKakao(query: query)
        } else {
            print(" 구글 API 사용")
            searchWithGoogle(query: query)
        }
    }

    private func searchWithKakao(query: String) {
        print(" KAKAO API 호출 시작: \(query)")
        print(" ===== 카카오 검색 실행 중 =====")

        NetworkManger.shared.searchKakaoPlaces(query: query)
            .subscribe(onNext: { [weak self] result in
                print(" 카카오 API 응답 받음")
                switch result {
                case .success(let response):
                    self?.currentSearchedPlaces = response.documents
                    self?.mapManager.displaySearchResults(places: response.documents)
                    print(" 카카오 검색 결과: \(response.documents.count)개")

                case .failure(let error):
                    print(" 카카오 검색 실패: \(error)")
                }
            })
            .disposed(by: disposeBag)
    }

    private func searchWithGoogle(query: String) {
        print(" GOOGLE API 호출 시작: \(query)")
        print(" ===== 구글 검색 실행 중 =====")

        NetworkManger.shared.searchGooglePlaces(query: query)
            .subscribe(onNext: { [weak self] result in
                print(" Google API 응답 받음")
                switch result {
                case .success(let response):
                    print(" Google Places 응답 성공: \(response.results.count)개 결과")
                    print(" 첫 번째 결과: \(response.results.first?.name ?? "없음")")

                    // PlaceResult를 KakaoPlace 형태로 변환
                    let kakaoPlaces = response.results.map { place in
                        KakaoPlace(
                            id: place.placeId,
                            placeName: place.name,
                            categoryName: place.types.first ?? "",
                            categoryGroupCode: "",
                            categoryGroupName: "",
                            phone: "",
                            addressName: place.formattedAddress ?? "",
                            roadAddressName: place.formattedAddress ?? "",
                            x: String(place.geometry.location.lng),
                            y: String(place.geometry.location.lat),
                            placeUrl: "",
                            distance: ""
                        )
                    }

                    self?.currentSearchedPlaces = kakaoPlaces
                    self?.mapManager.displaySearchResults(places: kakaoPlaces)
                    print(" Google Places 검색 결과: \(kakaoPlaces.count)개")

                case .failure(let error):
                    print(" Google Places 검색 실패: \(error)")
                    print(" 오류 상세: \(error.localizedDescription)")
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Search Modal Methods
    func presentSearchModal() {
        let searchVC = TravelSearchViewController()
        searchVC.delegate = self
        searchVC.countryType = countryType
        searchVC.modalPresentationStyle = .overFullScreen
        searchVC.modalTransitionStyle = .crossDissolve
        present(searchVC, animated: true)
    }
}

// MARK: - TravelSearchDelegate
extension TravelPlanDetailViewController: TravelSearchDelegate {
    func didSelectPlace(_ place: KakaoPlace) {
        selectedPlace = place
        selectedLocationLabel.text = place.placeName
        selectedLocationLabel.textColor = .label
        selectedLocationLabel.isHidden = false

        // 검색 버튼 텍스트 업데이트
        locationSearchButton.setTitle(place.placeName, for: .normal)
        locationSearchButton.setTitleColor(.label, for: .normal)

        print(" 장소 선택됨: \(place.placeName)")

        // 중복 검사 후 장소 누적 추가
        if !currentSearchedPlaces.contains(where: { $0.placeName == place.placeName }) {
            currentSearchedPlaces.append(place)
            print(" 새 장소 추가됨: \(place.placeName) (총 \(currentSearchedPlaces.count)개)")
        } else {
            print(" 이미 존재하는 장소: \(place.placeName)")
        }

        // 모든 누적된 장소들을 지도에 표시 (POI + 루트)
        mapManager.displaySearchResults(places: currentSearchedPlaces)
        print(" 지도에 \(currentSearchedPlaces.count)개 POI 표시 및 루트 그리기")
    }
}

// MARK: - Custom Back Button Methods
extension TravelPlanDetailViewController {
    private func setupCustomBackButton() {
        // 커스텀 뒤로가기 버튼 생성
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem = backButton

        // 네비게이션 바의 기본 뒤로가기 버튼을 감지하기 위한 설정
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    @objc private func backButtonTapped() {
        showCancelAlert()
    }

    private func showCancelAlert() {
        let alert = UIAlertController(
            title: NSLocalizedString("cancel_edit", comment: "Cancel edit"),
            message: NSLocalizedString("cancel_edit_message", comment: "Cancel edit message"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("continue_editing", comment: "Continue editing"), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("exit", comment: "Exit"), style: .destructive) { [weak self] _ in
            // 자동 저장 방지 활성화
            self?.shouldPreventAutoSave = true
            self?.viewModel.shouldPreventAutoSave = true
            print(" TravelPlanDetail: 사용자가 나가기 선택 - 자동 저장 방지")
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension TravelPlanDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // 스와이프 뒤로가기 제스처가 시작될 때 확인 알림 표시
        if gestureRecognizer == navigationController?.interactivePopGestureRecognizer {
            print(" 스와이프 뒤로가기 감지 - 확인 알림 표시")
            showCancelAlert()
            return false // 제스처를 취소하고 알림을 먼저 표시
        }
        return true
    }
}

// MARK: - UINavigationControllerDelegate
extension TravelPlanDetailViewController {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // TravelPlanDetailViewController에서 다른 화면으로 이동할 때
        if self != viewController {
            print(" TravelPlanDetail: 다른 화면으로 이동 중")

            // 자동 저장 방지 플래그가 설정된 경우 저장하지 않음
            if shouldPreventAutoSave {
                print(" navigationController willShow: 자동 저장 방지로 인해 데이터 저장 생략")
                return
            }

            // 정상적인 네비게이션의 경우에만 저장
            saveCurrentDayData()
        }
    }
}
