// Shared/Utilities/AppConstants.swift
import Foundation

enum AppConstants {
    // 앱의 URL 스킴 정의
    static let urlScheme = "postit"
    // 공유 시트 호스트 이름
    static let shareSheetHost = "share-sheet"
    // ⭐️ LA/DI에서 사용할 호스트 이름 추가
    static let openDashboardHost = "open-dashboard"
    // URL 쿼리 파라미터 이름
    static let contentQueryItemName = "content"
    // ⭐️ Live Activity 클릭 시 열릴 URL 수정
    static let liveActivityDeepLink = "\(urlScheme)://\(openDashboardHost)" // "postit://open-dashboard"
}
