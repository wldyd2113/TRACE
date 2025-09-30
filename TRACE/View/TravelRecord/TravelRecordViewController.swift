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
        print("📱 사진 선택: \(indexPath.item + 1)번째")

        let detailVC = TravelRecordPhotoViewController()
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
