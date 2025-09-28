//
//  TravelPlanWriteViewController.swift
//  TRACE
//
//  Created by 차지용 on 9/26/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Then

class TravelPlanWriteViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }
    
    private let contentView = UIView()
    
    private let titleLabel = UILabel().then {
        $0.applyTitleStyle(text: "여행 계획")
    }
    
    // 여행 국가 섹션
    private let countryTitleLabel = UILabel().then {
        $0.applySectionTitleStyle(text: "여행 국가")
    }
    
    private let countryTextField = UITextField().then {
        $0.applyTravelStyle(placeholder: "예) 국내/ 해외")
    }
    
    private let countryDescriptionLabel = UILabel().then {
        $0.applyDescriptionStyle(text: "원하시는 여행지를 입력해주세요.")
    }
    
    // 여행지 입력 섹션
    private let destinationTitleLabel = UILabel().then {
        $0.applySectionTitleStyle(text: "여행지 입력")
    }
    
    private let destinationTextField = UITextField().then {
        $0.applyTravelStyle(placeholder: "예: 파리")
    }
    
    private let destinationDescriptionLabel = UILabel().then {
        $0.applyDescriptionStyle(text: "원하시는 여행지를 입력해주세요.")
    }
    
    // 여행일자 입력 섹션
    private let dateTitleLabel = UILabel().then {
        $0.applySectionTitleStyle(text: "여행일자 입력")
    }

    private let startDateTextField = UITextField().then {
        $0.applyTravelStyle(placeholder: "여행 시작일")
    }

    private let endDateTextField = UITextField().then {
        $0.applyTravelStyle(placeholder: "여행 종료일")
    }

    private let startDatePicker = UIDatePicker().then {
        $0.datePickerMode = .date
        $0.preferredDatePickerStyle = .wheels
        $0.minimumDate = DateManager.shared.today()
    }

    private let endDatePicker = UIDatePicker().then {
        $0.datePickerMode = .date
        $0.preferredDatePickerStyle = .wheels
        $0.minimumDate = DateManager.shared.today()
    }

    private let dateDescriptionLabel = UILabel().then {
        $0.applyDescriptionStyle(text: "여행 시작일과 종료일을 입력해주세요.")
    }
    
    // 여행 계획하기 버튼
    private let planButton = UIButton(type: .system).then {
        $0.applyLightActionStyle(title: "여행 계획하기")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background
        
        configureHierarchy()
        configureUI()
        configureLayout()
        bind()
    }
 
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func datePickerDone() {
        startDateTextField.resignFirstResponder()
        endDateTextField.resignFirstResponder()
    }
    
    private func createTravelPlan() {
        guard let country = countryTextField.text, !country.isEmpty,
              let destination = destinationTextField.text, !destination.isEmpty,
              let startDate = startDateTextField.text, !startDate.isEmpty,
              let endDate = endDateTextField.text, !endDate.isEmpty else {
            return
        }

        // 여행 계획 생성 로직
        print("여행 계획 생성:")
        print("국가: \(country)")
        print("여행지: \(destination)")
        print("시작일: \(startDate)")
        print("종료일: \(endDate)")

        // 성공 알림 또는 다음 화면으로 이동
        let alert = UIAlertController(title: "완료", message: "여행 계획이 생성되었습니다!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}

extension TravelPlanWriteViewController: DesiginProtocolBind {
    func bind() {
        // DatePicker 값 변경 감지
        startDatePicker.rx.date
            .subscribe(onNext: { [weak self] date in
                guard let self = self else { return }

                // 시작일 텍스트 업데이트
                self.startDateTextField.text = DateManager.shared.formatToKoreanString(from: date)

                // 종료일 최소 날짜를 시작일로 설정
                self.endDatePicker.minimumDate = date

                // 종료일이 시작일보다 이전이면 시작일로 설정
                if self.endDatePicker.date < date {
                    self.endDatePicker.date = date
                    self.endDateTextField.text = DateManager.shared.formatToKoreanString(from: date)
                }
            })
            .disposed(by: disposeBag)

        endDatePicker.rx.date
            .map { date in
                return DateManager.shared.formatToKoreanString(from: date)
            }
            .bind(to: endDateTextField.rx.text)
            .disposed(by: disposeBag)

        // 여행 계획하기 버튼 액션
        planButton.rx.tap
            .bind(with: self, onNext: { owner, _ in
                let vc = TravelPlanDetailViewController()
                owner.navigationController?.pushViewController(vc, animated: true)
                
            })
            .disposed(by: disposeBag)

        // 텍스트필드 입력 감지
        Observable.combineLatest(
            countryTextField.rx.text.orEmpty,
            destinationTextField.rx.text.orEmpty,
            startDateTextField.rx.text.orEmpty,
            endDateTextField.rx.text.orEmpty
        )
        .map { !$0.isEmpty && !$1.isEmpty && !$2.isEmpty && !$3.isEmpty }
        .bind(to: planButton.rx.isEnabled)
        .disposed(by: disposeBag)

        // 버튼 활성/비활성 상태에 따른 색상 변경
        Observable.combineLatest(
            countryTextField.rx.text.orEmpty,
            destinationTextField.rx.text.orEmpty,
            startDateTextField.rx.text.orEmpty,
            endDateTextField.rx.text.orEmpty
        )
        .map { !$0.isEmpty && !$1.isEmpty && !$2.isEmpty && !$3.isEmpty }
        .map { $0 ? UIColor.buttonDark : UIColor.systemGray4 }
        .bind(to: planButton.rx.backgroundColor)
        .disposed(by: disposeBag)
    }

    func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [titleLabel, countryTitleLabel, countryTextField, countryDescriptionLabel,
         destinationTitleLabel, destinationTextField, destinationDescriptionLabel,
         dateTitleLabel, startDateTextField, endDateTextField, dateDescriptionLabel, planButton].forEach {
            contentView.addSubview($0)
        }
    }

    func configureUI() {
        // Navigation Bar 설정
        navigationItem.title = "여행 계획"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "airplane"), style: .plain, target: nil, action: nil),
            UIBarButtonItem(image: UIImage(systemName: "map"), style: .plain, target: nil, action: nil)
        ]

        // DatePicker 설정
        startDateTextField.inputView = startDatePicker
        endDateTextField.inputView = endDatePicker

        // 키보드 툴바 설정
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(datePickerDone))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [flexSpace, doneButton]

        startDateTextField.inputAccessoryView = toolbar
        endDateTextField.inputAccessoryView = toolbar
    }

    func configureLayout() {
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalToSuperview().offset(20)
        }

        // 여행 국가 섹션
        countryTitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        countryTextField.snp.makeConstraints {
            $0.top.equalTo(countryTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        countryDescriptionLabel.snp.makeConstraints {
            $0.top.equalTo(countryTextField.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        // 여행지 입력 섹션
        destinationTitleLabel.snp.makeConstraints {
            $0.top.equalTo(countryDescriptionLabel.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        destinationTextField.snp.makeConstraints {
            $0.top.equalTo(destinationTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        destinationDescriptionLabel.snp.makeConstraints {
            $0.top.equalTo(destinationTextField.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        // 여행일자 입력 섹션
        dateTitleLabel.snp.makeConstraints {
            $0.top.equalTo(destinationDescriptionLabel.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        startDateTextField.snp.makeConstraints {
            $0.top.equalTo(dateTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        endDateTextField.snp.makeConstraints {
            $0.top.equalTo(startDateTextField.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        dateDescriptionLabel.snp.makeConstraints {
            $0.top.equalTo(endDateTextField.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        // 여행 계획하기 버튼
        planButton.snp.makeConstraints {
            $0.top.equalTo(dateDescriptionLabel.snp.bottom).offset(50)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(50)
            $0.bottom.equalToSuperview().offset(-30)
        }
    }
}
