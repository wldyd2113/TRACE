//
//  MapManager.swift
//  TRACE
//
//  Created by 차지용 on 9/29/25.
//

import Foundation
import MapKit
import CoreLocation

class MapManager: NSObject {

    weak var delegate: MapManagerDelegate?

    private let locationManager = CLLocationManager()
    let mapView = MKMapView()

    // 검색된 장소들을 누적 저장
    private(set) var searchedPlaces: [KakaoPlace] = []

    override init() {
        super.init()
        do {
            setupMapView()
            setupLocationManager()
            print(" MapManager 초기화 완료")
        } catch {
            print(" MapManager 초기화 실패: \(error)")
        }
    }

    deinit {
        print(" MapManager 메모리 해제")
        delegate = nil
        locationManager.delegate = nil
        mapView.delegate = nil
    }

    // MARK: - Setup Methods
    private func setupMapView() {
        mapView.layer.cornerRadius = 12
        mapView.showsUserLocation = true
        mapView.mapType = .standard
        mapView.delegate = self
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - Public Methods
    func requestInitialLocation() {
        let authStatus = locationManager.authorizationStatus
        print(" MapManager: Current authorization status: \(authStatus.rawValue)")

        switch authStatus {
        case .notDetermined:
            print(" MapManager: Permission not determined, using default location")
            setDefaultLocation()
        case .denied, .restricted:
            print(" MapManager: Location access denied or restricted, using default location")
            setDefaultLocation()
        case .authorizedWhenInUse, .authorizedAlways:
            print(" MapManager: Location authorized, requesting current location...")
            locationManager.requestLocation()
        @unknown default:
            print(" MapManager: Unknown authorization status, using default location")
            setDefaultLocation()
        }
    }

    func requestCurrentLocation() {
        let authStatus = locationManager.authorizationStatus
        print(" MapManager: Requesting current location, status: \(authStatus.rawValue)")

        switch authStatus {
        case .notDetermined:
            print(" MapManager: Permission not determined, requesting permission...")
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print(" MapManager: Location access denied, cannot get current location")
            // 사용자에게 설정으로 이동하라는 알림을 보낼 수 있음
            delegate?.mapManagerDidFailToGetLocation()
        case .authorizedWhenInUse, .authorizedAlways:
            print(" MapManager: Location authorized, requesting current location...")
            locationManager.requestLocation()
        @unknown default:
            print(" MapManager: Unknown authorization status")
            delegate?.mapManagerDidFailToGetLocation()
        }
    }

    func setDefaultLocation() {
        print(" Setting default location (Seoul)")
        let defaultCoordinate = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        setMapRegion(coordinate: defaultCoordinate)
    }

    func setMapRegion(coordinate: CLLocationCoordinate2D) {
        print(" Setting map region to: \(coordinate.latitude), \(coordinate.longitude)")
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

    // MARK: - Search Results Display
    func displaySearchResults(places: [KakaoPlace]) {
        guard !places.isEmpty else {
            print(" 표시할 장소가 없음")
            return
        }

        print(" ===== 지도에 \(places.count)개 장소 표시 시작 =====")
        print(" 기존 장소 수: \(searchedPlaces.count)개")

        // 새로운 장소들을 기존 장소들에 누적 추가 (중복 제거)
        for newPlace in places {
            // 중복 검사 (같은 장소가 이미 있는지 확인)
            if !searchedPlaces.contains(where: { $0.placeName == newPlace.placeName }) {
                searchedPlaces.append(newPlace)
                print(" 새 장소 추가: \(newPlace.placeName)")
            } else {
                print(" 이미 존재하는 장소 스킵: \(newPlace.placeName)")
            }
        }

        // 기존 어노테이션 제거 후 모든 장소 다시 표시
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        var coordinates: [CLLocationCoordinate2D] = []

        // 모든 누적된 장소들을 지도에 표시
        for (index, place) in searchedPlaces.enumerated() {
            let annotation = PlaceAnnotation()
            annotation.coordinate = place.coordinate
            annotation.title = "\(index + 1). \(place.placeName)"
            annotation.subtitle = place.addressName
            annotation.kakaoPlace = place

            mapView.addAnnotation(annotation)
            coordinates.append(place.coordinate)

            print(" POI 표시: \(index + 1). \(place.placeName) (\(place.coordinate.latitude), \(place.coordinate.longitude))")
        }

        // 2개 이상의 장소가 있으면 루트 그리기
        if coordinates.count > 1 {
            drawRoute(coordinates: coordinates)
            print("🗺️ \(coordinates.count)개 지점을 연결하는 루트 표시")
        }

        // 지도 영역 조정
        updateMapRegion(coordinates: coordinates)

        // 델리게이트에 검색된 장소들 업데이트 알림
        delegate?.mapManagerDidUpdateSearchedPlaces(searchedPlaces)

        print(" ===== 지도 표시 완료: 총 \(searchedPlaces.count)개 마커 =====")
    }

    func clearAllSearchResults() {
        searchedPlaces.removeAll()
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        print(" 모든 검색 결과 삭제")
    }

    func removePlace(at coordinate: CLLocationCoordinate2D) {
        if let index = searchedPlaces.firstIndex(where: { place in
            abs(place.coordinate.latitude - coordinate.latitude) < 0.0001 &&
            abs(place.coordinate.longitude - coordinate.longitude) < 0.0001
        }) {
            let removedPlace = searchedPlaces.remove(at: index)
            print(" 장소 제거: \(removedPlace.placeName)")

            // 지도 다시 그리기 (루트 포함)
            displaySearchResults(places: searchedPlaces)
        }
    }

    private func updateMapRegion(coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else { return }

        if coordinates.count == 1 {
            // 하나의 장소만 있으면 해당 위치를 중심으로
            let region = MKCoordinateRegion(
                center: coordinates[0],
                latitudinalMeters: 2000,
                longitudinalMeters: 2000
            )
            mapView.setRegion(region, animated: true)
        } else {
            // 여러 장소가 있으면 모든 장소를 포함하는 영역으로
            let region = MKCoordinateRegion(coordinates: coordinates)
            mapView.setRegion(region, animated: true)
        }
    }

    private func drawRoute(coordinates: [CLLocationCoordinate2D]) {
        // 기존 루트 제거
        mapView.removeOverlays(mapView.overlays)

        guard coordinates.count >= 2 else { return }

        print("🗺️ 실제 도로 루트 그리기 시작: \(coordinates.count)개 지점")

        // 각 세그먼트별로 실제 도로 경로 요청
        drawRealRoutes(coordinates: coordinates, segmentIndex: 0, totalSegments: coordinates.count - 1)
    }

    private func drawRealRoutes(coordinates: [CLLocationCoordinate2D], segmentIndex: Int, totalSegments: Int) {
        guard segmentIndex < totalSegments else {
            print("🗺️ 모든 실제 도로 루트 그리기 완료")
            return
        }

        let startCoordinate = coordinates[segmentIndex]
        let endCoordinate = coordinates[segmentIndex + 1]

        // MKDirections 요청 생성
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endCoordinate))

        // 교통 수단 설정 (자동차 우선, 실패시 도보)
        request.transportType = .automobile
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)

