//
//  ContentProcessorService.swift
//  postit
//
//  Created by Gemini on 10/22/25.
//

import Foundation



// 입력된 콘텐츠를 분석하고 처리하는 서비스 모듈
class ContentProcessorService {

    // 입력 content를 받아 처리된 ProcessedContent 또는 Error를 반환하는 비동기 함수
    static func processContent(_ content: String) async -> Result<ProcessedContent, ContentProcessingError> {

        // 1. 콘텐츠 타입 판별
        let pinType: PinType = content.lowercased().hasPrefix("http") ? .url : .text

        // 2. 타입별 처리 분기
        switch pinType {
        case .url:
            // ⭐️ 변경: await로 직접 호출
            let metadataResult = await MetadataService.fetchMetadata(for: content)

            // 이후 로직은 동일
            let processed = ProcessedContent(
                originalContent: content,
                pinType: .url,
                metadataTitle: metadataResult?.title,
                metadataFaviconData: metadataResult?.faviconData
            )
            return .success(processed)

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
