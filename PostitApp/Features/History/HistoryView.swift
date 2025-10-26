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
            // ⭐️ 3. List -> ScrollView로 변경
            ScrollView {
                VStack(spacing: 12) { // ⭐️ 카드 간 간격
                    if viewModel.archivedPins.isEmpty {
                        // ⭐️ 4. EmptyStateView 사용
                        EmptyStateView()
                            .padding(.top, 100)
                    } else {
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
                    }
                }
                .padding(.horizontal, 16) // ⭐️ 카드 좌우 여백
                .padding(.top, 12)        // ⭐️ 네비게이션 바 아래 여백
                .padding(.bottom, 100)    // ⭐️ 플로팅 탭바를 위한 하단 여백
            }
            .background(Color.clear) // ⭐️ 배경색은 ContentView가 관리
            .navigationTitle("보관함")
            .navigationBarTitleDisplayMode(.inline) // ⭐️ 인라인 타이틀
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // ⭐️ 5. "모두 지우기" 버튼 스타일 변경
                    Button {
                        viewModel.clearAllHistory()
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.red)
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

// MARK: - ⭐️ 6. HistoryPinListRow (카드 스타일 적용)
private struct HistoryPinListRow: View {
    let pin: Pin
    var onRestore: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 15) {
            // 6-1. 핀 콘텐츠 (PinRowView 재사용)
            PinRowView(pin: pin)
            
            Spacer()

            // 6-2. "다시 핀하기" 버튼
            Button(action: {
                withAnimation(.spring()) { onRestore() }
            }) {
                Image(systemName: "pin.circle.fill") // ⭐️ 아이콘 변경
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)

            // 6-3. "영구 삭제" 버튼
            Button(action: {
                withAnimation(.spring()) { onDelete() }
            }) {
                Image(systemName: "trash.circle.fill") // ⭐️ 아이콘 변경
                    .font(.title2)
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(16) // ⭐️ 카드 내부 패딩
        .background(Color(uiColor: .systemBackground)) // ⭐️ 흰색 카드 배경
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // ⭐️ 둥근 모서리
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2) // ⭐️ 은은한 그림자
    }
}

// MARK: - ⭐️ 7. EmptyStateView 헬퍼 뷰 추가
private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "archivebox")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(Color(uiColor: .systemGray3))
            
            Text("보관된 핀이 없어요")
                .font(.title2.weight(.bold))
            
            Text("대시보드에서 핀을 삭제하거나\n핀이 만료되면 이곳에 보관됩니다.")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 60)
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
