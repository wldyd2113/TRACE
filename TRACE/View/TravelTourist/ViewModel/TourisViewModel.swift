//
//  TourisViewModel.swift
//  TRACE
//
//  Created by 차지용 on 10/27/25.
//

import Foundation
import RxSwift
import RxCocoa

final class TourisViewModel {

    // MARK: - Input/Output
    struct Input {
        let searchText: Observable<String>
        let categorySelection: Observable<TouristCategory>
        let attractionSelection: Observable<IndexPath>
    }

    struct Output {
        let attractions: Observable<[TouristAttraction]>
        let filteredAttractions: Observable<[TouristAttraction]>
        let isLoading: Observable<Bool>
        let errorMessage: Observable<String>
        let selectedAttraction: Observable<TouristAttraction>
    }

    // MARK: - Private Properties
    private let disposeBag = DisposeBag()
    private let attractionsRelay = BehaviorRelay<[TouristAttraction]>(value: [])
    private let currentCategoryRelay = BehaviorRelay<TouristCategory>(value: .popular)
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorMessageRelay = PublishRelay<String>()
    private let selectedAttractionRelay = PublishRelay<TouristAttraction>()

    // MARK: - Initialization
    init() {
        loadKoreanTouristAttractions()
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {

        // 검색 텍스트 처리
        input.searchText
            .debounce(.seconds(1), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] searchText in
                self?.searchCountryAttractions(query: searchText)
            })
            .disposed(by: disposeBag)

        // 카테고리 선택 처리
        input.categorySelection
            .bind(to: currentCategoryRelay)
            .disposed(by: disposeBag)

        // 필터링된 관광지
        let filteredAttractions = Observable.combineLatest(
            attractionsRelay.asObservable(),
            currentCategoryRelay.asObservable()
        ) { attractions, category in
            return attractions.filter { $0.category == category }
        }

        // 관광지 선택 처리
        let selectedAttraction = input.attractionSelection
            .withLatestFrom(filteredAttractions) { indexPath, attractions in
                return attractions[safe: indexPath.item]
            }
            .compactMap { $0 }
            .do(onNext: { [weak self] attraction in
                self?.selectedAttractionRelay.accept(attraction)
            })
            .asObservable()

