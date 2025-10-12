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

        // 확대 버튼 바인딩
        zoomInButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.zoomIn()
            })
            .disposed(by: disposeBag)

        // 축소 버튼 바인딩
        zoomOutButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.zoomOut()
            })
            .disposed(by: disposeBag)
    }

    func configureHierarchy() {
        view.addSubview(mapView)
        view.addSubview(currentLocationButton)
        view.addSubview(zoomInButton)
        view.addSubview(zoomOutButton)
    }

    func configureUI() {
        // Navigation Bar 설정
        navigationItem.title = "여행 경로"
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

        // 확대 버튼
        zoomInButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.bottom.equalTo(currentLocationButton.snp.top).offset(-12)
            $0.width.height.equalTo(40)
        }

        // 축소 버튼
        zoomOutButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.bottom.equalTo(zoomInButton.snp.top).offset(-8)
            $0.width.height.equalTo(40)
        }
    }
}
