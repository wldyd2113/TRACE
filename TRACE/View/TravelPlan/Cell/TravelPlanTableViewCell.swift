//
//  TravelPlanTableViewCell.swift
//  TRACE
//
//  Created by 차지용 on 9/26/25.
//

import UIKit
import SnapKit
import Then

class TravelPlanTableViewCell: UITableViewCell {

    // MARK: - UI Components
    private let locationIconImageView = UIImageView().then {
        $0.image = UIImage(systemName: "mappin.and.ellipse")
        $0.tintColor = .systemRed
        $0.contentMode = .scaleAspectFit
    }

    private let locationLabel = UILabel().then {
        $0.font = FontManager.onglapFont(16)
        $0.textColor = .labelLight
    }

    private let countryLabel = UILabel().then {
        $0.font = FontManager.onglapFont(12)
        $0.textColor = .systemGray
    }

    private let dateLabel = UILabel().then {
        $0.font = FontManager.onglapFont(12)
        $0.textColor = .systemGray
        $0.textAlignment = .right
    }

    private let editIconImageView = UIImageView().then {
        $0.image = UIImage(systemName: "pencil")
        $0.tintColor = .systemOrange
        $0.contentMode = .scaleAspectFit
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .background
        selectionStyle = .none

        contentView.addSubview(locationIconImageView)
        contentView.addSubview(locationLabel)
        contentView.addSubview(countryLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(editIconImageView)

        locationIconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(20)
        }

        locationLabel.snp.makeConstraints {
            $0.leading.equalTo(locationIconImageView.snp.trailing).offset(12)
            $0.top.equalToSuperview().offset(12)
        }

        countryLabel.snp.makeConstraints {
            $0.leading.equalTo(locationLabel)
            $0.top.equalTo(locationLabel.snp.bottom).offset(4)
            $0.bottom.equalToSuperview().offset(-12)
        }

        editIconImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(16)
        }

        dateLabel.snp.makeConstraints {
            $0.trailing.equalTo(editIconImageView.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
        }
    }

    func configure(location: String, country: String, date: String) {
        locationLabel.text = location
        countryLabel.text = country
        dateLabel.text = date
    }
}
