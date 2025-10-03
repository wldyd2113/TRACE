//
//  TravelRecordCell.swift
//  TRACE
//
//  Created by 차지용 on 9/30/25.
//

import UIKit
import SnapKit
import Then

class TravelRecordCell: UICollectionViewCell {

    // MARK: - UI Components
    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.backgroundColor = .systemGray5
        $0.layer.cornerRadius = 8
    }

    private let titleLabel = UILabel().then {
        $0.font = FontManager.onglapUIyeon.font(size: 14)
        $0.textColor = .white
        $0.textAlignment = .center
        $0.numberOfLines = 2
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        $0.layer.cornerRadius = 4
        $0.clipsToBounds = true
    }

    private let photoCountLabel = UILabel().then {
        $0.font = FontManager.onglapUIyeon.font(size: 12)
        $0.textColor = .white
        $0.textAlignment = .center
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
        $0.isHidden = true
    }

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(photoCountLabel)

        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(4)
            $0.bottom.equalToSuperview().offset(-4)
            $0.height.greaterThanOrEqualTo(20)
        }

        photoCountLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(4)
            $0.trailing.equalToSuperview().offset(-4)
            $0.width.equalTo(24)
            $0.height.equalTo(16)
        }
    }

    // MARK: - Configuration
    func configure(with model: TravelRecordDisplayModel) {
        // 제목 설정
        titleLabel.text = model.displayTitle

        // 첫 번째 사진 표시
        if let photoData = model.firstPhotoData,
           let image = UIImage(data: photoData) {
            imageView.image = image
        } else {
            // 기본 이미지 또는 색상 배경
            imageView.image = nil
            imageView.backgroundColor = getDefaultColor(for: model.id)
        }

        // 사진 개수 표시
        if model.photoCount > 1 {
            photoCountLabel.text = "\(model.photoCount)"
            photoCountLabel.isHidden = false
        } else {
            photoCountLabel.isHidden = true
        }
    }

    private func getDefaultColor(for id: String) -> UIColor {
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemRed, .systemOrange, .systemPurple]
        let index = abs(id.hashValue) % colors.count
        return colors[index]
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        titleLabel.text = nil
        photoCountLabel.text = nil
        photoCountLabel.isHidden = true
        imageView.backgroundColor = .systemGray5
    }
}