        directions.calculate { [weak self] response, error in
            if let error = error {
                print(" 자동차 경로 실패: \(error.localizedDescription), 도보 경로로 재시도")
                // 자동차 경로 실패시 도보 경로로 재시도
                self?.requestWalkingRoute(startCoordinate: startCoordinate,
                                        endCoordinate: endCoordinate,
                                        segmentIndex: segmentIndex,
                                        totalSegments: totalSegments,
                                        coordinates: coordinates)
                return
            }

            guard let route = response?.routes.first else {
                print(" 경로를 찾을 수 없음, 직선으로 대체")
                // 실제 경로를 찾을 수 없으면 직선으로 대체
                self?.drawStraightLine(startCoordinate: startCoordinate,
                                     endCoordinate: endCoordinate,
                                     segmentIndex: segmentIndex,
                                     totalSegments: totalSegments)
                self?.drawRealRoutes(coordinates: coordinates, segmentIndex: segmentIndex + 1, totalSegments: totalSegments)
                return
            }

            // 실제 도로 경로 표시
            let customPolyline = CustomPolyline(points: route.polyline.points(), count: route.polyline.pointCount)
            customPolyline.segmentIndex = segmentIndex
            customPolyline.totalSegments = totalSegments
            customPolyline.isRealRoute = true

            DispatchQueue.main.async {
                self?.mapView.addOverlay(customPolyline)
                print(" 실제 도로 경로 추가: 세그먼트 \(segmentIndex + 1)/\(totalSegments)")

                // 다음 세그먼트 처리
                self?.drawRealRoutes(coordinates: coordinates, segmentIndex: segmentIndex + 1, totalSegments: totalSegments)
            }
        }
    }

    private func requestWalkingRoute(startCoordinate: CLLocationCoordinate2D,
                                   endCoordinate: CLLocationCoordinate2D,
                                   segmentIndex: Int,
                                   totalSegments: Int,
                                   coordinates: [CLLocationCoordinate2D]) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endCoordinate))
        request.transportType = .walking
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)

        directions.calculate { [weak self] response, error in
            if let error = error {
                print(" 도보 경로도 실패: \(error.localizedDescription), 직선으로 대체")
                // 도보 경로도 실패하면 직선으로 대체
                self?.drawStraightLine(startCoordinate: startCoordinate,
                                     endCoordinate: endCoordinate,
                                     segmentIndex: segmentIndex,
                                     totalSegments: totalSegments)
                self?.drawRealRoutes(coordinates: coordinates, segmentIndex: segmentIndex + 1, totalSegments: totalSegments)
                return
            }

            guard let route = response?.routes.first else {
                print(" 도보 경로를 찾을 수 없음, 직선으로 대체")
                self?.drawStraightLine(startCoordinate: startCoordinate,
                                     endCoordinate: endCoordinate,
                                     segmentIndex: segmentIndex,
                                     totalSegments: totalSegments)
                self?.drawRealRoutes(coordinates: coordinates, segmentIndex: segmentIndex + 1, totalSegments: totalSegments)
                return
            }

            // 실제 도보 경로 표시
            let customPolyline = CustomPolyline(points: route.polyline.points(), count: route.polyline.pointCount)
            customPolyline.segmentIndex = segmentIndex
            customPolyline.totalSegments = totalSegments
            customPolyline.isRealRoute = true
            customPolyline.isWalkingRoute = true

            DispatchQueue.main.async {
                self?.mapView.addOverlay(customPolyline)
                print(" 실제 도보 경로 추가: 세그먼트 \(segmentIndex + 1)/\(totalSegments)")

                // 다음 세그먼트 처리
                self?.drawRealRoutes(coordinates: coordinates, segmentIndex: segmentIndex + 1, totalSegments: totalSegments)
            }
        }
    }

    private func drawStraightLine(startCoordinate: CLLocationCoordinate2D,
                                 endCoordinate: CLLocationCoordinate2D,
                                 segmentIndex: Int,
                                 totalSegments: Int) {
        let segmentCoordinates = [startCoordinate, endCoordinate]
        let polyline = CustomPolyline(coordinates: segmentCoordinates, count: 2)
        polyline.segmentIndex = segmentIndex
        polyline.totalSegments = totalSegments
        polyline.isRealRoute = false

        DispatchQueue.main.async { [weak self] in
            self?.mapView.addOverlay(polyline)
            print(" 직선 경로로 대체: 세그먼트 \(segmentIndex + 1)/\(totalSegments)")
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension MapManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            print(" No location found in locations array")
            return
        }
        print(" Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        setMapRegion(coordinate: location.coordinate)
        delegate?.mapManagerDidUpdateLocation(location.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(" Location error: \(error.localizedDescription)")
        setDefaultLocation()
        delegate?.mapManagerDidFailToGetLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let authStatus = manager.authorizationStatus
        print(" MapManager: Authorization changed to: \(authStatus.rawValue)")

        switch authStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print(" MapManager: Authorization granted, requesting location...")
            manager.requestLocation()
        case .denied, .restricted:
            print(" MapManager: Authorization denied/restricted, using default location")
            setDefaultLocation()
        case .notDetermined:
            print(" MapManager: Authorization not determined, using default location")
            setDefaultLocation()
        @unknown default:
            print(" MapManager: Unknown authorization status, using default location")
            setDefaultLocation()
        }
    }
}

