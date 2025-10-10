//
//  SearchViewModel.swift
//  TRACE
//
//  Created by 차지용 on 10/10/25.
//

import Foundation
import RxSwift
import RxCocoa

class SearchViewModel {

    private let disposeBag = DisposeBag()

    // MARK: - Input
    struct Input {
        let searchText: Observable<String>
        let searchButtonTapped: Observable<Void>
        let viewDidLoad: Observable<Void>
        let countryType: String
    }

    // MARK: - Output
    struct Output {
        let searchResults: Driver<[PlaceSearchResult]>
        let isLoading: Driver<Bool>
        let errorMessage: Driver<String?>
        let hasResults: Driver<Bool>
    }

    // MARK: - Private Properties
    private let searchResultsRelay = BehaviorRelay<[PlaceSearchResult]>(value: [])
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorMessageRelay = PublishRelay<String?>()

    // MARK: - Transform
    func transform(input: Input) -> Output {

        // 검색 버튼 탭 시 즉시 검색
        input.searchButtonTapped
            .withLatestFrom(input.searchText)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .subscribe(onNext: { [weak self] query in
                self?.performSearch(query: query, countryType: input.countryType)
            })
            .disposed(by: disposeBag)

        // 텍스트 입력 후 5초 지연 자동 검색
        input.searchText
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .debounce(.seconds(5), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] query in
                self?.performSearch(query: query, countryType: input.countryType)
            })
            .disposed(by: disposeBag)

        // 검색 결과가 있는지 확인
        let hasResults = searchResultsRelay
            .map { !$0.isEmpty }
            .asDriver(onErrorJustReturn: false)

        return Output(
            searchResults: searchResultsRelay.asDriver(),
            isLoading: isLoadingRelay.asDriver(),
            errorMessage: errorMessageRelay.asDriver(onErrorJustReturn: nil),
            hasResults: hasResults
        )
    }

    // MARK: - Private Methods
    private func performSearch(query: String, countryType: String) {
        print("🔍 검색 시작: '\(query)' (국가: \(countryType))")
        isLoadingRelay.accept(true)

        if countryType == "해외" {
            searchGooglePlaces(query: query)
        } else {
            searchKakaoPlaces(query: query)
        }
    }

    private func searchKakaoPlaces(query: String) {
        NetworkManger.shared.searchKakaoPlaces(query: query)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                self?.isLoadingRelay.accept(false)

                switch result {
                case .success(let response):
                    let places = response.documents.map { kakaoPlace in
                        PlaceSearchResult(
                            id: kakaoPlace.id,
                            name: kakaoPlace.placeName,
                            address: kakaoPlace.addressName,
                            roadAddress: kakaoPlace.roadAddressName,
                            latitude: kakaoPlace.coordinate.latitude,
                            longitude: kakaoPlace.coordinate.longitude,
                            category: kakaoPlace.categoryName,
                            phone: kakaoPlace.phone,
                            url: kakaoPlace.placeUrl,
                            distance: kakaoPlace.distance
                        )
                    }

                    self?.searchResultsRelay.accept(places)
                    print("✅ 카카오 검색 완료: \(places.count)개 장소 발견")

                case .failure(let error):
                    print("❌ 카카오 검색 실패: \(error.localizedDescription)")
                    self?.errorMessageRelay.accept("검색에 실패했습니다. 다시 시도해주세요.")
                    self?.searchResultsRelay.accept([])
                }
            }, onError: { [weak self] error in
                self?.isLoadingRelay.accept(false)
                print("❌ 카카오 네트워크 오류: \(error.localizedDescription)")
                self?.errorMessageRelay.accept("네트워크 오류가 발생했습니다.")
                self?.searchResultsRelay.accept([])
            })
            .disposed(by: disposeBag)
    }

    private func searchGooglePlaces(query: String) {
        NetworkManger.shared.searchGooglePlaces(query: query)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                self?.isLoadingRelay.accept(false)

                switch result {
                case .success(let response):
                    let places = response.results.map { googlePlace in
                        PlaceSearchResult(
                            id: googlePlace.placeId,
                            name: googlePlace.name,
                            address: googlePlace.formattedAddress ?? "",
                            roadAddress: googlePlace.formattedAddress ?? "",
                            latitude: googlePlace.geometry.location.lat,
                            longitude: googlePlace.geometry.location.lng,
                            category: googlePlace.types.first ?? "",
                            phone: "",
                            url: "",
                            distance: ""
                        )
                    }

                    self?.searchResultsRelay.accept(places)
                    print("✅ 구글 검색 완료: \(places.count)개 장소 발견")

                case .failure(let error):
                    print("❌ 구글 검색 실패: \(error.localizedDescription)")
                    self?.errorMessageRelay.accept("검색에 실패했습니다. 다시 시도해주세요.")
                    self?.searchResultsRelay.accept([])
                }
            }, onError: { [weak self] error in
                self?.isLoadingRelay.accept(false)
                print("❌ 구글 네트워크 오류: \(error.localizedDescription)")
                self?.errorMessageRelay.accept("네트워크 오류가 발생했습니다.")
                self?.searchResultsRelay.accept([])
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - PlaceSearchResult Model
struct PlaceSearchResult {
    let id: String
    let name: String
    let address: String
    let roadAddress: String
    let latitude: Double
    let longitude: Double
    let category: String
    let phone: String
    let url: String
    let distance: String

    // KakaoPlace로 변환하는 computed property
    var kakaoPlace: KakaoPlace {
        return KakaoPlace(
            id: id,
            placeName: name,
            categoryName: category,
            categoryGroupCode: "",
            categoryGroupName: "",
            phone: phone,
            addressName: address,
            roadAddressName: roadAddress,
            x: String(longitude),
            y: String(latitude),
            placeUrl: url,
            distance: distance
        )
    }
}
