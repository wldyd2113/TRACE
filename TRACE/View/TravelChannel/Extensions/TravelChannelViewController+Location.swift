//
//  TravelChannelViewController+Location.swift
//  TRACE
//
//  Created by 차지용 on 10/11/25.
//

import UIKit
import CoreLocation
import MapKit

// MARK: - CLLocationManagerDelegate
extension TravelChannelViewController: CLLocationManagerDelegate {

    func setupLocationManager() {
        guard locationManager.delegate == nil else {
            print("⚠️ LocationManager가 이미 설정됨")
            return
        }

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 10.0 // 10미터마다 위치 업데이트

        // 위치 권한 상태 확인 후 요청
        let authStatus = locationManager.authorizationStatus
        if authStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }

        print("✅ LocationManager 설정 완료 - 권한 상태: \(authStatus.rawValue)")
    }

    func startRouteTracking() {
        guard !currentTravelRoutes.isEmpty else {
            print("📍 추적할 경로가 없습니다")
            return
        }

        isTrackingRoute = true
        currentRouteIndex = 0

        print("📍 경로 추적 시작: \(currentTravelRoutes.count)개 여행 경로")

        // authorizationStatus를 직접 확인하여 UI 차단 방지
        let authStatus = locationManager.authorizationStatus
        switch authStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            startLocationUpdates()
        case .notDetermined:
            print("📍 위치 권한 요청")
            locationManager.requestAlwaysAuthorization()
        case .denied, .restricted:
            print("📍 위치 권한이 거부됨")
            showLocationPermissionAlert()
        @unknown default:
            print("📍 알 수 없는 위치 권한 상태")
            locationManager.requestAlwaysAuthorization()
        }
    }

    private func startLocationUpdates() {
        // CLLocationManager.locationServicesEnabled() 호출을 제거하여 UI 차단 방지
        // 권한이 허용된 상태에서만 호출되므로 직접 위치 업데이트 시작
        if let location = locationManager.location {
            guard !location.horizontalAccuracy.isNaN else {
                print("❌ 위치 정확도가 유효하지 않음")
                return
            }
        }

        locationManager.startUpdatingLocation()

        // 백그라운드 위치 업데이트 안전하게 설정
        if #available(iOS 9.0, *) {
            do {
                locationManager.allowsBackgroundLocationUpdates = true
                print("✅ 백그라운드 위치 업데이트 활성화")
            } catch {
                print("❌ 백그라운드 위치 업데이트 설정 실패: \(error)")
            }
        }
        print("📍 위치 업데이트 시작")
    }

    func stopRouteTracking() {
        isTrackingRoute = false
        locationManager.stopUpdatingLocation()

        // 백그라운드 위치 업데이트 안전하게 비활성화
        if #available(iOS 9.0, *) {
            do {
                locationManager.allowsBackgroundLocationUpdates = false
                print("✅ 백그라운드 위치 업데이트 비활성화")
            } catch {
                print("❌ 백그라운드 위치 업데이트 비활성화 실패: \(error)")
            }
        }
        print("📍 경로 추적 종료")
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last, isTrackingRoute else { return }

        print("📍 현재 위치 업데이트: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)")

        checkArrivalAtDestinations(currentLocation: currentLocation)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("📍 위치 권한 상태 변경: \(status.rawValue)")

        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            print("📍 위치 권한 허용됨")
            if isTrackingRoute {
                startLocationUpdates()
            }
        case .denied, .restricted:
            print("📍 위치 권한 거부됨")
            isTrackingRoute = false
            showLocationPermissionAlert()
        case .notDetermined:
            print("📍 위치 권한 미결정 상태")
            // 여기서는 아무것도 하지 않고 사용자의 응답을 기다림
        @unknown default:
            print("📍 알 수 없는 위치 권한 상태")
            isTrackingRoute = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ 위치 업데이트 실패: \(error.localizedDescription)")
    }

    private func checkArrivalAtDestinations(currentLocation: CLLocation) {
        guard currentRouteIndex < currentTravelRoutes.count else {
            // 모든 경로 완료
            stopRouteTracking()
            showRouteCompletionAlert()
            return
        }

        let currentRoute = currentTravelRoutes[currentRouteIndex]
        var hasArrivedAtAnyPlace = false

        // 현재 경로의 모든 장소들을 확인
        for (index, place) in currentRoute.routes.enumerated() {
            let placeLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
            let distance = currentLocation.distance(from: placeLocation)

            if distance <= arrivalThreshold {
                print("📍 도착! \(place.name) - 거리: \(String(format: "%.1f", distance))m")

                // 해당 장소를 지도에서 제거
                removeArrivedPlace(place)
                hasArrivedAtAnyPlace = true

                // 도착 알림 표시
                showArrivalNotification(placeName: place.name)
            }
        }

        // 현재 경로의 모든 장소에 도착했는지 확인
        if hasArrivedAtAnyPlace {
            checkIfRouteCompleted()
        }
    }

    private func removeArrivedPlace(_ arrivedPlace: TravelChannelViewModel.RoutePlace) {
        // MapManager에서 해당 장소 제거
        let coordinate = CLLocationCoordinate2D(latitude: arrivedPlace.latitude, longitude: arrivedPlace.longitude)
        mapManager.removePlace(at: coordinate)
        print("🗺️ 장소 제거 요청: \(arrivedPlace.name)")
    }

    private func checkIfRouteCompleted() {
        let currentRoute = currentTravelRoutes[currentRouteIndex]
        let remainingPlaces = currentRoute.routes.filter { place in
            // MapManager의 searchedPlaces에서 해당 장소가 아직 있는지 확인
            return mapManager.searchedPlaces.contains { searchedPlace in
                abs(searchedPlace.coordinate.latitude - place.latitude) < 0.0001 &&
                abs(searchedPlace.coordinate.longitude - place.longitude) < 0.0001
            }
        }

        if remainingPlaces.isEmpty {
            // 현재 경로 완료, 다음 경로로 이동
            currentRouteIndex += 1
            print("✅ \(currentRoute.travelName) \(currentRoute.currentDay)일차 완료!")

            if currentRouteIndex < currentTravelRoutes.count {
                let nextRoute = currentTravelRoutes[currentRouteIndex]
                showNextRouteAlert(nextRoute: nextRoute)
            } else {
                // 모든 경로 완료
                stopRouteTracking()
                showAllRoutesCompletionAlert()
            }
        }
    }

    private func showArrivalNotification(placeName: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(
                title: "도착!",
                message: "\(placeName)에 도착했습니다.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            self?.present(alert, animated: true)
        }
    }

    private func showNextRouteAlert(nextRoute: TravelChannelViewModel.TravelRouteData) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(
                title: "다음 경로",
                message: "\(nextRoute.travelName) \(nextRoute.currentDay)일차로 이동합니다.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "계속", style: .default))
            self?.present(alert, animated: true)
        }
    }

    private func showRouteCompletionAlert() {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(
                title: "경로 완료",
                message: "모든 여행 경로를 완주했습니다!",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            self?.present(alert, animated: true)
        }
    }

    private func showAllRoutesCompletionAlert() {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(
                title: "여행 완료!",
                message: "모든 여행 일정을 완주했습니다! 수고하셨습니다.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            self?.present(alert, animated: true)
        }
    }
}

// MARK: - Custom Annotation
class CustomAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?

    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        super.init()
    }
}
