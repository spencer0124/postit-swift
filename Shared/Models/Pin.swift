// Shared/Models/Pin.swift
import Foundation
import SwiftData // 1. Import
import ActivityKit // 2. Import

@Model // 3. @Model 매크로
class Pin {
    @Attribute(.unique) let id: UUID // 4. UUID는 고유 식별자
    
    let content: String
    let pinType: PinType
    var creationDate: Date // 5. 'var'로 변경 (갱신을 위해)
    
    // ⭐️ 6. 제안하신 핵심 필드
    var showInHistoryAt: Date
    
    // ⭐️ 7. 메타데이터도 DB에 저장
    var metadataTitle: String?
    var metadataFaviconData: Data?

    // ⭐️ 8. LA 상태 관리를 위한 임시(in-memory) 속성
    @Transient var associatedActivity: Activity<PinActivityAttributes>? = nil

    init(content: String,
         pinType: PinType,
         metadataTitle: String?,
         metadataFaviconData: Data?,
         creationDate: Date = .now)
    {
        self.id = UUID() // 신규 생성 시 UUID 발급
        self.content = content
        self.pinType = pinType
        self.metadataTitle = metadataTitle
        self.metadataFaviconData = metadataFaviconData
        self.creationDate = creationDate
        
        // ⭐️ 9. 보관함 표시 시점 = 생성 시점 + 8시간
        self.showInHistoryAt = creationDate.addingTimeInterval(8 * 60 * 60) // 8시간
    }
}

// PinType은 Codable 유지 (SwiftData가 지원)
enum PinType: String, Codable, Hashable {
    case text
    case url
}
