//
//  PinLiveActivityLiveActivity.swift
//  PinLiveActivity
//
//  Created by SeungYong on 10/20/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct PinLiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PinActivityAttributes.self) { context in
            // 잠금화면 UI
            LockScreenView(context: context)
                .padding()
                .activityBackgroundTint(Color.black.opacity(0.3))
                .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // 확장 UI
                DynamicIslandExpandedRegion(.leading) {
//                    Image(systemName: "pin.fill").font(.title3).padding(.leading, 5)
                }
                DynamicIslandExpandedRegion(.trailing) { }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedContentView(context: context)
                        .padding(.horizontal)
                }
            } compactLeading: {
                // 축소 (왼쪽)
                Image(systemName: "pin.fill")
                    .padding(.leading, 2)
            } compactTrailing: {
                // 축소 (오른쪽)
                Text(context.state.metadataTitle ?? context.state.content)
                    .lineLimit(1).font(.caption)
            } minimal: {
                 Image(systemName: "pin.fill")
            }
            .widgetURL(URL(string: "pinapp://open"))
            .keylineTint(Color.white)
        }
    }
}

// MARK: - 재사용 UI 컴포넌트

// LA UI를 그리는 메인 뷰
struct ExpandedContentView: View {
    let context: ActivityViewContext<PinActivityAttributes>

    var body: some View {
        PinContentView(
                    content: context.state.content, // context에서 데이터 전달
                    pinType: context.attributes.pinType, // context에서 데이터 전달
                    metadataTitle: context.state.metadataTitle, // context에서 데이터 전달
                    metadataFaviconData: context.state.metadataFaviconData // context에서 데이터 전달
                )
    }
}

// 잠금화면 뷰
struct LockScreenView: View {
    let context: ActivityViewContext<PinActivityAttributes>
    var body: some View {
        ExpandedContentView(context: context)
    }
}


// MARK: - SwiftUI Preview

// Preview에서 사용할 샘플 데이터 정의 (기존 코드 유지)
extension PinActivityAttributes {
    fileprivate static var previewText: PinActivityAttributes { PinActivityAttributes(pinType: .text, creationDate: .now) }
    fileprivate static var previewURL: PinActivityAttributes { PinActivityAttributes(pinType: .url, creationDate: .now) }
    // 아이콘 데이터를 포함한 URL 샘플 추가 (SF Symbol 사용)
    fileprivate static var previewURLWithIcon: PinActivityAttributes { PinActivityAttributes(pinType: .url, creationDate: .now) }
}

extension PinActivityAttributes.ContentState {
    fileprivate static var textExample: PinActivityAttributes.ContentState {
        .init(content: "회의록 정리하기 - 5시까지", metadataTitle: nil, metadataFaviconData: nil)
     }
     fileprivate static var urlExample: PinActivityAttributes.ContentState {
         .init(content: "https://www.apple.com", metadataTitle: "Apple (Preview)", metadataFaviconData: nil) // 아이콘 없음
     }
    // 아이콘 데이터를 포함한 URL 샘플 추가 (SF Symbol 사용)
    fileprivate static var urlExampleWithIcon: PinActivityAttributes.ContentState {
        .init(content: "https://developer.apple.com",
              metadataTitle: "Apple Developer",
              metadataFaviconData: UIImage(systemName: "apple.logo")?.pngData()) // SF Symbol 아이콘 데이터
    }
}


// --- ⭐️ 수정된 Preview 코드 ---

// 1. 잠금화면 (Lock Screen / Notification)
//#Preview("Lock Screen - Text", as: .content, using: PinActivityAttributes.previewText) {
//   PinLiveActivityLiveActivity()
//} contentStates: {
//    PinActivityAttributes.ContentState.textExample
//}
//
//#Preview("Lock Screen - URL (No Icon)", as: .content, using: PinActivityAttributes.previewURL) {
//   PinLiveActivityLiveActivity()
//} contentStates: {
//    PinActivityAttributes.ContentState.urlExample
//}

#Preview("Lock Screen - URL (With Icon)", as: .content, using: PinActivityAttributes.previewURLWithIcon) {
   PinLiveActivityLiveActivity()
} contentStates: {
    PinActivityAttributes.ContentState.urlExampleWithIcon
}


// 2. 다이나믹 아일랜드 - 축소 (Compact)
#Preview("Dynamic Island Compact - Text", as: .dynamicIsland(.compact), using: PinActivityAttributes.previewText) {
   PinLiveActivityLiveActivity()
} contentStates: {
    PinActivityAttributes.ContentState.textExample
}

//#Preview("Dynamic Island Compact - URL", as: .dynamicIsland(.compact), using: PinActivityAttributes.previewURL) {
//   PinLiveActivityLiveActivity()
//} contentStates: {
//    PinActivityAttributes.ContentState.urlExample // 축소 상태는 아이콘 표시 안 함
//}


// 3. 다이나믹 아일랜드 - 확장 (Expanded)
#Preview("Dynamic Island Expanded - Text", as: .dynamicIsland(.expanded), using: PinActivityAttributes.previewText) {
   PinLiveActivityLiveActivity()
} contentStates: {
    PinActivityAttributes.ContentState.textExample
}

#Preview("Dynamic Island Expanded - URL (No Icon)", as: .dynamicIsland(.expanded), using: PinActivityAttributes.previewURL) {
   PinLiveActivityLiveActivity()
} contentStates: {
    PinActivityAttributes.ContentState.urlExample
}

#Preview("Dynamic Island Expanded - URL (With Icon)", as: .dynamicIsland(.expanded), using: PinActivityAttributes.previewURLWithIcon) {
   PinLiveActivityLiveActivity()
} contentStates: {
    PinActivityAttributes.ContentState.urlExampleWithIcon
}


// 4. 다이나믹 아일랜드 - 최소 (Minimal)
#Preview("Dynamic Island Minimal", as: .dynamicIsland(.minimal), using: PinActivityAttributes.previewText) {
   PinLiveActivityLiveActivity()
} contentStates: {
    PinActivityAttributes.ContentState.textExample // 최소 상태는 내용 표시 안 함
}
