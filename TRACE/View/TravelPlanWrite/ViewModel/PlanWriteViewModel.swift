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

    deinit {
        print("🗑️ PlanWriteViewModel deinit - 자동 저장 방지 활성화")
        shouldPreventAutoSave = true
    }

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
            .map { $0 ? UIColor.skyBlue : UIColor.systemGray4 }

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
        print("🔍 createTravelPlan() 호출됨 - shouldPreventAutoSave: \(shouldPreventAutoSave)")

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
            showAlert.accept((title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("all_fields_required", comment: ""), completion: nil))
            return
        }

        // 시작일과 종료일 사이의 모든 일차 생성
        let calendar = Calendar.current
        let daysDifference = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        let totalDays = max(daysDifference + 1, 1) // 시작일과 종료일 포함, 최소 1일

        print("📅 날짜 계산 결과:")
        print("   • 시작일: \(DateManager.shared.formatToKoreanString(from: start))")
        print("   • 종료일: \(DateManager.shared.formatToKoreanString(from: end))")
        print("   • 일수 차이: \(daysDifference)일")
        print("   • 총 일차: \(totalDays)일")

        // TravelDay 초기값 생성 (첫 번째 일차용)
        let travelDay = TravelDay()
        travelDay.price = 0
        travelDay.place = ""
        travelDay.traffic = ""
        travelDay.location = ""
        travelDay.date = start
        travelDay.latitude = 0.0
        travelDay.longitude = 0.0

        // NSLocalizedString 값을 고정값으로 변환
        let nationValue = country == NSLocalizedString("international", comment: "") ? "해외" : "국내"

        // TravelPlan 생성
        let travelPlan = TravelPlan(
            nation: nationValue,
            travelName: destination,
            startDate: start,
            endDate: end,
            day: travelDay
        )

        // 각 일차별 상세 정보 생성
        print("📝 일차별 상세 정보 생성 시작:")
        for dayNumber in 1...totalDays {
            let dayDetail = TravelDayDetail()
            dayDetail.dayNumber = dayNumber
            dayDetail.budget = ""
            dayDetail.route = ""
            travelPlan.travelDays.append(dayDetail)
            print("   • \(dayNumber)일차 생성 완료")
        }
        print("📝 총 \(travelPlan.travelDays.count)개 일차 생성됨")

        // Realm에 저장
        saveTravelPlan(travelPlan)
    }

    private func saveTravelPlan(_ travelPlan: TravelPlan) {
        print("🔍 saveTravelPlan() 호출됨 - shouldPreventAutoSave: \(shouldPreventAutoSave)")

        // 한 번 더 자동 저장 방지 확인
        if shouldPreventAutoSave {
            print("🚫 saveTravelPlan에서 자동 저장이 방지되어 Realm 저장을 건너뜁니다")
            return
        }

        guard let realm = RealmManager.shared.getRealm() else {
            print("❌ ===== Realm 저장 실패 =====")
            print("오류 내용: Realm 인스턴스를 가져올 수 없습니다")
            showAlert.accept((
                title: NSLocalizedString("save_failed", comment: ""),
                message: NSLocalizedString("database_connection_failed", comment: ""),
                completion: nil
            ))
            return
        }

        do {

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
                title: NSLocalizedString("completion", comment: ""),
                message: NSLocalizedString("travel_plan_created", comment: ""),
                completion: nil
            ))

        } catch {
            print("❌ ===== Realm 저장 실패 =====")
            print("오류 내용: \(error.localizedDescription)")
            print("================================")
            showAlert.accept((title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("travel_plan_save_failed", comment: ""), completion: nil))
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
