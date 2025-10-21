//
//  TravelCalendarViewController.swift
//  TRACE
//
//  Created by 차지용 on 10/21/25.
//

import UIKit
import FSCalendar
import SnapKit
import Then

class TravelCalendarViewController: UIViewController {

    // MARK: - UI Components
    private lazy var calendar = FSCalendar().then {
        $0.delegate = self
        $0.dataSource = self
    }

    private lazy var headerView = UIView().then {
        $0.backgroundColor = .background
    }

    private lazy var titleLabel = UILabel().then {
        $0.applyTitleStyle(text: NSLocalizedString("calendar_tab", comment: "Calendar tab"))
    }

    private lazy var todayButton = UIButton(type: .system).then {
        $0.setTitle(NSLocalizedString("today", comment: "Today"), for: .normal)
        $0.titleLabel?.font = FontManager.onglapFont(22)
        $0.setTitleColor(.skyBlue, for: .normal)
        $0.addTarget(self, action: #selector(todayButtonTapped), for: .touchUpInside)
    }

    private lazy var selectedDateLabel = UILabel().then {
        $0.applySectionTitleStyle(text: "", fontSize: 24)
        $0.textAlignment = .center
    }

    // MARK: - Properties
    private var selectedDate: Date = Date()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureHierarchy()
        configureUI()
        configureLayout()
        bind()
        updateSelectedDateLabel()
    }
}

// MARK: - DesiginProtocolBind
extension TravelCalendarViewController: DesiginProtocolBind {
    func configureHierarchy() {
        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(todayButton)

        view.addSubview(calendar)
        view.addSubview(selectedDateLabel)
    }

    func configureUI() {
        view.backgroundColor = .background

        // Calendar 스타일 설정
        calendar.do {
            $0.backgroundColor = .background
            $0.appearance.headerTitleColor = .label
            $0.appearance.headerTitleFont = FontManager.onglapBoldFont(24)
            $0.appearance.weekdayTextColor = .systemGray
            $0.appearance.weekdayFont = FontManager.onglapFont(22)
            $0.appearance.titleDefaultColor = .label
            $0.appearance.titleTodayColor = .white
            $0.appearance.titleSelectionColor = .white
            $0.appearance.titleFont = FontManager.onglapFont(22)

            // 오늘 날짜 스타일
            $0.appearance.todayColor = .skyBlue
            $0.appearance.todaySelectionColor = .skyBlue

            // 선택된 날짜 스타일
            $0.appearance.selectionColor = .skyBlue

            // 이벤트 도트 스타일
            $0.appearance.eventDefaultColor = .systemOrange
            $0.appearance.eventSelectionColor = .white

            // 헤더 날짜 포맷
            $0.appearance.headerDateFormat = "yyyy년 M월"

            // 주 시작을 일요일로 설정
            $0.firstWeekday = 1

            // 스크롤 방향 설정
            $0.scrollDirection = .horizontal
            $0.scope = .month

            // 캘린더 모서리 둥글게
            $0.applyRoundedCorners(radius: 12)
            $0.applyShadow()
        }
    }

    func configureLayout() {
        headerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(60)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.centerY.equalToSuperview()
        }

        todayButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.centerY.equalToSuperview()
        }

        calendar.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.height.equalTo(300)
        }

        selectedDateLabel.snp.makeConstraints {
            $0.top.equalTo(calendar.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
    }

    func bind() {
        // 초기 선택 날짜 설정
        calendar.select(selectedDate)
    }
}

// MARK: - Actions
private extension TravelCalendarViewController {
    @objc func todayButtonTapped() {
        let today = Date()
        calendar.setCurrentPage(today, animated: true)
        calendar.select(today)
        selectedDate = today
        updateSelectedDateLabel()
    }

    func updateSelectedDateLabel() {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .full
        selectedDateLabel.text = formatter.string(from: selectedDate)
    }
}

// MARK: - FSCalendarDelegate
extension TravelCalendarViewController: FSCalendarDelegate {
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        selectedDate = date
        updateSelectedDateLabel()

        // 여기에 선택된 날짜에 대한 추가 로직 구현 가능
        // 예: 해당 날짜의 여행 계획 표시 등
    }
}

// MARK: - FSCalendarDataSource
extension TravelCalendarViewController: FSCalendarDataSource {
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        // 여기에 해당 날짜의 이벤트 개수 반환
        // 예: 여행 계획이 있는 날짜에 대해 1 반환
        return 0
    }
}
