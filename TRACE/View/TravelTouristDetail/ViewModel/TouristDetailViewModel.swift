//
//  TouristDetailViewModel.swift
//  TRACE
//
//  Created by 차지용 on 10/28/25.
//

import Foundation
import RxSwift
import RxCocoa

final class TouristDetailViewModel {

    // MARK: - Input/Output
    struct Input {
        let viewDidLoad: Observable<Void>
        let backButtonTapped: Observable<Void>
    }

    struct Output {
        let attraction: Observable<TouristAttraction>
        let photoURLs: Observable<[String]>
        let pageCount: Observable<Int>
        let attractionName: Observable<String>
        let countryName: Observable<String>
        let categoryText: Observable<String>
        let descriptionText: Observable<String>
        let coordinateText: Observable<String>
        let mapCoordinate: Observable<(latitude: Double, longitude: Double)>
        let dismissView: Observable<Void>
    }

    // MARK: - Private Properties
    private let disposeBag = DisposeBag()
    private let attraction: TouristAttraction
    private let attractionRelay: BehaviorRelay<TouristAttraction>
    private let photoURLsRelay = BehaviorRelay<[String]>(value: [])
    private let dismissViewRelay = PublishRelay<Void>()

    // MARK: - Initialization
    init(attraction: TouristAttraction) {
        self.attraction = attraction
        self.attractionRelay = BehaviorRelay(value: attraction)

        setupPhotoURLs()
    }

    // MARK: - Transform
    func transform(input: Input) -> Output {

        // 뒤로가기 버튼 처리
        input.backButtonTapped
            .bind(to: dismissViewRelay)
            .disposed(by: disposeBag)

        // viewDidLoad 시 초기 설정
        input.viewDidLoad
            .subscribe(onNext: { [weak self] in
                self?.setupInitialData()
            })
            .disposed(by: disposeBag)

        return Output(
            attraction: attractionRelay.asObservable(),
            photoURLs: photoURLsRelay.asObservable(),
            pageCount: photoURLsRelay.map { $0.count },
            attractionName: attractionRelay.map { $0.name },
            countryName: attractionRelay.map { $0.country },
            categoryText: attractionRelay.map { $0.category.localizedTitle },
            descriptionText: attractionRelay.map { attraction in
                attraction.description.isEmpty ?
                NSLocalizedString("no_description_available", comment: "No description available") :
                attraction.description
            },
            coordinateText: attractionRelay.map { attraction in
                String(format: "%.6f, %.6f", attraction.latitude, attraction.longitude)
            },
            mapCoordinate: attractionRelay.map { ($0.latitude, $0.longitude) },
            dismissView: dismissViewRelay.asObservable()
        )
    }

    // MARK: - Private Methods
    private func setupInitialData() {
        print("🏛️ 관광지 디테일 로딩: \(attraction.name)")
    }

    private func setupPhotoURLs() {
        var urls: [String] = []

        // 여러 이미지 URL이 있으면 사용
        if let imageURLs = attraction.imageURLs, !imageURLs.isEmpty {
            urls = imageURLs
        } else if let singleImageURL = attraction.imageURL {
            // 단일 이미지만 있는 경우
            urls = [singleImageURL]
        } else {
            // 이미지가 없는 경우 플레이스홀더만 표시
            urls = ["placeholder"]
        }

        photoURLsRelay.accept(urls)
        print("📸 사진 개수: \(urls.count)")
    }
}