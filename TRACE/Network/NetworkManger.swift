//
//  NetworkManger.swift
//  TRACE
//
//  Created by 차지용 on 9/28/25.
//

import Foundation
import Alamofire
import RxSwift
import RxCocoa

final class NetworkManger {
    static let shared = NetworkManger()

    private func request<T: Decodable>(_ convertible: URLRequestConvertible, type: T.Type) -> Observable<Result<T, AFError>>  {
        return Observable.create { observable in


            AF.request(convertible).validate(statusCode: 200..<300).responseDecodable(of: type) { response in
                print("🌐 Response Status Code: \(response.response?.statusCode ?? -1)")
                if let data = response.data, let responseString = String(data: data, encoding: .utf8) {
                    print("🌐 Response Data: \(responseString)")
                }

                switch response.result {
                case .success(let value):
                    observable.onNext(.success(value))
                case .failure(let error):
                    print("🌐 Request failed with error: \(error)")

                    // 네트워크 연결 오류인지 확인
                    if let urlError = error.underlyingError as? URLError {
                        switch urlError.code {
                        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                            // 네트워크 연결 문제인 경우 NetworkAlertManager로 처리
                            NetworkAlertManager.shared.showManualNetworkError(
                                message: "네트워크 연결을 확인해주세요.\n인터넷 연결 상태를 확인해보세요."
                            )
                        case .timedOut:
                            NetworkAlertManager.shared.showManualNetworkError(
                                message: "요청 시간이 초과되었습니다.\n잠시 후 다시 시도해주세요."
                            )
                        case .cannotConnectToHost, .cannotFindHost:
                            NetworkAlertManager.shared.showManualNetworkError(
                                message: "서버에 연결할 수 없습니다.\n잠시 후 다시 시도해주세요."
                            )
                        default:
                            NetworkAlertManager.shared.showManualNetworkError(
                                message: "네트워크 오류가 발생했습니다.\n(\(urlError.localizedDescription))"
                            )
                        }
                    } else {
                        // 기타 Alamofire 오류
                        NetworkAlertManager.shared.showManualNetworkError(
                            message: "요청 처리 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요."
                        )
                    }

                    observable.onNext(.failure(error))
                }
                observable.onCompleted()
            }
            return Disposables.create()

        }
    }

    // Kakao Places 검색
    func searchKakaoPlaces(query: String) -> Observable<Result<KakaoPlacesResponse, AFError>> {
        let headers: HTTPHeaders = [
            "Authorization": "KakaoAK \(APIKey.kakaoKey)",
            "KA": "sdk/1.0 os/ios origin/com.jiyong.TRACE", // 실제 번들ID로 변경
            "content-type": "application/json;charset=UTF-8"
        ]
        let router = NetworkRouter.kakaoMapsearch(query: query, headers: headers)
        return request(router, type: KakaoPlacesResponse.self)
    }

    // Google Places 검색
    func searchGooglePlaces(query: String) -> Observable<Result<GooglePlacesResponse, AFError>> {
        let router = NetworkRouter.googleMapsSearch(query: query)
        return request(router, type: GooglePlacesResponse.self)
    }

}
