//
//  PinLiveActivityLiveActivity.swift
//  PinLiveActivity
//
//  Created by SeungYong on 10/20/25.
//

import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

struct PinLiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PinActivityAttributes.self) { context in
            // 잠금화면 UI
            LockScreenView(context: context)
                .padding()
                // ⭐️ 1. URL을 잠금화면 *전체*에 적용
                .widgetURL(URL(string: AppConstants.liveActivityDeepLink))
                .activityBackgroundTint(Color.black.opacity(0.3))
                .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // 확장 UI
                // 2. 다이나믹 아일랜드 좌측 영역에 복사 버튼 배치
                DynamicIslandExpandedRegion(.leading) {
                    CopyButton(content: context.state.content)
                        .padding(.leading, 5)
                }
                // 3. 다이나믹 아일랜드 우측 영역 (타이머)
                DynamicIslandExpandedRegion(.trailing) {
                    TimerProgressView(creationDate: context.attributes.creationDate)
                        .padding(.trailing, 5)
                }
                // 4. 다이나믹 아일랜드 하단 영역 (콘텐츠)
                DynamicIslandExpandedRegion(.bottom) {
                    // ⭐️ 5. DI 하단 영역(콘텐츠)을 Link로 감싸서 앱 열기
                    Link(destination: URL(string: AppConstants.liveActivityDeepLink)!) {
                        ExpandedContentView(context: context)
                            .padding(.horizontal)
                    }
                }
            } compactLeading: {
                Image(systemName: "pin.fill")
                    .padding(.leading, 2)
            } compactTrailing: {
                Text(context.state.metadataTitle ?? context.state.content)
                    .lineLimit(1).font(.caption)
            } minimal: {
                 Image(systemName: "pin.fill")
            }
            // ⭐️ 6. .widgetURL을 DI 전체가 아닌 compact/minimal에만 적용되도록 함
            .widgetURL(URL(string: AppConstants.liveActivityDeepLink))
            .keylineTint(Color.white)
        }
    }
}

// ⭐️ 7. CopyButton 수정: Button(intent:) 사용 및 낙관적 업데이트
private struct CopyButton: View {
    let content: String
    @State private var showCheckmark: Bool = false
    
    // Intent 인스턴스
    private var copyIntent: CopyPinIntent {
        CopyPinIntent(content: content)
    }

    var body: some View {
        // ⭐️ 8. Button(intent:) 사용. label 클로저만 제공.
        Button(intent: copyIntent) {
            Image(systemName: showCheckmark ? "checkmark" : "doc.on.doc")
                .font(.body)
                .fontWeight(.medium)
                .animation(.none, value: showCheckmark) // 아이콘 전환 시 fade 방지
                .scaleEffect(showCheckmark ? 1.2 : 1.0) // 스케일 애니메이션
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: showCheckmark) { oldValue, newValue in
            newValue == true // 체크마크가 표시될 때만 햅틱 발생
        }
        // ⭐️ 9. .onTapGesture를 사용하여 버튼 탭 시 낙관적 UI 업데이트 트리거
        .onTapGesture {
            // 이미 체크마크 상태면 아무것도 안 함 (중복 탭 방지)
            guard !showCheckmark else { return }
            
            // 즉시 체크마크 표시 및 애니메이션 시작
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                showCheckmark = true
            }
            // 잠시 후 원래 아이콘으로 복원
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // 1초 후
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    showCheckmark = false
                }
            }
        }
    }
}


// 10. TimerProgressView (변경 없음)
private struct TimerProgressView: View {
    let creationDate: Date
    private let totalDuration: Double = 8 * 60 * 60
    
    var body: some View {
        ZStack {
            TimelineView(.periodic(from: .now, by: 60.0)) { context in
                let remainingTime = creationDate.addingTimeInterval(totalDuration).timeIntervalSince(context.date)
                
                ProgressView(value: max(0, remainingTime), total: totalDuration)
                    .progressViewStyle(.circular)
                    .tint(.primary)
                    .labelsHidden()
            }
            Image(systemName: "hourglass")
                .font(.caption2)
                .foregroundColor(.primary)
                .opacity(0.7)
        }
        .frame(width: 24, height: 24)
    }
}


// MARK: - 재사용 UI 컴포넌트

// 11. LA 콘텐츠 뷰 (변경 없음)
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

// 12. 잠금화면 뷰 (변경 없음)
struct LockScreenView: View {
    let context: ActivityViewContext<PinActivityAttributes>
    var body: some View {
        HStack {
            // Link가 ZStack(콘텐츠+타이머)을 감싸도록 수정
            Link(destination: URL(string: AppConstants.liveActivityDeepLink)!) {
                ZStack(alignment: .topTrailing) {
                    ExpandedContentView(context: context)
                        .padding(.trailing, 30)
                    
                    TimerProgressView(creationDate: context.attributes.creationDate)
                }
            }
            
            Spacer()
            
            // CopyButton은 Link 외부에 있어 앱을 열지 않습니다.
            CopyButton(content: context.state.content)
        }
    }
}


// MARK: - SwiftUI Preview (변경 없음)
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
         .init(content: "https://www.apple.com", metadataTitle: "Apple (Preview)", metadataFaviconData: nil)
     }
    fileprivate static var urlExampleWithIcon: PinActivityAttributes.ContentState {
        .init(content: "https://developer.apple.com",
              metadataTitle: "Apple Developer",
              metadataFaviconData: UIImage(systemName: "apple.logo")?.pngData())
    }
}

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
