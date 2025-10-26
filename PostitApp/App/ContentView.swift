// PostitApp/App/ContentView.swift

import SwiftUI
import SwiftData

struct ContentView: View {
    
    @Binding var selectedTab: Tab
    
    @EnvironmentObject var viewModel: ActivePinsViewModel
    @EnvironmentObject var historyViewModel: HistoryViewModel
    
    @Environment(\.displaySharedView) var displaySharedView
    @Environment(\.modelContext) private var modelContext

    enum Tab {
        case dashboard
        case archive
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // ⭐️ 1. 토스 스타일의 연한 회색 배경
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            // 2. 메인 콘텐츠
            VStack(spacing: 0) {
                switch selectedTab {
                case .dashboard:
                    Tab1View()
                case .archive:
                    Tab2View(selectedTab: $selectedTab)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environment(\.displaySharedView, displaySharedView)
            
            // 3. ⭐️ 플로팅 탭 바
            CustomTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 16) // ⭐️ 화면 좌우에 여백
                .padding(.bottom, 8)      // ⭐️ 화면 하단에 여백
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            historyViewModel.setModelContext(modelContext)
            Task {
                await viewModel.initialize(modelContext: modelContext)
            }
        }
    }
}

// MARK: - ⭐️ 커스텀 탭 바 뷰 (토스 스타일 수정)
private struct CustomTabBar: View {
    @Binding var selectedTab: ContentView.Tab
    
    // 부드러운 스프링 애니메이션
    private let tabAnimation: Animation = .spring(response: 0.35, dampingFraction: 0.8)

    var body: some View {
        HStack(spacing: 8) { // ⭐️ 버튼 사이 간격
            TabBarButton(
                icon: "pin.fill",
                label: "대시보드", // ⭐️ "핀" 제거 (간결하게)
                isSelected: selectedTab == .dashboard,
                action: {
                    withAnimation(tabAnimation) {
                        selectedTab = .dashboard
                    }
                }
            )
            
            TabBarButton(
                icon: "archivebox.fill",
                label: "보관함",
                isSelected: selectedTab == .archive,
                action: {
                    withAnimation(tabAnimation) {
                        selectedTab = .archive
                    }
                }
            )
        }
        .padding(8) // ⭐️ 캡슐 내부 여백
        .background(Color(uiColor: .systemBackground)) // ⭐️ 불투명 흰색 배경
        .clipShape(Capsule())
        // ⭐️ 토스 스타일의 은은한 그림자
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

// MARK: - ⭐️ 탭 바 내부 버튼 뷰 (토스 스타일 수정)
private struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold)) // ⭐️ 더 굵고 명확하게
                Text(label)
                    .font(.system(size: 11, weight: .bold)) // ⭐️ 더 굵고 명확하게
            }
            .foregroundColor(isSelected ? .primary : .secondary) // ⭐️ 선택 시 검정, 미선택 시 회색
            .frame(maxWidth: .infinity) // ⭐️ 버튼이 공간을 균등하게 차지
            .padding(.vertical, 10)     // ⭐️ 버튼 상하 여백
            .background {
                // ⭐️ 선택된 항목에만 회색 "Pill" 배경 추가
                if isSelected {
                    Capsule()
                        .fill(Color(uiColor: .secondarySystemBackground))
                }
            }
        }
        .buttonStyle(.plain) // ⭐️ 버튼의 기본 파란색 스타일 제거
    }
}

// MARK: - Preview (변경 없음)
#Preview {
    struct PreviewWrapper: View {
        @State private var tab: ContentView.Tab = .dashboard
        var body: some View {
            ContentView(selectedTab: $tab)
                .environmentObject(ActivePinsViewModel())
                .environmentObject(HistoryViewModel())
                // .modelContainer(for: Pin.self, inMemory: true)
        }
    }
    return PreviewWrapper()
}
