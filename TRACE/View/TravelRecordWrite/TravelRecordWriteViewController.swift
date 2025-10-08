//
//  TravelRecordWriteViewController.swift
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

class TravelRecordWriteViewController: UIViewController {

    let disposeBag = DisposeBag()
    let mapManager = MapManager()
    private let viewModel = RecordWriteViewModel()

    // 검색된 장소들을 저장 (좌표 정보 포함)
    var currentSearchedPlaces: [KakaoPlace] = []

    // ViewModel Input Relays
    private let photosRelay = BehaviorRelay<[Data]>(value: [])
    let searchedPlacesRelay = BehaviorRelay<[KakaoPlace]>(value: [])

    // MARK: - UI Components
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.keyboardDismissMode = .onDrag
    }

    private let contentView = UIView()

    // 사진 표시 섹션 (추가 기능 없이 보기만)
    private let photoSectionLabel = UILabel().then {
        $0.text = "선택된 여행 사진"
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
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PhotoDisplayOnlyCollectionViewCell.self, forCellWithReuseIdentifier: "PhotoDisplayOnlyCollectionViewCell")
        return collectionView
    }()

    // 여행 경로 섹션
    private let routeSectionLabel = UILabel().then {
        $0.text = "여행 경로"
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 18)
        $0.textColor = .label
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

    private let routeDescriptionLabel = UILabel().then {
        $0.text = "여행 경로를 누르면 맵 선택 일정이 나옵니다."
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 14)
        $0.textColor = .secondaryLabel
    }

    // MapKit 관련 (MapManager에서 관리)
    private var mapView: MKMapView {
        return mapManager.mapView
    }

    // 여행 일기 섹션
    private let diarySectionLabel = UILabel().then {
        $0.text = "여행 일지 작성"
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 18)
        $0.textColor = .label
    }

    private let diaryTextView = UITextView().then {
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 12
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.systemGray4.cgColor
        $0.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        $0.isScrollEnabled = false
    }

    private let diaryPlaceholderLabel = UILabel().then {
        $0.text = "오늘의 여행을 기록하세요..."
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.textColor = .placeholderText
    }

    private let diaryDescriptionLabel = UILabel().then {
        $0.text = "여행 중의 느낀 점이나 이야기를 적어주세요."
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 14)
        $0.textColor = .secondaryLabel
    }

    // 하단 버튼들
    private let cancelButton = UIButton(type: .system).then {
        $0.setTitle("취소", for: .normal)
        $0.titleLabel?.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 18)
        $0.backgroundColor = .systemGray4
        $0.setTitleColor(.label, for: .normal)
        $0.layer.cornerRadius = 25
    }

    private let saveButton = UIButton(type: .system).then {
        $0.setTitle("저장", for: .normal)
        $0.titleLabel?.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 18)
        $0.backgroundColor = .skyBlue
        $0.setTitleColor(.white, for: .normal)
        $0.layer.cornerRadius = 25
    }

    // MARK: - Data
    private var selectedPhotos: [UIImage] = []

    // MARK: - Public Methods
    func setSelectedPhotos(_ photos: [UIImage]) {
        selectedPhotos = photos
        print("📸 TravelRecordWrite: \(photos.count)개 사진 받음")

        // UIImage를 Data로 변환하여 ViewModel에 전달
        let photoDataArray = photos.compactMap { $0.jpegData(compressionQuality: 0.8) }
        photosRelay.accept(photoDataArray)

        // 사진이 있을 때만 섹션 표시
        DispatchQueue.main.async { [weak self] in
            self?.updatePhotoSectionVisibility()
            self?.photoCollectionView.reloadData()
        }
    }

    private func updatePhotoSectionVisibility() {
        let hasPhotos = !selectedPhotos.isEmpty
        photoSectionLabel.isHidden = !hasPhotos
        photoCollectionView.isHidden = !hasPhotos
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

        // 초기 사진 섹션 숨김
        updatePhotoSectionVisibility()

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
            widthDimension: .absolute(120),
            heightDimension: .absolute(120)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .estimated(120),
            heightDimension: .absolute(120)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)

        return UICollectionViewCompositionalLayout(section: section)
    }

    // MARK: - Actions
    @objc private func cancelButtonTapped() {
        let alert = UIAlertController(
            title: "작성 취소",
            message: "작성 중인 내용이 사라집니다. 정말 취소하시겠습니까?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "계속 작성", style: .cancel))
        alert.addAction(UIAlertAction(title: "취소", style: .destructive) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    @objc private func saveButtonTapped() {
        // ViewModel을 통한 저장은 bindViewModel에서 처리됨
        print("📝 저장 버튼 탭됨")
    }

    // MARK: - ViewModel Binding
    private func bindViewModel() {
        // Input 생성
        let input = RecordWriteViewModel.Input(
            routeText: routeSearchBar.rx.text.orEmpty.asDriver(),
            diaryText: diaryTextView.rx.text.orEmpty.asDriver(),
            saveButtonTapped: saveButton.rx.tap.asDriver(),
            photos: photosRelay,
            searchedPlaces: searchedPlacesRelay
        )

        // Transform
        let output = viewModel.transform(input: input)

        // Output 바인딩
        // 저장 버튼 활성화/비활성화
        output.isSaveEnabled
            .drive(saveButton.rx.isEnabled)
            .disposed(by: disposeBag)

        output.isSaveEnabled
            .drive(onNext: { [weak self] isEnabled in
                self?.saveButton.alpha = isEnabled ? 1.0 : 0.6
            })
            .disposed(by: disposeBag)

        // 로딩 상태 처리
        output.isLoading
            .drive(onNext: { [weak self] isLoading in
                self?.view.isUserInteractionEnabled = !isLoading
                if isLoading {
                    // 로딩 인디케이터 표시 (선택사항)
                    print("📝 저장 중...")
                }
            })
            .disposed(by: disposeBag)

        // 저장 결과 처리
        output.saveResult
            .drive(onNext: { [weak self] result in
                switch result {
                case .success:
                    self?.navigateToTravelRecord()
                case .failure(let message):
                    print("❌ 저장 실패: \(message)")
                }
            })
            .disposed(by: disposeBag)

        // 검색된 장소들 변경 시 ViewModel에 전달
        Driver.just(currentSearchedPlaces)
            .drive(onNext: { [weak self] places in
                self?.searchedPlacesRelay.accept(places)
            })
            .disposed(by: disposeBag)
    }

    private func navigateToTravelRecord() {
        // TravelRecordViewController로 이동 (네비게이션 스택에서 찾기)
        for viewController in navigationController?.viewControllers ?? [] {
            if let travelRecordVC = viewController as? TravelRecordViewController {
                navigationController?.popToViewController(travelRecordVC, animated: true)
                return
            }
        }

        // 만약 TravelRecordViewController가 스택에 없다면 새로 생성하여 이동
        let travelRecordVC = TravelRecordViewController()
        navigationController?.setViewControllers([travelRecordVC], animated: true)
    }

}

// MARK: - DesiginProtocolBind
extension TravelRecordWriteViewController: DesiginProtocolBind {
    func bind() {
        // 취소 버튼 바인딩
        cancelButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.cancelButtonTapped()
            })
            .disposed(by: disposeBag)

        // 저장 버튼은 ViewModel에서 처리됨

        // 텍스트뷰 플레이스홀더 처리
        diaryTextView.rx.text
            .subscribe(onNext: { [weak self] text in
                self?.diaryPlaceholderLabel.isHidden = !(text?.isEmpty ?? true)
            })
            .disposed(by: disposeBag)

        // 키보드 관련 처리
        diaryTextView.rx.didBeginEditing
            .subscribe(onNext: { [weak self] in
                self?.diaryPlaceholderLabel.isHidden = true
            })
            .disposed(by: disposeBag)

        diaryTextView.rx.didEndEditing
            .subscribe(onNext: { [weak self] in
                if self?.diaryTextView.text.isEmpty == true {
                    self?.diaryPlaceholderLabel.isHidden = false
                }
            })
            .disposed(by: disposeBag)

        // 검색 바 바인딩
        routeSearchBar.rx.searchButtonClicked
            .subscribe(onNext: { [weak self] in
                self?.routeSearchBar.resignFirstResponder()
                guard let query = self?.routeSearchBar.text, !query.isEmpty else { return }
                print("🔍 수동 검색 시작: '\(query)'")
                self?.performManualSearch(query: query)
            })
            .disposed(by: disposeBag)
    }

    func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(photoSectionLabel)
        contentView.addSubview(photoCollectionView)

        contentView.addSubview(routeSectionLabel)
        contentView.addSubview(routeSearchBar)
        contentView.addSubview(routeDescriptionLabel)

        contentView.addSubview(mapView)

        contentView.addSubview(diarySectionLabel)
        contentView.addSubview(diaryTextView)
        contentView.addSubview(diaryPlaceholderLabel)
        contentView.addSubview(diaryDescriptionLabel)

        view.addSubview(cancelButton)
        view.addSubview(saveButton)
    }

    func configureUI() {
        // Navigation Bar 설정
        navigationItem.title = "여행 기록"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(cancelButtonTapped)
        )
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(systemName: "trash"),
                style: .plain,
                target: self,
                action: #selector(clearSearchResults)
            )
        ]

        // Diary TextView 설정
        diaryTextView.textContainer.lineFragmentPadding = 0
        diaryTextView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }

    func configureLayout() {
        scrollView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(cancelButton.snp.top).offset(-20)
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
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(150)
        }

        // 여행 경로 섹션
        routeSectionLabel.snp.makeConstraints {
            $0.top.equalTo(photoCollectionView.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        routeSearchBar.snp.makeConstraints {
            $0.top.equalTo(routeSectionLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        routeDescriptionLabel.snp.makeConstraints {
            $0.top.equalTo(routeSearchBar.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        // 지도 영역
        mapView.snp.makeConstraints {
            $0.top.equalTo(routeDescriptionLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(200)
        }

        // 여행 일기 섹션
        diarySectionLabel.snp.makeConstraints {
            $0.top.equalTo(mapView.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        diaryTextView.snp.makeConstraints {
            $0.top.equalTo(diarySectionLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.greaterThanOrEqualTo(120)
        }

        diaryPlaceholderLabel.snp.makeConstraints {
            $0.top.equalTo(diaryTextView.snp.top).offset(16)
            $0.leading.equalTo(diaryTextView.snp.leading).offset(16)
            $0.trailing.equalTo(diaryTextView.snp.trailing).offset(-16)
        }

        diaryDescriptionLabel.snp.makeConstraints {
            $0.top.equalTo(diaryTextView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().offset(-40)
        }

        // 하단 버튼들
        cancelButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.height.equalTo(50)
            $0.width.equalTo(saveButton.snp.width)
        }

        saveButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.height.equalTo(50)
            $0.leading.equalTo(cancelButton.snp.trailing).offset(16)
        }
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension TravelRecordWriteViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedPhotos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoDisplayOnlyCollectionViewCell", for: indexPath) as! PhotoDisplayOnlyCollectionViewCell
        cell.configure(with: selectedPhotos[indexPath.item])
        return cell
    }
}

// MARK: - Keyboard Handling
extension TravelRecordWriteViewController {
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
            if self.diaryTextView.isFirstResponder {
                let textViewFrame = self.diaryTextView.convert(self.diaryTextView.bounds, to: self.scrollView)
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
