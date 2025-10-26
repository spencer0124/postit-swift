// PostitApp/App/ContentView.swift

import SwiftUI
import SwiftData // 1. Import

struct ContentView: View {
    
    @Binding var selectedTab: Tab
    
    // 2. VM들 가져오기
    @EnvironmentObject var viewModel: ActivePinsViewModel
    @EnvironmentObject var historyViewModel: HistoryViewModel
    
    @Environment(\.displaySharedView) var displaySharedView
    @Environment(\.modelContext) private var modelContext // 3. modelContext 가져오기

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
                    // 4. Tab2View에 selectedTab 바인딩 전달
                    // (HistoryVM은 이미 Environment에 있음)
                    Tab2View(selectedTab: $selectedTab)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environment(\.displaySharedView, displaySharedView)
            
            CustomTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 0)
        }
        .ignoresSafeArea(.keyboard)
        // 5. ⭐️ 뷰가 나타날 때 VM들에 modelContext 주입 (수정)
        .onAppear {
            // HistoryVM은 동기 함수이므로 그대로 둠
            historyViewModel.setModelContext(modelContext)
            
            // ⭐️ ActivePinsVM의 초기화 함수는 async이므로 Task로 감쌈
            Task {
                await viewModel.initialize(modelContext: modelContext)
            }
        }
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
                .environmentObject(HistoryViewModel()) // ⭐️ Preview에도 추가
                // .modelContainer(for: Pin.self, inMemory: true) // Preview를 위해 In-Memory DB 설정
        }
    }
    return PreviewWrapper()
}
