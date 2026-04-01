//
//  KakaoImageResponse.swift
//  TRACE
//
//  Created by 차지용 on 2026/04/02.
//

import Foundation

struct KakaoImageResponse: Codable {
    let documents: [ImageDocument]
    let meta: ImageMeta
}

struct ImageDocument: Codable {
    let collection: String
    let thumbnailUrl: String
    let imageUrl: String
    let width: Int
    let height: Int
    let displaySitename: String
    let docUrl: String
    let datetime: String

    enum CodingKeys: String, CodingKey {
        case collection
        case thumbnailUrl = "thumbnail_url"
        case imageUrl = "image_url"
        case width, height
        case displaySitename = "display_sitename"
        case docUrl = "doc_url"
        case datetime
    }
}

struct ImageMeta: Codable {
    let totalCount: Int
    let pageableCount: Int
    let isEnd: Bool

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case pageableCount = "pageable_count"
        case isEnd = "is_end"
    }
}
