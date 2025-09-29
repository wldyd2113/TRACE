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

        // 저장 결과 바인딩
        output.saveResult
            .subscribe(onNext: { [weak self] success, message in
                self?.showSaveAlert(success: success, message: message)
            })
            .disposed(by: disposeBag)

        // 에러 처리
        output.error
            .subscribe(onNext: { [weak self] errorMessage in
                self?.showErrorAlert(message: errorMessage)
            })
            .disposed(by: disposeBag)

        // 예산 텍스트 필드 변경 감지
        budgetTextField.rx.text.orEmpty
            .skip(1) // 초기값 스킵
            .subscribe(onNext: { budgetChangedSubject.onNext($0) })
            .disposed(by: disposeBag)

        // 경로 검색바 변경 감지
        routeSearchBar.rx.text.orEmpty
            .skip(1) // 초기값 스킵
            .subscribe(onNext: { routeChangedSubject.onNext($0) })
            .disposed(by: disposeBag)

        // 일정 추가 버튼
        addScheduleItemButton.rx.tap
            .withLatestFrom(Observable.combineLatest(
                timeTextField.rx.text.orEmpty,
                locationTextField.rx.text.orEmpty
            ))
            .subscribe(onNext: { addScheduleSubject.onNext($0) })
            .disposed(by: disposeBag)

        // 저장 버튼
        saveButton.rx.tap
            .subscribe(onNext: { saveChangesSubject.onNext(()) })
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
