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
import RxSwift
import RxCocoa

class TravelCalendarViewController: UIViewController {

    // MARK: - UI Components
    private lazy var calendar = FSCalendar().then {
        $0.delegate = self
        $0.dataSource = self
        $0.register(TravelCalendarCell.self, forCellReuseIdentifier: "TravelCalendarCell")
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
        $0.applySubtitleStyle(text: "")
        $0.textAlignment = .center
    }

    private lazy var travelInfoView = UIView().then {
        $0.applyCardStyle()
        $0.isHidden = true
        $0.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(travelInfoViewTapped))
        $0.addGestureRecognizer(tapGesture)
    }

    private lazy var travelTitleLabel = UILabel().then {
        $0.applySectionTitleStyle(text: "")
    }

    private lazy var travelCountryLabel = UILabel().then {
        $0.applyDescriptionStyle(text: "")
    }

    private lazy var travelPeriodLabel = UILabel().then {
        $0.applyCaptionStyle(text: "")
    }

    // MARK: - Properties
    private var selectedDate: Date = Date()
    private let viewModel = CalendarViewModel()
    private let disposeBag = DisposeBag()
    private var currentTravelPlan: TravelPlan? // 현재 선택된 여행 계획

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureHierarchy()
        configureUI()
        configureLayout()
        bind()
        updateSelectedDateLabel()
        viewModel.loadTravelPlans()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadTravelPlans()
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

        view.addSubview(travelInfoView)
        travelInfoView.addSubview(travelTitleLabel)
        travelInfoView.addSubview(travelCountryLabel)
        travelInfoView.addSubview(travelPeriodLabel)
    }

    func configureUI() {
        view.backgroundColor = .background

        // Calendar 스타일 설정 - UILabel+Extension 폰트 크기 적용
        calendar.do {
            $0.backgroundColor = .background
            $0.appearance.headerTitleColor = .labelLight
            $0.appearance.headerTitleFont = FontManager.onglapBoldFont(26) // applySectionTitleStyle 크기
            $0.appearance.weekdayTextColor = .systemGray
            $0.appearance.weekdayFont = FontManager.onglapFont(22) // applyDescriptionStyle 크기

            // 날짜 숫자 스타일
            $0.appearance.titleDefaultColor = .labelLight
            $0.appearance.titleTodayColor = .labelLight // 오늘 날짜도 보이는 색상으로
            $0.appearance.titleSelectionColor = .white
            $0.appearance.titleFont = FontManager.onglapFont(22) // applyDescriptionStyle 크기

            // 서브타이틀 (여행지 이름) 스타일
            $0.appearance.subtitleDefaultColor = .systemGray // 기본은 회색
            $0.appearance.subtitleTodayColor = .labelLight // 오늘 날짜도 보이는 색상으로
            $0.appearance.subtitleSelectionColor = .white
            $0.appearance.subtitleFont = FontManager.onglapFont(14) // 작은 폰트
            $0.appearance.subtitleOffset = CGPoint(x: 0, y: 3) // 아래쪽으로 위치 조정

            // 오늘 날짜 스타일 (동그라미 제거)
            $0.appearance.todayColor = UIColor.clear
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
            $0.height.equalTo(400)
        }

        selectedDateLabel.snp.makeConstraints {
            $0.top.equalTo(calendar.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        travelInfoView.snp.makeConstraints {
            $0.top.equalTo(selectedDateLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(120)
        }

        travelTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        travelCountryLabel.snp.makeConstraints {
            $0.top.equalTo(travelTitleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        travelPeriodLabel.snp.makeConstraints {
            $0.top.equalTo(travelCountryLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }

    func bind() {
        // 초기 선택 날짜 설정
        calendar.select(selectedDate)

        // ViewModel의 여행 날짜 데이터 바인딩
        viewModel.travelDates
            .subscribe(onNext: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.calendar.reloadData()
                }
            })
            .disposed(by: disposeBag)

        // 선택된 날짜 정보 바인딩
        viewModel.selectedDateInfo
            .subscribe(onNext: { [weak self] travelPlan in
                DispatchQueue.main.async {
                    self?.updateTravelInfoUI(with: travelPlan)
                }
            })
            .disposed(by: disposeBag)

        // 에러 메시지 바인딩
        viewModel.errorMessage
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] errorMessage in
                DispatchQueue.main.async {
                    self?.showErrorAlert(message: errorMessage)
                }
            })
            .disposed(by: disposeBag)
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
        viewModel.selectDate(today)
    }

    func updateSelectedDateLabel() {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .full
        selectedDateLabel.text = formatter.string(from: selectedDate)
    }

    func updateTravelInfoUI(with travelPlan: TravelPlan?) {
        currentTravelPlan = travelPlan // 현재 여행 계획 저장

        if let plan = travelPlan {
            // 여행 계획이 있는 경우
            print(" [UI] 여행 정보 표시: \(plan.travelName)")
            travelInfoView.isHidden = false
            travelTitleLabel.text = plan.travelName
            travelCountryLabel.text = plan.nation

            let periodFormatter = DateFormatter()
            periodFormatter.dateFormat = "MM/dd"
            let startDateString = periodFormatter.string(from: plan.startDate)
            let endDateString = periodFormatter.string(from: plan.endDate)
            travelPeriodLabel.text = "\(startDateString) - \(endDateString)"
        } else {
            // 여행 계획이 없는 경우
            print(" [UI] 여행 정보 숨김")
            travelInfoView.isHidden = true
        }
    }

    @objc private func travelInfoViewTapped() {
        guard let travelPlan = currentTravelPlan else {
            print(" [Navigation] 여행 계획이 없어서 이동할 수 없습니다")
            return
        }

        print("🚀 [Navigation] TravelPlanShowViewController로 이동: \(travelPlan.travelName)")

        let travelPlanShowVC = TravelPlanShowViewController()

        // 여행 계획 ID 전달 (ObjectId를 String으로 변환)
        travelPlanShowVC.travelPlanId = travelPlan.id.stringValue

        // 국내/해외 타입 설정
        travelPlanShowVC.setCountryType(travelPlan.nation == "대한민국" ? "국내" : "해외")

        // 네비게이션으로 이동
        navigationController?.pushViewController(travelPlanShowVC, animated: true)
    }

    func showErrorAlert(message: String) {
        let alert = UIAlertController(title: NSLocalizedString("error", comment: "Error"),
                                    message: message,
                                    preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: "OK"),
                                    style: .default))
        present(alert, animated: true)
    }
}

