//
//  TravelPlanShowViewController+ViewModel.swift
//  TRACE
//
//  Created by 차지용 on 9/29/25.
//

import UIKit
import RxSwift
import RxCocoa

// MARK: - ViewModel Binding
extension TravelPlanShowViewController {
    func bindViewModel() {
        guard let planId = travelPlanId else { return }

        let loadPlanSubject = PublishSubject<String>()
        let daySelectedSubject = PublishSubject<Int>()
        let budgetChangedSubject = PublishSubject<String>()
        let routeChangedSubject = PublishSubject<String>()
        let addScheduleSubject = PublishSubject<(time: String, location: String)>()
        let saveChangesSubject = PublishSubject<Void>()

        let input = PlanShowViewModel.Input(
            loadPlan: loadPlanSubject.asObservable(),
            daySelected: daySelectedSubject.asObservable(),
            budgetChanged: budgetChangedSubject.asObservable(),
            routeChanged: routeChangedSubject.asObservable(),
            addSchedule: addScheduleSubject.asObservable(),
            saveChanges: saveChangesSubject.asObservable()
        )

        let output = viewModel.transform(input: input)

        // 여행 계획 데이터 바인딩
        output.travelPlanData
            .subscribe(onNext: { [weak self] planData in
                self?.updateTravelPlanUI(with: planData)
            })
            .disposed(by: disposeBag)

        // 현재 일차 데이터 바인딩
        output.currentDayData
            .subscribe(onNext: { [weak self] dayData in
                self?.updateDayUI(with: dayData)
            })
            .disposed(by: disposeBag)

        // 일정 아이템 바인딩
        output.scheduleItems
            .subscribe(onNext: { [weak self] scheduleItems in
                self?.updateScheduleUI(with: scheduleItems)
            })
            .disposed(by: disposeBag)

        // 저장 결과 바인딩 (alert 제거, 콘솔 로그만)
        output.saveResult
            .subscribe(onNext: { [weak self] success, message in
                if success {
                    print("✅ 저장 성공: \(message)")
                    // 저장 성공 시 읽기 모드로 전환
                    self?.setReadOnlyMode()
                    self?.isEditMode = false
                } else {
                    print("❌ 저장 실패: \(message)")
                }
            })
            .disposed(by: disposeBag)

        // 에러 처리
        output.error
            .subscribe(onNext: { [weak self] errorMessage in
                self?.showErrorAlert(message: errorMessage)
            })
            .disposed(by: disposeBag)

        // 예산 텍스트 필드 변경 감지 (사용자 입력만 감지)
        budgetTextField.rx.text.orEmpty
            .skip(1) // 초기값 스킵
            .distinctUntilChanged() // 같은 값 연속 입력 방지
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance) // 연속 입력 방지
            .subscribe(onNext: { [weak self] text in
                guard let self = self else { return }
                // ViewModel 업데이트 중이거나 편집 모드가 아닐 때는 무시
                if !self.isUpdatingFromViewModel && self.isEditMode {
                    budgetChangedSubject.onNext(text)
                    print("💰 사용자가 예산 변경: '\(text)'")
                }
            })
            .disposed(by: disposeBag)

        // 일정 추가 버튼
        addScheduleItemButton.rx.tap
            .withLatestFrom(Observable.combineLatest(
                timeTextField.rx.text.orEmpty,
                locationTextField.rx.text.orEmpty
            ))
            .subscribe(onNext: { [weak self] timeAndLocation in
                // ViewModel에 일정 추가
                addScheduleSubject.onNext(timeAndLocation)

                // 입력 필드 초기화 (편집 모드는 유지)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.timeTextField.text = ""
                    self?.locationTextField.text = ""
                    print("✨ 일정 추가 후 입력 필드 초기화 완료 (편집 모드 유지)")
                }
            })
            .disposed(by: disposeBag)

        // 저장 버튼 - 경로 텍스트도 함께 업데이트
        saveButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }

                // 현재 입력된 텍스트들을 ViewModel에 업데이트
                if let budgetText = self.budgetTextField.text {
                    budgetChangedSubject.onNext(budgetText)
                }
                if let routeText = self.routeSearchBar.text {
                    routeChangedSubject.onNext(routeText)
                }

                // 저장 실행
                saveChangesSubject.onNext(())

                print("💾 저장 버튼 클릭 - 현재 텍스트 필드 값들 ViewModel에 업데이트 후 저장")
            })
            .disposed(by: disposeBag)

        // 일차 선택 (CollectionView에서 처리)
        // daySelectedSubject는 selectDay 메서드에서 호출

        // 초기 데이터 로드
        DispatchQueue.main.async {
            loadPlanSubject.onNext(planId)
        }

        // 인스턴스 변수로 저장하여 다른 메서드에서 사용할 수 있도록 함
        self.daySelectedSubject = daySelectedSubject
    }

    // MARK: - Schedule Item Management
    func getCurrentScheduleItems() -> [ScheduleItem] {
        return viewModel.getDayData(for: currentDay).scheduleItems
    }

}
