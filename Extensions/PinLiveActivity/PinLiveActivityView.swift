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
            // 1. 잠금화면 UI
            LockScreenView(context: context)
                .padding()
                .activityBackgroundTint(Color.black.opacity(0.3))
                .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // 확장 UI
                DynamicIslandExpandedRegion(.leading) {
                    // 비워둠
                }
                // 2. 다이나믹 아일랜드 우상단 영역
                DynamicIslandExpandedRegion(.trailing) {
                    // 글자 없는 타이머를 우상단에 배치
                    TimerProgressView(creationDate: context.attributes.creationDate)
                        .padding(.trailing, 5) // DI 영역 내 패딩
                }
                // 3. 다이나믹 아일랜드 하단 영역 (콘텐츠만)
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
            .widgetURL(URL(string: AppConstants.liveActivityDeepLink))
            .keylineTint(Color.white)
        }
    }
}

// ⭐️ 4. TimerProgressView 수정: 아이콘 색상을 .primary로 변경
private struct TimerProgressView: View {
    let creationDate: Date
    private let totalDuration: Double = 8 * 60 * 60 // 28800초 (8시간)
    
    var body: some View {
        // ZStack으로 ProgressView와 Image를 겹쳐서 배치
        ZStack {
            // 1분(60초)마다 뷰를 갱신
            TimelineView(.periodic(from: .now, by: 60.0)) { context in
                let remainingTime = creationDate.addingTimeInterval(totalDuration).timeIntervalSince(context.date)
                
                ProgressView(value: max(0, remainingTime), total: totalDuration)
                    .progressViewStyle(.circular)
                    .tint(.primary) // ⭐️ (흰색/검은색) 자동 조절
                    .labelsHidden() // 텍스트를 확실히 숨김
            }
            
            // hourglass 아이콘 추가
            Image(systemName: "hourglass")
                .font(.caption2) // 아이콘 크기 조정
                .foregroundColor(.primary) // ⭐️ .white에서 .primary로 변경
                .opacity(0.7) // ⭐️ 아이콘이 링보다 덜 튀도록
        }
        .frame(width: 24, height: 24) // 크기 고정
    }
}


// MARK: - 재사용 UI 컴포넌트

// 5. LA 콘텐츠 뷰 (변경 없음)
struct ExpandedContentView: View {
    let context: ActivityViewContext<PinActivityAttributes>

    var body: some View {
        PinContentView(
            content: context.state.content,
            pinType: context.attributes.pinType,
            metadataTitle: context.state.metadataTitle,
            metadataFaviconData: context.state.metadataFaviconData
        )
    }
}

// 6. 잠금화면 뷰 (변경 없음 - TimerProgressView를 사용하므로 자동 적용)
struct LockScreenView: View {
    let context: ActivityViewContext<PinActivityAttributes>
    var body: some View {
        // ZStack을 사용해 우상단 정렬 구현
        ZStack(alignment: .topTrailing) {
            
            // 기본 콘텐츠 (왼쪽 정렬됨)
            ExpandedContentView(context: context)
                // 타이머가 겹칠 공간을 확보하기 위해 우측 패딩
                .padding(.trailing, 30)
            
            // 글자 없는 원형 타이머
            TimerProgressView(creationDate: context.attributes.creationDate)
        }
    }
}


// MARK: - SwiftUI Preview

// Preview에서 사용할 샘플 데이터 정의 (오타 수정됨)
extension PinActivityAttributes {
    fileprivate static var previewText: PinActivityAttributes { PinActivityAttributes(pinType: .text, creationDate: .now) }
    fileprivate static var previewURL: PinActivityAttributes { PinActivityAttributes(pinType: .url, creationDate: .now) }
    fileprivate static var previewURLWithIcon: PinActivityAttributes { PinActivityAttributes(pinType: .url, creationDate: .now) }
}

extension PinActivityAttributes.ContentState {
    fileprivate static var textExample: PinActivityAttributes.ContentState {
        .init(content: "회의록 정리하기 - 5시까지", metadataTitle: nil, metadataFaviconData: nil)
     }
     fileprivate static var urlExample: PinActivityAttributes.ContentState {
         .init(content: "https://www.apple.com", metadataTitle: "Apple (Preview)", metadataFaviconData: nil) // 아이콘 없음
     }
    fileprivate static var urlExampleWithIcon: PinActivityAttributes.ContentState {
        .init(content: "https://developer.apple.com",
              metadataTitle: "Apple Developer",
              metadataFaviconData: UIImage(systemName: "apple.logo")?.pngData()) // SF Symbol 아이콘 데이터
    }
}


// --- Preview 코드 (변경 없음) ---

#Preview("Lock Screen - URL (With Icon)", as: .content, using: PinActivityAttributes.previewURLWithIcon) {
   PinLiveActivityLiveActivity()
} contentStates: {
    PinActivityAttributes.ContentState.urlExampleWithIcon
}

#Preview("Dynamic Island Compact - Text", as: .dynamicIsland(.compact), using: PinActivityAttributes.previewText) {
   PinLiveActivityLiveActivity()
} contentStates: {
    PinActivityAttributes.ContentState.textExample
}

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

#Preview("Dynamic Island Minimal", as: .dynamicIsland(.minimal), using: PinActivityAttributes.previewText) {
   PinLiveActivityLiveActivity()
} contentStates: {
    PinActivityAttributes.ContentState.textExample
}
