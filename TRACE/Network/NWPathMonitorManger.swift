//
//  NWPathMonitorManger.swift
//  TRACE
//
//  Created by 차지용 on 10/3/25.
//

import Foundation
import Network
import RxSwift

class NWPathMonitorManger {
    static let shared = NWPathMonitorManger()
    
    private init() {}
    
    private let nwPathMonitor = NWPathMonitor()
    private let disposeBag = DisposeBag()
    
    let networkStatus = PublishSubject<Bool>() // true: 연결, false: 끊김

    
    private var interfaceType: NWInterface.InterfaceType? = nil //연결된 네트워크 방식, 현재 연결된 네트워크 인터페이스의 유형을 저장
    
    //네트워크 연결 상태 확인
    var isCoonected: Bool {
        nwPathMonitor.currentPath.status == .satisfied //네트워크 연결가능, unsatisfied:불가능
    }
    
    //요금 사용 여부 확인
    var isExpensive: Bool {
        nwPathMonitor.currentPath.isExpensive //현재 네트워크 비용이 부과되는(셀룰러 데이트) 네트워크인지 여부를 나타냄
    }
    
    func addObserver() {
        nwPathMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                self.pathUpdateHandleInsideTask(path)
            }
        }
        nwPathMonitor.start(queue: .main)
    }
    //모니터링 종료
    func removeObserverNetWork() {
        nwPathMonitor.cancel()
    }
    
    private func pathUpdateHandleInsideTask(_ path: NWPath) {
        
        networkStatus.onNext(path.status == .satisfied)
        let interfaceTypes: [NWInterface.InterfaceType] = [.wifi, .cellular, .wiredEthernet, .other]
        
        for type in interfaceTypes {
            if path.usesInterfaceType(type) {
                // 연결된 경우
                switch type {
                case .wifi:
                    print("Wi-Fi를 이용하여 네트워크에 연결되었습니다")
                case .cellular:
                    print("세룰러 데이터를 이용하여 네트워크에 연결되었습니다")
                case .wiredEthernet:
                    print("유선 이더넷을 이용하여 네트워크에 연결되었습니다")
                case .other:
                    print("기타 방법을 이용하여 네트워크에 연결되었습니다")
                default:
                    print("알 수 없는 네트워크")
                }
            }
            else {
                switch type {
                case .wifi:
                    print("Wi-Fi 연결이 끊어져 있습니다")
                case .cellular:
                    print("세룰러 데이터가 비활성화 상태입니다")
                case .wiredEthernet:
                    print("유선 이더넷이 연결되지 않았습니다")
                case .other:
                    print("기타 네트워크가 비활성화 상태입니다")
                default:
                    print("알 수 없는 네트워크")
                }
            }
        }
        self.interfaceType = path.availableInterfaces.first?.type
        
    }
    
}
