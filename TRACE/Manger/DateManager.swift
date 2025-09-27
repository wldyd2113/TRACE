//
//  DateManager.swift
//  TRACE
//
//  Created by 차지용 on 9/27/25.
//

import Foundation

class DateManager {
    static let shared = DateManager()

    private init() {}

    // MARK: - DateFormatters
    private lazy var koreanDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    private lazy var standardDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private lazy var displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter
    }()

    // MARK: - Public Methods

    /// Date를 한국어 형식 문자열로 변환 (예: "2024년 12월 25일")
    func formatToKoreanString(from date: Date) -> String {
        return koreanDateFormatter.string(from: date)
    }

    /// Date를 표준 형식 문자열로 변환 (예: "2024-12-25")
    func formatToStandardString(from date: Date) -> String {
        return standardDateFormatter.string(from: date)
    }

    /// Date를 현재 로케일에 맞는 표시용 문자열로 변환
    func formatToDisplayString(from date: Date) -> String {
        return displayDateFormatter.string(from: date)
    }

    /// 한국어 형식 문자열을 Date로 변환
    func dateFromKoreanString(_ string: String) -> Date? {
        return koreanDateFormatter.date(from: string)
    }

    /// 표준 형식 문자열을 Date로 변환
    func dateFromStandardString(_ string: String) -> Date? {
        return standardDateFormatter.date(from: string)
    }

    /// 두 날짜 사이의 일수 계산
    func daysBetween(start: Date, end: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: start, to: end)
        return components.day ?? 0
    }

    /// 오늘 날짜 반환
    func today() -> Date {
        return Date()
    }

    /// 특정 날짜가 오늘 이후인지 확인
    func isFutureDate(_ date: Date) -> Bool {
        return date >= Calendar.current.startOfDay(for: Date())
    }
}
