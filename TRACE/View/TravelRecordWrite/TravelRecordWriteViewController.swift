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

    // 검색된 장소들을 저장 (좌표 정보 포함)
    var currentSearchedPlaces: [KakaoPlace] = []

    // MARK: - UI Components
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.keyboardDismissMode = .onDrag
    }

    private let contentView = UIView()

    // 사진 추가 섹션
    private let photoSectionLabel = UILabel().then {
        $0.text = "여기에서 여행 사진을 추가하세요."
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
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
        collectionView.register(PhotoAddCell.self, forCellWithReuseIdentifier: "PhotoAddCell")
        collectionView.register(PhotoDisplayCell.self, forCellWithReuseIdentifier: "PhotoDisplayCell")
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
        $0.text = "여행 일기"
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
        $0.backgroundColor = .darkBlue
        $0.setTitleColor(.white, for: .normal)
        $0.layer.cornerRadius = 25
    }

    // MARK: - Data
    private var selectedPhotos: [UIImage] = []

    // MARK: - Public Methods
    func setSelectedPhotos(_ photos: [UIImage]) {
        selectedPhotos = photos
        print("📸 TravelRecordWrite: \(photos.count)개 사진 받음")

        // 뷰가 로드된 후에 CollectionView 업데이트
        DispatchQueue.main.async { [weak self] in
            self?.photoCollectionView.reloadData()
        }
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
        print("📝 여행 기록 저장")

        // 여행 기록 데이터 수집
        let route = routeSearchBar.text ?? ""
        let diary = diaryTextView.text ?? ""
        let searchedPlaces = getCurrentSearchedPlaces()

        print("📝 저장할 데이터:")
        print("   🗺️ 경로: '\(route)'")
        print("   📖 일기: '\(diary.prefix(50))...'")
        print("   📸 사진: \(selectedPhotos.count)개")
        print("   📍 장소: \(searchedPlaces.count)개")

        // TODO: 여행 기록 저장 로직 구현 (Realm 등)

        navigationController?.popViewController(animated: true)
    }

    @objc private func photoAddButtonTapped() {
        let photoVC = TravelRecordPhotoViewController()
        navigationController?.pushViewController(photoVC, animated: true)
    }

    private func removePhoto(at index: Int) {
        guard index < selectedPhotos.count else { return }

        selectedPhotos.remove(at: index)
        photoCollectionView.reloadData()

        print("📸 사진 삭제: \(index)번째 사진, 남은 사진 \(selectedPhotos.count)개")
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

        // 저장 버튼 바인딩
        saveButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.saveButtonTapped()
            })
            .disposed(by: disposeBag)

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
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "photo"),
                style: .plain,
                target: self,
                action: #selector(photoAddButtonTapped)
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
        return selectedPhotos.count + 1 // +1 for add button
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            // 사진 추가 버튼 셀
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAddCell", for: indexPath) as! PhotoAddCell
            cell.configure()
            return cell
        } else {
            // 사진 표시 셀
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoDisplayCell", for: indexPath) as! PhotoDisplayCell
            let photo = selectedPhotos[indexPath.item - 1]
            cell.configure(with: photo)

            // 삭제 버튼 액션 설정
            cell.deleteHandler = { [weak self] in
                self?.removePhoto(at: indexPath.item - 1)
            }

            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            // 사진 추가 버튼 탭
            photoAddButtonTapped()
        }
    }
}

// MARK: - Collection View Cells
class PhotoAddCell: UICollectionViewCell {
    private let addImageView = UIImageView().then {
        $0.image = UIImage(systemName: "plus")
        $0.tintColor = .systemGray2
        $0.contentMode = .scaleAspectFit
    }

    private let addLabel = UILabel().then {
        $0.text = "사진 추가"
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 12)
        $0.textColor = .systemGray2
        $0.textAlignment = .center
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .systemGray5
        layer.cornerRadius = 8
        layer.borderWidth = 2
        layer.borderColor = UIColor.systemGray4.cgColor

        addSubview(addImageView)
        addSubview(addLabel)

        addImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-10)
            $0.width.height.equalTo(30)
        }

        addLabel.snp.makeConstraints {
            $0.top.equalTo(addImageView.snp.bottom).offset(4)
            $0.centerX.equalToSuperview()
        }
    }

    func configure() {
        // 필요시 추가 설정
    }
}

class PhotoDisplayCell: UICollectionViewCell {
    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
    }

    private let deleteButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        $0.tintColor = .systemRed
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 10
    }

    var deleteHandler: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        layer.cornerRadius = 8
        clipsToBounds = true

        addSubview(imageView)
        addSubview(deleteButton)

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        deleteButton.snp.makeConstraints {
            $0.top.trailing.equalToSuperview().inset(4)
            $0.width.height.equalTo(20)
        }

        // 삭제 버튼 액션 추가
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }

    @objc private func deleteButtonTapped() {
        deleteHandler?()
    }

    func configure(with image: UIImage) {
        imageView.image = image
    }
}
