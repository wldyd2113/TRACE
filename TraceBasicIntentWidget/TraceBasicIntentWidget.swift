//
//  TraceBasicIntentWidget.swift
//  TraceBasicIntentWidget
//
//  Created by 차지용 on 10/30/25.
//

import WidgetKit
import SwiftUI

struct TravelData {
    let destination: String
    let daysUntil: Int
    let travelDate: Date
    let hasUpcomingTravel: Bool
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        let sampleData = TravelData(
            destination: "도쿄, 일본",
            daysUntil: 15,
            travelDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date(),
            hasUpcomingTravel: true
        )
        return SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), travelData: sampleData)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let travelData = await loadTravelData()
        return SimpleEntry(date: Date(), configuration: configuration, travelData: travelData)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let currentDate = Date()
        let travelData = await loadTravelData()

        // 매시간 업데이트되도록 설정
        var entries: [SimpleEntry] = []
        for hourOffset in 0..<5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration, travelData: travelData)
            entries.append(entry)
        }

        // 하루에 한 번 업데이트
        let nextUpdate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        return Timeline(entries: entries, policy: .after(nextUpdate))
    }

    private func loadTravelData() async -> TravelData {
        let dataManager = WidgetDataManager.shared

        guard let widgetData = dataManager.loadUpcomingTravelData() else {
            return TravelData(
                destination: "계획된 여행 없음",
                daysUntil: 0,
                travelDate: Date(),
                hasUpcomingTravel: false
            )
        }

        return TravelData(
            destination: "\(widgetData.location), \(widgetData.nation)",
            daysUntil: widgetData.daysUntil,
            travelDate: widgetData.startDate,
            hasUpcomingTravel: widgetData.hasUpcomingTravel
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let travelData: TravelData
}

struct TraceBasicIntentWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        if entry.travelData.hasUpcomingTravel {
            // 다가오는 여행이 있을 때 - D-day 중심 디자인
            VStack(spacing: 12) {
                // 상단: 여행 아이콘과 목적지
                HStack {
                    Image(systemName: "airplane.departure")
                        .foregroundColor(.white)
                        .font(.title3)

                    Text(entry.travelData.destination)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer()
                }

                Spacer()

                // 중앙: D-day 큰 표시
                VStack(spacing: 4) {
                    if entry.travelData.daysUntil == 0 {
                        Text("TODAY")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text("출발!")
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundColor(.white)
                    } else if entry.travelData.daysUntil == 1 {
                        Text("TOMORROW")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text("출발!")
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(.white)
                    } else {
                        Text("D-DAY")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))

                        Text("D-\(entry.travelData.daysUntil)")
                            .font(.system(size: 36, weight: .heavy))
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                // 하단: 여행 날짜
                Text(entry.travelData.travelDate, style: .date)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.8),
                        Color.blue.opacity(0.6),
                        Color.cyan.opacity(0.7)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            // 다가오는 여행이 없을 때
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)

                Text("여행 계획을\n세워보세요!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGray6))
        }
    }
}

struct TraceBasicIntentWidget: Widget {
    let kind: String = "TraceBasicIntentWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            TraceBasicIntentWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemSmall) {
    TraceBasicIntentWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        configuration: .smiley,
        travelData: TravelData(
            destination: "도쿄, 일본",
            daysUntil: 15,
            travelDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date(),
            hasUpcomingTravel: true
        )
    )
    SimpleEntry(
        date: .now,
        configuration: .starEyes,
        travelData: TravelData(
            destination: "파리, 프랑스",
            daysUntil: 3,
            travelDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
            hasUpcomingTravel: true
        )
    )
}
