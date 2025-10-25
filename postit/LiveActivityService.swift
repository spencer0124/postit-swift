//
//  LiveActivityService.swift
//  postit
//
//  Created by SeungYong on 10/20/25.
//

import Foundation
import ActivityKit

class LiveActivityService {
    
    @discardableResult
    // ProcessedContent를 파라미터로 받습니다.
    static func start(pin: Pin, processedContent: ProcessedContent) -> Activity<PinActivityAttributes>? {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities가 비활성화되어 있습니다.")
            return nil
        }
        
        let attributes = PinActivityAttributes(
            pinType: pin.pinType,
            creationDate: pin.creationDate
        )
        
        // 초기 ContentState에 processedContent의 메타데이터를 포함시킵니다.
        let contentState = PinActivityAttributes.ContentState(
            content: processedContent.originalContent,
            metadataTitle: processedContent.metadataTitle, // 초기값 설정
            metadataFaviconData: processedContent.metadataFaviconData // 초기값 설정
        )
        
        do {
            let activity = try Activity<PinActivityAttributes>.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            print("Live Activity가 시작되었습니다: \(activity.id) - \(pin.content)")
            return activity
        } catch (let error) {
            print("오류: Live Activity 시작에 실패했습니다 - \(error.localizedDescription)")
            return nil
        }
    }
    
    // update 함수는 사용하지 않습니다.
}
