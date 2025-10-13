//
//  TravelRecordViewController.swift
//  TRACE
//
//  Created by 차지용 on 9/27/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Then
import RealmSwift

class TravelRecordViewController: UIViewController {

    private let disposeBag = DisposeBag()
    private let viewModel = RecordViewModel()

    // ViewModel Input Triggers
    private let viewDidLoadTrigger = PublishRelay<Void>()
    private let refreshTrigger = PublishRelay<Void>()
    private let recordSelectedTrigger = PublishRelay<IndexPath>()

    // MARK: - UI Components
    private let titleLabel = UILabel().then {
        $0.text = NSLocalizedString("travel_record", comment: "Travel Record title")
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 24)
        $0.textColor = .label
        $0.textAlignment = .left
    }

    private let addButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "plus"), for: .normal)
        $0.tintColor = .label
        $0.backgroundColor = .clear
    }

    private let recordCountLabel = UILabel().then {
        $0.text = String(format: NSLocalizedString("posts_format", comment: "Posts count format"), 0)
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 18)
        $0.textColor = .label
        $0.textAlignment = .center
        $0.numberOfLines = 2
    }

    private lazy var collectionView: UICollectionView = {
        let layout = Self.layout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .background
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()

    // MARK: - Cell Registration
    var registration: UICollectionView.CellRegistration<TravelRecordCell, TravelRecordDisplayModel>!

    // MARK: - Data
    private var displayModels: [TravelRecordDisplayModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        print("📱 TravelRecordViewController viewDidLoad 시작")

        // Realm 초기화 체크
        if RealmManager.shared.safeRealm() == nil {
            print("❌ Realm 초기화 실패 - 앱을 종료합니다")
            return
        }

        view.backgroundColor = .background

        configureHierarchy()
        configureUI()
        configureLayout()
        bind()
        bindViewModel()
        configureDataSource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)

        // 데이터 새로고침
        refreshTrigger.accept(())
    }

    // MARK: - Compositional Layout
    private static func layout() -> UICollectionViewLayout {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/3), heightDimension: .fractionalHeight(1.0)))

        item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(150))

        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)

        let layout = UICollectionViewCompositionalLayout(section: section)

        return layout
    }

    // MARK: - Actions
    @objc private func addButtonTapped() {
        print("📝 새 여행 기록 추가")
        let writeVC = TravelRecordPhotoViewController()
        navigationController?.pushViewController(writeVC, animated: true)
    }

    // MARK: - ViewModel Binding
    private func bindViewModel() {
        // Input 생성
        let input = RecordViewModel.Input(
            viewDidLoad: viewDidLoadTrigger.asDriver(onErrorJustReturn: ()),
            refreshTriggered: refreshTrigger.asDriver(onErrorJustReturn: ()),
            recordSelected: recordSelectedTrigger.asDriver(onErrorJustReturn: IndexPath(item: 0, section: 0))
        )

        // Transform
        let output = viewModel.transform(input: input)

        // Output 바인딩
        // 여행 기록 목록 업데이트
        output.records
            .drive(onNext: { [weak self] models in
                DispatchQueue.main.async {
                    self?.displayModels = models
                    self?.collectionView.reloadData()
                }
            })
            .disposed(by: disposeBag)

        // 기록 개수 업데이트
        output.recordCount
            .drive(onNext: { [weak self] count in
                self?.recordCountLabel.text = count
            })
            .disposed(by: disposeBag)

        // 선택된 기록 처리 (TravelShowRecordViewController로 이동)
        output.selectedRecordId
            .compactMap { $0 }
            .drive(onNext: { [weak self] recordId in
                self?.navigateToShowRecord(with: recordId)
            })
            .disposed(by: disposeBag)

        // 초기 로드 트리거 (안전하게 지연)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.viewDidLoadTrigger.accept(())
        }
    }

    private func navigateToShowRecord(with recordId: String) {
        print("📱 기록 상세보기 이동: \(recordId)")

        // ViewModel에서 기록 조회
        guard let record = viewModel.getRecord(by: recordId) else {
            print("❌ 기록을 찾을 수 없습니다: \(recordId)")
            return
        }

        let showRecordVC = TravelShowRecordViewController()

        // 실제 저장된 데이터를 TravelShowRecordViewController에 전달
        let photos = loadPhotosFromRecord(record)
        let route = record.travelName
        let recordText = record.recordLog
        let places = createPlacesFromRecord(record)

        showRecordVC.setRecordData(
            photos: photos,
            route: route,
            record: recordText,
            places: places
        )

        showRecordVC.travelRecordId = recordId

        navigationController?.pushViewController(showRecordVC, animated: true)
    }

    private func loadPhotosFromRecord(_ record: TravelRecord) -> [UIImage] {
        guard let photoFileNames = record.photo?.photos else { return [] }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var images: [UIImage] = []

        for fileName in photoFileNames {
            let photoPath = documentsPath.appendingPathComponent(fileName)
            do {
                let data = try Data(contentsOf: photoPath)
                if let image = UIImage(data: data) {
                    images.append(image)
                }
            } catch {
                print("❌ 사진 로드 실패: \(fileName)")
            }
        }

        return images
    }

    private func createPlacesFromRecord(_ record: TravelRecord) -> [KakaoPlace] {
        guard !record.locations.isEmpty else { return [] }

        return record.locations.map { location in
            KakaoPlace(
                id: record.id.stringValue,
                placeName: location.location,
                categoryName: NSLocalizedString("travel_destination_category", comment: "Travel destination category"),
                categoryGroupCode: "AT4",
                categoryGroupName: NSLocalizedString("tourist_attraction", comment: "Tourist attraction"),
                phone: "",
                addressName: location.location,
                roadAddressName: "",
                x: String(location.longitude),
                y: String(location.latitude),
                placeUrl: "",
                distance: "0"
            )
        }
    }
}

// MARK: - DesiginProtocolBind
extension TravelRecordViewController: DesiginProtocolBind {
    func bind() {
        addButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.addButtonTapped()
            })
            .disposed(by: disposeBag)
    }

    func configureHierarchy() {
        view.addSubview(titleLabel)
        view.addSubview(addButton)
        view.addSubview(recordCountLabel)
        view.addSubview(collectionView)
    }

    func configureUI() {
        collectionView.delegate = self
        collectionView.dataSource = self
    }

    func configureDataSource() {
        registration = UICollectionView.CellRegistration(handler: { cell, indexPath, model in
            cell.configure(with: model)
        })
    }

    func configureLayout() {
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.equalToSuperview().offset(20)
        }

        addButton.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().offset(-20)
            $0.width.height.equalTo(30)
        }

        recordCountLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(40)
            $0.centerX.equalToSuperview()
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(recordCountLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension TravelRecordViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = displayModels.count
        print("📱 CollectionView numberOfItems: \(count)")
        return count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("📱 CollectionView cellForItemAt: \(indexPath.item)")

        guard indexPath.item < displayModels.count else {
            print("❌ IndexPath out of bounds: \(indexPath.item) >= \(displayModels.count)")
            // 임시로 빈 셀 반환
            return UICollectionViewCell()
        }

        let model = displayModels[indexPath.item]
        let cell = collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: model)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("📱 여행 기록 선택: \(indexPath.item + 1)번째")
        recordSelectedTrigger.accept(indexPath)
    }

}
