//
//  ContentProcessorService.swift
//  postit
//
//  Created by Gemini on 10/22/25.
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

// 입력된 콘텐츠를 분석하고 처리하는 서비스 모듈
class ContentProcessorService {

    // 입력 content를 받아 처리된 ProcessedContent 또는 Error를 반환하는 비동기 함수
    static func processContent(_ content: String) async -> Result<ProcessedContent, ContentProcessingError> {

        // 1. 콘텐츠 타입 판별
        let pinType: PinType = content.lowercased().hasPrefix("http") ? .url : .text

        // 2. 타입별 처리 분기
        switch pinType {
        case .url:
            // URL인 경우 MetadataService 호출 (콜백을 async/await로 변환)
            let metadataResult: MetadataService.Metadata? = await withCheckedContinuation { continuation in
                MetadataService.fetchMetadata(for: content) { metadata in
                    continuation.resume(returning: metadata)
                }
            }

            // MetadataService가 실패했는지 여부 확인 (nil 반환 시 실패로 간주)
            // 참고: MetadataService 내부에서 title만 실패하고 favicon은 성공할 수도 있음
            //       여기서는 둘 중 하나라도 nil이면 실패로 처리할지, 아니면 nil이라도 성공으로 넘길지 결정 필요.
            //       현재는 nil이라도 성공으로 넘김 (제목 없어도 LA 띄우는 게 낫다고 판단)
            
            let processed = ProcessedContent(
                originalContent: content,
                pinType: .url,
                metadataTitle: metadataResult?.title,
                metadataFaviconData: metadataResult?.faviconData
            )
            return .success(processed) // URL 처리는 메타데이터 Fetch 실패 여부와 관계없이 성공

        case .text:
            // 텍스트는 별도 처리 없이 바로 성공 결과 반환
            let processed = ProcessedContent(
                originalContent: content,
                pinType: .text,
                metadataTitle: nil,
                metadataFaviconData: nil
            )
            return .success(processed)

        // default: // 추후 다른 타입 추가 시 여기에 case 추가
        //     return .failure(.unknown)
        }
    }
}
