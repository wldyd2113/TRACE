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
}
