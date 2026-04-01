//
//  NetworkRouter.swift
//  TRACE
//
//  Created by 차지용 on 9/28/25.
//

import Foundation
import Alamofire

enum NetworkRouter: URLRequestConvertible {

    case kakaoMapsearch(query: String, headers: HTTPHeaders)
    case kakaoImageSearch(query: String, headers: HTTPHeaders)
    case googleMapsSearch(query: String)
    
    var kakoBaseURL: String {
        return "\(APIKey.kakaoUrl)"
    }
    
    var kakaoImageURL: String {
        return "https://dapi.kakao.com/v2/search/image"
    }
    
    var googleBaseURL: String {
        return "\(APIKey.googleUrl)"
    }
    
    var path: String {
        switch self {
        case .kakaoMapsearch(let query, _):
            return "query=\(query)"
        case .kakaoImageSearch(let query, _):
            return "query=\(query)&size=1" // 일단 가장 관련성 높은 1개만 가져옴
        case .googleMapsSearch(let query):
            return "query=\(query)&language=ko&key=\(APIKey.googleKey)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .kakaoMapsearch, .kakaoImageSearch, .googleMapsSearch:
                .get
        }
    }
    
    
    var headers: HTTPHeaders {
        switch self {

        case .kakaoMapsearch(_, let headers), .kakaoImageSearch(_, let headers):
            return headers

        case .googleMapsSearch(_):
            return [
                "Accept": "application/json",
                "User-Agent": "TRACE-iOS-App"
            ]
        }
    }
    func asURLRequest() throws -> URLRequest {
        let baseURL: String

        switch self {
        case .kakaoMapsearch:
            baseURL = kakoBaseURL
        case .kakaoImageSearch:
            baseURL = kakaoImageURL
        case .googleMapsSearch:
            baseURL = googleBaseURL
        }

        // baseURL에 이미 ?가 있는지 확인해서 적절히 연결
        let fullURL: String
        if baseURL.hasSuffix("?") {
            fullURL = baseURL + path
        } else {
            fullURL = baseURL + "?" + path
        }

        guard let url = URL(string: fullURL) else {
            throw AFError.invalidURL(url: fullURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers.dictionary

        return request
    }
    
    
}
