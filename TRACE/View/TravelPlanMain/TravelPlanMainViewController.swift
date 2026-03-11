//
//  TravelPlanMainViewController.swift
//  TRACE
//
//  Created by 차지용 on 9/25/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Then

class TravelPlanMainViewController: UIViewController {

    private let disposeBag = DisposeBag()
    private let viewModel = PlanMainViewModel()
    
    // MARK: - UI Components
    private let titleLabel = UILabel().then {
        $0.applyTitleStyle(text: NSLocalizedString("travel_destinations", comment: "Travel destinations"))
    }
    
    private let subtitleLabel = UILabel().then {
        $0.applySubtitleStyle(text: NSLocalizedString("where_to_travel", comment: "Where to travel question"))
    }
    
    // 메인 여행 정보를 담는 컨테이너 뷰
    private let mainTravelContainerView = UIView().then {
        $0.applyCardStyle()
    }
    
    private let dDayLabel = UILabel().then {
        $0.applyCaptionStyle(text: "D-30")
        $0.textColor = .white
        $0.textAlignment = .center
        $0.backgroundColor = .skyBlue
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
    }
    
    private let mainImageView = UIImageView().then {
        $0.backgroundColor = .clear
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
    }

    // 이미지 컨테이너 뷰 (이미지가 잘리는 것을 방지)
    private let imageContainerView = UIView().then {
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
    }
    
    private let imagePlaceholderLabel = UILabel().then {
        $0.applyDescriptionStyle(text: NSLocalizedString("travel_photo_placeholder", comment: "Travel photo placeholder"))
        $0.textAlignment = .center
    }
    
    private let countryLabel = UILabel().then {
        $0.applyCaptionStyle(text: NSLocalizedString("sample_country", comment: "Sample country"))
    }
    
    private let dateLabel = UILabel().then {
        $0.applyCaptionStyle(text: "2024-03-15")
    }
    
    private let flagImageView = UIImageView().then {
        $0.image = UIImage(systemName: "flag.fill")
        $0.tintColor = .systemBlue
        $0.contentMode = .scaleAspectFit
    }
    
    private let addTravelButton = UIButton(type: .system).then {
        $0.applyMainActionStyle(title: NSLocalizedString("add_travel", comment: "Add travel"), fontSize: 16)
        $0.layer.cornerRadius = 10
    }

    private let travelListLabel = UILabel().then {
        $0.applyTitleStyle(text: NSLocalizedString("travel_plan_list", comment: "Travel plan list"), fontSize: 22)
    }

    private let myTravelLabel = UILabel().then {
        $0.applyDescriptionStyle(text: NSLocalizedString("my_travel_plan", comment: "My travel plan"))
    }
    
    private let tableView = UITableView().then {
        $0.backgroundColor = .background
        $0.separatorStyle = .singleLine
        $0.estimatedRowHeight = 60
        $0.rowHeight = UITableView.automaticDimension
    }
    
    // MARK: - Data
    // ViewModel을 통해 Realm 데이터를 가져오므로 하드코딩된 데이터 제거
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background

        configureHierarchy()
        configureUI()
        configureLayout()
        bind()
        bindViewModel()

        // 개발용: 샘플 데이터 추가 로직 제거 (프로덕션 버전에서는 사용하지 않음)
        // addSampleDataIfNeeded()
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 메인 화면에서는 Navigation Bar 숨기기
        navigationController?.setNavigationBarHidden(true, animated: animated)
        // ViewModel에 데이터 새로고침 요청
        viewModel.refreshData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 다른 화면으로 이동할 때는 Navigation Bar 다시 보이기
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Sample Data Methods
    private func addSampleDataIfNeeded() {
        guard let realm = RealmManager.shared.getRealm() else {
            print(" Realm 인스턴스를 가져올 수 없습니다")
            return
        }

        let existingPlans = realm.objects(TravelPlan.self)
        if existingPlans.isEmpty {
            print(" Realm에 여행 계획이 없습니다. 샘플 데이터를 추가합니다...")
            addSampleTravelPlans()
        } else {
            print(" Realm에 \(existingPlans.count)개의 여행 계획이 있습니다")
            for plan in existingPlans {
                print("   • \(plan.travelName), \(plan.nation) - \(DateManager.shared.formatToStandardString(from: plan.startDate))")
            }
        }
    }