        return Output(
            attractions: attractionsRelay.asObservable(),
            filteredAttractions: filteredAttractions,
            isLoading: isLoadingRelay.asObservable(),
            errorMessage: errorMessageRelay.asObservable(),
            selectedAttraction: selectedAttraction
        )
    }

    // MARK: - Private Methods
    private func searchCountryAttractions(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            loadKoreanTouristAttractions()
            return
        }

        isLoadingRelay.accept(true)
        print("🔍 ViewModel에서 관광지 검색: \(query)")

        searchWithGooglePlaces(country: query)
    }

    private func searchWithGooglePlaces(country: String) {
        // 관광지 관련 키워드들
        let touristKeywords = [
            "\(country) tourist attractions",
            "\(country) sightseeing",
            "\(country) landmarks",
            "\(country) museums",
            "\(country) temples",
            "\(country) parks",
            "\(country) popular places",
            "\(country) things to do",
            "\(country) famous places",
            "\(country) must visit"
        ]

        var allAttractions: [TouristAttraction] = []
        let group = DispatchGroup()

        // 6개 키워드로 병렬 검색
        touristKeywords.prefix(6).forEach { keyword in
            group.enter()

            NetworkManger.shared.searchGooglePlaces(query: keyword)
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] result in
                    defer { group.leave() }

                    switch result {
                    case .success(let response):
                        print("✅ Google Places 검색 성공: '\(keyword)' - \(response.results.count)개 결과")

                        // GooglePlace를 TouristAttraction으로 변환
                        let attractions = response.results.prefix(10).map { place in
                            self?.convertGooglePlaceToTouristAttraction(place: place, country: country) ?? TouristAttraction.empty
                        }.filter { $0.id != "empty" }

                        allAttractions.append(contentsOf: attractions)

                    case .failure(let error):
                        print("❌ Google Places 검색 실패: '\(keyword)' - \(error.localizedDescription)")
                    }
                })
                .disposed(by: disposeBag)
        }

        // 모든 검색 완료 후 결과 처리
        group.notify(queue: .main) { [weak self] in
            self?.isLoadingRelay.accept(false)

            if allAttractions.isEmpty {
                print("⚠️ 검색 결과 없음, 한국 샘플 데이터 사용")
                self?.errorMessageRelay.accept("'\(country)' 관광지 검색에 실패했습니다.")
                self?.loadSampleData()
            } else {
                print("✅ 총 \(allAttractions.count)개 관광지 발견")
                let uniqueAttractions = self?.removeDuplicateAttractions(allAttractions) ?? []
                self?.attractionsRelay.accept(uniqueAttractions)
            }
        }
    }

    private func convertGooglePlaceToTouristAttraction(place: PlaceResult, country: String) -> TouristAttraction {
        let category = determineCategoryFromGoogleTypes(types: place.types)
        let imageURL = place.photos?.first?.getPhotoURL(maxWidth: 400)

        // 여러 이미지 URL 생성 (최대 5개)
        let imageURLs = place.photos?.prefix(5).map { photo in
            photo.getPhotoURL(maxWidth: 400)
        }

        return TouristAttraction(
            id: place.placeId,
            name: place.name,
            country: country,
            category: category,
            imageURL: imageURL,
            imageURLs: imageURLs,
            description: place.formattedAddress ?? "",
            latitude: place.geometry.location.lat,
            longitude: place.geometry.location.lng
        )
    }

    private func determineCategoryFromGoogleTypes(types: [String]) -> TouristCategory {
        let typeString = types.joined(separator: " ").lowercased()

        if typeString.contains("museum") || typeString.contains("historical") ||
           typeString.contains("heritage") || typeString.contains("monument") ||
           typeString.contains("temple") || typeString.contains("church") ||
           typeString.contains("shrine") || typeString.contains("castle") {
            return .historical
        } else if typeString.contains("park") || typeString.contains("natural") ||
                  typeString.contains("beach") || typeString.contains("mountain") ||
                  typeString.contains("garden") || typeString.contains("scenic") {
            return .scenic
        } else {
            return .popular
        }
    }

    private func removeDuplicateAttractions(_ attractions: [TouristAttraction]) -> [TouristAttraction] {
        var seen = Set<String>()
        return attractions.filter { attraction in
            let key = attraction.name.lowercased()
            if seen.contains(key) {
                return false
            } else {
                seen.insert(key)
                return true
            }
        }
    }

    private func loadKoreanTouristAttractions() {
        print("🇰🇷 한국 관광지 로딩 시작")
        isLoadingRelay.accept(true)

        searchWithGooglePlaces(country: "한국")
    }

    private func loadSampleData() {
        let sampleAttractions = [
            // 인기 관광지
            TouristAttraction(id: "1", name: "경복궁", country: "한국", category: .popular, imageURL: nil, imageURLs: nil, description: "조선 왕조의 대표 궁궐", latitude: 37.5796, longitude: 126.9770),
            TouristAttraction(id: "2", name: "명동", country: "한국", category: .popular, imageURL: nil, imageURLs: nil, description: "서울의 대표 쇼핑 거리", latitude: 37.5636, longitude: 126.9828),
            TouristAttraction(id: "3", name: "부산 해운대해수욕장", country: "한국", category: .popular, imageURL: nil, imageURLs: nil, description: "부산의 대표 해수욕장", latitude: 35.1584, longitude: 129.1600),

            // 자연/경치
            TouristAttraction(id: "4", name: "제주도 한라산", country: "한국", category: .scenic, imageURL: nil, imageURLs: nil, description: "제주도의 최고봉", latitude: 33.3617, longitude: 126.5292),
            TouristAttraction(id: "5", name: "설악산 국립공원", country: "한국", category: .scenic, imageURL: nil, imageURLs: nil, description: "강원도의 아름다운 산", latitude: 38.1197, longitude: 128.4656),
            TouristAttraction(id: "6", name: "남이섬", country: "한국", category: .scenic, imageURL: nil, imageURLs: nil, description: "춘천의 아름다운 섬", latitude: 37.7914, longitude: 127.5267),

            // 역사 문화
            TouristAttraction(id: "7", name: "불국사", country: "한국", category: .historical, imageURL: nil, imageURLs: nil, description: "경주의 유네스코 세계문화유산", latitude: 35.7898, longitude: 129.3320),
            TouristAttraction(id: "8", name: "창덕궁", country: "한국", category: .historical, imageURL: nil, imageURLs: nil, description: "조선 왕조의 이궁", latitude: 37.5804, longitude: 126.9910),
            TouristAttraction(id: "9", name: "안동 하회마을", country: "한국", category: .historical, imageURL: nil, imageURLs: nil, description: "전통 한옥 마을", latitude: 36.5392, longitude: 128.5185)
        ]

        attractionsRelay.accept(sampleAttractions)
    }
}

// MARK: - Extensions
extension TouristAttraction {
    static let empty = TouristAttraction(
        id: "empty",
        name: "",
        country: "",
        category: .popular,
        imageURL: nil,
        imageURLs: nil,
        description: "",
        latitude: 0,
        longitude: 0
    )
}
