//
//  PlanWriteViewModel.swift
//  TRACE
//
//  Created by 차지용 on 9/29/25.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift
import UIKit

class PlanWriteViewModel {

    private let disposeBag = DisposeBag()

    // MARK: - Inputs
    let countryText = BehaviorRelay<String>(value: "")
    let destinationText = BehaviorRelay<String>(value: "")
    let startDate = BehaviorRelay<Date>(value: Date())
    let endDate = BehaviorRelay<Date>(value: Date())

    // MARK: - Auto Save Prevention
    private var shouldPreventAutoSave = false

    // MARK: - Outputs
    let isFormValid: Observable<Bool>
    let buttonBackgroundColor: Observable<UIColor>
    let startDateText: Observable<String>
    let endDateText: Observable<String>
    let endDateMinimum: Observable<Date>
    let showAlert = PublishRelay<(title: String, message: String, completion: (() -> Void)?)>()

    init() {
        // 먼저 날짜 텍스트를 정의
        startDateText = startDate
            .map { DateManager.shared.formatToKoreanString(from: $0) }

        endDateText = endDate
            .map { DateManager.shared.formatToKoreanString(from: $0) }

        // 종료일 최소값
        endDateMinimum = startDate.asObservable()

        // 폼 유효성 검사 (startDateText, endDateText가 정의된 후)
        isFormValid = Observable.combineLatest(
            countryText.asObservable(),
            destinationText.asObservable(),
            startDateText,
            endDateText
        ) { country, destination, start, end in
            return !country.isEmpty && !destination.isEmpty && !start.isEmpty && !end.isEmpty
        }

        // 버튼 배경색
        buttonBackgroundColor = isFormValid
            .map { $0 ? UIColor.buttonDark : UIColor.systemGray4 }

        // 시작일이 변경되면 종료일 자동 조정
        startDate
            .subscribe(onNext: { [weak self] newStartDate in
                if let currentEndDate = self?.endDate.value, currentEndDate < newStartDate {
                    self?.endDate.accept(newStartDate)
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Methods
    func createTravelPlan() {
        // 자동 저장 방지 플래그 확인
        if shouldPreventAutoSave {
            print("🚫 자동 저장이 방지되어 여행 계획 생성을 건너뜁니다")
            return
        }

        let country = countryText.value
        let destination = destinationText.value
        let start = startDate.value
        let end = endDate.value

        guard !country.isEmpty, !destination.isEmpty else {
            showAlert.accept((title: "오류", message: "모든 필드를 입력해주세요.", completion: nil))
            return
        }

        // TravelDay 초기값 생성
        let travelDay = TravelDay()
        travelDay.price = 0
        travelDay.place = ""
        travelDay.traffic = ""
        travelDay.location = ""
        travelDay.date = start
        travelDay.latitude = 0.0
        travelDay.longitude = 0.0

        // TravelPlan 생성
        let travelPlan = TravelPlan(
            nation: country,
            travelName: destination,
            startDate: start,
            endDate: end,
            day: travelDay
        )

        // Realm에 저장
        saveTravelPlan(travelPlan)
    }

    private func saveTravelPlan(_ travelPlan: TravelPlan) {
        do {
            let realm = try Realm()

            // Realm 파일 경로 출력
            print("📁 Realm 파일 경로: \(realm.configuration.fileURL?.path ?? "경로를 찾을 수 없음")")

            try realm.write {
                realm.add(travelPlan)
            }

            print("✅ ===== 여행 계획 저장 완료 =====")
            print("📝 저장된 데이터:")
            print("   • 국가: \(travelPlan.nation)")
            print("   • 여행지: \(travelPlan.travelName)")
            print("   • 시작일: \(DateManager.shared.formatToKoreanString(from: travelPlan.startDate))")
            print("   • 종료일: \(DateManager.shared.formatToKoreanString(from: travelPlan.endDate))")
            print("   • ID: \(travelPlan.id)")

            // Realm 데이터베이스 현재 상태 확인
            let allPlans = realm.objects(TravelPlan.self)
            print("🗄️ 총 저장된 여행 계획 수: \(allPlans.count)")
            print("=====================================")

            // 성공 알림과 함께 화면 이동 콜백
            showAlert.accept((
                title: "완료",
                message: "여행 계획이 생성되었습니다!",
                completion: nil
            ))

        } catch {
            print("❌ ===== Realm 저장 실패 =====")
            print("오류 내용: \(error.localizedDescription)")
            print("================================")
            showAlert.accept((title: "오류", message: "여행 계획 저장에 실패했습니다.", completion: nil))
        }
    }

    // MARK: - Auto Save Prevention
    func enableAutoSavePrevention() {
        shouldPreventAutoSave = true
        print("🚫 자동 저장 방지 활성화")
    }

    func disableAutoSavePrevention() {
        shouldPreventAutoSave = false
        print("✅ 자동 저장 방지 비활성화")
    }
}
