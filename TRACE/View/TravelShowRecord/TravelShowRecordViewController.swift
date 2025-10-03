//
//  TravelShowRecordViewController.swift
//  TRACE
//
//  Created by 차지용 on 9/30/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Then
import MapKit
import CoreLocation

class TravelShowRecordViewController: UIViewController {

    let disposeBag = DisposeBag()
    let mapManager = MapManager()
    private let viewModel = TravelShowRecordViewModel()

    // MARK: - Data
    var travelRecordId: String?
    var currentSearchedPlaces: [KakaoPlace] = []
    private var recordPhotos: [UIImage] = []

    // MARK: - UI Components
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }

    private let contentView = UIView()

    // 사진 섹션
    private let photoSectionLabel = UILabel().then {
        $0.text = "여행의 순간들을 담은 사진"
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 18)
        $0.textColor = .label
        $0.textAlignment = .center
    }

    private lazy var photoCollectionView: UICollectionView = {
        let layout = createPhotoCollectionLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemGray6
        collectionView.layer.cornerRadius = 12
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.register(RecordPhotoCollectionCell.self, forCellWithReuseIdentifier: "RecordPhotoCollectionCell")
        return collectionView
    }()

    // 여행 경로 섹션
    private let routeTitleLabel = UILabel().then {
        $0.text = "여행 경로"
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 18)
        $0.textColor = .label
    }


    // MapKit 관련 (MapManager에서 관리)
    private var mapView: MKMapView {
        return mapManager.mapView
    }

    let routeSearchBar = UISearchBar().then {
        $0.placeholder = "여행지를 검색해보세요"
        $0.searchBarStyle = .minimal
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
        $0.searchTextField.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.searchTextField.backgroundColor = .systemGray6
        $0.isUserInteractionEnabled = true
        $0.searchTextField.isUserInteractionEnabled = true
    }

    private let mapDescriptionLabel = UILabel().then {
        $0.text = "여행 경로를 선택할 수 있는 맵"
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 14)
        $0.textColor = .systemBlue
        $0.textAlignment = .center
    }

    // 여행 기록 작성 섹션
    private let recordTitleLabel = UILabel().then {
        $0.text = "여행 기록 작성"
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 18)
        $0.textColor = .label
    }

    private let recordTextView = UITextView().then {
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 12
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.systemGray4.cgColor
        $0.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        $0.isScrollEnabled = false
        $0.isEditable = false
    }

    private let recordPlaceholderLabel = UILabel().then {
        $0.text = "여행의 정말 좋은 기록하세요..."
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.textColor = .placeholderText
    }

    private let recordDescriptionLabel = UILabel().then {
        $0.text = "사진을 추가하고, 후기를 남겨주세요."
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 14)
        $0.textColor = .secondaryLabel
    }


    // 편집 모드 버튼들
    private let editButton = UIButton(type: .system).then {
        $0.setTitle("수정", for: .normal)
        $0.titleLabel?.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.backgroundColor = .skyBlue
        $0.setTitleColor(.white, for: .normal)
        $0.layer.cornerRadius = 20
        $0.isHidden = false
    }

    private let saveButton = UIButton(type: .system).then {
        $0.setTitle("저장", for: .normal)
        $0.titleLabel?.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.backgroundColor = .skyBlue
        $0.setTitleColor(.white, for: .normal)
        $0.layer.cornerRadius = 20
        $0.isHidden = true
    }

    private let cancelButton = UIButton(type: .system).then {
        $0.setTitle("취소", for: .normal)
        $0.titleLabel?.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.backgroundColor = .systemGray
        $0.setTitleColor(.white, for: .normal)
        $0.layer.cornerRadius = 20
        $0.isHidden = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background

        configureHierarchy()
        configureUI()
        configureLayout()
        bind()

        // 맵 관리자 설정
        setupMapManager()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Collection Layout
    private func createPhotoCollectionLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(300)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

        return UICollectionViewCompositionalLayout(section: section)
    }

    // MARK: - ViewModel Binding
    private func bindViewModel() {
        let editButtonTapped = editButton.rx.tap.asObservable()
        let saveButtonTapped = saveButton.rx.tap
            .withLatestFrom(Observable.combineLatest(
                Observable.just(""),
                recordTextView.rx.text.orEmpty
            ))
            .map { [weak self] in
                (route: $0.0, record: $0.1, places: self?.currentSearchedPlaces ?? [])
            }
            .asObservable()
        let cancelButtonTapped = cancelButton.rx.tap.asObservable()

        let input = TravelShowRecordViewModel.Input(
            recordId: travelRecordId,
            viewDidLoad: Observable.just(()),
            editButtonTapped: editButtonTapped,
            saveButtonTapped: saveButtonTapped,
            cancelButtonTapped: cancelButtonTapped
        )

        let output = viewModel.transform(input: input)

        // 데이터 바인딩
        output.recordData
            .drive(onNext: { [weak self] data in
                self?.updateUI(with: data)
            })
            .disposed(by: disposeBag)

        // 편집 모드 바인딩
        output.isEditMode
            .drive(onNext: { [weak self] isEdit in
                self?.updateEditMode(isEdit)
            })
            .disposed(by: disposeBag)

        // 알림 바인딩
        output.showAlert
            .drive(onNext: { [weak self] (alertData: AlertData) in
                self?.showAlert(title: alertData.title, message: alertData.message, completion: alertData.completion)
            })
            .disposed(by: disposeBag)

        // 로딩 상태 바인딩
        output.isLoading
            .drive(onNext: { [weak self] (isLoading: Bool) in
                // TODO: 로딩 인디케이터 표시/숨김
                print("🔄 로딩 상태: \(isLoading)")
            })
            .disposed(by: disposeBag)

        // 네비게이션 바인딩
        output.navigateBack
            .drive(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }

    private func updateUI(with data: RecordDisplayData?) {
        guard let data = data else { return }

        recordTextView.text = data.recordLog
        recordPlaceholderLabel.isHidden = !data.hasPlaceholder

        // 사진 데이터를 UIImage로 변환
        recordPhotos = data.photos.compactMap { UIImage(data: $0) }
        photoCollectionView.reloadData()

        // 지도에 장소 표시
        let places = data.places.map { place in
            KakaoPlace(
                id: place.id,
                placeName: place.placeName,
                categoryName: "",
                categoryGroupCode: "",
                categoryGroupName: "",
                phone: "",
                addressName: "",
                roadAddressName: "",
                x: String(place.longitude),
                y: String(place.latitude),
                placeUrl: "",
                distance: ""
            )
        }
        currentSearchedPlaces = places
        mapManager.displaySearchResults(places: places)
    }

    private func updateEditMode(_ isEdit: Bool) {
        recordTextView.isEditable = isEdit
        routeSearchBar.isUserInteractionEnabled = isEdit

        editButton.isHidden = isEdit
        saveButton.isHidden = !isEdit
        cancelButton.isHidden = !isEdit

        if isEdit {
            recordTextView.becomeFirstResponder()
        } else {
            view.endEditing(true)
        }
    }

    private func showAlert(title: String, message: String, completion: (() -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }


    // MARK: - Public Methods
    func setRecordData(photos: [UIImage], route: String, record: String, places: [KakaoPlace]) {
        recordPhotos = photos
        recordTextView.text = record
        currentSearchedPlaces = places

        DispatchQueue.main.async { [weak self] in
            self?.photoCollectionView.reloadData()
            if !places.isEmpty {
                self?.mapManager.displaySearchResults(places: places)
            }
        }

        print("📖 여행 기록 데이터 설정: 사진 \(photos.count)개, 장소 \(places.count)개")
    }
}

// MARK: - DesiginProtocolBind
extension TravelShowRecordViewController: DesiginProtocolBind {
    func bind() {
        // ViewModel 바인딩
        bindViewModel()

        // 텍스트뷰 플레이스홀더 처리
        recordTextView.rx.text
            .subscribe(onNext: { [weak self] text in
                self?.recordPlaceholderLabel.isHidden = !(text?.isEmpty ?? true)
            })
            .disposed(by: disposeBag)

        // 텍스트뷰 편집 상태 처리
        recordTextView.rx.didBeginEditing
            .subscribe(onNext: { [weak self] in
                self?.recordPlaceholderLabel.isHidden = true
            })
            .disposed(by: disposeBag)

        recordTextView.rx.didEndEditing
            .subscribe(onNext: { [weak self] in
                if self?.recordTextView.text.isEmpty == true {
                    self?.recordPlaceholderLabel.isHidden = false
                }
            })
            .disposed(by: disposeBag)
    }

    func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(photoSectionLabel)
        contentView.addSubview(photoCollectionView)

        contentView.addSubview(routeTitleLabel)

        contentView.addSubview(routeSearchBar)
        contentView.addSubview(mapView)
        contentView.addSubview(mapDescriptionLabel)

        contentView.addSubview(recordTitleLabel)
        contentView.addSubview(recordTextView)
        contentView.addSubview(recordPlaceholderLabel)
        contentView.addSubview(recordDescriptionLabel)

        view.addSubview(editButton)
        view.addSubview(saveButton)
        view.addSubview(cancelButton)
    }

    func configureUI() {
        // Navigation Bar 설정
        navigationItem.title = "여행 기록"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )

        // TextView 설정
        recordTextView.textContainer.lineFragmentPadding = 0
        recordTextView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }

    func configureLayout() {
        scrollView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        // 사진 섹션
        photoSectionLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        photoCollectionView.snp.makeConstraints {
            $0.top.equalTo(photoSectionLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(300)
        }

        // 여행 경로 섹션
        routeTitleLabel.snp.makeConstraints {
            $0.top.equalTo(photoCollectionView.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        routeSearchBar.snp.makeConstraints {
            $0.top.equalTo(routeTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        // 지도 영역
        mapView.snp.makeConstraints {
            $0.top.equalTo(routeSearchBar.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(200)
        }

        mapDescriptionLabel.snp.makeConstraints {
            $0.top.equalTo(mapView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        // 여행 기록 작성 섹션
        recordTitleLabel.snp.makeConstraints {
            $0.top.equalTo(mapDescriptionLabel.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        recordTextView.snp.makeConstraints {
            $0.top.equalTo(recordTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.greaterThanOrEqualTo(120)
        }

        recordPlaceholderLabel.snp.makeConstraints {
            $0.top.equalTo(recordTextView.snp.top).offset(16)
            $0.leading.equalTo(recordTextView.snp.leading).offset(16)
            $0.trailing.equalTo(recordTextView.snp.trailing).offset(-16)
        }

        recordDescriptionLabel.snp.makeConstraints {
            $0.top.equalTo(recordTextView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().offset(-40)
        }

        // 편집 모드 버튼들
        editButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.width.equalTo(60)
            $0.height.equalTo(40)
        }

        saveButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.width.equalTo(60)
            $0.height.equalTo(40)
        }

        cancelButton.snp.makeConstraints {
            $0.trailing.equalTo(saveButton.snp.leading).offset(-12)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.width.equalTo(60)
            $0.height.equalTo(40)
        }
    }
}

// MARK: - Navigation Actions
extension TravelShowRecordViewController {
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

}

// MARK: - UICollectionViewDataSource & Delegate
extension TravelShowRecordViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recordPhotos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecordPhotoCollectionCell", for: indexPath) as! RecordPhotoCollectionCell
        let photo = indexPath.item < recordPhotos.count ? recordPhotos[indexPath.item] : nil
        cell.configure(with: photo)
        return cell
    }

}

