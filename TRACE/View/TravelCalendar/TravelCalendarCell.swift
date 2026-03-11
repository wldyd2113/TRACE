//
//  TravelCalendarViewController.swift
//  TRACE
//
//  Created by 차지용 on 10/21/25.
//
import UIKit
import FSCalendar
import SnapKit

class TravelCalendarCell: FSCalendarCell {

    private var travelLineView: UIView!
    private var leftLineView: UIView!
    private var rightLineView: UIView!
    private var travelNameLabel: UILabel!
    private var travelIconView: UIView!
    private var iconLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTravelLineViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTravelLineViews()
    }

    private func setupTravelLineViews() {
        // 전체 라인 뷰
        travelLineView = UIView()
        travelLineView.backgroundColor = UIColor.skyBlue.withAlphaComponent(0.8)
        travelLineView.layer.cornerRadius = 10
        travelLineView.isUserInteractionEnabled = false // 터치 이벤트 차단 방지
        contentView.addSubview(travelLineView)

        // 왼쪽 라인 (이전 날짜와 연결)
        leftLineView = UIView()
        leftLineView.backgroundColor = UIColor.skyBlue.withAlphaComponent(0.8)
        leftLineView.isUserInteractionEnabled = false // 터치 이벤트 차단 방지
        contentView.addSubview(leftLineView)

        // 오른쪽 라인 (다음 날짜와 연결)
        rightLineView = UIView()
        rightLineView.backgroundColor = UIColor.skyBlue.withAlphaComponent(0.8)
        rightLineView.isUserInteractionEnabled = false // 터치 이벤트 차단 방지
        contentView.addSubview(rightLineView)

        // 여행 이름 라벨
        travelNameLabel = UILabel()
        travelNameLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        travelNameLabel.textColor = .white
        travelNameLabel.textAlignment = .center
        travelNameLabel.numberOfLines = 1
        travelNameLabel.adjustsFontSizeToFitWidth = true
        travelNameLabel.minimumScaleFactor = 0.7
        travelNameLabel.isUserInteractionEnabled = false // 터치 이벤트 차단 방지
        contentView.addSubview(travelNameLabel)

        // 아이콘 뷰 (시작일에만 표시)
        travelIconView = UIView()
        travelIconView.backgroundColor = UIColor.systemPurple
        travelIconView.layer.cornerRadius = 8
        travelIconView.isHidden = true
        travelIconView.isUserInteractionEnabled = false // 터치 이벤트 차단 방지
        contentView.addSubview(travelIconView)

        // 아이콘 라벨 ( 또는 다른 이모지)
        iconLabel = UILabel()
        iconLabel.text = ""
        iconLabel.font = UIFont.systemFont(ofSize: 12)
        iconLabel.textAlignment = .center
        iconLabel.isUserInteractionEnabled = false // 터치 이벤트 차단 방지
        travelIconView.addSubview(iconLabel)

        // 레이아웃 설정
        travelLineView.snp.makeConstraints {
            $0.centerY.equalToSuperview().offset(10)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(20)
        }

        leftLineView.snp.makeConstraints {
            $0.centerY.equalTo(travelLineView)
            $0.leading.equalToSuperview()
            $0.trailing.equalTo(travelLineView.snp.leading)
            $0.height.equalTo(20)
        }

        rightLineView.snp.makeConstraints {
            $0.centerY.equalTo(travelLineView)
            $0.leading.equalTo(travelLineView.snp.trailing)
            $0.trailing.equalToSuperview()
            $0.height.equalTo(20)
        }

        travelNameLabel.snp.makeConstraints {
            $0.centerY.equalTo(travelLineView)
            $0.leading.trailing.equalTo(travelLineView).inset(8)
            $0.height.equalTo(16)
        }

        travelIconView.snp.makeConstraints {
            $0.centerY.equalTo(travelLineView)
            $0.leading.equalTo(travelLineView).offset(4)
            $0.width.height.equalTo(16)
        }

        iconLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        // 초기에는 모든 라인 숨김
        hideTravelLines()
    }

    func configureTravelLine(isStartDate: Bool, isEndDate: Bool, hasTravel: Bool, travelName: String? = nil, showTravelName: Bool = false) {
        if hasTravel {
            showTravelLines(isStartDate: isStartDate, isEndDate: isEndDate)

            // 시작일에 여행 이름만 표시 (아이콘 제거)
            if isStartDate, let name = travelName {
                travelNameLabel.text = name
                travelNameLabel.isHidden = false
            } else {
                travelNameLabel.isHidden = true
            }
            travelIconView.isHidden = true
        } else {
            hideTravelLines()
        }
    }

    private func showTravelLines(isStartDate: Bool, isEndDate: Bool) {
        // 모든 여행 날짜에 일직선으로 표시
        travelLineView.isHidden = false
        leftLineView.isHidden = false
        rightLineView.isHidden = false

        // 시작일과 종료일에만 둥근 끝처리
        if isStartDate {
            leftLineView.isHidden = true
            travelLineView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        } else {
            travelLineView.layer.maskedCorners = []
        }

        if isEndDate {
            rightLineView.isHidden = true
            travelLineView.layer.maskedCorners.insert([.layerMaxXMinYCorner, .layerMaxXMaxYCorner])
        }

        // 1일 여행 (시작일이면서 종료일)
        if isStartDate && isEndDate {
            leftLineView.isHidden = true
            rightLineView.isHidden = true
            travelLineView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        }
    }

    private func hideTravelLines() {
        travelLineView.isHidden = true
        leftLineView.isHidden = true
        rightLineView.isHidden = true
        travelNameLabel.isHidden = true
        travelIconView.isHidden = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        hideTravelLines()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 모든 터치 이벤트를 부모 뷰(FSCalendarCell)로 전달
        let hitView = super.hitTest(point, with: event)
        if hitView == travelLineView || hitView == leftLineView || hitView == rightLineView || hitView == travelNameLabel || hitView == travelIconView || hitView == iconLabel {
            return self
        }
        return hitView
    }
}
