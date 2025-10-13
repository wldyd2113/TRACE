//
//  TravelSearchViewController.swift
//  TRACE
//
//  Created by 차지용 on 10/9/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Then

protocol TravelSearchDelegate: AnyObject {
    func didSelectPlace(_ place: KakaoPlace)
}

class TravelSearchViewController: UIViewController {

    weak var delegate: TravelSearchDelegate?

    private let disposeBag = DisposeBag()
    private let viewModel = SearchViewModel()

    // 국내/해외 구분
    var countryType: String = "국내"

    // MARK: - UI Components
    private let containerView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 20
        $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }

    private let headerView = UIView().then {
        $0.backgroundColor = .systemBackground
    }

    private let dragIndicator = UIView().then {
        $0.backgroundColor = .systemGray3
        $0.layer.cornerRadius = 2
    }

    private let titleLabel = UILabel().then {
        $0.text = NSLocalizedString("search_destination", comment: "Search destination")
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 18)
        $0.textColor = .label
        $0.textAlignment = .center
    }

    private let closeButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "xmark"), for: .normal)
        $0.tintColor = .label
    }

    private let searchBar = UISearchBar().then {
        $0.placeholder = NSLocalizedString("search_place_placeholder", comment: "Search place placeholder")
        $0.searchBarStyle = .minimal
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.searchTextField.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.searchTextField.backgroundColor = .systemGray6
    }

    private let countryTypeLabel = UILabel().then {
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 14)
        $0.textColor = .secondaryLabel
        $0.textAlignment = .center
    }

    private let loadingIndicator = UIActivityIndicatorView(style: .medium).then {
        $0.hidesWhenStopped = true
    }

    private let emptyStateLabel = UILabel().then {
        $0.text = NSLocalizedString("no_search_results", comment: "No search results")
        $0.font = UIFont(name: FontManager.onglapUIyeon.fontName, size: 16)
        $0.textColor = .secondaryLabel
        $0.textAlignment = .center
        $0.numberOfLines = 0
        $0.isHidden = true
    }

    private lazy var tableView = UITableView().then {
        $0.backgroundColor = .systemBackground
        $0.separatorStyle = .singleLine
        $0.rowHeight = UITableView.automaticDimension
        $0.estimatedRowHeight = 80
        $0.register(SearchResultTableViewCell.self, forCellReuseIdentifier: "SearchResultTableViewCell")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        setupUI()
        setupConstraints()
        bindViewModel()
        setupActions()

        // 국가 타입 라벨 업데이트
        updateCountryTypeLabel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.becomeFirstResponder()
    }

    // MARK: - Setup Methods
    private func setupUI() {
        view.addSubview(containerView)

        containerView.addSubview(headerView)
        headerView.addSubview(dragIndicator)
        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)

        containerView.addSubview(searchBar)
        containerView.addSubview(countryTypeLabel)
        containerView.addSubview(loadingIndicator)
        containerView.addSubview(emptyStateLabel)
        containerView.addSubview(tableView)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(600)
        }

        headerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(60)
        }

        dragIndicator.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(40)
            $0.height.equalTo(4)
        }

        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        closeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(44)
        }

        searchBar.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(50)
        }

        countryTypeLabel.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        loadingIndicator.snp.makeConstraints {
            $0.center.equalTo(tableView)
        }

        emptyStateLabel.snp.makeConstraints {
            $0.center.equalTo(tableView)
            $0.leading.trailing.equalToSuperview().inset(32)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(countryTypeLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func bindViewModel() {
        let searchText = searchBar.rx.text.orEmpty.asObservable()
        let searchButtonTapped = searchBar.rx.searchButtonClicked.asObservable()
        let viewDidLoad = Observable.just(())

        let input = SearchViewModel.Input(
            searchText: searchText,
            searchButtonTapped: searchButtonTapped,
            viewDidLoad: viewDidLoad,
            countryType: countryType
        )

        let output = viewModel.transform(input: input)

        // 검색 결과 바인딩
        output.searchResults
            .drive(tableView.rx.items(cellIdentifier: "SearchResultTableViewCell", cellType: SearchResultTableViewCell.self)) { [weak self] index, item, cell in
                cell.configure(with: item, countryType: self?.countryType ?? "국내")
            }
            .disposed(by: disposeBag)

        // 로딩 상태 바인딩
        output.isLoading
            .drive(onNext: { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                    self?.emptyStateLabel.isHidden = true
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            })
            .disposed(by: disposeBag)

        // 빈 상태 바인딩
        output.hasResults
            .drive(onNext: { [weak self] hasResults in
                self?.emptyStateLabel.isHidden = hasResults
            })
            .disposed(by: disposeBag)

        // 에러 메시지 바인딩
        output.errorMessage
            .compactMap { $0 }
            .drive(onNext: { [weak self] message in
                self?.showErrorAlert(message: message)
            })
            .disposed(by: disposeBag)

        // 셀 선택 바인딩
        tableView.rx.itemSelected
            .withLatestFrom(output.searchResults) { indexPath, results in
                return results[indexPath.row]
            }
            .subscribe(onNext: { [weak self] result in
                self?.delegate?.didSelectPlace(result.kakaoPlace)
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
    }

    private func setupActions() {
        closeButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)

        searchBar.rx.searchButtonClicked
            .subscribe(onNext: { [weak self] in
                self?.searchBar.resignFirstResponder()
            })
            .disposed(by: disposeBag)
    }

    private func updateCountryTypeLabel() {
        let countryKey = countryType == "해외" ? "country_type_international" : "country_type_domestic"
        countryTypeLabel.text = NSLocalizedString(countryKey, comment: "Country type label")
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: NSLocalizedString("search_error", comment: "Search error"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: "OK"), style: .default))
        present(alert, animated: true)
    }
}

