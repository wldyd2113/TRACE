//
//  TravelPlanData.swift
//  TRACE
//
//  Created by 차지용 on 9/30/25.
//

import Foundation
struct TravelPlanData {
    let location: String
    let country: String
    let date: String
    let id: String

    init(from travelPlan: TravelPlan) {
        self.location = travelPlan.travelName
        self.country = travelPlan.nation
        self.date = DateManager.shared.formatToStandardString(from: travelPlan.startDate)
        self.id = travelPlan.id.stringValue
    }
}
