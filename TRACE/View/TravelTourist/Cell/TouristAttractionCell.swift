//
//  TouristAttractionCell.swift
//  TRACE
//
//  Created by 차지용 on 10/27/25.
//

import UIKit
import SnapKit
import Then
import Kingfisher

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
    }

    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(containerView)

        [imageView, nameLabel, countryLabel].forEach {
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
            $0.height.equalTo(180)
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

        // Kingfisher로 이미지 로딩
        if let imageURLString = attraction.imageURL, let imageURL = URL(string: imageURLString) {
            print("🖼️ 이미지 로딩 시작: \(attraction.name)")

            // 로딩 인디케이터와 플레이스홀더 설정
            let placeholder = UIImage(systemName: "photo")

            imageView.kf.setImage(
                with: imageURL,
                placeholder: placeholder,
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage,
                    .backgroundDecode,
                    .scaleFactor(UIScreen.main.scale),
                    .processor(DownsamplingImageProcessor(size: CGSize(width: 400, height: 400)))
                ]
            ) { [weak self] result in
                switch result {
                case .success(let value):
                    print(" 이미지 로딩 성공: \(attraction.name)")
                    // 이미지 로딩 성공 시 tint 제거
                    self?.imageView.tintColor = nil
                case .failure(let error):
                    print(" 이미지 로딩 실패: \(attraction.name) - \(error.localizedDescription)")
                    // 실패 시 플레이스홀더 아이콘으로 설정
                    self?.imageView.image = UIImage(systemName: "photo")
                    self?.imageView.tintColor = .systemGray3
                }
            }
        } else {
            // 이미지 URL이 없는 경우 플레이스홀더
            imageView.image = UIImage(systemName: "photo")
            imageView.tintColor = .systemGray3
            print("📷 이미지 URL 없음: \(attraction.name)")
        }
    }
}
