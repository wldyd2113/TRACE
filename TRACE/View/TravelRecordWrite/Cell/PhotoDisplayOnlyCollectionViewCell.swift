//
//  PhotoDisplayOnlyCollectionViewCell.swift
//  TRACE
//
//  Created by 차지용 on 9/30/25.
//

import UIKit
import SnapKit
import Then
    
class PhotoDisplayOnlyCollectionViewCell: UICollectionViewCell {

    // MARK: - UI Components
    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.backgroundColor = .systemGray5
        $0.layer.cornerRadius = 8
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

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    // MARK: - Configuration
    func configure(with image: UIImage) {
        imageView.image = image
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}
