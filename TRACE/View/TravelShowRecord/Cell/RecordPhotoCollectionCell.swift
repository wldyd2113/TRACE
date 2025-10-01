//
//  RecordPhotoCollectionCell.swift
//  TRACE
//
//  Created by 차지용 on 9/30/25.
//

import UIKit
import SnapKit
import Then

class RecordPhotoCollectionCell: UICollectionViewCell {

    // MARK: - UI Components
    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
        $0.backgroundColor = .systemGray5
    }

    private let placeholderLabel = UILabel().then {
        $0.text = "📷"
        $0.font = .systemFont(ofSize: 40)
        $0.textAlignment = .center
        $0.textColor = .systemGray3
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
        layer.cornerRadius = 8
        clipsToBounds = true
        backgroundColor = .systemGray6

        contentView.addSubview(imageView)
        contentView.addSubview(placeholderLabel)

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        placeholderLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    // MARK: - Configuration
    func configure(with image: UIImage?) {
        if let image = image {
            imageView.image = image
            imageView.isHidden = false
            placeholderLabel.isHidden = true
        } else {
            imageView.image = nil
            imageView.isHidden = true
            placeholderLabel.isHidden = false
        }
    }

    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        imageView.isHidden = false
        placeholderLabel.isHidden = true
    }
}