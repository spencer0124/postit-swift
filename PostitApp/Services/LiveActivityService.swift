// PostitApp/Services/LiveActivityService.swift

import Foundation
import ActivityKit

class LiveActivityService {

    @discardableResult
    // ⭐️ 반환 타입이 Activity<...>?
    static func start(pin: Pin, processedContent: ProcessedContent) -> Activity<PinActivityAttributes>? {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities가 비활성화되어 있습니다.")
            return nil // ⭐️ 실패 시 nil 반환
        }

        let attributes = PinActivityAttributes(
            pinType: pin.pinType,
            creationDate: pin.creationDate
        )

        let contentState = PinActivityAttributes.ContentState(
            content: processedContent.originalContent,
            metadataTitle: processedContent.metadataTitle,
            metadataFaviconData: processedContent.metadataFaviconData
        )

        // ⭐️ 1. relevanceScore를 변수로 추출
        let relevanceScore = pin.creationDate.timeIntervalSince1970
        
        let activityContent = ActivityContent(
            state: contentState,
            staleDate: nil,
            relevanceScore: relevanceScore // ⭐️ 변수 사용
        )

        do {
            let activity = try Activity<PinActivityAttributes>.request(
                attributes: attributes,
                content: activityContent,
                pushType: nil
            )
            print("Live Activity가 시작되었습니다: \(activity.id) - (Score: \(relevanceScore))")
            return activity // ⭐️ 성공 시 Activity 반환
        } catch (let error) {
            print("오류: Live Activity 시작에 실패했습니다 - \(error.localizedDescription)")
            // ⭐️ 에러 발생 시 nil 반환 (에러 종류 구분 없음)
            return nil
        }
    }
    
    // ⭐️ 2. relevanceScore를 업데이트하는 함수 추가
    /**
     기존 Live Activity의 relevanceScore를 현재 시간으로 업데이트합니다.
     - Parameter activity: 업데이트할 Activity 인스턴스
     */
    static func updateRelevance(for activity: Activity<PinActivityAttributes>) {
        // 1. 현재 시간을 새 relevanceScore로 설정
        let newRelevanceScore = Date().timeIntervalSince1970
        
        // 2. 기존 state는 유지하고 score만 변경
        let updatedContent = ActivityContent(
            state: activity.content.state, // 기존 state 재사용
            staleDate: nil,
            relevanceScore: newRelevanceScore // 새 score 적용
        )
        
        // 3. Activity 업데이트 (비동기)
        Task {
            await activity.update(updatedContent)
            print("Live Activity relevance updated: \(activity.id) - (New Score: \(newRelevanceScore))")
        }
    }
}
