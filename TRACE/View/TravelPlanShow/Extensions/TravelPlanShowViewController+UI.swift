//
//  TravelPlanShowViewController+UI.swift
//  TRACE
//
//  Created by 차지용 on 9/29/25.
//

import UIKit
import RxSwift
import RxCocoa
import RealmSwift

// MARK: - DesiginProtocolBind Implementation
extension TravelPlanShowViewController: DesiginProtocolBind {
    func bind() {
        // 수정 모드 활성화 (토글이 아닌 무조건 편집 모드로)
        editButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.setEditMode()
                self?.isEditMode = true
                print("🔓 수정하기 버튼 - 편집 모드 활성화")
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
                self?.setReadOnlyMode()
                self?.isEditMode = false
                print("🔒 취소 버튼 - 읽기 모드로 전환")
            })
            .disposed(by: disposeBag)

        // 시간 피커 값 변경 감지
        timePicker.rx.date
            .map { date in
                let formatter = DateFormatter()
                formatter.dateFormat = "a h:mm"
                formatter.locale = Locale.current
                return formatter.string(from: date)
            }
            .bind(to: timeTextField.rx.text)
            .disposed(by: disposeBag)

        // 검색 버튼 클릭 시 모달 검색 뷰 표시
        locationSearchButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.presentSearchModal()
            })
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
         scheduleTitleLabel, timeTextField, locationSearchButton, selectedLocationLabel, addScheduleItemButton, scheduleDescriptionLabel,
         scheduleStackView, mapView].forEach {
            contentView.addSubview($0)
        }

        // 편집 관련 버튼들은 contentView가 아닌 view에 직접 추가 (TravelShowRecordViewController처럼)
        view.addSubview(editButton)
        view.addSubview(saveButton)
        view.addSubview(cancelButton)
    }

    func configureUI() {
        // Navigation Bar 설정
        navigationItem.title = NSLocalizedString("view_travel_plan", comment: "View travel plan")
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
            action: #selector(showDeleteConfirmation)
        )
        navigationItem.rightBarButtonItem?.tintColor = .skyBlue


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

        locationSearchButton.snp.makeConstraints {
            $0.top.equalTo(timeTextField.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        selectedLocationLabel.snp.makeConstraints {
            $0.top.equalTo(locationSearchButton.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        addScheduleItemButton.snp.makeConstraints {
            $0.top.equalTo(selectedLocationLabel.snp.bottom).offset(12)
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

        mapView.snp.makeConstraints {
            $0.top.equalTo(scheduleStackView.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(200)
            $0.bottom.equalToSuperview().offset(-30)
        }

        // editButton은 TravelShowRecordViewController처럼 오른쪽 하단에 작게 배치
        editButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.width.equalTo(60)
            $0.height.equalTo(40)
        }

        saveButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.width.equalTo(60)
            $0.height.equalTo(40)
        }

        cancelButton.snp.makeConstraints {
            $0.trailing.equalTo(saveButton.snp.leading).offset(-12)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.width.equalTo(60)
            $0.height.equalTo(40)
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
        locationSearchButton.isUserInteractionEnabled = false
        addScheduleItemButton.isHidden = true

        // 지도 인터랙션 비활성화
        mapView.isUserInteractionEnabled = true // 스크롤/줌은 허용
        navigationItem.rightBarButtonItem?.isEnabled = false

        editButton.isHidden = false
        saveButton.isHidden = true
        cancelButton.isHidden = true

        print("🔒 읽기 전용 모드 활성화")
    }

    func setEditMode() {
        budgetTextField.isUserInteractionEnabled = true
        timeTextField.isUserInteractionEnabled = true
        locationSearchButton.isUserInteractionEnabled = true
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
        print("💾 변경사항 저장 (편집 모드 유지)")
        // 저장 후에도 편집 모드 유지 - setReadOnlyMode() 제거
    }

    func cancelEdit() {
        // 변경사항 취소하고 원래 데이터로 복원
        print(" 편집 취소")
        setReadOnlyMode()

        // 원래 데이터로 UI 복원
        let originalDayData = viewModel.getDayData(for: currentDay)
        updateDayUI(with: originalDayData)
        updateScheduleUI(with: originalDayData.scheduleItems)

        print(" 원래 데이터로 복원 완료")
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

            // countryType 설정 (API 분기용)
            // planData.nation이 NSLocalizedString 값일 수 있으므로 고정값으로 변환
            let planCountryType: String
            if planData.nation == "해외" || planData.nation == NSLocalizedString("international", comment: "") {
                planCountryType = "해외"
            } else {
                planCountryType = "국내"
            }
            print(" nation 값 변환: '\(planData.nation)' → '\(planCountryType)'")
            self?.setCountryType(planCountryType)

            // CollectionView 업데이트
            self?.dateCollectionView.reloadData()

            print(" 여행 계획 UI 업데이트:")
            print("    여행지: \(planData.travelName)")
            print("    국가: \(planData.nation)")
            print("    기간: \(DateManager.shared.formatToKoreanString(from: planData.startDate)) ~ \(DateManager.shared.formatToKoreanString(from: planData.endDate))")
            print("    총 일차: \(planData.totalDays)일")
        }
    }

    func updateDayUI(with dayData: PlanShowViewModel.DayData) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // 무한 루프 방지 플래그 설정
            self.isUpdatingFromViewModel = true

            // 텍스트 필드 업데이트 (무한 루프 방지)
            self.budgetTextField.text = dayData.budget

            // 플래그 해제
            self.isUpdatingFromViewModel = false

            // 현재 검색된 장소들 업데이트 (검색 업데이트 중이 아닐 때만)
            if !self.isUpdatingSearchFromMap {
                // 기존 장소와 새 장소가 다를 때만 지도 업데이트
                let currentPlaceNames = self.currentSearchedPlaces.map { $0.placeName }.sorted()
                let newPlaceNames = dayData.searchedPlaces.map { $0.placeName }.sorted()

                if currentPlaceNames != newPlaceNames {
                    print("🗺️ 장소 변경 감지: \(currentPlaceNames) → \(newPlaceNames)")

                    self.currentSearchedPlaces = dayData.searchedPlaces

                    // 지도 업데이트 (편집 모드 상관없이)
                    self.mapManager.clearAllSearchResults()
                    if !dayData.searchedPlaces.isEmpty {
                        self.mapManager.displaySearchResults(places: dayData.searchedPlaces)
                        print("🗺️ 지도에 \(dayData.searchedPlaces.count)개 마커 표시")
                        for (index, place) in dayData.searchedPlaces.enumerated() {
                            print("   \(index + 1). \(place.placeName) (\(place.coordinate.latitude), \(place.coordinate.longitude))")
                        }
                    } else {
                        print("🗺️ 표시할 마커가 없음")
                    }
                } else {
                    print("🗺️ 동일한 장소들이므로 지도 업데이트 스킵")
                }
            } else {
                print("🗺️ 검색 업데이트 중이므로 지도 업데이트 스킵")
            }

            print(" Day \(self.currentDay) UI 업데이트:")
            print("    예산: '\(dayData.budget.isEmpty ? "미설정" : dayData.budget)'")
            print("    일정: \(dayData.scheduleItems.count)개")
            print("    장소: \(dayData.searchedPlaces.count)개")
        }
    }

    func updateScheduleUI(with scheduleItems: [ScheduleItem]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // 애니메이션과 함께 기존 스케줄 아이템들 제거
            UIView.animate(withDuration: 0.3, animations: {
                self.scheduleStackView.arrangedSubviews.forEach { view in
                    view.alpha = 0
                    view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                }
            }) { _ in
                // 애니메이션 완료 후 실제 제거
                self.scheduleStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

                // 새로운 스케줄 아이템들 추가 (애니메이션과 함께)
                scheduleItems.enumerated().forEach { index, item in
                    let scheduleView = self.createScheduleItemView(item: item, index: index)
                    scheduleView.alpha = 0
                    scheduleView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

                    self.scheduleStackView.addArrangedSubview(scheduleView)

                    // 지연된 애니메이션으로 등장 효과
                    UIView.animate(withDuration: 0.3, delay: Double(index) * 0.1, options: [.curveEaseOut], animations: {
                        scheduleView.alpha = 1
                        scheduleView.transform = .identity
                    })
                }

                print(" Schedule UI 업데이트: \(scheduleItems.count)개 일정 (애니메이션 적용)")
            }
        }
    }

    func createScheduleItemView(item: ScheduleItem, index: Int) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 8

        let timeLabel = UILabel()
        timeLabel.text = item.time.isEmpty ? NSLocalizedString("time_unscheduled", comment: "Time unscheduled") : item.time
        timeLabel.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 14)
        timeLabel.textColor = .labelLight

        let locationLabel = UILabel()
        locationLabel.text = item.location.isEmpty ? NSLocalizedString("location_unscheduled", comment: "Location unscheduled") : item.location
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
        let currentScheduleItems = viewModel.getDayData(for: currentDay).scheduleItems

        // 유효한 인덱스인지 확인
        guard index < currentScheduleItems.count else {
            print(" 잘못된 인덱스: \(index)")
            return
        }

        let itemToDelete = currentScheduleItems[index]

        // 편집 모드에서만 삭제 가능
        guard isEditMode else {
            print("🔒 읽기 전용 모드에서는 삭제할 수 없습니다")
            return
        }

        // 삭제 확인 알림
        let alert = UIAlertController(
            title: NSLocalizedString("schedule_delete_title", comment: "Schedule delete title"),
            message: "'\(itemToDelete.time) - \(itemToDelete.location)' 일정을 삭제하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: "Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("delete", comment: "Delete"), style: .destructive) { [weak self] _ in
            self?.viewModel.removeScheduleItem(at: index, forDay: self?.currentDay ?? 1)
            print(" 일정 삭제 완료: \(itemToDelete.time) - \(itemToDelete.location)")
        })

        present(alert, animated: true)
    }

    func showSaveAlert(success: Bool, message: String) {
        DispatchQueue.main.async { [weak self] in
            let title = success ? "저장 완료" : "저장 실패"
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            self?.present(alert, animated: true)
        }
    }

    func showErrorAlert(message: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            self?.present(alert, animated: true)
        }
    }

    @objc func showDeleteConfirmation() {
        let alert = UIAlertController(
            title: NSLocalizedString("travel_plan_delete", comment: "Travel plan delete"),
            message: NSLocalizedString("travel_plan_delete_message", comment: "Travel plan delete message"),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: "Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("delete_complete", comment: "Delete complete"), style: .destructive) { [weak self] _ in
            self?.deleteTravelPlan()
        })

        present(alert, animated: true)
    }

    func deleteTravelPlan() {
        // ViewModel을 통해 여행 계획 삭제
        guard let planIdString = travelPlanId else {
            showErrorAlert(message: "삭제할 여행 계획을 찾을 수 없습니다.")
            return
        }

        do {
            // String을 ObjectId로 변환
            guard let objectId = try? ObjectId(string: planIdString) else {
                showErrorAlert(message: "잘못된 여행 계획 ID입니다.")
                return
            }

            // Realm에서 여행 계획 삭제
            guard let realm = try RealmManager.shared.getRealm() else {
                showErrorAlert(message: "데이터베이스 연결에 실패했습니다.")
                return
            }

            try realm.write {
                if let planToDelete = realm.object(ofType: TravelPlan.self, forPrimaryKey: objectId) {
                    realm.delete(planToDelete)
                    print(" 여행 계획 삭제 완료: \(planIdString)")
                }
            }

            // 성공 알림 후 메인 화면으로 이동
            let successAlert = UIAlertController(
                title: NSLocalizedString("delete_complete", comment: "Delete complete"),
                message: NSLocalizedString("plan_delete_complete_message", comment: "Plan delete complete message"),
                preferredStyle: .alert
            )
            successAlert.addAction(UIAlertAction(title: NSLocalizedString("confirm", comment: "Confirm"), style: .default) { [weak self] _ in
                self?.navigateToMainScreen()
            })
            present(successAlert, animated: true)

        } catch {
            showErrorAlert(message: "삭제 중 오류가 발생했습니다: \(error.localizedDescription)")
        }
    }

    func navigateToMainScreen() {
        // TravelPlanMainViewController로 이동
        if let navigationController = navigationController {
            for viewController in navigationController.viewControllers {
                if viewController is TravelPlanMainViewController {
                    navigationController.popToViewController(viewController, animated: true)
                    return
                }
            }
        }

        // 만약 스택에 없다면 루트로 이동
        navigationController?.popToRootViewController(animated: true)
    }
}
