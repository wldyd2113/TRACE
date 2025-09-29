//
//  MapManger.swift
//  TRACE
//
//  Created by 차지용 on 9/29/25.
//

import Foundation
import MapKit
import CoreLocation

protocol MapMangerDelegate: AnyObject {
    func mapManagerDidUpdateLocation(_ coordinate: CLLocationCoordinate2D)
    func mapManagerDidFailToGetLocation()
}

class MapManger: NSObject {

    weak var delegate: MapMangerDelegate?

    private let locationManager = CLLocationManager()
    let mapView = MKMapView()

    override init() {
        super.init()
        setupMapView()
        setupLocationManager()
    }

    // MARK: - Setup Methods
    private func setupMapView() {
        mapView.layer.cornerRadius = 12
        mapView.showsUserLocation = true
        mapView.mapType = .standard
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - Public Methods
    func requestInitialLocation() {
        let authStatus = locationManager.authorizationStatus
        print("📍 MapManger: Current authorization status: \(authStatus.rawValue)")

        switch authStatus {
        case .notDetermined:
            print("📍 MapManger: Permission not determined, using default location")
            setDefaultLocation()
        case .denied, .restricted:
            print("📍 MapManger: Location access denied or restricted, using default location")
            setDefaultLocation()
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 MapManger: Location authorized, requesting current location...")
            locationManager.requestLocation()
        @unknown default:
            print("📍 MapManger: Unknown authorization status, using default location")
            setDefaultLocation()
        }
    }

    func setDefaultLocation() {
        print("📍 Setting default location (Seoul)")
        let defaultCoordinate = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        setMapRegion(coordinate: defaultCoordinate)
    }

    func setMapRegion(coordinate: CLLocationCoordinate2D) {
        print("📍 Setting map region to: \(coordinate.latitude), \(coordinate.longitude)")
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 5000,
            longitudinalMeters: 5000
        )
        mapView.setRegion(region, animated: true)
    }

    func showRouteOnMap(coordinates: [CLLocationCoordinate2D]) {
        // 기존 어노테이션 제거
        mapView.removeAnnotations(mapView.annotations)

        // 좌표들을 지도에 표시
        for (index, coordinate) in coordinates.enumerated() {
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "지점 \(index + 1)"
            mapView.addAnnotation(annotation)
        }

        // 지도 영역 설정
        if !coordinates.isEmpty {
            let region = MKCoordinateRegion(coordinates: coordinates)
            mapView.setRegion(region, animated: true)
        }
    }

    func clearAnnotations() {
        mapView.removeAnnotations(mapView.annotations)
    }
}

// MARK: - CLLocationManagerDelegate
extension MapManger: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            print("📍 No location found in locations array")
            return
        }
        print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        setMapRegion(coordinate: location.coordinate)
        delegate?.mapManagerDidUpdateLocation(location.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("📍 Location error: \(error.localizedDescription)")
        setDefaultLocation()
        delegate?.mapManagerDidFailToGetLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let authStatus = manager.authorizationStatus
        print("📍 MapManger: Authorization changed to: \(authStatus.rawValue)")

        switch authStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 MapManger: Authorization granted, requesting location...")
            manager.requestLocation()
        case .denied, .restricted:
            print("📍 MapManger: Authorization denied/restricted, using default location")
            setDefaultLocation()
        case .notDetermined:
            print("📍 MapManger: Authorization not determined, using default location")
            setDefaultLocation()
        @unknown default:
            print("📍 MapManger: Unknown authorization status, using default location")
            setDefaultLocation()
        }
    }
}

// MARK: - MapKit Extension
extension MKCoordinateRegion {
    init(coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else {
            self.init()
            return
        }

        let minLat = coordinates.map { $0.latitude }.min()!
        let maxLat = coordinates.map { $0.latitude }.max()!
        let minLon = coordinates.map { $0.longitude }.min()!
        let maxLon = coordinates.map { $0.longitude }.max()!

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.2,
            longitudeDelta: (maxLon - minLon) * 1.2
        )

        self.init(center: center, span: span)
    }
}
