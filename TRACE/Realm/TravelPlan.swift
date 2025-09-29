//
//  TravelSaveData.swift
//  TRACE
//
//  Created by 차지용 on 9/25/25.
//

import Foundation
import RealmSwift

class TravelPlan: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var nation: String //여행 타입
    @Persisted var travelName: String // 여행지
    @Persisted var startDate: Date //여행 시작일
    @Persisted var endDate: Date // 여행 종료일
    @Persisted var day: TravelDay? // 여행 일차 (optional)
    @Persisted var travelDays: List<TravelDayDetail> = List<TravelDayDetail>() // 일차별 상세 정보

    convenience init(nation: String, travelName: String, startDate: Date, endDate: Date, day: TravelDay?) {
        self.init()
        self.nation = nation
        self.travelName = travelName
        self.startDate = startDate
        self.endDate = endDate
        self.day = day
    }

}

class TravelDay: EmbeddedObject {
    @Persisted var price: Int // 예상 비용
    @Persisted var place: String //관광지/맛집
    @Persisted var traffic: String
    @Persisted var location: String // 가는곳 경로
    @Persisted var date: Date //시간
    @Persisted var latitude: Double //위도
    @Persisted var longitude: Double
}

// 일차별 상세 정보
class TravelDayDetail: EmbeddedObject {
    @Persisted var dayNumber: Int // 여행 일차 (1, 2, 3일차)
    @Persisted var budget: String // 예상 경비
    @Persisted var route: String // 여행 경로
    @Persisted var schedules: List<TravelSchedule> = List<TravelSchedule>() // 일정 목록
    @Persisted var routeCoordinates: List<RouteCoordinate> = List<RouteCoordinate>() // 경로 좌표
}

// 개별 일정 정보
class TravelSchedule: EmbeddedObject {
    @Persisted var time: String // 시간 (예: "오전 9:00")
    @Persisted var location: String // 장소명
    @Persisted var createdAt: Date = Date() // 생성 시간
}

// 경로 좌표 정보
class RouteCoordinate: EmbeddedObject {
    @Persisted var latitude: Double // 위도
    @Persisted var longitude: Double // 경도
    @Persisted var placeName: String // 장소명
    @Persisted var order: Int // 순서 (1, 2, 3...)
}
