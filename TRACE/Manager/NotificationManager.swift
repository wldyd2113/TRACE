//
//  NotificationManager.swift
//  TRACE
//
//  Created by 차지용 on 10/14/25.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - 알림 권한 요청
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("알림 권한 요청 실패: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }

            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    // MARK: - 현재 알림 권한 상태 확인
    func checkNotificationPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }

    // MARK: - 여행 전날 알림 스케줄링
    func scheduleTravelReminder(for travelPlan: TravelPlan) {
        // 알림 권한 확인 (메인 스레드에서 실행)
        checkNotificationPermission { [weak self] isAuthorized in
            DispatchQueue.main.async {
                guard isAuthorized else {
                    print(" 알림 권한이 없습니다.")
                    return
                }

                self?.createTravelNotification(for: travelPlan)
            }
        }
    }

    private func createTravelNotification(for travelPlan: TravelPlan) {
        // 여행 시작일 하루 전 계산
        let calendar = Calendar.current
        guard let reminderDate = calendar.date(byAdding: .day, value: -1, to: travelPlan.startDate) else {
            print(" 알림 날짜 계산 실패")
            return
        }

        // 알림 시간 설정 (오후 8시)
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: reminderDate)
        dateComponents.hour = 20  // 오후 8시
        dateComponents.minute = 0

        guard let scheduledTime = calendar.date(from: dateComponents) else {
            print(" 알림 시간 생성 실패")
            return
        }

        let now = Date()
        print("🕐 시간 비교:")
        print("   • 현재 시간: \(DateManager.shared.formatToKoreanString(from: now))")
        print("   • 알림 예정 시간: \(DateManager.shared.formatToKoreanString(from: scheduledTime))")

        // 과거 시간은 알림 스케줄링하지 않음
        if scheduledTime <= now {
            print(" 알림 예정 시간이 이미 지났습니다.")
            return
        }

        // 알림 내용 설정
        let content = UNMutableNotificationContent()
        content.title = "내일은 여행 출발일이에요! ✈️"
        content.body = "\(travelPlan.travelName) 여행이 내일 시작됩니다. 준비물을 확인해보세요!"
        content.sound = .default
        content.badge = 1

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        // 알림 식별자 생성 (여행 계획 ID 기반)
        let identifier = "travel_reminder_\(travelPlan.id.stringValue)"

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // 알림 스케줄링
        notificationCenter.add(request) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print(" 알림 스케줄링 실패: \(error.localizedDescription)")
                } else {
                    print(" 여행 알림 스케줄링 완료!")
                    print("   • 여행지: \(travelPlan.travelName)")
                    print("   • 여행 시작일: \(DateManager.shared.formatToKoreanString(from: travelPlan.startDate))")
                    print("   • 알림 예정일: \(DateManager.shared.formatToKoreanString(from: scheduledTime))")
                }
            }
        }
    }

    // MARK: - 특정 여행 계획의 알림 취소
    func cancelTravelReminder(for travelPlan: TravelPlan, silent: Bool = false) {
        let identifier = "travel_reminder_\(travelPlan.id.stringValue)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        if !silent {
            print("여행 알림이 취소되었습니다: \(travelPlan.travelName)")
        }
    }

    // MARK: - 모든 여행 알림 취소
    func cancelAllTravelReminders() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("모든 여행 알림이 취소되었습니다.")
    }

    // MARK: - 현재 스케줄된 알림 목록 조회
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
}