// MARK: - FSCalendarDelegate
extension TravelCalendarViewController: FSCalendarDelegate {
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        selectedDate = date
        updateSelectedDateLabel()

        print(" [Calendar] 날짜 선택됨: \(date)")
        viewModel.selectDate(date)
    }

    // 날짜 숫자는 기본값 사용 (nil 반환시 자동으로 날짜 숫자 표시)
    func calendar(_ calendar: FSCalendar, titleFor date: Date) -> String? {
        return nil
    }

    // 여행 계획이 있는 날짜에 여행지 이름을 서브타이틀로 표시 (선형 스타일에서는 비활성화)
    func calendar(_ calendar: FSCalendar, subtitleFor date: Date) -> String? {
        return nil // 아이폰 캘린더 스타일을 위해 서브타이틀 제거
    }

    // 여행 계획이 있는 날짜의 배경색 커스터마이징 (아이폰 캘린더 스타일)
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillDefaultColorFor date: Date) -> UIColor? {
        let hasTravelPlan = viewModel.hasTravelPlan(for: date)

        if hasTravelPlan {
            if let travelData = viewModel.getTravelInfo(for: date) {
                // 시작일과 종료일
                if travelData.isStartDate || travelData.isEndDate {
                    return UIColor.skyBlue
                } else {
                    // 중간 날짜들은 투명하게 (선으로만 표시)
                    return UIColor.clear
                }
            }
        }
        return nil
    }

    // 여행 계획이 있는 날짜의 텍스트 색상
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        let hasTravelPlan = viewModel.hasTravelPlan(for: date)

        if hasTravelPlan {
            return .white
        }
        return .labelLight
    }

    // 서브타이틀 (여행지 이름) 색상
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, subtitleDefaultColorFor date: Date) -> UIColor? {
        let hasTravelPlan = viewModel.hasTravelPlan(for: date)

        if hasTravelPlan {
            return .white
        }
        return .systemGray
    }

}

// MARK: - FSCalendarDataSource
extension TravelCalendarViewController: FSCalendarDataSource {
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        return 0
    }

    func calendar(_ calendar: FSCalendar, cellFor date: Date, at position: FSCalendarMonthPosition) -> FSCalendarCell {
        let cell = calendar.dequeueReusableCell(withIdentifier: "TravelCalendarCell", for: date, at: position) as! TravelCalendarCell

        // 여행 계획 정보 가져오기
        if let travelData = viewModel.getTravelInfo(for: date) {
            cell.configureTravelLine(
                isStartDate: travelData.isStartDate,
                isEndDate: travelData.isEndDate,
                hasTravel: true,
                travelName: travelData.travelName,
                showTravelName: travelData.isStartDate // 시작일에만 여행 이름 표시
            )
        } else {
            cell.configureTravelLine(
                isStartDate: false,
                isEndDate: false,
                hasTravel: false
            )
        }

        return cell
    }
}
