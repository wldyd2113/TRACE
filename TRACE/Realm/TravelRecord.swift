//
//  TravelRecod.swift
//  TRACE
//
//  Created by 차지용 on 9/25/25.
//

import Foundation
import RealmSwift

class TravelRecord: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var nation: String
    @Persisted var travelName: String
    @Persisted var recordLog: String
    @Persisted var travelDate: Date
    @Persisted var photo: TravelPhoto?
    @Persisted var locations: List<RecordPlace> = List<RecordPlace>()

    convenience init(id: ObjectId, nation: String, travelName: String, recordLog: String, TravelDate: Date, photo: TravelPhoto?, locations: [RecordPlace]) {
        self.init()
        self.nation = nation
        self.travelName = travelName
        self.recordLog = recordLog
        self.travelDate = travelDate
        self.photo = photo
        self.locations.append(objectsIn: locations)
    }
}

class TravelPhoto: Object {
    @Persisted var photos: List<String> = List<String>()
}

class RecordPlace: Object {
    @Persisted var location: String //가는곳
    @Persisted var latitude: Double //위도
    @Persisted var longitude: Double //경도
}

