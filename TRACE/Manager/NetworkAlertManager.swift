//
//  NetworkAlertManager.swift
//  TRACE
//
//  Created by 차지용 on 10/3/25.
//

import UIKit
import RxSwift

class NetworkAlertManager {
    static let shared = NetworkAlertManager()

    private init() {
        setupNetworkMonitoring()
    }

    private let disposeBag = DisposeBag()
    private var isAlertShowing = false

    private func setupNetworkMonitoring() {
        // NWPathMonitorManger의 네트워크 상태 관찰
        NWPathMonitorManger.shared.networkStatus
            .distinctUntilChanged() // 상태가 실제로 변경될 때만 반응
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isConnected in
                self?.handleNetworkStatusChange(isConnected: isConnected)
            })
            .disposed(by: disposeBag)
    }

    private func handleNetworkStatusChange(isConnected: Bool) {
        if !isConnected {
            showNetworkErrorAlert()
        } else {
            dismissNetworkErrorAlert()
        }
    }

    private func showNetworkErrorAlert() {
        // 이미 alert가 표시 중이면 중복 표시하지 않음
        guard !isAlertShowing else { return }

        DispatchQueue.main.async { [weak self] in
            guard let topViewController = self?.getTopViewController() else { return }

            let alert = UIAlertController(
                title: "네트워크 연결 오류",
                message: "인터넷 연결을 확인해주세요.\nWi-Fi 또는 모바일 데이터를 켜주세요.",
                preferredStyle: .alert
            )

            // 설정으로 이동
            alert.addAction(UIAlertAction(title: "설정", style: .default) { _ in
                self?.openSettings()
                self?.isAlertShowing = false
            })

            // 재시도
            alert.addAction(UIAlertAction(title: "재시도", style: .default) { _ in
                self?.checkNetworkAndRetry()
                self?.isAlertShowing = false
            })

            // 취소
            alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
                self?.isAlertShowing = false
            })

            self?.isAlertShowing = true
            topViewController.present(alert, animated: true)

            print("📶 네트워크 연결 오류 alert 표시")
        }
    }

    private func dismissNetworkErrorAlert() {
        DispatchQueue.main.async { [weak self] in
            if self?.isAlertShowing == true {
                if let topViewController = self?.getTopViewController(),
                   topViewController.presentedViewController is UIAlertController {
                    topViewController.dismiss(animated: true)
                    self?.isAlertShowing = false
                    print("📶 네트워크 연결 복구 - alert 자동 닫기")
                }
            }
        }
    }

    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }

        var topViewController = window.rootViewController
        while let presentedViewController = topViewController?.presentedViewController {
            topViewController = presentedViewController
        }

        return topViewController
    }

    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
            print(" 설정 앱으로 이동")
        }
    }

    private func checkNetworkAndRetry() {
        // 네트워크 상태 재확인
        let isConnected = NWPathMonitorManger.shared.isCoonected
        print("📶 네트워크 재시도 - 연결 상태: \(isConnected)")

        if isConnected {
            // 연결되었다면 성공 메시지 표시
            showNetworkRestoredAlert()
        } else {
            // 여전히 연결되지 않았다면 다시 오류 alert 표시
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showNetworkErrorAlert()
            }
        }
    }

    private func showNetworkRestoredAlert() {
        DispatchQueue.main.async { [weak self] in
            guard let topViewController = self?.getTopViewController() else { return }

            let alert = UIAlertController(
                title: "네트워크 연결 복구",
                message: "인터넷 연결이 복구되었습니다.",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "확인", style: .default))

            topViewController.present(alert, animated: true)
            print("📶 네트워크 연결 복구 alert 표시")
        }
    }

    // MARK: - Public Methods

    /// 네트워크 모니터링 시작
    func startMonitoring() {
        NWPathMonitorManger.shared.addObserver()
        print("📶 NetworkAlertManager 모니터링 시작")
    }

    /// 네트워크 모니터링 중지
    func stopMonitoring() {
        NWPathMonitorManger.shared.removeObserverNetWork()
        print("📶 NetworkAlertManager 모니터링 중지")
    }

    /// 수동으로 네트워크 에러 alert 표시
    func showManualNetworkError(message: String? = nil) {
        let errorMessage = message ?? "네트워크 오류가 발생했습니다.\n인터넷 연결을 확인해주세요."

        DispatchQueue.main.async { [weak self] in
            guard let topViewController = self?.getTopViewController() else { return }

            let alert = UIAlertController(
                title: "네트워크 오류",
                message: errorMessage,
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "확인", style: .default))

            topViewController.present(alert, animated: true)
        }
    }
}