// MARK: - MKMapViewDelegate
extension MapManager: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            let identifier = "UserLocation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }

            annotationView?.image = UIImage(named: "현재위치 이미지")
            annotationView?.frame = CGRect(x: 0, y: 0, width: 40, height: 40)

            return annotationView
        }
        return nil
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("🎯 ===== 마커 클릭 이벤트 발생 =====")
        print("   • 어노테이션 타이틀: \(view.annotation?.title ?? "nil")")
        print("   • 어노테이션 타입: \(type(of: view.annotation))")

        guard let placeAnnotation = view.annotation as? PlaceAnnotation else {
            print(" PlaceAnnotation으로 캐스팅 실패")
            return
        }

        print(" PlaceAnnotation 캐스팅 성공")

        guard let kakaoPlace = placeAnnotation.kakaoPlace else {
            print(" kakaoPlace 데이터가 nil")
            return
        }

        print(" KakaoPlace 데이터 확인:")
        print("   • 장소명: '\(kakaoPlace.placeName)'")
        print("   • 주소: '\(kakaoPlace.addressName)'")
        print("   • 카테고리: '\(kakaoPlace.categoryName)'")
        print("   • 전화번호: '\(kakaoPlace.phone)'")
        print("   • 좌표: (\(kakaoPlace.coordinate.latitude), \(kakaoPlace.coordinate.longitude))")

        delegate?.mapManagerDidSelectPlace(kakaoPlace)
        print("🎯 ===== 델리게이트 호출 완료 =====")
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let customPolyline = overlay as? CustomPolyline {
            let renderer = MKPolylineRenderer(polyline: customPolyline)

            // 실제 경로 vs 직선 경로에 따른 스타일 설정
            if customPolyline.isRealRoute {
                // 실제 도로/도보 경로
                if customPolyline.isWalkingRoute {
                    // 도보 경로: 점선으로 표시
                    renderer.strokeColor = UIColor.systemOrange
                    renderer.lineWidth = 4.0
                    renderer.lineDashPattern = [8, 4] // 점선 패턴
                    print("🚶‍♂️ 도보 경로 렌더링")
                } else {
                    // 차량 경로: 실선으로 표시
                    let progress = Float(customPolyline.segmentIndex) / Float(max(customPolyline.totalSegments - 1, 1))
                    let startColor = UIColor.systemBlue
                    let endColor = UIColor.systemPurple
                    let blendedColor = UIColor.blendColors(
                        startColor: startColor,
                        endColor: endColor,
                        progress: CGFloat(progress)
                    )
                    renderer.strokeColor = blendedColor
                    renderer.lineWidth = 5.0
                    print(" 차량 경로 렌더링")
                }
            } else {
                // 직선 경로 (실제 경로를 찾을 수 없는 경우)
                renderer.strokeColor = UIColor.systemGray
                renderer.lineWidth = 3.0
                renderer.lineDashPattern = [4, 4] // 짧은 점선
                renderer.alpha = 0.7
                print("➖ 직선 경로 렌더링 (실제 경로 없음)")
            }

            renderer.lineCap = .round
            renderer.lineJoin = .round
            renderer.alpha = customPolyline.isRealRoute ? 0.9 : 0.7

            return renderer
        }

        // 기본 폴리라인 처리
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.systemBlue
            renderer.lineWidth = 4.0
            renderer.lineCap = .round
            renderer.lineJoin = .round
            renderer.alpha = 0.8
            return renderer
        }

        return MKOverlayRenderer(overlay: overlay)
    }
}

