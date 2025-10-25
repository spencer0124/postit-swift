//
//  AppIntent.swift
//  PinLiveActivity
//
//  Created by SeungYong on 10/20/25.
//

import WidgetKit
import AppIntents
import UIKit // UIPasteboard 사용을 위해 import

// 기존 ConfigurationAppIntent는 그대로 둡니다.
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is an example widget." }

    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String
}

// 클립보드 복사를 위한 App Intent
struct CopyPinIntent: AppIntent {
    static var title: LocalizedStringResource = "Copy Pin Content"
    
    @Parameter(title: "Content to Copy")
    var content: String
    
    init(content: String) {
        self.content = content
    }
    
    init() {
    }
    
    // perform의 반환 타입에 '& ReturnsValue<Bool>'을 추가합니다.
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        UIPasteboard.general.string = content
        print("Copied to clipboard: \(content)")
        
        // 복사 성공 시 'true' 값을 포함하는 .result를 반환
        return .result(value: true)
    }
}
