//
//  DayButton.swift
//  TRACE
//
//  Created by 차지용 on 9/28/25.
//

import UIKit
import SnapKit

class DayButton: UIButton {
    let dayNumber: Int
    private let customTitle: String?

    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }

    init(day: Int, title: String? = nil, isSelected: Bool = false) {
        self.dayNumber = day
        self.customTitle = title
        super.init(frame: .zero)

        self.isSelected = isSelected
        setupButton()
        updateAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupButton() {
        backgroundColor = .systemGray6
        layer.cornerRadius = 8

        let calendarImageView = UIImageView(image: UIImage(systemName: "calendar"))
        calendarImageView.tintColor = .systemRed
        calendarImageView.contentMode = .scaleAspectFit

        let dayLabel = UILabel()
        dayLabel.text = "17"
        dayLabel.font = UIFont.boldSystemFont(ofSize: 16)
        dayLabel.textColor = .labelLight
        dayLabel.textAlignment = .center

        let titleLabel = UILabel()
        titleLabel.text = customTitle ?? "\(dayNumber)일차"
        titleLabel.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 12)
        titleLabel.textColor = .labelLight
        titleLabel.textAlignment = .center

        addSubview(calendarImageView)
        addSubview(dayLabel)
        addSubview(titleLabel)

        calendarImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(20)
        }

        dayLabel.snp.makeConstraints {
            $0.top.equalTo(calendarImageView.snp.bottom).offset(4)
            $0.centerX.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(dayLabel.snp.bottom).offset(4)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-8)
        }
    }

    private func updateAppearance() {
        backgroundColor = isSelected ? .background : .systemGray6
        alpha = isSelected ? 1.0 : 0.7
    }
}
