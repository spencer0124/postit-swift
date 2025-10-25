// PostitApp/Features/SharedPinView/FakeNotificationView.swift
import SwiftUI

// MARK: - 가짜 알림 뷰 (Shimmer 효과)
/// 'shimmer' 느낌의 가짜 알림 플레이스홀더 UI입니다.
struct FakeNotificationView: View {
    var body: some View {
        ZStack {
            // 1. 배경
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(.ultraThinMaterial)
            
            // 2. 컨텐츠
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Circle().frame(width: 20, height: 20)
                        .opacity(0.7)
                    RoundedRectangle(cornerRadius: 4).frame(width: 80, height: 14)
                        .opacity(0.7)
                    Spacer()
                    RoundedRectangle(cornerRadius: 4).frame(width: 40, height: 12)
                        .opacity(0.7)
                }
                .padding(.bottom, 2)
                
                RoundedRectangle(cornerRadius: 4).frame(width: 180, height: 16)
                RoundedRectangle(cornerRadius: 4).frame(width: 220, height: 14)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading) // 컨텐츠가 꽉 차되 왼쪽 정렬
        }
        .frame(height: 80)
        .redacted(reason: .placeholder)
    }
}

// Preview 추가 (선택 사항)
#Preview {
    FakeNotificationView()
        .padding()
}
