// PostitApp/Features/History/HistoryView.swift

import SwiftUI

struct Tab2View: View {
    // 1. ViewModel들을 Environment에서 받음
    @EnvironmentObject var viewModel: HistoryViewModel
    @EnvironmentObject var activePinsViewModel: ActivePinsViewModel
    
    // 2. ContentView로부터 탭 전환을 위한 Binding 받기
    @Binding var selectedTab: ContentView.Tab
    
    var body: some View {
        NavigationStack {
            List {
                // 3. ⭐️ ForEach 수정 -> HistoryPinListRow 사용
                ForEach(viewModel.archivedPins) { pin in
                    HistoryPinListRow(
                        pin: pin,
                        onRestore: {
                            // "다시 핀하기" 로직
                            Task {
                                await activePinsViewModel.restorePin(pin)
                                withAnimation {
                                    selectedTab = .dashboard
                                }
                            }
                        },
                        onDelete: {
                            // "영구 삭제" 로직
                            if let index = viewModel.archivedPins.firstIndex(where: { $0.id == pin.id }) {
                                viewModel.deleteFromHistory(at: IndexSet(integer: index))
                            }
                        }
                    )
                }
                // 4. ⭐️ 기존 .onDelete(perform:)는 버튼으로 대체되었으므로 제거
            }
            .listStyle(.plain)
            .navigationTitle("보관함")
            .overlay {
                if viewModel.archivedPins.isEmpty {
                    Text("보관된 기록이 없습니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // "모두 지우기" 버튼 (변경 없음)
                    Button("모두 지우기", role: .destructive) {
                        viewModel.clearAllHistory()
                    }
                    .disabled(viewModel.archivedPins.isEmpty)
                }
            }
            // 탭이 나타날 때마다 보관함 목록 새로고침 (변경 없음)
            .onAppear {
                viewModel.fetchHistory()
            }
        }
    }
}

// MARK: - ⭐️ 5. HistoryPinListRow 헬퍼 뷰 추가 ⭐️
private struct HistoryPinListRow: View {
    let pin: Pin
    var onRestore: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 15) { // 버튼 간 간격 추가
            // 5-1. 핀 콘텐츠 (PinRowView 재사용)
            PinRowView(pin: pin)
            
            Spacer()

            // 5-2. "다시 핀하기" 버튼 (Tab1View 스타일 참조)
            Button(action: {
                withAnimation(.spring()) { onRestore() }
            }) {
                Image(systemName: "pin.fill") // "pin.fill" 아이콘 사용
                    .font(.title2)
                    .foregroundColor(.blue) // 파란색
            }
            .buttonStyle(.plain)

            // 5-3. "영구 삭제" 버튼 (Tab1View 스타일 참조)
            Button(action: {
                withAnimation(.spring()) { onDelete() }
            }) {
                Image(systemName: "trash.fill") // "trash.fill" 아이콘 사용
                    .font(.title2)
                    .foregroundColor(.red) // 빨간색
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 5) // 기존 List Row의 패딩 유지
    }
}


// MARK: - Preview (변경 없음)
#Preview {
    struct PreviewWrapper: View {
        @State private var tab: ContentView.Tab = .archive
        var body: some View {
            Tab2View(selectedTab: $tab)
                .environmentObject(HistoryViewModel())
                .environmentObject(ActivePinsViewModel())
                // .modelContainer(for: Pin.self, inMemory: true)
        }
    }
    return PreviewWrapper()
}
