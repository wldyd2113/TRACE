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
    var currentGooglePlaces: [PlaceResult] = []
    private var recordPhotos: [UIImage] = []
    internal var countryType: String = "국내"

    // 선택된 장소 저장
    var selectedPlace: KakaoPlace?

    // MARK: - Triggers
    private let deleteButtonTrigger = PublishRelay<Void>()

    // MARK: - UI Components
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }

    private let contentView = UIView()

    // 사진 섹션
    private let photoSectionLabel = UILabel().then {
        $0.text = NSLocalizedString("travel_moments_photos", comment: "Travel moments photos")
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
        $0.text = NSLocalizedString("travel_route", comment: "Travel route")
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 18)
        $0.textColor = .label
    }


    // MapKit 관련 (MapManager에서 관리)
    private var mapView: MKMapView {
        return mapManager.mapView
    }

    // 여행지 검색 버튼
    let routeSearchButton = UIButton(type: .system).then {
        $0.setTitle(NSLocalizedString("search_destination", comment: "Search destination"), for: .normal)
        $0.titleLabel?.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.backgroundColor = .systemGray6
        $0.setTitleColor(.label, for: .normal)
        $0.layer.cornerRadius = 8
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.systemGray4.cgColor
        $0.contentHorizontalAlignment = .left
        $0.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        $0.isUserInteractionEnabled = false // 편집 모드에서만 활성화
    }

    // 선택된 장소 표시 라벨
    let selectedRouteLabel = UILabel().then {
        $0.text = NSLocalizedString("edit_mode_add_destination", comment: "Edit mode add destination")
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 14)
        $0.textColor = .secondaryLabel
        $0.isHidden = true
    }

    private let mapDescriptionLabel = UILabel().then {
        $0.text = NSLocalizedString("route_selection_map", comment: "Route selection map")
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 14)
        $0.textColor = .systemBlue
        $0.textAlignment = .center
    }

    // 여행 기록 작성 섹션
    private let recordTitleLabel = UILabel().then {
        $0.text = NSLocalizedString("travel_record_writing", comment: "Travel record writing")
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
        $0.text = NSLocalizedString("record_placeholder", comment: "Record placeholder")
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.textColor = .placeholderText
    }

    private let recordDescriptionLabel = UILabel().then {
        $0.text = NSLocalizedString("record_description", comment: "Record description")
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 14)
        $0.textColor = .secondaryLabel
    }


    // 편집 모드 버튼들
    private let editButton = UIButton(type: .system).then {
        $0.setTitle(NSLocalizedString("edit", comment: "Edit"), for: .normal)
        $0.titleLabel?.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.backgroundColor = .skyBlue
        $0.setTitleColor(.white, for: .normal)
        $0.layer.cornerRadius = 20
        $0.isHidden = false
    }

    private let saveButton = UIButton(type: .system).then {
        $0.setTitle(NSLocalizedString("save", comment: "Save"), for: .normal)
        $0.titleLabel?.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.backgroundColor = .skyBlue
        $0.setTitleColor(.white, for: .normal)
        $0.layer.cornerRadius = 20
        $0.isHidden = true
    }

    private let cancelButton = UIButton(type: .system).then {
        $0.setTitle(NSLocalizedString("cancel", comment: "Cancel"), for: .normal)
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
        // 키보드 해제 설정
        setupKeyboardDismissal()
        // 키보드 알림 설정
        setupKeyboardNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
        // 선택된 장소 텍스트를 Observable로 변환
        let selectedRouteText = selectedRouteLabel.rx.observe(String.self, "text")
            .map { $0 ?? "" }
            .asObservable()

        let editButtonTapped = editButton.rx.tap.asObservable()
        let saveButtonTapped = saveButton.rx.tap
            .withLatestFrom(Observable.combineLatest(
                selectedRouteText,
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
            cancelButtonTapped: cancelButtonTapped,
            deleteButtonTapped: deleteButtonTrigger.asObservable()
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
                print(" 로딩 상태: \(isLoading)")
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

        // 저장된 장소들을 기반으로 국내/해외 구분
        determineCountryType(from: places)
    }

    private func updateEditMode(_ isEdit: Bool) {
        recordTextView.isEditable = isEdit
        routeSearchButton.isUserInteractionEnabled = isEdit

        editButton.isHidden = isEdit
        saveButton.isHidden = !isEdit
        cancelButton.isHidden = !isEdit

        // 편집 모드에 따른 UI 업데이트
        if isEdit {
            routeSearchButton.backgroundColor = .systemGray6
            routeSearchButton.setTitleColor(.label, for: .normal)
            selectedRouteLabel.text = "여행지를 추가하려면 검색 버튼을 눌러주세요"
            selectedRouteLabel.isHidden = false
            recordTextView.becomeFirstResponder()
        } else {
            routeSearchButton.backgroundColor = .systemGray5
            routeSearchButton.setTitleColor(.secondaryLabel, for: .normal)
            selectedRouteLabel.isHidden = true
            view.endEditing(true)
        }
    }

    private func determineCountryType(from places: [KakaoPlace]) {
        for place in places {
            let latitude = place.coordinate.latitude
            let longitude = place.coordinate.longitude

            // 한국 좌표 범위 체크 (대략적인 범위)
            if latitude >= 33.0 && latitude <= 38.6 && longitude >= 124.0 && longitude <= 132.0 {
                countryType = "국내"
                print(" 국내 여행으로 판단: \(place.placeName)")
                return
            }
        }

        // 한국 범위를 벗어나면 해외로 판단
        if !places.isEmpty {
            countryType = "해외"
            print(" 해외 여행으로 판단")
        }
    }

    private func showAlert(title: String, message: String, completion: (() -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("confirm", comment: "Confirm"), style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }

    // MARK: - Search Modal Methods
    private func presentSearchModal() {
        let searchVC = TravelSearchViewController()
        searchVC.delegate = self
        searchVC.countryType = countryType
        searchVC.modalPresentationStyle = .overFullScreen
        searchVC.modalTransitionStyle = .crossDissolve
        present(searchVC, animated: true)
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

    // MARK: - Keyboard Handling
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        let keyboardHeight = keyboardFrame.height
        let safeAreaBottom = view.safeAreaInsets.bottom
        let adjustedHeight = keyboardHeight - safeAreaBottom

        UIView.animate(withDuration: animationDuration) {
            self.scrollView.contentInset.bottom = adjustedHeight
            self.scrollView.verticalScrollIndicatorInsets.bottom = adjustedHeight

            // TextView가 키보드에 가려지지 않도록 스크롤
            if self.recordTextView.isFirstResponder {
                let textViewFrame = self.recordTextView.convert(self.recordTextView.bounds, to: self.scrollView)
                let visibleHeight = self.scrollView.frame.height - adjustedHeight

                if textViewFrame.maxY > visibleHeight {
                    let offsetY = textViewFrame.maxY - visibleHeight + 20 // 여유공간 20pt
                    self.scrollView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: false)
                }
            }
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        UIView.animate(withDuration: animationDuration) {
            self.scrollView.contentInset.bottom = 0
            self.scrollView.verticalScrollIndicatorInsets.bottom = 0
        }
    }
}

// MARK: - TravelSearchDelegate
extension TravelShowRecordViewController: TravelSearchDelegate {
    func didSelectPlace(_ place: KakaoPlace) {
        selectedPlace = place
        selectedRouteLabel.text = place.placeName
        selectedRouteLabel.textColor = .label
        selectedRouteLabel.isHidden = false

        // 검색 버튼 텍스트 업데이트
        routeSearchButton.setTitle(place.placeName, for: .normal)
        routeSearchButton.setTitleColor(.label, for: .normal)

        print(" 장소 선택됨: \(place.placeName)")

        // 선택된 장소를 현재 검색된 장소에 추가
        if !currentSearchedPlaces.contains(where: { $0.placeName == place.placeName }) {
            currentSearchedPlaces.append(place)
            mapManager.displaySearchResults(places: currentSearchedPlaces)
        }
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

        // 여행지 검색 버튼 바인딩 (편집 모드에서만 작동)
        routeSearchButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.presentSearchModal()
            })
            .disposed(by: disposeBag)
    }

    func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(photoSectionLabel)
        contentView.addSubview(photoCollectionView)

        contentView.addSubview(routeTitleLabel)
        contentView.addSubview(routeSearchButton)
        contentView.addSubview(selectedRouteLabel)
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
        navigationItem.title = NSLocalizedString("travel_record", comment: "Travel record")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(deleteButtonTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = .skyBlue

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

        routeSearchButton.snp.makeConstraints {
            $0.top.equalTo(routeTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        selectedRouteLabel.snp.makeConstraints {
            $0.top.equalTo(routeSearchButton.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        // 지도 영역
        mapView.snp.makeConstraints {
            $0.top.equalTo(selectedRouteLabel.snp.bottom).offset(16)
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

    @objc private func deleteButtonTapped() {
        showDeleteConfirmationAlert()
    }

    private func showDeleteConfirmationAlert() {
        let alert = UIAlertController(
            title: NSLocalizedString("delete_post", comment: "Delete post"),
            message: NSLocalizedString("delete_confirmation_message", comment: "Delete confirmation message"),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: "Cancel"), style: .cancel))

        alert.addAction(UIAlertAction(title: NSLocalizedString("delete", comment: "Delete"), style: .destructive) { [weak self] _ in
            self?.deleteRecord()
        })

        present(alert, animated: true)
    }

    private func deleteRecord() {
        // ViewModel에 삭제 요청
        deleteButtonTrigger.accept(())
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

