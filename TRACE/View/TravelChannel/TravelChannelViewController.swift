//
//  TravelChannelViewController.swift
//  TRACE
//
//  Created by 차지용 on 10/10/25.
//

import UIKit
import SnapKit
import Then
import MapKit
import CoreLocation
import RxSwift
import RxCocoa

class TravelChannelViewController: UIViewController {

    let disposeBag = DisposeBag()
    let mapManager = MapManager()
    let viewModel = TravelChannelViewModel()

    // MARK: - UI Components
    // MapKit 관련 (MapManager에서 관리)
    var mapView: MKMapView {
        return mapManager.mapView
    }

    // 현재 위치 버튼
    let currentLocationButton = UIButton(type: .system).then {
        $0.backgroundColor = .white
        $0.setImage(UIImage(systemName: "location.fill"), for: .normal)
        $0.tintColor = .skyBlue
        $0.layer.cornerRadius = 25
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.2
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 4
    }

    // 확대 버튼
    let zoomInButton = UIButton(type: .system).then {
        $0.backgroundColor = .white
        $0.setImage(UIImage(systemName: "plus"), for: .normal)
        $0.tintColor = .skyBlue
        $0.layer.cornerRadius = 20
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.2
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 4
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
    }

    // 축소 버튼
    let zoomOutButton = UIButton(type: .system).then {
        $0.backgroundColor = .white
        $0.setImage(UIImage(systemName: "minus"), for: .normal)
        $0.tintColor = .skyBlue
        $0.layer.cornerRadius = 20
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.2
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 4
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .background

        configureHierarchy()
        configureUI()
        configureLayout()
        bind()

        // 맵 관리자 설정
        setupMapManager()

        // ViewModel 바인딩
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

