//
//  TravelPlanShowViewController+UI.swift
//  TRACE
//
//  Created by 차지용 on 9/29/25.
//

import UIKit
import RxSwift
import RxCocoa

// MARK: - DesiginProtocolBind Implementation
extension TravelPlanShowViewController: DesiginProtocolBind {
    func bind() {
        // 수정 모드 토글
        editButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.toggleEditMode()
            })
            .disposed(by: disposeBag)

        // 저장 버튼
        saveButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.saveChanges()
            })
            .disposed(by: disposeBag)

        // 취소 버튼
        cancelButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.cancelEdit()
            })
            .disposed(by: disposeBag)

        // 시간 피커 값 변경 감지
        timePicker.rx.date
            .map { date in
                let formatter = DateFormatter()
                formatter.dateFormat = "a h:mm"
                formatter.locale = Locale(identifier: "ko_KR")
                return formatter.string(from: date)
            }
            .bind(to: timeTextField.rx.text)
            .disposed(by: disposeBag)

        // 텍스트필드 입력 감지 (둘 다 입력되어야 버튼 활성화)
        Observable.combineLatest(
            timeTextField.rx.text.orEmpty,
            locationTextField.rx.text.orEmpty
        )
        .map { !$0.isEmpty && !$1.isEmpty }
        .bind(to: addScheduleItemButton.rx.isEnabled)
        .disposed(by: disposeBag)

        // 버튼 활성/비활성 상태에 따른 색상 변경
        Observable.combineLatest(
            timeTextField.rx.text.orEmpty,
            locationTextField.rx.text.orEmpty
        )
        .map { !$0.isEmpty && !$1.isEmpty }
        .map { $0 ? UIColor.buttonDark : UIColor.systemGray4 }
        .bind(to: addScheduleItemButton.rx.backgroundColor)
        .disposed(by: disposeBag)

        // 일정 추가 버튼
        addScheduleItemButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.addScheduleItem()
            })
            .disposed(by: disposeBag)
    }

    func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [dateCollectionView, budgetTitleLabel, budgetTextField, budgetDescriptionLabel,
         scheduleTitleLabel, timeTextField, locationTextField, addScheduleItemButton, scheduleDescriptionLabel,
         scheduleStackView, routeTitleLabel, routeSearchBar, routeDescriptionLabel,
         mapView, editButton, saveButton, cancelButton].forEach {
            contentView.addSubview($0)
        }
    }

    func configureUI() {
        // Navigation Bar 설정
        navigationItem.title = "여행 계획 보기"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(clearSearchResults)
        )

        // RouteSearchBar 설정
        routeSearchBar.delegate = self

        // 시간 피커 설정
        timeTextField.inputView = timePicker

        // 키보드 툴바 설정
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(timePickerDone))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [flexSpace, doneButton]
        timeTextField.inputAccessoryView = toolbar

        // 초기에는 읽기 전용 모드로 설정
        setReadOnlyMode()
    }

    func configureLayout() {
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        dateCollectionView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(60)
        }

        budgetTitleLabel.snp.makeConstraints {
            $0.top.equalTo(dateCollectionView.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        budgetTextField.snp.makeConstraints {
            $0.top.equalTo(budgetTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        budgetDescriptionLabel.snp.makeConstraints {
            $0.top.equalTo(budgetTextField.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        scheduleTitleLabel.snp.makeConstraints {
            $0.top.equalTo(budgetDescriptionLabel.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        timeTextField.snp.makeConstraints {
            $0.top.equalTo(scheduleTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        locationTextField.snp.makeConstraints {
            $0.top.equalTo(timeTextField.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        addScheduleItemButton.snp.makeConstraints {
            $0.top.equalTo(locationTextField.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        scheduleDescriptionLabel.snp.makeConstraints {
            $0.top.equalTo(addScheduleItemButton.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        scheduleStackView.snp.makeConstraints {
            $0.top.equalTo(scheduleDescriptionLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        routeTitleLabel.snp.makeConstraints {
            $0.top.equalTo(scheduleStackView.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        routeSearchBar.snp.makeConstraints {
            $0.top.equalTo(routeTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        routeDescriptionLabel.snp.makeConstraints {
            $0.top.equalTo(routeSearchBar.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        mapView.snp.makeConstraints {
            $0.top.equalTo(routeDescriptionLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(200)
        }

        editButton.snp.makeConstraints {
            $0.top.equalTo(mapView.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(50)
        }

        saveButton.snp.makeConstraints {
            $0.top.equalTo(mapView.snp.bottom).offset(30)
            $0.leading.equalToSuperview().inset(20)
            $0.trailing.equalTo(contentView.snp.centerX).offset(-6)
            $0.height.equalTo(50)
            $0.bottom.equalToSuperview().offset(-30)
        }

        cancelButton.snp.makeConstraints {
            $0.top.equalTo(mapView.snp.bottom).offset(30)
            $0.leading.equalTo(contentView.snp.centerX).offset(6)
            $0.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(50)
            $0.bottom.equalToSuperview().offset(-30)
        }
    }
}

// MARK: - UI Helper Methods
extension TravelPlanShowViewController {
    @objc func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc func timePickerDone() {
        timeTextField.resignFirstResponder()
    }

    func toggleEditMode() {
        isEditMode.toggle()

        if isEditMode {
            setEditMode()
        } else {
            setReadOnlyMode()
        }
    }

    func setReadOnlyMode() {
        budgetTextField.isUserInteractionEnabled = false
        timeTextField.isUserInteractionEnabled = false
        locationTextField.isUserInteractionEnabled = false
        routeSearchBar.isUserInteractionEnabled = false
        addScheduleItemButton.isHidden = true

        // 지도 인터랙션 비활성화
        mapView.isUserInteractionEnabled = true // 스크롤/줌은 허용
        navigationItem.rightBarButtonItem?.isEnabled = false

        editButton.isHidden = false
        saveButton.isHidden = true
        cancelButton.isHidden = true

        editButton.snp.remakeConstraints {
            $0.top.equalTo(mapView.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(50)
            $0.bottom.equalToSuperview().offset(-30)
        }

        print("🔒 읽기 전용 모드 활성화")
    }

    func setEditMode() {
        budgetTextField.isUserInteractionEnabled = true
        timeTextField.isUserInteractionEnabled = true
        locationTextField.isUserInteractionEnabled = true
        routeSearchBar.isUserInteractionEnabled = true
        addScheduleItemButton.isHidden = false

        // 지도 인터랙션 활성화
        mapView.isUserInteractionEnabled = true
        navigationItem.rightBarButtonItem?.isEnabled = true

        editButton.isHidden = true
        saveButton.isHidden = false
        cancelButton.isHidden = false

        print("✏️ 편집 모드 활성화")
    }

    func saveChanges() {
        // ViewModel을 통해 변경사항 저장
        print("💾 변경사항 저장")
        setReadOnlyMode()
    }

    func cancelEdit() {
        // 변경사항 취소하고 원래 데이터로 복원
        print("❌ 편집 취소")
        setReadOnlyMode()

        // 원래 데이터로 UI 복원
        let originalDayData = viewModel.getDayData(for: currentDay)
        updateDayUI(with: originalDayData)
        updateScheduleUI(with: originalDayData.scheduleItems)

        print("🔄 원래 데이터로 복원 완료")
    }

    func addScheduleItem() {
        // 일정 추가 로직
        print("➕ 일정 추가")
    }

    // MARK: - UI Update Methods
    func updateTravelPlanUI(with planData: PlanShowViewModel.TravelPlanData) {
        DispatchQueue.main.async { [weak self] in
            self?.navigationItem.title = planData.travelName
            self?.totalDays = planData.totalDays

            // CollectionView 업데이트
            self?.dateCollectionView.reloadData()

            print("🔄 여행 계획 UI 업데이트:")
            print("   🏝️ 여행지: \(planData.travelName)")
            print("   🌍 국가: \(planData.nation)")
            print("   📅 기간: \(DateManager.shared.formatToKoreanString(from: planData.startDate)) ~ \(DateManager.shared.formatToKoreanString(from: planData.endDate))")
            print("   📊 총 일차: \(planData.totalDays)일")
        }
    }

    func updateDayUI(with dayData: PlanShowViewModel.DayData) {
        DispatchQueue.main.async { [weak self] in
            self?.budgetTextField.text = dayData.budget
            self?.routeSearchBar.text = dayData.route

            // 현재 검색된 장소들 업데이트
            self?.currentSearchedPlaces = dayData.searchedPlaces

            // 지도에 검색된 장소들 표시
            self?.mapManager.clearAllSearchResults()
            if !dayData.searchedPlaces.isEmpty {
                self?.mapManager.displaySearchResults(places: dayData.searchedPlaces)
            }

            print("🔄 Day \(self?.currentDay ?? 0) UI 업데이트:")
            print("   💰 예산: '\(dayData.budget.isEmpty ? "미설정" : dayData.budget)'")
            print("   🚗 경로: '\(dayData.route.isEmpty ? "미설정" : dayData.route)'")
            print("   📋 일정: \(dayData.scheduleItems.count)개")
            print("   📍 장소: \(dayData.searchedPlaces.count)개")
        }
    }

    func updateScheduleUI(with scheduleItems: [ScheduleItem]) {
        DispatchQueue.main.async { [weak self] in
            // 기존 스케줄 아이템들 제거
            self?.scheduleStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

            // 새로운 스케줄 아이템들 추가
            scheduleItems.enumerated().forEach { index, item in
                let scheduleView = self?.createScheduleItemView(item: item, index: index)
                if let view = scheduleView {
                    self?.scheduleStackView.addArrangedSubview(view)
                }
            }

            print("🔄 Schedule UI 업데이트: \(scheduleItems.count)개 일정")
        }
    }

    func createScheduleItemView(item: ScheduleItem, index: Int) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 8

        let timeLabel = UILabel()
        timeLabel.text = item.time.isEmpty ? "시간 미정" : item.time
        timeLabel.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 14)
        timeLabel.textColor = .labelLight

        let locationLabel = UILabel()
        locationLabel.text = item.location.isEmpty ? "장소 미정" : item.location
        locationLabel.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 14)
        locationLabel.textColor = .systemGray

        let deleteButton = UIButton(type: .system)
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.tag = index
        deleteButton.addTarget(self, action: #selector(deleteScheduleItem(_:)), for: .touchUpInside)

        containerView.addSubview(timeLabel)
        containerView.addSubview(locationLabel)
        containerView.addSubview(deleteButton)

        timeLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(12)
        }

        locationLabel.snp.makeConstraints {
            $0.top.equalTo(timeLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview().offset(12)
            $0.bottom.equalToSuperview().offset(-12)
        }

        deleteButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-12)
            $0.width.height.equalTo(24)
        }

        containerView.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(60)
        }

        return containerView
    }

    @objc func deleteScheduleItem(_ sender: UIButton) {
        let index = sender.tag
        viewModel.removeScheduleItem(at: index, forDay: currentDay)
        print("🗑️ 일정 삭제 요청: index \(index)")
    }

    func showSaveAlert(success: Bool, message: String) {
        DispatchQueue.main.async { [weak self] in
            let title = success ? "저장 완료" : "저장 실패"
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            self?.present(alert, animated: true)

            if success {
                self?.setReadOnlyMode()
            }
        }
    }

    func showErrorAlert(message: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            self?.present(alert, animated: true)
        }
    }
}