//
//  SearchResultTableViewCell.swift
//  TRACE
//
//  Created by 차지용 on 10/10/25.
//

import UIKit
import Then

class SearchResultTableViewCell: UITableViewCell {

    private let nameLabel = UILabel().then {
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.textColor = .label
        $0.numberOfLines = 1
    }

    private let addressLabel = UILabel().then {
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 14)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 2
    }

    private let categoryLabel = UILabel().then {
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 12)
        $0.textColor = .systemBlue
        $0.numberOfLines = 1
    }

    private let distanceLabel = UILabel().then {
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 12)
        $0.textColor = .systemGray
        $0.numberOfLines = 1
        $0.textAlignment = .right
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .default

        contentView.addSubview(nameLabel)
        contentView.addSubview(addressLabel)
        contentView.addSubview(categoryLabel)
        contentView.addSubview(distanceLabel)

        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalTo(distanceLabel.snp.leading).offset(-8)
        }

        addressLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalTo(distanceLabel.snp.leading).offset(-8)
        }

        categoryLabel.snp.makeConstraints {
            $0.top.equalTo(addressLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview().offset(16)
            $0.bottom.equalToSuperview().offset(-12)
            $0.trailing.equalTo(distanceLabel.snp.leading).offset(-8)
        }

        distanceLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.trailing.equalToSuperview().offset(-16)
            $0.width.equalTo(60)
        }
    }

    func configure(with result: PlaceSearchResult, countryType: String) {
        nameLabel.text = result.name
        addressLabel.text = result.address.isEmpty ? result.roadAddress : result.address
        categoryLabel.text = result.category.isEmpty ? "정보 없음" : result.category

        if countryType == "국내" && !result.distance.isEmpty {
            distanceLabel.text = "\(result.distance)m"
            distanceLabel.isHidden = false
        } else {
            distanceLabel.isHidden = true
        }
    }
}
