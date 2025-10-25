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
                    Image(systemName: "pin.fill").font(.title3).padding(.leading, 5)
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
        // phase 로직이 제거된 원래의 UI 로직
        VStack(alignment: .leading, spacing: 5) {
            Text("📌 고정된 메모")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if context.attributes.pinType == .url {
                // URL 타입 UI
                HStack {
                    if let data = context.state.metadataFaviconData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable().aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        Image(systemName: "link.circle.fill").font(.title3).frame(width: 20, height: 20)
                    }
                    Text(context.state.metadataTitle ?? context.state.content)
                        .font(.headline).lineLimit(1)
                }
                if context.state.metadataTitle != nil {
                    Text(context.state.content).font(.caption).foregroundColor(.secondary).lineLimit(1)
                }
            } else {
                // 텍스트 타입 UI
                Text(context.state.content).font(.headline).lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading) // 왼쪽 정렬 유지
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
extension PinActivityAttributes {
    fileprivate static var previewText: PinActivityAttributes { PinActivityAttributes(pinType: .text, creationDate: .now) }
    fileprivate static var previewURL: PinActivityAttributes { PinActivityAttributes(pinType: .url, creationDate: .now) }
}

extension PinActivityAttributes.ContentState {
    fileprivate static var textExample: PinActivityAttributes.ContentState {
        .init(content: "회의록 정리하기 - 5시까지", metadataTitle: nil, metadataFaviconData: nil)
     }
     fileprivate static var urlExample: PinActivityAttributes.ContentState {
         .init(content: "https://www.apple.com", metadataTitle: "Apple (Preview)", metadataFaviconData: nil)
     }
}

#Preview("Notification", as: .content, using: PinActivityAttributes.previewText) {
   PinLiveActivityLiveActivity()
} contentStates: {
    PinActivityAttributes.ContentState.textExample
    PinActivityAttributes.ContentState.urlExample
}
