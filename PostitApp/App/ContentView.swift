//
//  ContentView.swift
//  postit
//
//  Created by SeungYong on 10/20/25.
//

import SwiftUI

struct ContentView: View {
    
    // 1. 현재 선택된 탭을 추적하는 상태 변수
    @State private var selectedTab: Tab = .dashboard
    
    // 2. 탭을 명확하게 구분하기 위한 열거형(Enum)
    enum Tab {
        case dashboard
        case archive
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 3. 선택된 탭에 따라 메인 뷰를 교체
            VStack {
                switch selectedTab {
                case .dashboard:
                    Tab1View()
                case .archive:
                    Tab2View()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 4. 커스텀 탭 바를 화면 하단에 오버레이로 띄움
            CustomTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 0) // 하단 Safe Area와 약간의 여유 공간
        }
        .ignoresSafeArea(.keyboard) // 키보드가 올라올 때 탭 바가 밀려나지 않도록
    }
}

// MARK: - 커스텀 탭 바 뷰

private struct CustomTabBar: View {
    
    @Binding var selectedTab: ContentView.Tab
    
    var body: some View {
        HStack(spacing: 0) {
            // "핀 대시보드" 탭 버튼
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
            
            // "보관함" 탭 버튼
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
        .frame(width: 280) // 탭 바의 전체 너비 고정 (토스 스타일)
        .background(.ultraThinMaterial) // 애플의 블러(Blur) 효과
        .clipShape(Capsule()) // 캡슐 모양으로 자르기
        .shadow(color: .black.opacity(0.15), radius: 10, y: 5) // 은은한 그림자
    }
}

// MARK: - 탭 바 내부 버튼 뷰

private struct TabBarButton: View {
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
            .foregroundColor(isSelected ? .primary : .secondary) // 선택 시 강조
        }
        .frame(width: 80) // 버튼의 탭 영역
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(ActivePinsViewModel()) // ViewModel 주입은 그대로 유지
}
