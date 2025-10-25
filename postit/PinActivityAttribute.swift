//
//  PinActivityAttributes.swift
//  postit
//
//  Created by SeungYong on 10/20/25.
//

import Foundation
import ActivityKit

// Live Activity가 어떤 데이터를 가질지 정의하는 구조체입니다.
// 이 파일은 postit(앱)과 PinLiveActivityExtension(위젯) 두 타겟 모두에 포함되어야 합니다.
struct PinActivityAttributes: ActivityAttributes {

    // ContentState는 나중에 업데이트될 수 있는 동적 데이터를 담습니다.
    public struct ContentState: Codable, Hashable {
        var content: String             // 원본 내용 (텍스트 또는 URL)
        var metadataTitle: String?      // URL 제목
        var metadataFaviconData: Data?  // URL 아이콘 (이미지 데이터)
    }

    // 이 부분은 변하지 않는 정적 데이터입니다.
    let pinType: PinType // 텍스트인지 URL인지 구분
    let creationDate: Date // 생성 시간
}
