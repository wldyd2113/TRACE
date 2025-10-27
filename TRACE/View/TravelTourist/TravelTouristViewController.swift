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

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(TouristAttractionCell.self, forCellWithReuseIdentifier: "TouristAttractionCell")
        collectionView.delegate = self
        collectionView.dataSource = self

        return collectionView
    }()

    // 선택된 카테고리
    private var selectedCategory: TouristCategory = .popular
    private var attractions: [TouristAttraction] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background

        configureHierarchy()
        configureUI()
        configureLayout()
        bind()

        // 초기 데이터 로드
        loadSampleData()
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
    let description: String
    let latitude: Double
    let longitude: Double
}

extension TravelTouristViewController: DesiginProtocolBind {
    func bind() {
        // 검색 텍스트필드 이벤트
        countrySearchTextField.rx.text.orEmpty
            .debounce(.seconds(1), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] searchText in
                self?.searchCountryAttractions(query: searchText)
            })
            .disposed(by: disposeBag)

        // 카테고리 버튼 이벤트
        popularButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.selectCategory(.popular)
            })
            .disposed(by: disposeBag)

        scenicButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.selectCategory(.scenic)
            })
            .disposed(by: disposeBag)

        historicalButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.selectCategory(.historical)
            })
            .disposed(by: disposeBag)
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

        // 초기 선택된 카테고리 설정
        selectCategory(.popular)
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
            $0.height.equalTo(400) // 임시 높이, 나중에 동적으로 조정
            $0.bottom.equalToSuperview().offset(-20)
        }
    }
}

// MARK: - Helper Methods
extension TravelTouristViewController {
    private func selectCategory(_ category: TouristCategory) {
        selectedCategory = category
        updateCategoryButtons()
        filterAttractionsByCategory()
    }

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

    private func filterAttractionsByCategory() {
        let filteredAttractions = attractions.filter { $0.category == selectedCategory }
        // TODO: 컬렉션뷰 업데이트
        DispatchQueue.main.async { [weak self] in
            self?.attractionsCollectionView.reloadData()
        }
    }

    private func searchCountryAttractions(query: String) {
        print("🔍 나라 검색: \(query)")
        // TODO: API 호출하여 해당 나라의 관광지 검색
        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            loadAttractionsForCountry(query)
        }
    }

    private func loadSampleData() {
        // 샘플 데이터 로드
        attractions = [
            TouristAttraction(id: "1", name: "도쿄 타워", country: "일본", category: .popular, imageURL: nil, description: "도쿄의 상징적인 타워", latitude: 35.6586, longitude: 139.7454),
            TouristAttraction(id: "2", name: "에펠탑", country: "프랑스", category: .popular, imageURL: nil, description: "파리의 상징", latitude: 48.8584, longitude: 2.2945),
            TouristAttraction(id: "3", name: "후지산", country: "일본", category: .scenic, imageURL: nil, description: "일본의 명산", latitude: 35.3606, longitude: 138.7274),
            TouristAttraction(id: "4", name: "베르사유 궁전", country: "프랑스", category: .historical, imageURL: nil, description: "프랑스 역사 궁전", latitude: 48.8049, longitude: 2.1204)
        ]

        filterAttractionsByCategory()
    }

    private func loadAttractionsForCountry(_ country: String) {
        // TODO: 실제 API 연동 시 구현
        // 현재는 샘플 데이터에서 해당 국가 필터링
        let countryAttractions = attractions.filter { $0.country.contains(country) }
        print("📍 \(country) 관광지 \(countryAttractions.count)개 발견")
    }
}

// MARK: - UICollectionViewDataSource
extension TravelTouristViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return attractions.filter { $0.category == selectedCategory }.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TouristAttractionCell", for: indexPath) as! TouristAttractionCell

        let filteredAttractions = attractions.filter { $0.category == selectedCategory }
        if indexPath.item < filteredAttractions.count {
            let attraction = filteredAttractions[indexPath.item]
            cell.configure(with: attraction)
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension TravelTouristViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 12) / 2 // 2열 레이아웃
        return CGSize(width: width, height: 200)
    }
}

// MARK: - UICollectionViewDelegate
extension TravelTouristViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let filteredAttractions = attractions.filter { $0.category == selectedCategory }
        if indexPath.item < filteredAttractions.count {
            let attraction = filteredAttractions[indexPath.item]
            showAttractionDetail(attraction)
        }
    }

    private func showAttractionDetail(_ attraction: TouristAttraction) {
        print("📍 관광지 선택됨: \(attraction.name)")
        // TODO: 상세 화면으로 이동 또는 상세 정보 표시
    }
}
