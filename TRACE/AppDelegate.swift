//
//  AppDelegate.swift
//  TRACE
//
//  Created by 차지용 on 9/25/25.
//

import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications
@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Realm 초기화
        _ = RealmManager.shared
        FirebaseApp.configure()

        // 알림 대리자 설정

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
              options: authOptions,
              completionHandler: { _, _ in }
            )

            application.registerForRemoteNotifications()
        }
        else {
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        application.registerForRemoteNotifications()
        
        Messaging.messaging().delegate = self

        // FCM 토큰 요청은 APNS 토큰 설정 후에 수행됩니다

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // APNS 토큰을 Firebase에 설정
        Messaging.messaging().apnsToken = deviceToken
        print("✅ APNS 토큰이 설정되었습니다.")

        // APNS 토큰 설정 완료 후 FCM 토큰 요청
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ FCM 토큰 요청 오류: \(error.localizedDescription)")
            } else if let token = token {
                print("🔑 FCM 토큰: \(token)")
            }
        }
    }

    // APNS 등록 실패 시 처리
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ APNS 등록 실패: \(error.localizedDescription)")
    }
    // 앱이 포그라운드에 있을 때 알림을 받는 경우
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 앱이 실행 중일 때도 알림을 표시
        completionHandler([.alert, .sound, .badge])
    }

    // 사용자가 알림을 탭했을 때
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        // 여행 알림인지 확인
        if response.notification.request.identifier.contains("travel_reminder") {
            // 여행 계획 화면으로 이동하거나 관련 액션 수행
            print("여행 알림을 탭했습니다.")
        }

        completionHandler()
    }
}



extension AppDelegate: MessagingDelegate {
    
    //디바이스 토큰 정보가 변경이 되면 알려줌
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
      print("Firebase registration token: \(String(describing: fcmToken))")

      let dataDict: [String: String] = ["token": fcmToken ?? ""]
      NotificationCenter.default.post(
        name: Notification.Name("FCMToken"),
        object: nil,
        userInfo: dataDict
      )
      // TODO: If necessary send token to application server.
      // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
}
