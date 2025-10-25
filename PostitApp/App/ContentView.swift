//
//  ContentView.swift
//  postit
//
//  Created by SeungYong on 10/20/25.
//

import SwiftUI

struct ContentView: View {
    
    // ⭐️ @State -> @Binding 변경
    @Binding var selectedTab: Tab
    
    // ⭐️ displaySharedView 환경 값 받기 (하위 뷰 전달용)
    @Environment(\.displaySharedView) var displaySharedView
    
    enum Tab {
        case dashboard
        case archive
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                switch selectedTab {
                case .dashboard:
                    Tab1View()
                case .archive:
                    Tab2View()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // ⭐️ displaySharedView 환경 값을 하위 뷰로 전달
            .environment(\.displaySharedView, displaySharedView)
            
            CustomTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 0)
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - 커스텀 탭 바 뷰 (변경 없음)
private struct CustomTabBar: View {
    // ... (내용 동일) ...
    @Binding var selectedTab: ContentView.Tab
    
    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(
                icon: "pin.fill",
                label: "핀 대시보드",
                isSelected: selectedTab == .dashboard,
                action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = .dashboard
                    }
                }
            )
            Spacer()
            TabBarButton(
                icon: "archivebox.fill",
                label: "보관함",
                isSelected: selectedTab == .archive,
                action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = .archive
                    }
                }
            )
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 14)
        .frame(width: 280)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
    }
}

// MARK: - 탭 바 내부 버튼 뷰 (변경 없음)
private struct TabBarButton: View {
    // ... (내용 동일) ...
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? .primary : .secondary)
        }
        .frame(width: 80)
    }
}

// MARK: - Preview (변경 없음)
#Preview {
    struct PreviewWrapper: View {
        @State private var tab: ContentView.Tab = .dashboard
        var body: some View {
            ContentView(selectedTab: $tab)
                .environmentObject(ActivePinsViewModel())
        }
    }
    return PreviewWrapper()
}
