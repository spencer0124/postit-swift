// Shared/Models/Pin.swift
import Foundation
import SwiftData
import ActivityKit

@Model
class Pin {
    @Attribute(.unique) let id: UUID
    
    let content: String
    let pinType: PinType
    var creationDate: Date
    
    var showInHistoryAt: Date
    
    var metadataTitle: String?
    var metadataFaviconData: Data?

    // ⭐️ 1. Activity.id를 저장할 속성 추가 (DB에 저장됨)
    var activityID: String? = nil

    // ⭐️ 2. associatedActivity는 @Transient (In-Memory) 유지
    @Transient var associatedActivity: Activity<PinActivityAttributes>? = nil

    init(content: String,
         pinType: PinType,
         metadataTitle: String?,
         metadataFaviconData: Data?,
         creationDate: Date = .now)
    {
        self.id = UUID()
        self.content = content
        self.pinType = pinType
        self.metadataTitle = metadataTitle
        self.metadataFaviconData = metadataFaviconData
        self.creationDate = creationDate
        self.showInHistoryAt = creationDate.addingTimeInterval(8 * 60 * 60)
        self.activityID = nil // ⭐️ (초기값)
    }
}

// PinType은 Codable 유지 (SwiftData가 지원)
enum PinType: String, Codable, Hashable {
    case text
    case url
}
