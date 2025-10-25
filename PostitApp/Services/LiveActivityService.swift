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

        let relevanceScore = pin.creationDate.timeIntervalSince1970
        let activityContent = ActivityContent(
            state: contentState,
            staleDate: nil,
            relevanceScore: relevanceScore
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
}
