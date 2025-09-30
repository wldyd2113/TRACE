//
//  TravelRecordPhotoViewController.swift
//  TRACE
//
//  Created by 차지용 on 9/30/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Then
import Photos
import PhotosUI

class TravelRecordPhotoViewController: UIViewController {

    private let disposeBag = DisposeBag()

    // MARK: - UI Components
    private let mainImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.backgroundColor = .systemGray5
    }

    private lazy var collectionView: UICollectionView = {
        let layout = createCompositionalLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .background
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()

    private let selectButton = UIButton(type: .system).then {
        $0.setTitle("선택", for: .normal)
        $0.titleLabel?.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.setTitleColor(.systemBlue, for: .normal)
    }

    private let statusLabel = UILabel().then {
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 14)
        $0.textColor = .secondaryLabel
        $0.textAlignment = .center
        $0.numberOfLines = 2
    }

    // MARK: - PhotoKit Properties
    private var allPhotos: PHFetchResult<PHAsset>!
    private let imageManager = PHCachingImageManager()
    private var thumbnailSize: CGSize!
    private var mainImageSize: CGSize!
    private var selectedAssets: Set<PHAsset> = []
    private var currentMainAsset: PHAsset?

    // MARK: - Cell Registration
    private var photoCellRegistration: UICollectionView.CellRegistration<PhotoCollectionViewCell, PHAsset>!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background

        configureHierarchy()
        configureUI()
        configureLayout()
        bind()
        configureCellRegistration()
        requestPhotoLibraryPermission()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - PhotoKit Setup
    private func requestPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .authorized:
            loadPhotos()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self?.loadPhotos()
                    } else {
                        self?.showPermissionDeniedAlert()
                    }
                }
            }
        case .denied, .restricted:
            showPermissionDeniedAlert()
        case .limited:
            loadPhotos()
        @unknown default:
            showPermissionDeniedAlert()
        }
    }

    private func loadPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        DispatchQueue.main.async { [weak self] in
            self?.updateStatusLabel()
            self?.collectionView.reloadData()
            self?.loadFirstPhoto()
        }

        print("📸 사진 로드 완료: \(allPhotos.count)개")
    }

    private func updateStatusLabel() {
        let totalCount = allPhotos?.count ?? 0
        let selectedCount = selectedAssets.count

        if selectedCount > 0 {
            statusLabel.text = "\(selectedCount)개 선택됨"
        } else {
            statusLabel.text = "총 \(totalCount)개 사진"
        }
    }

    private func showPermissionDeniedAlert() {
        statusLabel.text = "사진 접근 권한이 필요합니다\n설정에서 권한을 허용해주세요"

        let alert = UIAlertController(
            title: "사진 접근 권한 필요",
            message: "여행 기록을 위해 사진 라이브러리 접근 권한이 필요합니다.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        present(alert, animated: true)
    }

    private func loadFirstPhoto() {
        guard let allPhotos = allPhotos, allPhotos.count > 0 else { return }

        let firstAsset = allPhotos.object(at: 0)
        currentMainAsset = firstAsset
        loadMainImage(asset: firstAsset)
    }

    private func loadMainImage(asset: PHAsset) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        imageManager.requestImage(
            for: asset,
            targetSize: mainImageSize,
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, _ in
            DispatchQueue.main.async {
                self?.mainImageView.image = image
            }
        }
    }

    // MARK: - Compositional Layout (인스타그램 스타일)
    private func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0/4.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(80)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0)

        return UICollectionViewCompositionalLayout(section: section)
    }

    // MARK: - Cell Registration
    private func configureCellRegistration() {
        photoCellRegistration = UICollectionView.CellRegistration<PhotoCollectionViewCell, PHAsset> { [weak self] cell, indexPath, asset in
            guard let self = self else { return }

            // 안전한 썸네일 크기 확인
            let safeSize = self.thumbnailSize ?? CGSize(width: 100, height: 100)

            cell.configure(with: asset, imageManager: self.imageManager, thumbnailSize: safeSize)

            // 현재 메인에 표시된 사진인지 확인
            cell.isCurrentMain = (asset == self.currentMainAsset)
            cell.isSelectedForUpload = self.selectedAssets.contains(asset)

            cell.selectionHandler = { [weak self] in
                self?.handleCellTap(asset: asset, at: indexPath)
            }
        }
    }

    private func handleCellTap(asset: PHAsset, at indexPath: IndexPath) {
        // 메인 이미지 변경
        selectPhotoForMain(asset: asset, at: indexPath)

        // 다중 선택 토글
        toggleMultiSelection(asset: asset, at: indexPath)
    }

    private func selectPhotoForMain(asset: PHAsset, at indexPath: IndexPath) {
        // 이전 선택된 셀 업데이트
        if let previousAsset = currentMainAsset,
           let previousIndex = findIndexPath(for: previousAsset) {
            if let previousCell = collectionView.cellForItem(at: previousIndex) as? PhotoCollectionViewCell {
                previousCell.isCurrentMain = false
            }
        }

        // 새로운 셀 업데이트
        currentMainAsset = asset
        if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell {
            cell.isCurrentMain = true
        }

        // 메인 이미지 변경
        loadMainImage(asset: asset)

        print("📸 메인 사진 변경: \(indexPath.item)번째 사진")
    }

    private func toggleMultiSelection(asset: PHAsset, at indexPath: IndexPath) {
        if selectedAssets.contains(asset) {
            selectedAssets.remove(asset)
        } else {
            selectedAssets.insert(asset)
        }

        // 셀 업데이트
        if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell {
            cell.isSelectedForUpload = selectedAssets.contains(asset)
        }

        updateStatusLabel()
        print("📸 다중 선택: \(selectedAssets.count)개 사진 선택됨")
    }

    private func findIndexPath(for asset: PHAsset) -> IndexPath? {
        guard let allPhotos = allPhotos else { return nil }

        for i in 0..<allPhotos.count {
            if allPhotos.object(at: i) == asset {
                return IndexPath(item: i, section: 0)
            }
        }
        return nil
    }

    // MARK: - Actions
    @objc private func backButtonTapped() {
        print("🔙 사진 선택: Back 버튼 클릭")
        navigationController?.popViewController(animated: true)
    }

    @objc private func selectButtonTapped() {
        if selectedAssets.isEmpty {
            let alert = UIAlertController(title: "알림", message: "선택된 사진이 없습니다.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }

        print("📸 선택 완료: \(selectedAssets.count)개 사진 선택됨")

        // 선택된 PHAsset들을 UIImage로 변환
        convertSelectedAssetsToImages { [weak self] images in
            DispatchQueue.main.async {
                // TravelRecordWriteViewController로 이동
                let writeVC = TravelRecordWriteViewController()
                writeVC.setSelectedPhotos(images)
                self?.navigationController?.pushViewController(writeVC, animated: true)
            }
        }
    }

    // MARK: - Image Conversion
    private func convertSelectedAssetsToImages(completion: @escaping ([UIImage]) -> Void) {
        let group = DispatchGroup()
        var images: [UIImage] = []
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        let targetSize = CGSize(width: 1000, height: 1000) // 적절한 크기로 조정

        for asset in selectedAssets {
            group.enter()

            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                if let image = image {
                    images.append(image)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            print("📸 이미지 변환 완료: \(images.count)개")
            completion(images)
        }
    }
}

// MARK: - DesiginProtocolBind
extension TravelRecordPhotoViewController: DesiginProtocolBind {
    func bind() {
        selectButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.selectButtonTapped()
            })
            .disposed(by: disposeBag)
    }

    func configureHierarchy() {
        view.addSubview(mainImageView)
        view.addSubview(collectionView)
        view.addSubview(statusLabel)
    }

    func configureUI() {
        // Navigation Bar 설정
        navigationItem.title = "사진 선택"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: selectButton)

        // CollectionView 설정
        collectionView.delegate = self
        collectionView.dataSource = self

        // 이미지 크기 계산
        let scale = UIScreen.main.scale
        let screenWidth = max(view.bounds.width, 300)

        // 메인 이미지 크기 (정사각형)
        mainImageSize = CGSize(width: screenWidth * scale, height: screenWidth * scale)

        // 썸네일 크기 (4열 그리드)
        let cellSize: CGFloat = 80
        thumbnailSize = CGSize(width: cellSize * scale, height: cellSize * scale)
    }

    func configureLayout() {
        mainImageView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(mainImageView.snp.width) // 정사각형
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(mainImageView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(statusLabel.snp.top).offset(-10)
        }

        statusLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.height.equalTo(40)
        }
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension TravelRecordPhotoViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let allPhotos = allPhotos else {
            print("⚠️ allPhotos가 nil입니다")
            return 0
        }
        return allPhotos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let allPhotos = allPhotos,
              indexPath.item < allPhotos.count else {
            print("❌ 잘못된 인덱스 접근: \(indexPath.item)")
            // 빈 셀 반환
            return UICollectionViewCell()
        }

        let asset = allPhotos.object(at: indexPath.item)
        let cell = collectionView.dequeueConfiguredReusableCell(using: photoCellRegistration, for: indexPath, item: asset)
        return cell
    }
}


