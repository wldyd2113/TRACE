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
    let mapManager = MapManager()
    let viewModel = PlanShowViewModel()

    // MARK: - Data
    var travelPlanId: String?
    var currentDay = 1
    var totalDays = 1
    var selectedDayIndex = 0
    var isEditMode = false
    var isUpdatingFromViewModel = false // 무한 루프 방지 플래그
    var isUpdatingSearchFromMap = false // 검색 업데이트 무한 루프 방지 플래그

    // 국내/해외 구분 (기본값: 국내)
    internal var countryType: String = "국내"

    // 국내/해외 타입 설정 메서드
    func setCountryType(_ type: String) {
        print("🔄 TravelPlanShow: setCountryType 호출됨")
        print("   • 이전 countryType: '\(countryType)'")
        print("   • 새로운 countryType: '\(type)'")

        countryType = type
        print("✅ TravelPlanShow: countryType 설정 완료 - '\(countryType)'")
    }

    // 검색된 장소들을 저장 (좌표 정보 포함)
    var currentSearchedPlaces: [KakaoPlace] = []
    var currentGooglePlaces: [PlaceResult] = []

    // 선택된 장소 저장
    var selectedPlace: KakaoPlace?

    // Helper property to store subjects
    var daySelectedSubject: PublishSubject<Int>?

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
        collectionView.register(TravelDayCell.self, forCellWithReuseIdentifier: TravelDayCell.identifier)
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

    // 여행 일정 섹션
    let scheduleTitleLabel = UILabel().then {
        $0.applySectionTitleStyle(text: NSLocalizedString("travel_schedule", comment: "Travel schedule"))
    }

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

    let addScheduleItemButton = UIButton(type: .system).then {
        $0.applyMainActionStyle(title: NSLocalizedString("add_schedule", comment: "Add schedule"))
        $0.isEnabled = false
        $0.backgroundColor = .systemGray4
    }

    let timePicker = UIDatePicker().then {
        $0.datePickerMode = .time
        $0.preferredDatePickerStyle = .wheels
        $0.locale = Locale(identifier: "ko_KR")
    }

    let scheduleDescriptionLabel = UILabel().then {
        $0.applyDescriptionStyle(text: NSLocalizedString("each_time_schedule", comment: "Each time schedule description"))
    }


    // 동적으로 추가될 일정 컨테이너
    let scheduleStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 12
    }

    // 하단 버튼들
    let editButton = UIButton(type: .system).then {
        $0.setTitle(NSLocalizedString("edit", comment: "Edit"), for: .normal)
        $0.titleLabel?.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.backgroundColor = .skyBlue
        $0.setTitleColor(.white, for: .normal)
        $0.layer.cornerRadius = 20
        $0.isHidden = false
    }

    let saveButton = UIButton(type: .system).then {
        $0.setTitle(NSLocalizedString("save", comment: "Save"), for: .normal)
        $0.titleLabel?.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.backgroundColor = .skyBlue
        $0.setTitleColor(.white, for: .normal)
        $0.layer.cornerRadius = 20
        $0.isHidden = true
    }

    let cancelButton = UIButton(type: .system).then {
        $0.setTitle(NSLocalizedString("cancel", comment: "Cancel"), for: .normal)
        $0.titleLabel?.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.backgroundColor = .systemGray
        $0.setTitleColor(.white, for: .normal)
        $0.layer.cornerRadius = 20
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

        // 맵 관리자 설정
        setupMapManager()

        // 키보드 해제 설정
        setupKeyboardDismissal()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 데이터 새로고침
        if let planId = travelPlanId {
            viewModel.loadTravelPlan(id: planId)
        }
    }

    // MARK: - Search Modal Methods
    func presentSearchModal() {
        print("🔍 TravelPlanShow: presentSearchModal 호출")
        print("🌍 현재 countryType: '\(countryType)'")

        let searchVC = TravelSearchViewController()
        searchVC.delegate = self
        searchVC.countryType = countryType
        print("🔄 TravelSearchViewController에 countryType 전달: '\(countryType)'")

        searchVC.modalPresentationStyle = .overFullScreen
        searchVC.modalTransitionStyle = .crossDissolve
        present(searchVC, animated: true)
    }
}

// MARK: - TravelSearchDelegate
extension TravelPlanShowViewController: TravelSearchDelegate {
    func didSelectPlace(_ place: KakaoPlace) {
        selectedPlace = place
        selectedLocationLabel.text = place.placeName
        selectedLocationLabel.textColor = .label
        selectedLocationLabel.isHidden = false

        // 검색 버튼 텍스트 업데이트
        locationSearchButton.setTitle(place.placeName, for: .normal)
        locationSearchButton.setTitleColor(.label, for: .normal)

        print("📍 장소 선택됨: \(place.placeName)")

        // 선택된 장소를 지도에 표시 (선택된 장소만)
        currentSearchedPlaces = [place]
        mapManager.displaySearchResults(places: [place])
    }
}





