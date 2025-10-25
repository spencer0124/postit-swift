//
//  ProcessedContent.swift
//  postit
//
//  Created by SeungYong on 10/25/25.
//

import Foundation
// 콘텐츠 처리 결과를 담는 구조체
struct ProcessedContent {
    let originalContent: String
    let pinType: PinType
    let metadataTitle: String?
    let metadataFaviconData: Data?
    // 추후 다른 타입의 처리 결과도 여기에 추가 가능
}

// 콘텐츠 처리 중 발생할 수 있는 에러 타입


enum ContentProcessingError: Error, LocalizedError {
    case metadataFetchFailed
    case liveActivityStartFailed
    case maxActivitiesReached // ⭐️ 추가
    case unknown

    var errorDescription: String? {
        switch self {
        case .metadataFetchFailed: return "웹사이트 정보 로딩에 실패했어요."
        case .liveActivityStartFailed: return "Live Activity를 시작하지 못했어요."
        case .maxActivitiesReached: return "더 이상 핀을 추가할 수 없어요. (최대 개수 도달)" // ⭐️ 메시지 추가
        case .unknown: return "알 수 없는 오류가 발생했어요."
        }
    }
}

