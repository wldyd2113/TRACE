//
//  TravelChannelViewController+UI.swift
//  TRACE
//
//  Created by 차지용 on 10/10/25.
//

import UIKit
import SnapKit
import RxSwift

// MARK: - DesiginProtocolBind
extension TravelChannelViewController: DesiginProtocolBind {
    func bind() {
        // 현재 위치 버튼 바인딩
        currentLocationButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.moveToCurrentLocation()
            })
            .disposed(by: disposeBag)
    }

    func configureHierarchy() {
        view.addSubview(mapView)
        view.addSubview(currentLocationButton)
    }

    func configureUI() {
        // Navigation Bar 설정
        navigationItem.title = "여행 채널"
    }

    func configureLayout() {
        // 지도 영역
        mapView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        // 현재 위치 버튼
        currentLocationButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.width.height.equalTo(50)
        }
    }
}
