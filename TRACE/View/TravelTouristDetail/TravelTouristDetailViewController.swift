//
//  TravelTouristDetailViewController.swift
//  TRACE
//
//  Created by 차지용 on 10/28/25.
//

import UIKit
import SnapKit
import Then
import MapKit
import Kingfisher
import RxSwift

class TravelTouristDetailViewController: UIViewController {

    // MARK: - Properties
    private let viewModel: TouristDetailViewModel
    private let disposeBag = DisposeBag()
    private var photoURLs: [String] = []

    // ViewModel Output
    private var output: TouristDetailViewModel.Output!

    // MARK: - UI Components
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }

    private let contentView = UIView()

    // 상단 이미지 컬렉션뷰
    private lazy var photoCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 300)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemGray5
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: "PhotoCell")
        collectionView.dataSource = self
        collectionView.delegate = self

        return collectionView
    }()

    // 페이지 컨트롤
    private let pageControl = UIPageControl().then {
        $0.currentPageIndicatorTintColor = .white
        $0.pageIndicatorTintColor = .white.withAlphaComponent(0.5)
        $0.hidesForSinglePage = true
    }

    // 뒤로가기 버튼
    private let backButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        $0.tintColor = .white
        $0.layer.cornerRadius = 20
        $0.clipsToBounds = true
    }

    // 관광지 정보 섹션
    private let infoContainerView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 20
        $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }

    private let attractionNameLabel = UILabel().then {
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 24)
        $0.textColor = .label
        $0.numberOfLines = 0
    }

    private let countryLabel = UILabel().then {
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.textColor = .secondaryLabel
    }

    private let categoryBadge = UILabel().then {
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 12)
        $0.textColor = .white
        $0.backgroundColor = .skyBlue
        $0.textAlignment = .center
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }

    private let dividerView = UIView().then {
        $0.backgroundColor = .separator
    }

    // 설명 섹션
    private let descriptionTitleLabel = UILabel().then {
        $0.applySectionTitleStyle(text: NSLocalizedString("description", comment: "Description"))
    }

    private let descriptionLabel = UILabel().then {
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 14)
        $0.textColor = .label
        $0.numberOfLines = 0
    }

    // 위치 정보 섹션
    private let locationTitleLabel = UILabel().then {
        $0.applySectionTitleStyle(text: NSLocalizedString("location", comment: "Location"))
    }

    private let coordinateLabel = UILabel().then {
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 14)
        $0.textColor = .secondaryLabel
    }

    // 지도
    private let mapView = MKMapView().then {
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }


    // MARK: - Initialization
    init(attraction: TouristAttraction) {
        self.viewModel = TouristDetailViewModel(attraction: attraction)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        configureHierarchy()
        configureUI()
        configureLayout()
        bindViewModel()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

// MARK: - DesiginProtocolBind
extension TravelTouristDetailViewController: DesiginProtocolBind {

    func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        view.addSubview(backButton)
        view.addSubview(pageControl)

        [photoCollectionView, infoContainerView].forEach {
            contentView.addSubview($0)
        }

        [attractionNameLabel, countryLabel, categoryBadge, dividerView,
         descriptionTitleLabel, descriptionLabel,
         locationTitleLabel, coordinateLabel, mapView].forEach {
            infoContainerView.addSubview($0)
        }
    }

    func configureUI() {
        view.backgroundColor = .systemBackground
    }

    func bindViewModel() {
        // Input 생성
        let viewDidLoadInput = Observable.just(())
        let backButtonTappedInput = backButton.rx.tap.asObservable()

        let input = TouristDetailViewModel.Input(
            viewDidLoad: viewDidLoadInput,
            backButtonTapped: backButtonTappedInput
        )

        // ViewModel과 바인딩
        output = viewModel.transform(input: input)

        // Output 구독
        output.attractionName
            .bind(to: attractionNameLabel.rx.text)
            .disposed(by: disposeBag)

        output.countryName
            .bind(to: countryLabel.rx.text)
            .disposed(by: disposeBag)

        output.categoryText
            .bind(to: categoryBadge.rx.text)
            .disposed(by: disposeBag)

        output.descriptionText
            .bind(to: descriptionLabel.rx.text)
            .disposed(by: disposeBag)

        output.coordinateText
            .bind(to: coordinateLabel.rx.text)
            .disposed(by: disposeBag)

        output.photoURLs
            .subscribe(onNext: { [weak self] urls in
                self?.photoURLs = urls
                self?.photoCollectionView.reloadData()
            })
            .disposed(by: disposeBag)

        output.pageCount
            .bind(to: pageControl.rx.numberOfPages)
            .disposed(by: disposeBag)

        output.mapCoordinate
            .subscribe(onNext: { [weak self] coordinate in
                self?.setupMapLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            })
            .disposed(by: disposeBag)

        output.dismissView
            .subscribe(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }

    func configureLayout() {
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        backButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.leading.equalToSuperview().offset(20)
            $0.width.height.equalTo(40)
        }

        photoCollectionView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(300)
        }

        pageControl.snp.makeConstraints {
            $0.bottom.equalTo(photoCollectionView.snp.bottom).offset(-16)
            $0.centerX.equalToSuperview()
        }

        infoContainerView.snp.makeConstraints {
            $0.top.equalTo(photoCollectionView.snp.bottom).offset(-20)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

        attractionNameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(30)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalTo(categoryBadge.snp.leading).offset(-12)
        }

        categoryBadge.snp.makeConstraints {
            $0.top.equalToSuperview().offset(30)
            $0.trailing.equalToSuperview().offset(-20)
            $0.width.equalTo(60)
            $0.height.equalTo(24)
        }

        countryLabel.snp.makeConstraints {
            $0.top.equalTo(attractionNameLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        dividerView.snp.makeConstraints {
            $0.top.equalTo(countryLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(1)
        }

        descriptionTitleLabel.snp.makeConstraints {
            $0.top.equalTo(dividerView.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(descriptionTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        locationTitleLabel.snp.makeConstraints {
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        coordinateLabel.snp.makeConstraints {
            $0.top.equalTo(locationTitleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        mapView.snp.makeConstraints {
            $0.top.equalTo(coordinateLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(200)
        }

        mapView.snp.makeConstraints {
            $0.bottom.equalToSuperview().offset(-30)
        }
    }

    func bind() {
        // UI 전용 바인딩 (현재 추가 바인딩 없음)
    }
}

// MARK: - Private Methods
extension TravelTouristDetailViewController {

    private func setupMapLocation(latitude: Double, longitude: Double) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate

        // 관광지 이름과 국가는 ViewModel에서 가져옴
        output.attractionName
            .take(1)
            .subscribe(onNext: { name in
                annotation.title = name
            })
            .disposed(by: disposeBag)

        output.countryName
            .take(1)
            .subscribe(onNext: { country in
                annotation.subtitle = country
            })
            .disposed(by: disposeBag)

        mapView.addAnnotation(annotation)

        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: false)
    }
}

// MARK: - UICollectionViewDataSource
extension TravelTouristDetailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoURLs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        let photoURL = photoURLs[indexPath.item]
        cell.configure(with: photoURL)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension TravelTouristDetailViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == photoCollectionView {
            let pageIndex = round(scrollView.contentOffset.x / scrollView.frame.width)
            pageControl.currentPage = Int(pageIndex)
        }
    }
}

// MARK: - PhotoCell
class PhotoCell: UICollectionViewCell {

    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.backgroundColor = .systemGray5
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(imageView)

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    func configure(with photoURL: String) {
        if photoURL == "placeholder" {
            imageView.image = UIImage(systemName: "photo.fill")
            imageView.tintColor = .systemGray3
        } else if let url = URL(string: photoURL) {
            imageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "photo.fill"),
                options: [
                    .transition(.fade(0.3)),
                    .cacheOriginalImage,
                    .backgroundDecode,
                    .processor(DownsamplingImageProcessor(size: CGSize(width: 600, height: 400)))
                ]
            ) { [weak self] result in
                switch result {
                case .success(_):
                    self?.imageView.tintColor = nil
                case .failure(_):
                    self?.imageView.image = UIImage(systemName: "photo.fill")
                    self?.imageView.tintColor = .systemGray3
                }
            }
        }
    }
}
