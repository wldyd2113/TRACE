//
//  TravelDayCell.swift
//  TRACE
//
//  Created by 차지용 on 9/29/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

class TravelDayCell: UICollectionViewCell, BaseCellProtocol, DesiginProtocol {

    // MARK: - Properties
    private var disposeBag = DisposeBag()

    // MARK: - UI Components
    private let dayLabel = UILabel().then {
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.textAlignment = .center
        $0.textColor = .labelLight
    }

    private let containerView = UIView().then {
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 12
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.systemGray4.cgColor
    }

    // MARK: - BaseCellProtocol Implementation
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureLayout()
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - DesiginProtocol Implementation
    func configureHierarchy() {
        contentView.addSubview(containerView)
        containerView.addSubview(dayLabel)
    }

    func configureLayout() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(60)
        }

        dayLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    func configureUI() {
        // 초기 상태 설정
        updateSelectionState(isSelected: false)
    }

    // MARK: - Configuration
    func configure(day: Int, isSelected: Bool) {
        dayLabel.text = "\(day)일차"
        updateSelectionState(isSelected: isSelected)

        print("📱 TravelDayCell 구성: \(day)일차, 선택됨: \(isSelected)")
    }

    private func updateSelectionState(isSelected: Bool) {
        if isSelected {
            containerView.backgroundColor = .buttonDark
            containerView.layer.borderColor = UIColor.buttonDark.cgColor
            dayLabel.textColor = .white
            dayLabel.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)?.withWeight(.bold)
        } else {
            containerView.backgroundColor = .systemGray6
            containerView.layer.borderColor = UIColor.systemGray4.cgColor
            dayLabel.textColor = .labelLight
            dayLabel.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        }
    }

    // MARK: - Animation
    func animateSelection() {
        UIView.animate(withDuration: 0.2, animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                self.transform = CGAffineTransform.identity
            }
        }
    }
}

// MARK: - UIFont Extension for Weight
extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([
            UIFontDescriptor.AttributeName.traits: [
                UIFontDescriptor.TraitKey.weight: weight
            ]
        ])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
