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
        
        // 1. ContentState(업데이트 가능한 동적 데이터)를 생성합니다.
        let contentState = PinActivityAttributes.ContentState(
            content: processedContent.originalContent,
            metadataTitle: processedContent.metadataTitle,
            metadataFaviconData: processedContent.metadataFaviconData
        )
        
        // 2. ⭐️ Relevance Score 설정: 최신 핀일수록 높은 점수를 가집니다.
        // pin.creationDate는 .now로 생성되므로, timeIntervalSince1970 (Double) 값을 점수로 사용합니다.
        let relevanceScore = pin.creationDate.timeIntervalSince1970
        
        // 3. ⭐️ ActivityContent 객체를 생성하여 state와 relevanceScore를 함께 전달합니다.
        let activityContent = ActivityContent(
            state: contentState,
            staleDate: nil, // 8시간 뒤 만료는 시스템이 자동으로 처리
            relevanceScore: relevanceScore // ⭐️ 점수 설정 (높을수록 위로)
        )
        
        do {
            // 4. ⭐️ .request 함수 호출 시 'contentState:' 대신 'content:' 파라미터를 사용합니다.
            let activity = try Activity<PinActivityAttributes>.request(
                attributes: attributes,
                content: activityContent, // ⭐️ 수정된 부분
                pushType: nil
            )
            print("Live Activity가 시작되었습니다: \(activity.id) - (Score: \(relevanceScore))")
            return activity
        } catch (let error) {
            print("오류: Live Activity 시작에 실패했습니다 - \(error.localizedDescription)")
            return nil
        }
    }
    

}
