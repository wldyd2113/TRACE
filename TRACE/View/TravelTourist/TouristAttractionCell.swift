//
//  TouristAttractionCell.swift
//  TRACE
//
//  Created by 차지용 on 10/27/25.
//

import UIKit
import SnapKit
import Then

class TouristAttractionCell: UICollectionViewCell {

    // MARK: - UI Components
    private let containerView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 12
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 4
        $0.layer.shadowOpacity = 0.1
    }

    private let imageView = UIImageView().then {
        $0.backgroundColor = .systemGray5
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
        $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }

    private let nameLabel = UILabel().then {
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.textColor = .label
        $0.textAlignment = .center
        $0.numberOfLines = 2
    }

    private let countryLabel = UILabel().then {
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 12)
        $0.textColor = .secondaryLabel
        $0.textAlignment = .center
    }

    private let categoryBadge = UILabel().then {
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 10)
        $0.textColor = .white
        $0.backgroundColor = .skyBlue
        $0.textAlignment = .center
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
    }

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        nameLabel.text = nil
        countryLabel.text = nil
        categoryBadge.text = nil
    }

    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(containerView)

        [imageView, nameLabel, countryLabel, categoryBadge].forEach {
            containerView.addSubview($0)
        }

        setupConstraints()
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(4)
        }

        imageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(8)
            $0.height.equalTo(120)
        }

        categoryBadge.snp.makeConstraints {
            $0.top.equalTo(imageView).offset(8)
            $0.trailing.equalTo(imageView).offset(-8)
            $0.width.equalTo(50)
            $0.height.equalTo(16)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(8)
        }

        countryLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(8)
            $0.bottom.equalToSuperview().offset(-8)
        }
    }

    // MARK: - Configuration
    func configure(with attraction: TouristAttraction) {
        nameLabel.text = attraction.name
        countryLabel.text = attraction.country
        categoryBadge.text = attraction.category.localizedTitle

        // 플레이스홀더 이미지 설정
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = .systemGray3

        // TODO: 실제 이미지 로드
        if let imageURL = attraction.imageURL {
            loadImage(from: imageURL)
        }
    }

    private func loadImage(from urlString: String) {
        // TODO: 이미지 로딩 구현 (Kingfisher 등 사용)
        // 현재는 플레이스홀더만 표시
    }
}