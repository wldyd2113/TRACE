//
//  TravelTouristViewController.swift
//  TRACE
//
//  Created by 차지용 on 10/27/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Then

class TravelTouristViewController: UIViewController {

    private let disposeBag = DisposeBag()
    private let viewModel = TourisViewModel()

    // MARK: - UI Components
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }

    private let contentView = UIView()

    // 나라 검색 섹션
    private let countrySearchTitleLabel = UILabel().then {
        $0.applySectionTitleStyle(text: NSLocalizedString("country_search", comment: "Country search"))
    }

    private let countrySearchTextField = UITextField().then {
        $0.applyTravelStyle(placeholder: NSLocalizedString("enter_country_name", comment: "Enter country name"), fontSize: 16)
    }

    private let countryExampleLabel = UILabel().then {
        $0.applyDescriptionStyle(text: NSLocalizedString("country_example", comment: "e.g., Japan, France"))
    }

    // 추천 관광지 섹션
    private let recommendationTitleLabel = UILabel().then {
        $0.applySectionTitleStyle(text: NSLocalizedString("recommended_attractions", comment: "Recommended attractions"))
    }

    // 카테고리 버튼들
    private let categoryStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.distribution = .fillEqually
        $0.spacing = 12
    }

    private let popularButton = UIButton(type: .system).then {
        $0.applyCategoryButtonStyle(title: NSLocalizedString("popular", comment: "Popular"))
    }

    private let scenicButton = UIButton(type: .system).then {
        $0.applyCategoryButtonStyle(title: NSLocalizedString("scenic", comment: "Scenic"))
    }

    private let historicalButton = UIButton(type: .system).then {
        $0.applyCategoryButtonStyle(title: NSLocalizedString("historical", comment: "Historical"))
    }

    // 관광지 컬렉션 뷰
    private lazy var attractionsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)

        // 셀 크기를 더 크게 설정
        let screenWidth = UIScreen.main.bounds.width
        let cellWidth = (screenWidth - 60) / 2 // 양쪽 여백(40) + 중간 간격(12) + 추가 여백(8)
        layout.itemSize = CGSize(width: cellWidth, height: 280)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(TouristAttractionCell.self, forCellWithReuseIdentifier: "TouristAttractionCell")

        return collectionView
    }()

    // ViewModel Output
    private var output: TourisViewModel.Output!

    // 선택된 카테고리 (UI 상태만)
    private var selectedCategory: TouristCategory = .popular

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background

        configureHierarchy()
        configureUI()
        configureLayout()
        bindViewModel()
        bind()
    }
}

// MARK: - Data Models
enum TouristCategory: String, CaseIterable {
    case popular = "popular"
    case scenic = "scenic"
    case historical = "historical"

    var localizedTitle: String {
        switch self {
        case .popular:
            return NSLocalizedString("popular", comment: "Popular")
        case .scenic:
            return NSLocalizedString("scenic", comment: "Scenic")
        case .historical:
            return NSLocalizedString("historical", comment: "Historical")
        }
    }
}

struct TouristAttraction {
    let id: String
    let name: String
    let country: String
    let category: TouristCategory
    let imageURL: String?
    let imageURLs: [String]?  // 여러 이미지 URL
    let description: String
    let latitude: Double
    let longitude: Double
}

extension TravelTouristViewController: DesiginProtocolBind {

    func bindViewModel() {
        // Input 생성
        let searchTextInput = countrySearchTextField.rx.text.orEmpty.asObservable()

        let categorySelectionInput = Observable.merge(
            popularButton.rx.tap.map { TouristCategory.popular },
            scenicButton.rx.tap.map { TouristCategory.scenic },
            historicalButton.rx.tap.map { TouristCategory.historical }
        ).startWith(.popular)

        let attractionSelectionInput = attractionsCollectionView.rx.itemSelected.asObservable()

        let input = TourisViewModel.Input(
            searchText: searchTextInput,
            categorySelection: categorySelectionInput,
            attractionSelection: attractionSelectionInput
        )

        // ViewModel과 바인딩
        output = viewModel.transform(input: input)

        // Output 구독
        output.filteredAttractions
            .bind(to: attractionsCollectionView.rx.items(cellIdentifier: "TouristAttractionCell", cellType: TouristAttractionCell.self)) { index, attraction, cell in
                cell.configure(with: attraction)
            }
            .disposed(by: disposeBag)

        output.errorMessage
            .subscribe(onNext: { [weak self] message in
                self?.showErrorAlert(message: message)
            })
            .disposed(by: disposeBag)

        output.selectedAttraction
            .subscribe(onNext: { [weak self] attraction in
                self?.navigateToDetail(attraction)
            })
            .disposed(by: disposeBag)

        // 카테고리 선택 UI 업데이트
        categorySelectionInput
            .subscribe(onNext: { [weak self] category in
                self?.selectedCategory = category
                self?.updateCategoryButtons()
            })
            .disposed(by: disposeBag)
    }

