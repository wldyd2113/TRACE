//
//  SceneDelegate.swift
//  TRACE
//
//  Created by 차지용 on 9/25/25.
//

import UIKit
import CoreLocation

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private let locationManager = CLLocationManager()


    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let tabBarController = UITabBarController()
        
        let planVC = TravelPlanMainViewController()
        let plan = UINavigationController(rootViewController: planVC)
        plan.tabBarItem = UITabBarItem(title: "계획", image: UIImage(systemName: "calendar"), tag: 0)
        
        let recordVc = TravelRecordViewController()
        let record = UINavigationController(rootViewController: recordVc)
        record.tabBarItem = UITabBarItem(title: "기록", image: UIImage(systemName: "text.page.fill"), tag: 1)



        tabBarController.viewControllers = [plan, record]
        tabBarController.tabBar.tintColor = .skyBlue
        tabBarController.tabBar.unselectedItemTintColor = .systemGray4

        // Navigation Bar 전역 스타일 설정
        configureNavigationBarAppearance()

        window = UIWindow(windowScene: windowScene)

        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()
    }

    // MARK: - Navigation Bar Configuration
    private func configureNavigationBarAppearance() {
        // iOS 15+ 대응
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .background
            appearance.titleTextAttributes = [
                .foregroundColor: UIColor.label,
                .font: UIFont(name: FontManager.onglapUIyeon.fontName, size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .medium)
            ]
            appearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor.label,
                .font: UIFont(name: FontManager.onglapUIyeon.fontName, size: 24) ?? UIFont.systemFont(ofSize: 24, weight: .bold)
            ]

            // 버튼과 아이콘 색상
            UINavigationBar.appearance().tintColor = .skyBlue
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
        } else {
            // iOS 14 이하 대응
            UINavigationBar.appearance().backgroundColor = .background
            UINavigationBar.appearance().barTintColor = .background
            UINavigationBar.appearance().tintColor = .skyBlue
            UINavigationBar.appearance().titleTextAttributes = [
                .foregroundColor: UIColor.label,
                .font: UIFont(name: FontManager.onglapUIyeon.fontName, size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .medium)
            ]
            UINavigationBar.appearance().largeTitleTextAttributes = [
                .foregroundColor: UIColor.label,
                .font: UIFont(name: FontManager.onglapUIyeon.fontName, size: 24) ?? UIFont.systemFont(ofSize: 24, weight: .bold)
            ]
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.

        // 위치 권한 요청
        requestLocationPermissionIfNeeded()

        // 네트워크 모니터링 시작
        NetworkAlertManager.shared.startMonitoring()
    }

    private func requestLocationPermissionIfNeeded() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            print("📍 App startup: Requesting location permission")
            locationManager.requestWhenInUseAuthorization()
        case .denied:
            print("📍 App startup: Location permission denied")
        case .restricted:
            print("📍 App startup: Location permission restricted")
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 App startup: Location permission already granted")
        @unknown default:
            print("📍 App startup: Unknown location permission status")
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // 네트워크 모니터링 중지
        NetworkAlertManager.shared.stopMonitoring()
    }


}

