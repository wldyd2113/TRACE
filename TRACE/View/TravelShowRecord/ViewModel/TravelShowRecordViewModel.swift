//
//  TravelShowRecordViewModel.swift
//  TRACE
//
//  Created by 차지용 on 9/30/25.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift

class TravelShowRecordViewModel {

    private let disposeBag = DisposeBag()

    // MARK: - Input
    struct Input {
        let recordId: String?
        let viewDidLoad: Observable<Void>
        let editButtonTapped: Observable<Void>
        let saveButtonTapped: Observable<(route: String, record: String)>
        let cancelButtonTapped: Observable<Void>
    }

    // MARK: - Output
    struct Output {
        let recordData: Driver<RecordDisplayData?>
        let isEditMode: Driver<Bool>
        let showAlert: Driver<AlertData>
        let isLoading: Driver<Bool>
        let navigateBack: Driver<Void>
    }

    // MARK: - Data Models
    struct RecordDisplayData {
        let travelName: String
        let recordLog: String
        let photos: [Data]
        let places: [PlaceDisplayData]
        let hasPlaceholder: Bool

        var hasContent: Bool {
            return !recordLog.isEmpty
        }
    }

    struct PlaceDisplayData {
        let id: String
        let placeName: String
        let latitude: Double
        let longitude: Double
    }

    struct AlertData {
        let title: String
        let message: String
        let completion: (() -> Void)?
    }

    // MARK: - Private Properties
    private let recordDataRelay = BehaviorRelay<RecordDisplayData?>(value: nil)
    private let isEditModeRelay = BehaviorRelay<Bool>(value: false)
    private let showAlertRelay = PublishRelay<AlertData>()
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let navigateBackRelay = PublishRelay<Void>()

    private var currentRecordId: String?
    private var originalData: RecordDisplayData?

    // MARK: - Transform
    func transform(input: Input) -> Output {

        currentRecordId = input.recordId

        // viewDidLoad 시 데이터 로드
        input.viewDidLoad
            .subscribe(onNext: { [weak self] in
                self?.loadRecordData()
            })
            .disposed(by: disposeBag)

        // 편집 모드 토글
        input.editButtonTapped
            .subscribe(onNext: { [weak self] in
                self?.toggleEditMode(true)
            })
            .disposed(by: disposeBag)

        // 저장 버튼 처리
        input.saveButtonTapped
            .subscribe(onNext: { [weak self] data in
                self?.saveUpdatedRecord(route: data.route, record: data.record)
            })
            .disposed(by: disposeBag)

        // 취소 버튼 처리
        input.cancelButtonTapped
            .subscribe(onNext: { [weak self] in
                self?.cancelEdit()
            })
            .disposed(by: disposeBag)

        return Output(
            recordData: recordDataRelay.asDriver(),
            isEditMode: isEditModeRelay.asDriver(),
            showAlert: showAlertRelay.asDriver(onErrorJustReturn: AlertData(title: "오류", message: "알 수 없는 오류가 발생했습니다", completion: nil)),
            isLoading: isLoadingRelay.asDriver(),
            navigateBack: navigateBackRelay.asDriver(onErrorJustReturn: ())
        )
    }

    // MARK: - Private Methods
    private func loadRecordData() {
        guard let recordId = currentRecordId else {
            print("❌ 여행 기록 ID가 없습니다.")
            return
        }

        isLoadingRelay.accept(true)

        guard let realm = RealmManager.shared.getRealm() else {
            print("❌ Realm 접근 실패")
            isLoadingRelay.accept(false)
            showAlertRelay.accept(AlertData(
                title: "오류",
                message: "데이터베이스 연결에 실패했습니다",
                completion: nil
            ))
            return
        }

        do {
            let objectId = try ObjectId(string: recordId)
            if let record = realm.object(ofType: TravelRecord.self, forPrimaryKey: objectId) {
                let displayData = createDisplayData(from: record)
                originalData = displayData
                recordDataRelay.accept(displayData)
                print("📖 여행 기록 데이터 로드 성공: \(record.travelName)")
            } else {
                print("❌ 해당 ID의 여행 기록을 찾을 수 없습니다: \(recordId)")
                showAlertRelay.accept(AlertData(
                    title: "오류",
                    message: "여행 기록을 찾을 수 없습니다",
                    completion: nil
                ))
            }
        } catch {
            print("❌ ObjectId 변환 실패: \(error)")
            showAlertRelay.accept(AlertData(
                title: "오류",
                message: "잘못된 여행 기록 ID입니다",
                completion: nil
            ))
        }

        isLoadingRelay.accept(false)
    }

    private func createDisplayData(from record: TravelRecord) -> RecordDisplayData {
        // 사진 데이터 로드
        let photos = loadPhotosFromRecord(record)

        // 장소 데이터 변환
        let places = Array(record.locations.map { location in
            PlaceDisplayData(
                id: "",
                placeName: location.location,
                latitude: location.latitude,
                longitude: location.longitude
            )
        })

        return RecordDisplayData(
            travelName: record.travelName,
            recordLog: record.recordLog,
            photos: photos,
            places: places,
            hasPlaceholder: record.recordLog.isEmpty
        )
    }

    private func loadPhotosFromRecord(_ record: TravelRecord) -> [Data] {
        guard let travelPhoto = record.photo else { return [] }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        return travelPhoto.photos.compactMap { fileName in
            let photoPath = documentsPath.appendingPathComponent(fileName)
            do {
                return try Data(contentsOf: photoPath)
            } catch {
                print("❌ 사진 로드 실패: \(error) - 경로: \(photoPath.path)")
                return nil
            }
        }
    }

    private func toggleEditMode(_ edit: Bool) {
        isEditModeRelay.accept(edit)
        print("🔄 편집 모드: \(edit ? "ON" : "OFF")")
    }

    private func saveUpdatedRecord(route: String, record: String) {
        guard let recordId = currentRecordId,
              let realm = RealmManager.shared.getRealm() else {
            print("❌ 저장 실패: Realm 접근 불가")
            showAlertRelay.accept(AlertData(
                title: "저장 실패",
                message: "데이터베이스 연결에 실패했습니다",
                completion: nil
            ))
            return
        }

        isLoadingRelay.accept(true)

        do {
            let objectId = try ObjectId(string: recordId)
            if let travelRecord = realm.object(ofType: TravelRecord.self, forPrimaryKey: objectId) {
                try realm.write {
                    travelRecord.travelName = route
                    travelRecord.recordLog = record
                }

                // UI 업데이트를 위해 새 데이터 로드
                let updatedData = createDisplayData(from: travelRecord)
                originalData = updatedData
                recordDataRelay.accept(updatedData)

                toggleEditMode(false)

                // 저장 완료 후 바로 이전 화면으로 이동
                navigateBackRelay.accept(())

                print("✅ 여행 기록 수정 완료")
            }
        } catch {
            print("❌ 여행 기록 저장 실패: \(error)")
            showAlertRelay.accept(AlertData(
                title: "저장 실패",
                message: "여행 기록 저장 중 오류가 발생했습니다",
                completion: nil
            ))
        }

        isLoadingRelay.accept(false)
    }

    private func cancelEdit() {
        if let originalData = originalData {
            recordDataRelay.accept(originalData)
        }
        toggleEditMode(false)
        print("❌ 편집 취소")
    }
}