    func bind() {
        // UI 전용 바인딩 (현재 추가 바인딩 없음)
    }

    func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // 카테고리 버튼들을 스택뷰에 추가
        [popularButton, scenicButton, historicalButton].forEach {
            categoryStackView.addArrangedSubview($0)
        }

        [countrySearchTitleLabel, countrySearchTextField, countryExampleLabel,
         recommendationTitleLabel, categoryStackView, attractionsCollectionView].forEach {
            contentView.addSubview($0)
        }
    }

    func configureUI() {
        navigationItem.title = NSLocalizedString("tourist_recommendation", comment: "Tourist recommendation")

        updateCategoryButtons()
    }

    func configureLayout() {
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        countrySearchTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        countrySearchTextField.snp.makeConstraints {
            $0.top.equalTo(countrySearchTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        countryExampleLabel.snp.makeConstraints {
            $0.top.equalTo(countrySearchTextField.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        recommendationTitleLabel.snp.makeConstraints {
            $0.top.equalTo(countryExampleLabel.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        categoryStackView.snp.makeConstraints {
            $0.top.equalTo(recommendationTitleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        attractionsCollectionView.snp.makeConstraints {
            $0.top.equalTo(categoryStackView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.greaterThanOrEqualTo(500)
            $0.bottom.equalToSuperview().offset(-20)
        }
    }
}

// MARK: - Helper Methods (UI Only)
extension TravelTouristViewController {

    private func updateCategoryButtons() {
        [popularButton, scenicButton, historicalButton].forEach { button in
            button.backgroundColor = .systemGray6
            button.setTitleColor(.label, for: .normal)
        }

        let selectedButton: UIButton
        switch selectedCategory {
        case .popular:
            selectedButton = popularButton
        case .scenic:
            selectedButton = scenicButton
        case .historical:
            selectedButton = historicalButton
        }

        selectedButton.backgroundColor = .skyBlue
        selectedButton.setTitleColor(.white, for: .normal)
    }

    private func showErrorAlert(message: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(
                title: NSLocalizedString("error", comment: "Error"),
                message: message,
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: "OK"), style: .default))

            self?.present(alert, animated: true)
        }
    }

    private func navigateToDetail(_ attraction: TouristAttraction) {
        let detailVC = TravelTouristDetailViewController(attraction: attraction)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    private func showAttractionInfoAlert(_ attraction: TouristAttraction) {
        let alert = UIAlertController(title: attraction.name, message: nil, preferredStyle: .actionSheet)

        let infoMessage = """
        🌍 \(NSLocalizedString("country", comment: "Country")): \(attraction.country)
        🏷️ \(NSLocalizedString("category", comment: "Category")): \(attraction.category.localizedTitle)
        📍 \(NSLocalizedString("location", comment: "Location")): \(attraction.latitude), \(attraction.longitude)
        📝 \(NSLocalizedString("description", comment: "Description")): \(attraction.description)
        """

        alert.message = infoMessage

        alert.addAction(UIAlertAction(title: NSLocalizedString("add_to_travel_plan", comment: "Add to travel plan"), style: .default) { _ in
            print("📋 여행 계획에 추가: \(attraction.name)")
            // TODO: 여행 계획에 추가 기능 구현
        })

        alert.addAction(UIAlertAction(title: NSLocalizedString("close", comment: "Close"), style: .cancel))

        // iPad 대응
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)
    }
}

