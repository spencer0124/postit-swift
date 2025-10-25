//
//  AppConstants.swift
//  postit
//
//  Created by SeungYong on 10/25/25.
//


// Shared/Utilities/AppConstants.swift
import Foundation

enum AppConstants {
    // 앱의 URL 스킴 정의
    static let urlScheme = "postit"
    // 공유 시트 호스트 이름
    static let shareSheetHost = "share-sheet"
    // URL 쿼리 파라미터 이름
    static let contentQueryItemName = "content"
    // Live Activity 클릭 시 열릴 URL (앱 실행)
    static let liveActivityDeepLink = "pinapp://open" // PinLiveActivityView.swift에서도 사용됨
}