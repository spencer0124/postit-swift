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
    case metadataFetchFailed // MetadataService 내부 에러를 포장
    case liveActivityStartFailed // LA 시작 실패 (ViewModel에서 사용)
    case unknown

    var errorDescription: String? {
        switch self {
        case .metadataFetchFailed: return "웹사이트 정보 로딩에 실패했어요."
        case .liveActivityStartFailed: return "Live Activity를 시작하지 못했어요."
        case .unknown: return "알 수 없는 오류가 발생했어요."
        }
    }
}
