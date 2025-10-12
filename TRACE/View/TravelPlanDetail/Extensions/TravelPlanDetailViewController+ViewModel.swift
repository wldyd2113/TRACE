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

        // 선택된 장소 텍스트를 Observable로 변환
        let selectedLocationText = selectedLocationLabel.rx.observe(String.self, "text")
            .map { $0 ?? "" }
            .asObservable()

        let input = PlanDetailViewModel.Input(
            budgetText: Observable.just(""), // 자동 업데이트 비활성화
            routeText: Observable.just(""), // 여행 경로 기능 제거
            timeText: timeTextField.rx.text.orEmpty.asObservable(),
            locationText: selectedLocationText,
            addScheduleButtonTapped: addScheduleItemButton.rx.tap.asObservable(),
            dayButtonTapped: createDayButtonObservable(),
            saveButtonTapped: Observable.never(), // 자동 저장 비활성화
            searchQuery: searchQuery
        )

        let output = viewModel.transform(input: input)

        // ViewModel의 검색 결과는 사용하지 않음 (항상 카카오만 사용하므로)
        // 대신 TravelPlanDetailViewController의 countryType 기반 검색 사용
        // output.searchResults
        //     .subscribe(onNext: { [weak self] places in
        //         self?.mapManager.displaySearchResults(places: places)
        //     })
        //     .disposed(by: disposeBag)

        // 기타 바인딩들
        output.isAddScheduleEnabled
            .bind(to: addScheduleItemButton.rx.isEnabled)
            .disposed(by: disposeBag)

        output.isAddScheduleButtonEnabled
            .subscribe(onNext: { [weak self] isEnabled in
                self?.addScheduleItemButton.backgroundColor = isEnabled ? .skyBlue : .systemGray4
            })
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
                self.selectedLocationLabel.text = "장소를 선택해주세요"
                self.selectedLocationLabel.textColor = .secondaryLabel
                self.selectedLocationLabel.isHidden = true
                self.locationSearchButton.setTitle("여행지 검색", for: .normal)
                self.locationSearchButton.setTitleColor(.label, for: .normal)
                self.selectedPlace = nil

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


        // 메인 화면으로 이동
        output.navigateToMain
            .subscribe(onNext: { [weak self] in
                self?.navigateToTravelPlanMain()
            })
            .disposed(by: disposeBag)
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
        print("🗑️ 일정 삭제 요청: index \(index)")

        // 삭제할 뷰 찾기
        guard index < scheduleStackView.arrangedSubviews.count else {
            print("❌ 잘못된 인덱스: \(index)")
            return
        }

        let viewToDelete = scheduleStackView.arrangedSubviews[index]

        // 삭제 애니메이션 실행
        UIView.animate(withDuration: 0.3, animations: {
            viewToDelete.alpha = 0
            viewToDelete.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { [weak self] _ in
            // 애니메이션 완료 후 ViewModel에서 삭제 및 UI 업데이트
            self?.viewModel.removeScheduleItem(at: index)

            DispatchQueue.main.async {
                guard let self = self else { return }
                let updatedItems = self.viewModel.getDayData(for: self.currentDay).scheduleItems
                self.updateScheduleUI(items: updatedItems)
                print("✅ 일정 삭제 후 UI 업데이트 완료 (애니메이션 포함)")
            }
        }
    }

    private func getCurrentScheduleItems() -> [ScheduleItem] {
        return viewModel.getDayData(for: currentDay).scheduleItems
    }
}
