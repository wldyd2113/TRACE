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
        // 초기화 시 한국 인기 관광지를 불러옴
        loadKoreanTouristAttractions()
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {

        // 검색 텍스트 처리 (한국 지역/장소 기반)
        input.searchText
            .debounce(.seconds(1), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] searchText in
                if searchText.isEmpty {
                    self?.loadKoreanTouristAttractions()
                } else {
                    self?.searchCountryAttractions(query: searchText)
                }
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
            // 검색어가 비어있으면 목록을 비움
            attractionsRelay.accept([])
            return
        }

        isLoadingRelay.accept(true)
        print(" ViewModel에서 카카오 관광지 검색: \(query)")

        searchWithKakaoPlaces(query: query)
    }

    private func searchWithKakaoPlaces(query: String) {
        // 검색어에 '관광지'를 붙여서 더 정확한 결과를 가져옴
        let searchQuery = "\(query) 관광지"
        
        NetworkManger.shared.searchKakaoPlaces(query: searchQuery)
            .observe(on: MainScheduler.instance)
            .flatMap { [weak self] result -> Observable<[TouristAttraction]> in
                guard let self = self else { return .just([]) }
                
                switch result {
                case .success(let response):
                    print(" 카카오 장소 검색 성공: \(response.documents.count)개 결과")
                    
                    // 각 장소에 대해 이미지 검색 수행
                    let attractionObservables = response.documents.map { document in
                        return self.fetchImageAndCreateAttraction(kakaoPlace: document)
                    }
                    
                    return Observable.zip(attractionObservables)
                    
                case .failure(let error):
                    print(" 카카오 장소 검색 실패: \(error.localizedDescription)")
                    self.errorMessageRelay.accept("검색 중 오류가 발생했습니다.")
                    return .just([])
                }
            }
            .subscribe(onNext: { [weak self] attractions in
                self?.isLoadingRelay.accept(false)
                let validAttractions = attractions.filter { $0.id != "empty" }
                self?.attractionsRelay.accept(validAttractions)
                
                if validAttractions.isEmpty && !query.isEmpty {
                    self?.errorMessageRelay.accept("'\(query)'에 대한 검색 결과가 없습니다.")
                }
            }, onError: { [weak self] error in
                self?.isLoadingRelay.accept(false)
                print(" 카카오 네트워크 오류: \(error.localizedDescription)")
                self?.errorMessageRelay.accept("네트워크 오류가 발생했습니다.")
                self?.attractionsRelay.accept([])
            })
            .disposed(by: disposeBag)
    }

    private func fetchImageAndCreateAttraction(kakaoPlace: KakaoPlace) -> Observable<TouristAttraction> {
        // 장소 이름으로 이미지 검색
        return NetworkManger.shared.searchKakaoImage(query: kakaoPlace.placeName)
            .map { result -> TouristAttraction in
                var imageUrl: String? = nil
                
                if case .success(let response) = result, let firstImage = response.documents.first {
                    imageUrl = firstImage.imageUrl
                    print("📷 이미지 발견: \(kakaoPlace.placeName) -> \(imageUrl ?? "")")
                } else {
                    print("📷 이미지 URL 없음: \(kakaoPlace.placeName)")
                }
                
                let category = self.determineCategoryFromKakaoCategory(categoryName: kakaoPlace.categoryName)
                
                return TouristAttraction(
                    id: kakaoPlace.id,
                    name: kakaoPlace.placeName,
                    country: "한국",
                    category: category,
                    imageURL: imageUrl,
                    imageURLs: imageUrl != nil ? [imageUrl!] : nil,
                    description: kakaoPlace.addressName,
                    latitude: Double(kakaoPlace.coordinate.latitude),
                    longitude: Double(kakaoPlace.coordinate.longitude)
                )
            }
            .catchAndReturn(TouristAttraction(
                id: kakaoPlace.id,
                name: kakaoPlace.placeName,
                country: "한국",
                category: .popular,
                imageURL: nil,
                imageURLs: nil,
                description: kakaoPlace.addressName,
                latitude: Double(kakaoPlace.coordinate.latitude),
                longitude: Double(kakaoPlace.coordinate.longitude)
            ))
    }

    private func convertKakaoPlaceToTouristAttraction(kakaoPlace: KakaoPlace) -> TouristAttraction {
        let category = determineCategoryFromKakaoCategory(categoryName: kakaoPlace.categoryName)
        
        // 카카오는 검색 API에서 이미지 URL을 제공하지 않으므로 nil로 설정하거나 
        // 추후 이미지 검색 API를 연동할 수 있도록 구조 유지
        return TouristAttraction(
            id: kakaoPlace.id,
            name: kakaoPlace.placeName,
            country: "한국",
            category: category,
            imageURL: nil, 
            imageURLs: nil,
            description: kakaoPlace.addressName,
            latitude: Double(kakaoPlace.coordinate.latitude),
            longitude: Double(kakaoPlace.coordinate.longitude)
        )
    }

    private func determineCategoryFromKakaoCategory(categoryName: String) -> TouristCategory {
        if categoryName.contains("문화") || categoryName.contains("유적") || categoryName.contains("역사") {
            return .historical
        } else if categoryName.contains("자연") || categoryName.contains("산") || categoryName.contains("바다") || categoryName.contains("공원") {
            return .scenic
        } else {
            return .popular
        }
    }

    private func loadKoreanTouristAttractions() {
        print(" 한국 인기 관광지 로딩 시작")
        isLoadingRelay.accept(true)
        
        // 기본적으로 '한국 인기 관광지'로 검색
        searchWithKakaoPlaces(query: "한국 인기")
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