    private func addSampleTravelPlans() {
        guard let realm = RealmManager.shared.getRealm() else { return }

        do {
            try realm.write {
                // 샘플 여행 계획 1: 7일 후 도쿄 여행
                let tokyoTrip = TravelPlan()
                tokyoTrip.nation = "일본"
                tokyoTrip.travelName = "도쿄"
                tokyoTrip.startDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
                tokyoTrip.endDate = Calendar.current.date(byAdding: .day, value: 10, to: Date()) ?? Date()
                realm.add(tokyoTrip)

                // 샘플 여행 계획 2: 15일 후 파리 여행
                let parisTrip = TravelPlan()
                parisTrip.nation = "프랑스"
                parisTrip.travelName = "파리"
                parisTrip.startDate = Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date()
                parisTrip.endDate = Calendar.current.date(byAdding: .day, value: 20, to: Date()) ?? Date()
                realm.add(parisTrip)

                // 샘플 여행 계획 3: 30일 후 제주도 여행
                let jejuTrip = TravelPlan()
                jejuTrip.nation = "대한민국"
                jejuTrip.travelName = "제주도"
                jejuTrip.startDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
                jejuTrip.endDate = Calendar.current.date(byAdding: .day, value: 33, to: Date()) ?? Date()
                realm.add(jejuTrip)

                print(" 샘플 여행 계획 3개를 추가했습니다")
            }
        } catch {
            print(" 샘플 데이터 추가 실패: \(error)")
        }
    }
}

extension TravelPlanMainViewController: DesiginProtocolBind {
    func bind() {
        // 버튼 액션
        addTravelButton.rx.tap
            .bind(with: self, onNext: { owner, _ in
                let vc = TravelPlanWriteViewController()
                owner.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
    }

    func bindViewModel() {
        let viewDidLoadSubject = PublishSubject<Void>()
        let refreshDataSubject = PublishSubject<Void>()

        let input = PlanMainViewModel.Input(
            viewDidLoad: viewDidLoadSubject.asObservable(),
            refreshData: refreshDataSubject.asObservable(),
            recordButtonTapped: Observable.never<Void>()
        )

        // viewDidLoad 시점에 데이터 로드 트리거
        DispatchQueue.main.async {
            viewDidLoadSubject.onNext(())
        }

        let output = viewModel.transform(input: input)

        // 메인 여행 데이터 바인딩
        output.mainTravelData
            .subscribe(onNext: { [weak self] mainData in
                self?.updateMainTravelView(with: mainData)
            })
            .disposed(by: disposeBag)

        // 여행 계획 리스트 바인딩
        output.travelList
            .bind(to: tableView.rx.items(cellIdentifier: "TravelCell", cellType: TravelPlanTableViewCell.self)) { index, item, cell in
                cell.configure(location: item.location, country: item.country, date: item.date)
            }
            .disposed(by: disposeBag)

        // 테이블뷰 셀 선택 시 상세 화면으로 이동
        tableView.rx.itemSelected
            .withLatestFrom(output.travelList) { indexPath, travelList in
                return travelList[indexPath.row]
            }
            .subscribe(onNext: { [weak self] selectedPlan in
                let showVC = TravelPlanShowViewController()
                showVC.travelPlanId = selectedPlan.id
                self?.navigationController?.pushViewController(showVC, animated: true)
                print("🏃‍♂️ Moving to travel plan detail: \(selectedPlan.location)")
            })
            .disposed(by: disposeBag)

        // 에러 처리
        output.error
            .subscribe(onNext: { [weak self] errorMessage in
                self?.showErrorAlert(message: errorMessage)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Helper Methods
    private func updateMainTravelView(with data: PlanMainViewModel.MainTravelData?) {
        DispatchQueue.main.async { [weak self] in
            // 랜덤 햄토리 이미지 설정 (1~15번)
            self?.setRandomHamtoriImage()

            guard let data = data else {
                // 다가오는 여행 계획이 없는 경우
                self?.countryLabel.text = NSLocalizedString("no_upcoming_travel", comment: "No upcoming travel")
                self?.dateLabel.text = NSLocalizedString("plan_new_travel", comment: "Plan new travel")
                self?.dDayLabel.text = ""
                self?.imagePlaceholderLabel.isHidden = true // 이미지가 있으므로 텍스트 숨김
                print(" No upcoming travel plans, showing default UI")
                return
            }

            self?.countryLabel.text = data.country  // 여행지명 표시
            self?.dateLabel.text = data.date
            self?.dDayLabel.text = data.dDay
            self?.imagePlaceholderLabel.isHidden = true // 이미지가 있으므로 텍스트 숨김

            print(" 메인 여행 데이터 업데이트:")
            print("    여행지: \(data.country)")
            print("    국가: \(data.nation)")
            print("    날짜: \(data.date)")
            print("    D-Day: \(data.dDay)")
        }
    }

    private func setRandomHamtoriImage() {
        // 1~15 중 랜덤 숫자 생성
        let randomNumber = Int.random(in: 1...15)
        let imageName = "햄토리\(randomNumber)"

        if let hamtoriImage = UIImage(named: imageName) {
            mainImageView.image = hamtoriImage
            imagePlaceholderLabel.isHidden = true
            print("🐹 랜덤 햄토리 이미지 설정: \(imageName)")
        } else {
            print(" 햄토리 이미지를 찾을 수 없음: \(imageName)")
            // 이미지가 없으면 기본 상태 유지
            imagePlaceholderLabel.isHidden = false
        }
    }

    private func showErrorAlert(message: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: NSLocalizedString("error", comment: "Error"), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: "OK"), style: .default))
            self?.present(alert, animated: true)
        }
    }
    
    func configureHierarchy() {
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(mainTravelContainerView)
        view.addSubview(addTravelButton)
        view.addSubview(travelListLabel)
        view.addSubview(myTravelLabel)
        view.addSubview(tableView)
        
        // 메인 컨테이너 내부 요소들
        mainTravelContainerView.addSubview(imageContainerView)
        imageContainerView.addSubview(mainImageView)
        mainTravelContainerView.addSubview(countryLabel)
        mainTravelContainerView.addSubview(dateLabel)
        mainTravelContainerView.addSubview(flagImageView)

        // 이미지 내부 요소들
        imageContainerView.addSubview(imagePlaceholderLabel)
        imageContainerView.addSubview(dDayLabel)
    }
    
    func configureUI() {
        // TableView 셀 등록
        tableView.register(TravelPlanTableViewCell.self, forCellReuseIdentifier: "TravelCell")
    }
    
    func configureLayout() {
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.equalToSuperview().offset(20)
        }
        
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.equalTo(titleLabel)
        }
        
