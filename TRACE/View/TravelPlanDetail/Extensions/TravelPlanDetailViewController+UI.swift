//
//  TravelPlanDetailViewController+UI.swift
//  TRACE
//
//  Created by 차지용 on 9/29/25.
//

import UIKit
import RxSwift
import RxCocoa

// MARK: - DesiginProtocolBind Implementation
extension TravelPlanDetailViewController: DesiginProtocolBind {
    func bind() {
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

        // 일정 추가 버튼은 ViewModel에서 처리됨 (bindViewModel()에서 바인딩)

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
        .map { $0 ? UIColor.skyBlue : UIColor.systemGray4 }
        .bind(to: addScheduleItemButton.rx.backgroundColor)
        .disposed(by: disposeBag)

        // 저장 버튼 - 직접 액션과 ViewModel 바인딩 모두 사용
        saveButton.rx.tap
            .subscribe(onNext: { [weak self] in
                print("💾 저장 버튼 직접 탭 감지!")
                self?.saveAllDataToRealm()
            })
            .disposed(by: disposeBag)

        // 여행 시작하기 버튼 (현재는 숨김 처리)
        startTravelButton.isHidden = true

        // CollectionView 선택 이벤트만 RxSwift로 처리
        bindCollectionView()
    }

    func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [dateCollectionView, budgetTitleLabel, budgetTextField, budgetDescriptionLabel,
         scheduleTitleLabel, timeTextField, locationTextField, addScheduleItemButton, scheduleDescriptionLabel,
         scheduleStackView, routeTitleLabel, routeSearchBar, routeDescriptionLabel,
         mapView, saveButton, startTravelButton].forEach {
            contentView.addSubview($0)
        }
    }

    func configureUI() {
        // Navigation Bar 설정
        navigationItem.title = "여행 계획"
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
            action: #selector(clearCurrentDayData)
        )

        // RouteSearchBar 설정 - 수동 검색을 위해 delegate 활성화
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

        saveButton.snp.makeConstraints {
            $0.top.equalTo(mapView.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(50)
            $0.bottom.equalToSuperview().offset(-30) // ScrollView content 영역 설정
        }

        // startTravelButton은 숨겨져 있으므로 제약조건 제거
        startTravelButton.snp.makeConstraints {
            $0.top.equalTo(saveButton.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(0) // 높이를 0으로 설정
        }
    }
}

// MARK: - UI Helper Methods
extension TravelPlanDetailViewController {
    @objc func backButtonTapped() {
        print("🔙 TravelPlanDetail: Back 버튼 클릭 - 데이터 저장 없이 뒤로가기")

        // ViewController와 ViewModel 모두 자동 저장 방지 활성화
        shouldPreventAutoSave = true
        viewModel.shouldPreventAutoSave = true

        // 데이터 저장 없이 바로 뒤로가기
        navigationController?.popViewController(animated: true)
    }

    @objc func timePickerDone() {
        timeTextField.resignFirstResponder()
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

        // 삭제 버튼 액션 추가 - ViewModel을 통해 처리
        deleteButton.addTarget(self, action: #selector(deleteScheduleItem(_:)), for: .touchUpInside)
        deleteButton.tag = index

        containerView.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(60)
        }

        return containerView
    }

    // MARK: - UI Update Methods
    func updateScheduleUI(items: [ScheduleItem]) {
        print("🔄 Schedule UI 업데이트 시작: \(items.count)개 일정")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // 기존 스케줄 아이템들 애니메이션과 함께 제거
            let existingViews = self.scheduleStackView.arrangedSubviews

            if !existingViews.isEmpty {
                UIView.animate(withDuration: 0.3, animations: {
                    existingViews.forEach { view in
                        view.alpha = 0
                        view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                    }
                }) { _ in
                    existingViews.forEach { $0.removeFromSuperview() }
                    self.addNewScheduleItemsWithAnimation(items: items)
                }
            } else {
                self.addNewScheduleItemsWithAnimation(items: items)
            }
        }
    }

    private func addNewScheduleItemsWithAnimation(items: [ScheduleItem]) {
        // 새로운 스케줄 아이템들을 애니메이션과 함께 추가
        items.enumerated().forEach { index, item in
            let scheduleView = self.createScheduleItemView(item: item, index: index)

            // 초기 상태 설정 (애니메이션 시작점)
            scheduleView.alpha = 0
            scheduleView.transform = CGAffineTransform(translationX: 0, y: 30).scaledBy(x: 0.9, y: 0.9)

            self.scheduleStackView.addArrangedSubview(scheduleView)

            // 순차적으로 애니메이션 실행 (약간의 지연으로 부드러운 효과)
            UIView.animate(
                withDuration: 0.5,
                delay: Double(index) * 0.1,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.3,
                options: [.curveEaseInOut]
            ) {
                scheduleView.alpha = 1.0
                scheduleView.transform = .identity
            }
        }

        print("✅ Schedule UI 업데이트 완료: \(items.count)개 일정 (애니메이션 포함)")
    }

    func updateDayUI(dayData: PlanDetailViewModel.DayData) {
        DispatchQueue.main.async { [weak self] in
            // 텍스트 필드 업데이트 (ViewModel 데이터 기준)
            self?.budgetTextField.text = dayData.budget
            self?.routeSearchBar.text = dayData.route

            // 일정 UI도 업데이트
            self?.updateScheduleUI(items: dayData.scheduleItems)

            // 지도 데이터도 업데이트
            self?.currentSearchedPlaces = dayData.searchedPlaces
            self?.mapManager.clearAllSearchResults()
            if !dayData.searchedPlaces.isEmpty {
                self?.mapManager.displaySearchResults(places: dayData.searchedPlaces)
            }

            print("🔄 ViewModel Day UI 업데이트: Day \(self?.viewModel.getCurrentDay() ?? 0)")
            print("   💰 예산: '\(dayData.budget.isEmpty ? "빈 값" : dayData.budget)'")
            print("   🚗 경로: '\(dayData.route.isEmpty ? "빈 값" : dayData.route)'")
            print("   📋 일정: \(dayData.scheduleItems.count)개")
            print("   📍 좌표: \(dayData.searchedPlaces.count)개")
        }
    }

    // MARK: - RxSwift CollectionView Binding
    func bindCollectionView() {
        // 셀 선택 처리만 RxSwift로 처리
        dateCollectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                // 애니메이션 효과
                let cell = self?.dateCollectionView.cellForItem(at: indexPath) as? TravelDayCell
                cell?.animateSelection()

                // 일차 선택
                self?.selectDay(at: indexPath.item)
            })
            .disposed(by: disposeBag)
    }

    // CollectionView 업데이트 메서드 (기존 방식으로 복원)
    func updateCollectionViewReactively() {
        DispatchQueue.main.async { [weak self] in
            self?.dateCollectionView.reloadData()
            print("📱 CollectionView 업데이트: \(self?.totalDays ?? 0)개 일차")
        }
    }
}