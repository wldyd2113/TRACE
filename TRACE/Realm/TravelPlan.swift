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
