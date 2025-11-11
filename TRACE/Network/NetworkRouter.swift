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
    case googleMapsSearch(query: String)
    
    var kakoBaseURL: String {
        return "\(APIKey.kakaoUrl)"
    }
    
    var googleBaseURL: String {
        return "\(APIKey.googleUrl)"
    }
    
    var path: String {
        switch self {
        case .kakaoMapsearch(let query, _):
            return "query=\(query)"
        case .googleMapsSearch(let query):
            return "query=\(query)&language=ko&key=\(APIKey.googleKey)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .kakaoMapsearch(query: let query, headers: let headers):
                .get
        case .googleMapsSearch(query: let query):
                .get
        }
    }
    
    
    var headers: HTTPHeaders {
        switch self {

        case .kakaoMapsearch(query: let query, headers: let headers):
            return headers

        case .googleMapsSearch(query: let query):
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
