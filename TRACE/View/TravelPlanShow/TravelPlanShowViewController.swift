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

    // 검색된 장소들을 저장 (좌표 정보 포함)
    var currentSearchedPlaces: [KakaoPlace] = []

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
        $0.setTitle("수정", for: .normal)
        $0.titleLabel?.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.backgroundColor = .systemBlue
        $0.setTitleColor(.white, for: .normal)
        $0.layer.cornerRadius = 20
        $0.isHidden = false
    }

    let saveButton = UIButton(type: .system).then {
        $0.setTitle("저장", for: .normal)
        $0.titleLabel?.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.backgroundColor = .darkBlue
        $0.setTitleColor(.white, for: .normal)
        $0.layer.cornerRadius = 20
        $0.isHidden = true
    }

    let cancelButton = UIButton(type: .system).then {
        $0.setTitle("취소", for: .normal)
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

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 데이터 새로고침
        if let planId = travelPlanId {
            viewModel.loadTravelPlan(id: planId)
        }
    }
}