// MARK: - Custom Annotation
class PlaceAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var kakaoPlace: KakaoPlace?

    override init() {
        self.coordinate = CLLocationCoordinate2D()
        super.init()
    }
}

// MARK: - Custom Polyline
class CustomPolyline: MKPolyline {
    var segmentIndex: Int = 0
    var totalSegments: Int = 1
    var isRealRoute: Bool = false
    var isWalkingRoute: Bool = false
}

// MARK: - UIColor Extension
extension UIColor {
    static func blendColors(startColor: UIColor, endColor: UIColor, progress: CGFloat) -> UIColor {
        let clampedProgress = max(0.0, min(1.0, progress))

        var startRed: CGFloat = 0, startGreen: CGFloat = 0, startBlue: CGFloat = 0, startAlpha: CGFloat = 0
        var endRed: CGFloat = 0, endGreen: CGFloat = 0, endBlue: CGFloat = 0, endAlpha: CGFloat = 0

        startColor.getRed(&startRed, green: &startGreen, blue: &startBlue, alpha: &startAlpha)
        endColor.getRed(&endRed, green: &endGreen, blue: &endBlue, alpha: &endAlpha)

        let blendedRed = startRed + (endRed - startRed) * clampedProgress
        let blendedGreen = startGreen + (endGreen - startGreen) * clampedProgress
        let blendedBlue = startBlue + (endBlue - startBlue) * clampedProgress
        let blendedAlpha = startAlpha + (endAlpha - startAlpha) * clampedProgress

        return UIColor(red: blendedRed, green: blendedGreen, blue: blendedBlue, alpha: blendedAlpha)
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
