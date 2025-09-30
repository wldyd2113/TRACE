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

    private let disposeBag = DisposeBag()
    let mapManager = MapManager()

    // MARK: - Data
    var travelRecordId: String?
    var isEditMode = false
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
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(RecordPhotoCell.self, forCellWithReuseIdentifier: "RecordPhotoCell")
        return collectionView
    }()

    // 여행 경로 섹션
    private let routeTitleLabel = UILabel().then {
        $0.text = "여행 경로"
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 18)
        $0.textColor = .label
    }

    private let routeTextField = UITextField().then {
        $0.placeholder = "정말놀라운 여행이었어요"
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.borderStyle = .roundedRect
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 8
        $0.isUserInteractionEnabled = false
    }

    // MapKit 관련 (MapManager에서 관리)
    private var mapView: MKMapView {
        return mapManager.mapView
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

    // 하단 버튼
    private let routeButton = UIButton(type: .system).then {
        $0.setTitle("경로보러가기", for: .normal)
        $0.titleLabel?.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 18)
        $0.backgroundColor = .black
        $0.setTitleColor(.white, for: .normal)
        $0.layer.cornerRadius = 25
    }

    // 편집 모드 버튼들
    private let editButton = UIButton(type: .system).then {
        $0.setTitle("편집", for: .normal)
        $0.titleLabel?.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.backgroundColor = .systemBlue
        $0.setTitleColor(.white, for: .normal)
        $0.layer.cornerRadius = 20
        $0.isHidden = false
    }

    private let saveButton = UIButton(type: .system).then {
        $0.setTitle("저장", for: .normal)
        $0.titleLabel?.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.backgroundColor = .darkBlue
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

        // 초기 데이터 로드
        loadRecordData()
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

    // MARK: - Data Loading
    private func loadRecordData() {
        // TODO: Realm에서 여행 기록 데이터 로드
        print("📖 여행 기록 데이터 로드")

        // 샘플 데이터
        routeTextField.text = "정말놀라운 여행이었어요"
        recordTextView.text = "여행의 정말 좋은 기록하세요..."
        recordPlaceholderLabel.isHidden = !recordTextView.text.isEmpty
    }

    // MARK: - Actions
    @objc private func editButtonTapped() {
        toggleEditMode(true)
    }

    @objc private func saveButtonTapped() {
        print("💾 여행 기록 저장")
        // TODO: 수정된 데이터 저장
        toggleEditMode(false)
    }

    @objc private func cancelButtonTapped() {
        print("❌ 편집 취소")
        // TODO: 원래 데이터로 복원
        toggleEditMode(false)
    }

    @objc private func routeButtonTapped() {
        print("🗺️ 경로보러가기")
        handleRouteButtonTapped()
    }

    private func toggleEditMode(_ edit: Bool) {
        isEditMode = edit

        recordTextView.isEditable = edit
        routeTextField.isUserInteractionEnabled = edit

        editButton.isHidden = edit
        saveButton.isHidden = !edit
        cancelButton.isHidden = !edit

        if edit {
            recordTextView.becomeFirstResponder()
        } else {
            view.endEditing(true)
        }

        print("🔄 편집 모드: \(edit ? "ON" : "OFF")")
    }

    // MARK: - Public Methods
    func setRecordData(photos: [UIImage], route: String, record: String, places: [KakaoPlace]) {
        recordPhotos = photos
        routeTextField.text = route
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
        // 편집 버튼 바인딩
        editButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.editButtonTapped()
            })
            .disposed(by: disposeBag)

        // 저장 버튼 바인딩
        saveButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.saveButtonTapped()
            })
            .disposed(by: disposeBag)

        // 취소 버튼 바인딩
        cancelButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.cancelButtonTapped()
            })
            .disposed(by: disposeBag)

        // 경로보러가기 버튼 바인딩
        routeButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.routeButtonTapped()
            })
            .disposed(by: disposeBag)

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
        contentView.addSubview(routeTextField)

        contentView.addSubview(mapView)
        contentView.addSubview(mapDescriptionLabel)

        contentView.addSubview(recordTitleLabel)
        contentView.addSubview(recordTextView)
        contentView.addSubview(recordPlaceholderLabel)
        contentView.addSubview(recordDescriptionLabel)

        view.addSubview(routeButton)
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
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(systemName: "square.and.arrow.up"),
                style: .plain,
                target: self,
                action: #selector(shareButtonTapped)
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "folder"),
                style: .plain,
                target: self,
                action: #selector(saveToAlbumTapped)
            )
        ]

        // TextView 설정
        recordTextView.textContainer.lineFragmentPadding = 0
        recordTextView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }

    func configureLayout() {
        scrollView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(routeButton.snp.top).offset(-20)
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
        routeTitleLabel.snp.makeConstraints {
            $0.top.equalTo(photoCollectionView.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        routeTextField.snp.makeConstraints {
            $0.top.equalTo(routeTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        // 지도 영역
        mapView.snp.makeConstraints {
            $0.top.equalTo(routeTextField.snp.bottom).offset(16)
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

        // 하단 버튼들
        routeButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.height.equalTo(50)
        }

        // 편집 모드 버튼들
        editButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.bottom.equalTo(routeButton.snp.top).offset(-16)
            $0.width.equalTo(60)
            $0.height.equalTo(40)
        }

        saveButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.bottom.equalTo(routeButton.snp.top).offset(-16)
            $0.width.equalTo(60)
            $0.height.equalTo(40)
        }

        cancelButton.snp.makeConstraints {
            $0.trailing.equalTo(saveButton.snp.leading).offset(-12)
            $0.bottom.equalTo(routeButton.snp.top).offset(-16)
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

    @objc private func shareButtonTapped() {
        print("📤 여행 기록 공유")
        // TODO: 여행 기록 공유 기능 구현
    }

    @objc private func saveToAlbumTapped() {
        print("📁 앨범에 저장")
        // TODO: 사진 앨범에 저장 기능 구현
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension TravelShowRecordViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recordPhotos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecordPhotoCell", for: indexPath) as! RecordPhotoCell
        let photo = recordPhotos[indexPath.item]
        cell.configure(with: photo)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 사진 확대 보기
        let photo = recordPhotos[indexPath.item]
        showPhotoDetail(photo: photo, at: indexPath.item)
    }

    private func showPhotoDetail(photo: UIImage, at index: Int) {
        print("🖼️ 사진 상세 보기: \(index + 1)번째 사진")
        // TODO: 사진 상세 보기 화면 구현
    }
}

// MARK: - Collection View Cell
class RecordPhotoCell: UICollectionViewCell {
    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
    }

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

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    func configure(with image: UIImage) {
        imageView.image = image
    }
}
