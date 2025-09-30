//
//  PhotoCollectionViewCell.swift
//  TRACE
//
//  Created by 차지용 on 9/30/25.
//

import UIKit
import Then
import Photos
import PhotosUI

class PhotoCollectionViewCell: UICollectionViewCell {

    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
    }

    private let selectionBorder = UIView().then {
        $0.layer.borderWidth = 3
        $0.layer.borderColor = UIColor.systemBlue.cgColor
        $0.isHidden = true
    }

    private let selectionOverlay = UIView().then {
        $0.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        $0.isHidden = true
    }

    private let checkmarkImageView = UIImageView().then {
        $0.image = UIImage(systemName: "checkmark.circle.fill")
        $0.tintColor = .systemBlue
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.isHidden = true
    }

    var selectionHandler: (() -> Void)?

    var isCurrentMain: Bool = false {
        didSet {
            selectionBorder.isHidden = !isCurrentMain
        }
    }

    var isSelectedForUpload: Bool = false {
        didSet {
            selectionOverlay.isHidden = !isSelectedForUpload
            checkmarkImageView.isHidden = !isSelectedForUpload
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(selectionBorder)
        contentView.addSubview(selectionOverlay)
        contentView.addSubview(checkmarkImageView)

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        selectionBorder.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        selectionOverlay.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        checkmarkImageView.snp.makeConstraints {
            $0.top.trailing.equalToSuperview().inset(8)
            $0.width.height.equalTo(24)
        }
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        contentView.addGestureRecognizer(tapGesture)
    }

    @objc private func cellTapped() {
        selectionHandler?()
    }

    func configure(with asset: PHAsset, imageManager: PHCachingImageManager, thumbnailSize: CGSize) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true

        imageManager.requestImage(
            for: asset,
            targetSize: thumbnailSize,
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, _ in
            DispatchQueue.main.async {
                self?.imageView.image = image
            }
        }
    }
}
