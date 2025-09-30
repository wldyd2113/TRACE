//
//  TravelPlanDetailViewController+ViewModel.swift
//  TRACE
//
//  Created by 차지용 on 9/29/25.
//

import UIKit
import RxSwift
import RxCocoa

// MARK: - ViewModel Binding
extension TravelPlanDetailViewController {
    func bindViewModel() {
        // 자동 검색 비활성화 - 빈 문자열로 고정
        let searchQuery = Observable.just("").filter { _ in false }

        let input = PlanDetailViewModel.Input(
            budgetText: budgetTextField.rx.text.orEmpty.asObservable(),
            routeText: routeSearchBar.rx.text.orEmpty.asObservable(),
            timeText: timeTextField.rx.text.orEmpty.asObservable(),
            locationText: locationTextField.rx.text.orEmpty.asObservable(),
            addScheduleButtonTapped: addScheduleItemButton.rx.tap.asObservable(),
            dayButtonTapped: createDayButtonObservable(),
            saveButtonTapped: Observable.never<Void>(), // 사용하지 않음
            searchQuery: searchQuery
        )

        let output = viewModel.transform(input: input)

        // 검색 결과를 MapManager로 전달
        output.searchResults
            .subscribe(onNext: { [weak self] places in
                self?.mapManager.displaySearchResults(places: places)
            })
            .disposed(by: disposeBag)

        // 기타 바인딩들
        output.isAddScheduleEnabled
            .bind(to: addScheduleItemButton.rx.isEnabled)
            .disposed(by: disposeBag)

        output.addScheduleButtonColor
            .bind(to: addScheduleItemButton.rx.backgroundColor)
            .disposed(by: disposeBag)

        // 일정 아이템 변화 감지 및 UI 업데이트 - 비활성화 (일차 변경 시에만 수동으로 업데이트)
        // output.scheduleItems
        //     .subscribe(onNext: { [weak self] items in
        //         self?.updateScheduleUI(items: items)
        //     })
        //     .disposed(by: disposeBag)

        // 일정 추가 성공 시 입력 필드 초기화 및 현재 일차 UI 업데이트
        input.addScheduleButtonTapped
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }

                // 입력 필드 초기화
                self.timeTextField.text = ""
                self.locationTextField.text = ""

                // 현재 일차의 최신 일정 데이터로 UI 업데이트
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let currentDayData = self.viewModel.getDayData(for: self.currentDay)
                    self.updateScheduleUI(items: currentDayData.scheduleItems)
                    print("✅ 일정 추가 후 현재 일차(\(self.currentDay)) UI 업데이트 완료")
                }
            })
            .disposed(by: disposeBag)

        // 현재 일차 데이터 변화 감지 (무한 루프 방지를 위해 주석처리)
        // output.currentDayData
        //     .subscribe(onNext: { [weak self] dayData in
        //         self?.updateDayUI(dayData: dayData)
        //     })
        //     .disposed(by: disposeBag)

        // 저장 결과 처리
        output.saveResult
            .subscribe(onNext: { [weak self] success, message in
                self?.showSaveAlert(success: success, message: message)
            })
            .disposed(by: disposeBag)

        // navigateBack은 사용하지 않음 - 저장 후 수동으로 화면 제어
    }

    private func createDayButtonObservable() -> Observable<Int> {
        // CollectionView delegate를 통해 처리하므로 빈 Observable 반환
        return Observable.never<Int>()
    }
}

// MARK: - Schedule Item Management
extension TravelPlanDetailViewController {
    @objc func deleteScheduleItem(_ sender: UIButton) {
        let index = sender.tag
        viewModel.removeScheduleItem(at: index)
        print("🗑️ 일정 삭제 요청: index \(index)")
    }

    private func getCurrentScheduleItems() -> [ScheduleItem] {
        return viewModel.getDayData(for: currentDay).scheduleItems
    }
}
