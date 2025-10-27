//
//  CountryCoordinateManager.swift
//  TRACE
//
//  Created by 차지용 on 10/27/25.
//

import Foundation

struct CountryCoordinate: Hashable {
    let name: String
    let latitude: Double
    let longitude: Double
    let radius: Int // 검색 반경 (km)

    // Hashable 준수를 위한 구현
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(latitude)
        hasher.combine(longitude)
        hasher.combine(radius)
    }

    // Equatable 준수를 위한 구현
    static func == (lhs: CountryCoordinate, rhs: CountryCoordinate) -> Bool {
        return lhs.name == rhs.name &&
               lhs.latitude == rhs.latitude &&
               lhs.longitude == rhs.longitude &&
               lhs.radius == rhs.radius
    }
}

class CountryCoordinateManager {

    static let shared = CountryCoordinateManager()

    private init() {}

    // 주요 국가 및 도시의 좌표 데이터
    private let countryCoordinates: [String: CountryCoordinate] = [
        // 아시아
        "한국": CountryCoordinate(name: "한국", latitude: 37.5665, longitude: 126.9780, radius: 50),
        "korea": CountryCoordinate(name: "Korea", latitude: 37.5665, longitude: 126.9780, radius: 50),
        "서울": CountryCoordinate(name: "서울", latitude: 37.5665, longitude: 126.9780, radius: 30),
        "seoul": CountryCoordinate(name: "Seoul", latitude: 37.5665, longitude: 126.9780, radius: 30),

        "일본": CountryCoordinate(name: "일본", latitude: 35.6762, longitude: 139.6503, radius: 50),
        "japan": CountryCoordinate(name: "Japan", latitude: 35.6762, longitude: 139.6503, radius: 50),
        "도쿄": CountryCoordinate(name: "도쿄", latitude: 35.6762, longitude: 139.6503, radius: 30),
        "tokyo": CountryCoordinate(name: "Tokyo", latitude: 35.6762, longitude: 139.6503, radius: 30),
        "오사카": CountryCoordinate(name: "오사카", latitude: 34.6937, longitude: 135.5023, radius: 30),
        "osaka": CountryCoordinate(name: "Osaka", latitude: 34.6937, longitude: 135.5023, radius: 30),

        "중국": CountryCoordinate(name: "중국", latitude: 39.9042, longitude: 116.4074, radius: 100),
        "china": CountryCoordinate(name: "China", latitude: 39.9042, longitude: 116.4074, radius: 100),
        "베이징": CountryCoordinate(name: "베이징", latitude: 39.9042, longitude: 116.4074, radius: 30),
        "beijing": CountryCoordinate(name: "Beijing", latitude: 39.9042, longitude: 116.4074, radius: 30),
        "상하이": CountryCoordinate(name: "상하이", latitude: 31.2304, longitude: 121.4737, radius: 30),
        "shanghai": CountryCoordinate(name: "Shanghai", latitude: 31.2304, longitude: 121.4737, radius: 30),

        "태국": CountryCoordinate(name: "태국", latitude: 13.7563, longitude: 100.5018, radius: 50),
        "thailand": CountryCoordinate(name: "Thailand", latitude: 13.7563, longitude: 100.5018, radius: 50),
        "방콕": CountryCoordinate(name: "방콕", latitude: 13.7563, longitude: 100.5018, radius: 30),
        "bangkok": CountryCoordinate(name: "Bangkok", latitude: 13.7563, longitude: 100.5018, radius: 30),

        // 유럽
        "프랑스": CountryCoordinate(name: "프랑스", latitude: 48.8566, longitude: 2.3522, radius: 50),
        "france": CountryCoordinate(name: "France", latitude: 48.8566, longitude: 2.3522, radius: 50),
        "파리": CountryCoordinate(name: "파리", latitude: 48.8566, longitude: 2.3522, radius: 30),
        "paris": CountryCoordinate(name: "Paris", latitude: 48.8566, longitude: 2.3522, radius: 30),

        "이탈리아": CountryCoordinate(name: "이탈리아", latitude: 41.9028, longitude: 12.4964, radius: 50),
        "italy": CountryCoordinate(name: "Italy", latitude: 41.9028, longitude: 12.4964, radius: 50),
        "로마": CountryCoordinate(name: "로마", latitude: 41.9028, longitude: 12.4964, radius: 30),
        "rome": CountryCoordinate(name: "Rome", latitude: 41.9028, longitude: 12.4964, radius: 30),
        "밀라노": CountryCoordinate(name: "밀라노", latitude: 45.4642, longitude: 9.1900, radius: 30),
        "milan": CountryCoordinate(name: "Milan", latitude: 45.4642, longitude: 9.1900, radius: 30),

        "영국": CountryCoordinate(name: "영국", latitude: 51.5074, longitude: -0.1278, radius: 50),
        "uk": CountryCoordinate(name: "UK", latitude: 51.5074, longitude: -0.1278, radius: 50),
        "england": CountryCoordinate(name: "England", latitude: 51.5074, longitude: -0.1278, radius: 50),
        "런던": CountryCoordinate(name: "런던", latitude: 51.5074, longitude: -0.1278, radius: 30),
        "london": CountryCoordinate(name: "London", latitude: 51.5074, longitude: -0.1278, radius: 30),

        "스페인": CountryCoordinate(name: "스페인", latitude: 40.4168, longitude: -3.7038, radius: 50),
        "spain": CountryCoordinate(name: "Spain", latitude: 40.4168, longitude: -3.7038, radius: 50),
        "마드리드": CountryCoordinate(name: "마드리드", latitude: 40.4168, longitude: -3.7038, radius: 30),
        "madrid": CountryCoordinate(name: "Madrid", latitude: 40.4168, longitude: -3.7038, radius: 30),
        "바르셀로나": CountryCoordinate(name: "바르셀로나", latitude: 41.3851, longitude: 2.1734, radius: 30),
        "barcelona": CountryCoordinate(name: "Barcelona", latitude: 41.3851, longitude: 2.1734, radius: 30),

        "독일": CountryCoordinate(name: "독일", latitude: 52.5200, longitude: 13.4050, radius: 50),
        "germany": CountryCoordinate(name: "Germany", latitude: 52.5200, longitude: 13.4050, radius: 50),
        "베를린": CountryCoordinate(name: "베를린", latitude: 52.5200, longitude: 13.4050, radius: 30),
        "berlin": CountryCoordinate(name: "Berlin", latitude: 52.5200, longitude: 13.4050, radius: 30),

        // 미국
        "미국": CountryCoordinate(name: "미국", latitude: 40.7128, longitude: -74.0060, radius: 100),
        "usa": CountryCoordinate(name: "USA", latitude: 40.7128, longitude: -74.0060, radius: 100),
        "america": CountryCoordinate(name: "America", latitude: 40.7128, longitude: -74.0060, radius: 100),
        "뉴욕": CountryCoordinate(name: "뉴욕", latitude: 40.7128, longitude: -74.0060, radius: 30),
        "new york": CountryCoordinate(name: "New York", latitude: 40.7128, longitude: -74.0060, radius: 30),
        "로스앤젤레스": CountryCoordinate(name: "로스앤젤레스", latitude: 34.0522, longitude: -118.2437, radius: 30),
        "los angeles": CountryCoordinate(name: "Los Angeles", latitude: 34.0522, longitude: -118.2437, radius: 30),
        "샌프란시스코": CountryCoordinate(name: "샌프란시스코", latitude: 37.7749, longitude: -122.4194, radius: 30),
        "san francisco": CountryCoordinate(name: "San Francisco", latitude: 37.7749, longitude: -122.4194, radius: 30),

        // 오세아니아
        "호주": CountryCoordinate(name: "호주", latitude: -33.8688, longitude: 151.2093, radius: 100),
        "australia": CountryCoordinate(name: "Australia", latitude: -33.8688, longitude: 151.2093, radius: 100),
        "시드니": CountryCoordinate(name: "시드니", latitude: -33.8688, longitude: 151.2093, radius: 30),
        "sydney": CountryCoordinate(name: "Sydney", latitude: -33.8688, longitude: 151.2093, radius: 30),

        // 기타
        "싱가포르": CountryCoordinate(name: "싱가포르", latitude: 1.3521, longitude: 103.8198, radius: 20),
        "singapore": CountryCoordinate(name: "Singapore", latitude: 1.3521, longitude: 103.8198, radius: 20),

        "홍콩": CountryCoordinate(name: "홍콩", latitude: 22.3193, longitude: 114.1694, radius: 20),
        "hong kong": CountryCoordinate(name: "Hong Kong", latitude: 22.3193, longitude: 114.1694, radius: 20),

        "인도": CountryCoordinate(name: "인도", latitude: 28.6139, longitude: 77.2090, radius: 100),
        "india": CountryCoordinate(name: "India", latitude: 28.6139, longitude: 77.2090, radius: 100),
        "뭄바이": CountryCoordinate(name: "뭄바이", latitude: 19.0760, longitude: 72.8777, radius: 30),
        "mumbai": CountryCoordinate(name: "Mumbai", latitude: 19.0760, longitude: 72.8777, radius: 30)
    ]

    // MARK: - Public Methods

    /// 국가명으로 좌표를 검색합니다
    func getCoordinate(for countryName: String) -> CountryCoordinate? {
        let searchKey = countryName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // 정확히 일치하는 경우
        if let coordinate = countryCoordinates[searchKey] {
            return coordinate
        }

        // 부분 일치 검색
        for (key, coordinate) in countryCoordinates {
            if key.lowercased().contains(searchKey) || searchKey.contains(key.lowercased()) {
                return coordinate
            }
        }

        return nil
    }

    /// 모든 국가 목록을 반환합니다
    func getAllCountries() -> [CountryCoordinate] {
        return Array(Set(countryCoordinates.values)) // 중복 제거
    }

    /// 국가명 자동완성을 위한 검색
    func searchCountries(query: String) -> [CountryCoordinate] {
        let searchQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if searchQuery.isEmpty {
            return []
        }

        let filteredCoordinates = countryCoordinates.filter { (key, _) in
            key.lowercased().contains(searchQuery)
        }.map { $0.value }

        return Array(Set(filteredCoordinates)) // 중복 제거
    }
}
