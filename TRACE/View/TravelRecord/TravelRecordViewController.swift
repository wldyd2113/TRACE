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

    // MARK: - UI Components
    private let titleLabel = UILabel().then {
        $0.text = "여행기록"
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
        $0.text = "5\n게시물"
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
    var registration: UICollectionView.CellRegistration<UICollectionViewListCell, String>!

    // MARK: - Data
    private let samplePhotos = [
        "사진 1",
        "사진 2",
        "사진 3",
        "사진 4",
        "사진 5"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background

        configureHierarchy()
        configureUI()
        configureLayout()
        bind()
        configureDataSource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
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
        registration = UICollectionView.CellRegistration(handler: { cell, indexPath, itemIdentifier in
            var content = UIListContentConfiguration.valueCell()
            content.text = itemIdentifier
            content.textProperties.color = .white
            content.textProperties.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16) ?? .boldSystemFont(ofSize: 16)
            content.textProperties.alignment = .center

            cell.contentConfiguration = content

            var background = UIBackgroundConfiguration.listGroupedCell()

            // 인덱스에 따른 다른 색상 설정
            let colors: [UIColor] = [.systemBlue, .systemGreen, .systemRed, .systemOrange, .systemPurple]
            background.backgroundColor = colors[indexPath.item % colors.count]
            background.cornerRadius = 8

            cell.backgroundConfiguration = background
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
        return samplePhotos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: samplePhotos[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("📱 여행 기록 선택: \(indexPath.item + 1)번째")

        // TravelShowRecordViewController로 이동
        let showRecordVC = TravelShowRecordViewController()

        // 샘플 데이터 전달 (실제로는 Realm에서 로드)
        let sampleData = createSampleRecordData(for: indexPath.item)
        showRecordVC.setRecordData(
            photos: sampleData.photos,
            route: sampleData.route,
            record: sampleData.record,
            places: sampleData.places
        )

        showRecordVC.travelRecordId = "\(indexPath.item + 1)" // 실제로는 Realm ID 사용

        navigationController?.pushViewController(showRecordVC, animated: true)
    }

    // MARK: - Sample Data Creation
    private func createSampleRecordData(for index: Int) -> (photos: [UIImage], route: String, record: String, places: [KakaoPlace]) {

        // 샘플 사진들 생성 (실제로는 저장된 이미지 사용)
        let samplePhotos: [UIImage] = {
            var photos: [UIImage] = []
            for i in 0..<(index % 3 + 1) { // 1~3개 사진
                if let image = createSampleImage(with: "📷 \(i + 1)", color: getSampleColor(for: index)) {
                    photos.append(image)
                }
            }
            return photos
        }()

        // 샘플 경로 데이터
        let sampleRoutes = [
            "서울 → 부산 여행",
            "제주도 한 바퀴",
            "경주 역사 탐방",
            "강릉 바다 여행",
            "전주 맛집 투어"
        ]

        // 샘플 기록 데이터
        let sampleRecords = [
            "정말 즐거운 여행이었습니다! 날씨도 좋고 음식도 맛있었어요. 다음에 또 오고 싶은 곳입니다.",
            "아름다운 자연 경관에 감동받았습니다. 사진으로는 담을 수 없는 아름다움이었어요.",
            "역사의 흔적을 따라 걷는 의미 있는 시간이었습니다. 많은 것을 배우고 느꼈어요.",
            "시원한 바닷바람과 함께한 힐링 여행! 스트레스가 모두 날아갔습니다.",
            "맛있는 음식들로 가득한 여행! 배도 마음도 모두 만족스러웠습니다."
        ]

        // 샘플 장소 데이터
        let samplePlaces: [KakaoPlace] = {
            let places = [
                ("서울역", 37.5547, 126.9707),
                ("부산역", 35.1151, 129.0416),
                ("제주공항", 33.5120, 126.4914),
                ("경주 불국사", 35.7898, 129.3322),
                ("강릉 경포대", 37.7954, 128.8961)
            ]

            let selectedPlace = places[index % places.count]

            return [KakaoPlace(
                id: "\(index)",
                placeName: selectedPlace.0,
                categoryName: "관광지",
                categoryGroupCode: "AT4",
                categoryGroupName: "관광명소",
                phone: "",
                addressName: "\(selectedPlace.0) 주변",
                roadAddressName: "",
                x: String(selectedPlace.2),
                y: String(selectedPlace.1),
                placeUrl: "https://place.map.kakao.com/\(index)",
                distance: "0"
            )]
        }()

        return (
            photos: samplePhotos,
            route: sampleRoutes[index % sampleRoutes.count],
            record: sampleRecords[index % sampleRecords.count],
            places: samplePlaces
        )
    }

    private func createSampleImage(with text: String, color: UIColor) -> UIImage? {
        let size = CGSize(width: 300, height: 300)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)

        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.white
        ]

        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )

        text.draw(in: textRect, withAttributes: attributes)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    private func getSampleColor(for index: Int) -> UIColor {
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemRed, .systemOrange, .systemPurple]
        return colors[index % colors.count]
    }
}
