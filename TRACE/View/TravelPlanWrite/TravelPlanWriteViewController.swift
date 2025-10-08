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
import RealmSwift

class TravelPlanWriteViewController: UIViewController {

    private let disposeBag = DisposeBag()
    private let viewModel = PlanWriteViewModel()
    
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
        $0.applyTravelStyle(placeholder: "국내/해외 선택")
        $0.isUserInteractionEnabled = true
        $0.isEnabled = true
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
        $0.isUserInteractionEnabled = true
        $0.isEnabled = true
    }

    private let endDateTextField = UITextField().then {
        $0.applyTravelStyle(placeholder: "여행 종료일")
        $0.isUserInteractionEnabled = true
        $0.isEnabled = true
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

    // 국가 선택 ActionSheet
    private lazy var countryActionSheet: UIAlertController = {
        let alert = UIAlertController(title: "여행 국가 선택", message: "여행 지역을 선택해주세요", preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "국내", style: .default) { [weak self] _ in
            self?.countryTextField.text = "국내"
            self?.viewModel.countryText.accept("국내")
        })

        alert.addAction(UIAlertAction(title: "해외", style: .default) { [weak self] _ in
            self?.countryTextField.text = "해외"
            self?.viewModel.countryText.accept("해외")
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        // iPad 대응은 present 시점에 설정

        return alert
    }()

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
        setupKeyboardDismissal()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 명시적으로 자동 저장 방지
        print("🚫 TravelPlanWrite: viewWillDisappear - 자동 저장 비활성화")
        // 여기서는 의도적으로 아무것도 저장하지 않음
    }
 
    @objc private func backButtonTapped() {
        // 명시적으로 자동 저장 방지 활성화
        viewModel.enableAutoSavePrevention()
        print("🔙 Back 버튼 클릭 - 자동 저장 없이 바로 뒤로가기")

        // Alert 없이 바로 뒤로가기
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func datePickerDone() {
        startDateTextField.resignFirstResponder()
        endDateTextField.resignFirstResponder()
    }

}

// MARK: - UITextFieldDelegate
extension TravelPlanWriteViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // countryTextField, startDateTextField, endDateTextField는 직접 입력 방지
        if textField == countryTextField || textField == startDateTextField || textField == endDateTextField {
            return false
        }
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == countryTextField {
            presentActionSheet(countryActionSheet, sourceView: countryTextField)
            return false
        }
        return true
    }
}

extension TravelPlanWriteViewController: DesiginProtocolBind {
    func bind() {
        // 국가 선택 TextField 탭 이벤트
        let countryTapGesture = UITapGestureRecognizer()
        countryTextField.addGestureRecognizer(countryTapGesture)
        countryTapGesture.rx.event
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.presentActionSheet(self.countryActionSheet, sourceView: self.countryTextField)
            })
            .disposed(by: disposeBag)

        // 국가 TextField 직접 입력 방지
        countryTextField.rx.controlEvent(.editingDidBegin)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.countryTextField.resignFirstResponder()
                self.presentActionSheet(self.countryActionSheet, sourceView: self.countryTextField)
            })
            .disposed(by: disposeBag)

        destinationTextField.rx.text.orEmpty
            .bind(to: viewModel.destinationText)
            .disposed(by: disposeBag)

        startDatePicker.rx.date
            .bind(to: viewModel.startDate)
            .disposed(by: disposeBag)

        endDatePicker.rx.date
            .bind(to: viewModel.endDate)
            .disposed(by: disposeBag)

        // Output: ViewModel -> View
        viewModel.startDateText
            .bind(to: startDateTextField.rx.text)
            .disposed(by: disposeBag)

        viewModel.endDateText
            .bind(to: endDateTextField.rx.text)
            .disposed(by: disposeBag)

        viewModel.endDateMinimum
            .bind(to: endDatePicker.rx.minimumDate)
            .disposed(by: disposeBag)

        viewModel.isFormValid
            .bind(to: planButton.rx.isEnabled)
            .disposed(by: disposeBag)

        viewModel.buttonBackgroundColor
            .bind(to: planButton.rx.backgroundColor)
            .disposed(by: disposeBag)

        // 여행 계획 생성 성공 시 Detail 화면으로 바로 이동
        viewModel.showAlert
            .subscribe(onNext: { [weak self] title, message, completion in
                if title == "완료" {
                    // 성공 시 Detail 화면으로 이동
                    let detailVC = TravelPlanDetailViewController()
                    // 선택된 국내/해외 정보 전달
                    let selectedCountry = self?.countryTextField.text ?? ""
                    print("🚀 TravelPlanWrite: 선택된 국가 - '\(selectedCountry)'")
                    detailVC.setCountryType(selectedCountry)
                    print("✅ TravelPlanWrite: setCountryType 호출 완료")
                    self?.navigationController?.pushViewController(detailVC, animated: true)
                }
            })
            .disposed(by: disposeBag)

        // 여행 계획하기 버튼 액션
        planButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.viewModel.createTravelPlan()
            })
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
        // 비활성화된 비행기 버튼
        let airplaneUIButton = UIButton(type: .system)
        airplaneUIButton.setImage(UIImage(systemName: "airplane"), for: .normal)
        airplaneUIButton.tintColor = .skyBlue
        airplaneUIButton.isUserInteractionEnabled = false
        let airplaneButton = UIBarButtonItem(customView: airplaneUIButton)

        // 비활성화된 지도 버튼
        let mapUIButton = UIButton(type: .system)
        mapUIButton.setImage(UIImage(systemName: "map"), for: .normal)
        mapUIButton.tintColor = .skyBlue
        mapUIButton.isUserInteractionEnabled = false
        let mapButton = UIBarButtonItem(customView: mapUIButton)

        navigationItem.rightBarButtonItems = [airplaneButton, mapButton]

        // TextField 직접 입력 방지 및 DatePicker 설정
        startDateTextField.inputView = startDatePicker
        endDateTextField.inputView = endDatePicker

        // 텍스트 직접 입력 방지
        countryTextField.delegate = self
        startDateTextField.delegate = self
        endDateTextField.delegate = self

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