        mainTravelContainerView.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(320)
        }

        imageContainerView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(240)
        }

        mainImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.lessThanOrEqualToSuperview()
            $0.height.lessThanOrEqualToSuperview()
        }

        dDayLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalToSuperview()
            $0.width.equalTo(60)
            $0.height.equalTo(24)
        }
        
        imagePlaceholderLabel.snp.makeConstraints {
            $0.center.equalTo(imageContainerView)
        }
        
        countryLabel.snp.makeConstraints {
            $0.top.equalTo(imageContainerView.snp.bottom).offset(12)
            $0.leading.equalToSuperview().offset(16)
        }

        dateLabel.snp.makeConstraints {
            $0.top.equalTo(countryLabel.snp.bottom).offset(6)
            $0.leading.equalTo(countryLabel)
            $0.bottom.lessThanOrEqualToSuperview().offset(-16)
        }
        
        flagImageView.snp.makeConstraints {
            $0.centerY.equalTo(dateLabel)
            $0.leading.equalTo(dateLabel.snp.trailing).offset(8)
            $0.width.height.equalTo(16)
        }
        
        addTravelButton.snp.makeConstraints {
            $0.top.equalTo(mainTravelContainerView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(50)
        }

        travelListLabel.snp.makeConstraints {
            $0.top.equalTo(addTravelButton.snp.bottom).offset(32)
            $0.leading.equalToSuperview().offset(20)
        }
        
        myTravelLabel.snp.makeConstraints {
            $0.top.equalTo(travelListLabel.snp.bottom).offset(4)
            $0.leading.equalTo(travelListLabel)
        }
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(myTravelLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
}
