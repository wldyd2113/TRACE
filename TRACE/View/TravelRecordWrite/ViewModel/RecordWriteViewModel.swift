//
//  RecordWriteViewModel.swift
//  TRACE
//
//  Created by 차지용 on 9/30/25.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift

final class RecordWriteViewModel: BaseViewModel {

    private let disposeBag = DisposeBag()

    // MARK: - Input/Output
    struct Input {
        let routeText: Driver<String>
        let diaryText: Driver<String>
        let saveButtonTapped: Driver<Void>
        let photos: BehaviorRelay<[Data]>
        let searchedPlaces: BehaviorRelay<[KakaoPlace]>
    }

    struct Output {
        let isSaveEnabled: Driver<Bool>
        let saveResult: Driver<SaveResult>
        let isLoading: Driver<Bool>
    }

    enum SaveResult {
        case success
        case failure(String)
    }

    // MARK: - Private Properties
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let saveResultRelay = PublishRelay<SaveResult>()

    // MARK: - Transform
    func transform(input: Input) -> Output {

        // 저장 가능 여부 체크 (경로나 일기 중 하나라도 있으면 저장 가능)
        let isSaveEnabled = Driver.combineLatest(
            input.routeText,
            input.diaryText
        ) { route, diary in
            !route.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !diary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        // 저장 버튼 탭 처리
        input.saveButtonTapped
            .withLatestFrom(Driver.combineLatest(
                input.routeText,
                input.diaryText,
                input.photos.asDriver(),
                input.searchedPlaces.asDriver()
            ))
            .drive(onNext: { [weak self] route, diary, photos, places in
                self?.saveRecord(
                    route: route,
                    diary: diary,
                    photos: photos,
                    places: places
                )
            })
            .disposed(by: disposeBag)

        return Output(
            isSaveEnabled: isSaveEnabled,
            saveResult: saveResultRelay.asDriver(onErrorJustReturn: .failure(NSLocalizedString("unknown_error", comment: "Unknown error"))),
            isLoading: isLoadingRelay.asDriver()
        )
    }

    // MARK: - Private Methods
    private func saveRecord(route: String, diary: String, photos: [Data], places: [KakaoPlace]) {
        isLoadingRelay.accept(true)

        // 사진 저장은 백그라운드에서 처리
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // 사진 파일들을 먼저 저장
            let photoFileNames = photos.compactMap { photoData in
                return self.savePhotoToDocuments(photoData)
            }

            // 메인 스레드에서 Realm 작업 수행
            DispatchQueue.main.async {
                guard let realm = RealmManager.shared.safeRealm() else {
                    self.isLoadingRelay.accept(false)
                    self.saveResultRelay.accept(.failure(NSLocalizedString("database_connection_failed", comment: "Database connection failed")))
                    print("❌ Realm 인스턴스 생성 실패")
                    return
                }

                do {
                    var recordId: String = ""
                    try realm.write {
                        let record = TravelRecord()
                        record.travelName = route.isEmpty ? NSLocalizedString("travel_record", comment: "Travel record") : route
                        record.nation = self.extractNationFromRoute(route) ?? NSLocalizedString("korea", comment: "Korea")
                        record.recordLog = diary
                        record.travelDate = Date()

                        // 사진 저장
                        if !photoFileNames.isEmpty {
                            let travelPhoto = TravelPhoto()
                            travelPhoto.photos.append(objectsIn: photoFileNames)
                            record.photo = travelPhoto
                        }

                        // 위치 정보 저장
                        for place in places {
                            let recordPlace = RecordPlace()
                            recordPlace.location = place.placeName
                            recordPlace.latitude = place.coordinate.latitude
                            recordPlace.longitude = place.coordinate.longitude
                            record.locations.append(recordPlace)
                        }

                        realm.add(record)
                        recordId = record.id.stringValue
                    }

                    self.isLoadingRelay.accept(false)
                    self.saveResultRelay.accept(.success)
                    print("📝 여행 기록 저장 완료: \(recordId)")

                } catch {
                    self.isLoadingRelay.accept(false)
                    self.saveResultRelay.accept(.failure(String(format: "%@ %@", NSLocalizedString("record_save_error", comment: "Record save error"), error.localizedDescription)))
                    print("❌ 여행 기록 저장 실패: \(error)")
                }
            }
        }
    }


    private func extractNationFromRoute(_ route: String) -> String? {
        // 간단한 국가 추출 로직 (필요에 따라 확장)
        let koreanKeywords = ["서울", "부산", "제주", "경주", "강릉", "전주", "대구", "인천", "광주", "대전"]

        for keyword in koreanKeywords {
            if route.contains(keyword) {
                return NSLocalizedString("korea", comment: "Korea")
            }
        }

        return nil
    }

    private func savePhotoToDocuments(_ photoData: Data) -> String? {
        let fileName = "\(UUID().uuidString).jpg"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photoFolderPath = documentsPath.appendingPathComponent("photo")
        let filePath = photoFolderPath.appendingPathComponent(fileName)

        do {
            // photo 폴더가 없으면 생성
            if !FileManager.default.fileExists(atPath: photoFolderPath.path) {
                try FileManager.default.createDirectory(at: photoFolderPath, withIntermediateDirectories: true, attributes: nil)
                print("📁 photo 폴더 생성: \(photoFolderPath.path)")
            }

            // 사진 파일 저장
            try photoData.write(to: filePath)
            print("📸 사진 저장 완료: \(filePath.path)")
            return "photo/\(fileName)" // photo/ 경로 포함해서 반환
        } catch {
            print("❌ 사진 저장 실패: \(error)")
            return nil
        }
    }

    // MARK: - Public Methods
    func getAllRecords() -> [TravelRecord] {
        do {
            let realm = try Realm()
            return Array(realm.objects(TravelRecord.self).sorted(byKeyPath: "travelDate", ascending: false))
        } catch {
            print("❌ Realm 접근 실패: \(error)")
            return []
        }
    }

    func deleteRecord(with id: ObjectId) -> Bool {
        do {
            let realm = try Realm()
            guard let record = realm.object(ofType: TravelRecord.self, forPrimaryKey: id) else {
                return false
            }

            // 관련 사진 파일들도 삭제
            if let photos = record.photo?.photos {
                for photoFileName in photos {
                    deletePhotoFromDocuments(photoFileName)
                }
            }

            try realm.write {
                realm.delete(record)
            }
            return true
        } catch {
            print("❌ 기록 삭제 실패: \(error)")
            return false
        }
    }

    private func deletePhotoFromDocuments(_ fileName: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent(fileName) // fileName이 "photo/xxx.jpg" 형태

        do {
            try FileManager.default.removeItem(at: filePath)
            print("📸 사진 삭제 완료: \(filePath.path)")
        } catch {
            print("❌ 사진 삭제 실패: \(error)")
        }
    }
}
