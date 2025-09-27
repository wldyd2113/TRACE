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
    
    // MARK: - UI Components
    private let titleLabel = UILabel().then {
        $0.text = "여행지"
        $0.font = FontManager.onglapBoldFont(24)
        $0.textColor = .label
    }
    
    private let subtitleLabel = UILabel().then {
        $0.text = "어디로 여행을 가나요?"
        $0.font = FontManager.onglapFont(14)
        $0.textColor = .systemGray
    }
    
    // 메인 여행 정보를 담는 컨테이너 뷰
    private let mainTravelContainerView = UIView().then {
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }
    
    private let dDayLabel = UILabel().then {
        $0.text = "D-30"
        $0.font = FontManager.onglapFont(14)
        $0.textColor = .labelLight
        $0.textAlignment = .left
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
        $0.textAlignment = .center
    }
    
    private let mainImageView = UIImageView().then {
        $0.backgroundColor = .systemGray4
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
    }
    
    private let imagePlaceholderLabel = UILabel().then {
        $0.text = "일본 여행 사진"
        $0.font = FontManager.onglapFont(16)
        $0.textColor = .label
        $0.textAlignment = .center
    }
    
    private let countryLabel = UILabel().then {
        $0.text = "일본"
        $0.font = FontManager.onglapFont(14)
        $0.textColor = .systemGray
    }
    
    private let dateLabel = UILabel().then {
        $0.text = "2024-03-15"
        $0.font = FontManager.onglapFont(16)
        $0.textColor = .label
    }
    
    private let flagImageView = UIImageView().then {
        $0.image = UIImage(systemName: "flag.fill")
        $0.tintColor = .systemBlue
        $0.contentMode = .scaleAspectFit
    }
    
    private let recordButton = UIButton(type: .system).then {
        $0.setTitle("일정 보기", for: .normal)
        $0.titleLabel?.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.setTitleColor(.label, for: .normal)
        $0.backgroundColor = .background
        $0.layer.cornerRadius = 10
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.systemGray4.cgColor
    }
    
    private let addTravelButton = UIButton(type: .system).then {
        $0.setTitle("여행 추가하기", for: .normal)
        $0.titleLabel?.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = .buttonDark
        $0.layer.cornerRadius = 10
    }
    
    private let travelListLabel = UILabel().then {
        $0.text = "여행 계획 리스트"
        $0.font = FontManager.onglapBoldFont(18)
        $0.textColor = .labelLight
    }
    
    private let myTravelLabel = UILabel().then {
        $0.text = "나의 여행 계획"
        $0.font = FontManager.onglapFont(12)
        $0.textColor = .systemGray
    }
    
    private let manageButton = UIButton(type: .system).then {
        $0.setTitle("계획 수정하기", for: .normal)
        $0.titleLabel?.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 12)
        $0.setTitleColor(.labelLight, for: .normal)
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.buttonDark.cgColor
        $0.layer.cornerRadius = 5
        $0.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
    }
    
    private let tableView = UITableView().then {
        $0.backgroundColor = .background
        $0.separatorStyle = .singleLine
        $0.estimatedRowHeight = 60
        $0.rowHeight = UITableView.automaticDimension
    }
    
    // MARK: - Data
    private let travelData = BehaviorRelay<[(location: String, country: String, date: String)]>(
        value: [
            ("일본", "도쿄", "2024-03-15"),
            ("프랑스", "파리", "2024-06-10")
        ]
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background
        
        configureHierarchy()
        configureUI()
        configureLayout()
        bind()
    }
}

extension TravelPlanMainViewController: DesiginProtocolBind {
    func bind() {
        // TableView 데이터 바인딩
        travelData
            .bind(to: tableView.rx.items(cellIdentifier: "TravelCell", cellType: TravelPlanTableViewCell.self)) { index, item, cell in
                cell.configure(location: item.location, country: item.country, date: item.date)
            }
            .disposed(by: disposeBag)
        
        // 버튼 액션
        recordButton.rx.tap
            .bind(with: self, onNext: { owner, _ in
//                let vc = TravelPlanWriteViewController()
//                owner.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
        
        addTravelButton.rx.tap
            .bind(with: self, onNext: { owner, _ in
                let vc = TravelPlanWriteViewController()
                owner.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
        
        manageButton.rx.tap
            .subscribe(onNext: { [weak self] in
                print("계획 수정하기 버튼 클릭")
            })
            .disposed(by: disposeBag)
    }
    
    func configureHierarchy() {
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(mainTravelContainerView)
        view.addSubview(recordButton)
        view.addSubview(addTravelButton)
        view.addSubview(travelListLabel)
        view.addSubview(myTravelLabel)
        view.addSubview(manageButton)
        view.addSubview(tableView)
        
        // 메인 컨테이너 내부 요소들
        mainTravelContainerView.addSubview(mainImageView)
        mainTravelContainerView.addSubview(countryLabel)
        mainTravelContainerView.addSubview(dateLabel)
        mainTravelContainerView.addSubview(flagImageView)

        // 이미지 내부 요소들
        mainImageView.addSubview(imagePlaceholderLabel)
        mainImageView.addSubview(dDayLabel)
    }
    
    func configureUI() {
        // TableView 셀 등록
        tableView.register(TravelPlanTableViewCell.self, forCellReuseIdentifier: "TravelCell")

        // Navigation Bar 설정
        navigationController?.navigationBar.isHidden = true
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
            $0.height.equalTo(300)
        }
        
        mainImageView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(250)
        }

        dDayLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalToSuperview()
            $0.width.equalTo(60)
            $0.height.equalTo(24)
        }
        
        imagePlaceholderLabel.snp.makeConstraints {
            $0.center.equalTo(mainImageView)
        }
        
        countryLabel.snp.makeConstraints {
            $0.top.equalTo(mainImageView.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(16)
        }
        
        dateLabel.snp.makeConstraints {
            $0.top.equalTo(countryLabel.snp.bottom).offset(4)
            $0.leading.equalTo(countryLabel)
        }
        
        flagImageView.snp.makeConstraints {
            $0.centerY.equalTo(dateLabel)
            $0.leading.equalTo(dateLabel.snp.trailing).offset(8)
            $0.width.height.equalTo(16)
        }
        
        recordButton.snp.makeConstraints {
            $0.top.equalTo(mainTravelContainerView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(50)
        }
        
        addTravelButton.snp.makeConstraints {
            $0.top.equalTo(recordButton.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(50)
        }
        
        travelListLabel.snp.makeConstraints {
            $0.top.equalTo(addTravelButton.snp.bottom).offset(32)
            $0.leading.equalToSuperview().offset(20)
        }
        
        manageButton.snp.makeConstraints {
            $0.centerY.equalTo(travelListLabel)
            $0.trailing.equalToSuperview().offset(-20)
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
