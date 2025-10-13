//
//  RecordViewModel.swift
//  TRACE
//
//  Created by 차지용 on 9/30/25.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift

final class RecordViewModel: BaseViewModel {

    private let disposeBag = DisposeBag()

    // MARK: - Input/Output
    struct Input {
        let viewDidLoad: Driver<Void>
        let refreshTriggered: Driver<Void>
        let recordSelected: Driver<IndexPath>
    }

    struct Output {
        let records: Driver<[TravelRecordDisplayModel]>
        let isLoading: Driver<Bool>
        let recordCount: Driver<String>
        let selectedRecordId: Driver<String?>
    }

    // MARK: - Private Properties
    private let recordsRelay = BehaviorRelay<[TravelRecord]>(value: [])
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let selectedRecordIdRelay = PublishRelay<String?>()

    // MARK: - Transform
    func transform(input: Input) -> Output {

        // viewDidLoad 또는 refresh 시 데이터 로드
        Driver.merge(input.viewDidLoad, input.refreshTriggered)
            .drive(onNext: { [weak self] in
                self?.loadRecords()
            })
            .disposed(by: disposeBag)

        // 기록 선택 처리
        input.recordSelected
            .withLatestFrom(recordsRelay.asDriver()) { indexPath, records in
                return records[safe: indexPath.item]?.id.stringValue
            }
            .drive(onNext: { [weak self] recordId in
                self?.selectedRecordIdRelay.accept(recordId)
            })
            .disposed(by: disposeBag)

        // TravelRecord를 TravelRecordDisplayModel로 변환
        let displayModels = recordsRelay.asDriver()
            .map { [weak self] records in
                return records.compactMap { record in
                    self?.createDisplayModel(from: record)
                }
            }

        // 기록 개수 문자열 생성
        let recordCountString = recordsRelay.asDriver()
            .map { records in
                return String(format: NSLocalizedString("posts_format", comment: "Posts format"), records.count)
            }

        return Output(
            records: displayModels,
            isLoading: isLoadingRelay.asDriver(),
            recordCount: recordCountString,
            selectedRecordId: selectedRecordIdRelay.asDriver(onErrorJustReturn: nil)
        )
    }

    // MARK: - Private Methods
    private func loadRecords() {
        isLoadingRelay.accept(true)

        // 안전한 Realm 로드
        guard let realm = RealmManager.shared.safeRealm() else {
            print("❌ Realm 인스턴스를 생성할 수 없습니다")
            isLoadingRelay.accept(false)
            recordsRelay.accept([])
            return
        }

        do {
            let results = realm.objects(TravelRecord.self).sorted(byKeyPath: "travelDate", ascending: false)
            let records = Array(results)

            recordsRelay.accept(records)
            isLoadingRelay.accept(false)
            print("📝 여행 기록 로드 완료: \(records.count)개")
        } catch {
            isLoadingRelay.accept(false)
            recordsRelay.accept([])
            print("❌ 여행 기록 로드 실패: \(error)")
        }
    }

    private func createDisplayModel(from record: TravelRecord) -> TravelRecordDisplayModel {
        let firstPhotoData = loadFirstPhoto(from: record)

        return TravelRecordDisplayModel(
            id: record.id.stringValue,
            travelName: record.travelName,
            nation: record.nation,
            recordLog: record.recordLog,
            travelDate: record.travelDate,
            firstPhotoData: firstPhotoData,
            photoCount: record.photo?.photos.count ?? 0,
            hasLocation: !record.locations.isEmpty
        )
    }

    private func loadFirstPhoto(from record: TravelRecord) -> Data? {
        guard let firstPhotoFileName = record.photo?.photos.first else {
            return nil
        }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photoPath = documentsPath.appendingPathComponent(firstPhotoFileName)

        do {
            let photoData = try Data(contentsOf: photoPath)
            return photoData
        } catch {
            print("❌ 사진 로드 실패: \(error) - 경로: \(photoPath.path)")
            return nil
        }
    }

    // MARK: - Public Methods
    func deleteRecord(at index: Int) -> Bool {
        let currentRecords = recordsRelay.value
        guard index < currentRecords.count else { return false }

        let recordToDelete = currentRecords[index]

        do {
            let realm = try Realm()
            guard let record = realm.object(ofType: TravelRecord.self, forPrimaryKey: recordToDelete.id) else {
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

            // 업데이트된 목록 다시 로드
            loadRecords()
            return true
        } catch {
            print("❌ 기록 삭제 실패: \(error)")
            return false
        }
    }

    private func deletePhotoFromDocuments(_ fileName: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent(fileName)

        do {
            try FileManager.default.removeItem(at: filePath)
            print("📸 사진 삭제 완료: \(filePath.path)")
        } catch {
            print("❌ 사진 삭제 실패: \(error)")
        }
    }

    func getRecord(by id: String) -> TravelRecord? {
        guard let realm = RealmManager.shared.safeRealm() else {
            print("❌ Realm 인스턴스를 생성할 수 없습니다")
            return nil
        }

        guard let objectId = try? ObjectId(string: id) else {
            print("❌ 잘못된 ObjectId: \(id)")
            return nil
        }

        return realm.object(ofType: TravelRecord.self, forPrimaryKey: objectId)
    }
}

// MARK: - Display Model
struct TravelRecordDisplayModel {
    let id: String
    let travelName: String
    let nation: String
    let recordLog: String
    let travelDate: Date
    let firstPhotoData: Data?
    let photoCount: Int
    let hasLocation: Bool

    var displayTitle: String {
        return travelName.isEmpty ? NSLocalizedString("travel_record", comment: "Travel record") : travelName
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: travelDate)
    }
}

// MARK: - Array Extension
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
