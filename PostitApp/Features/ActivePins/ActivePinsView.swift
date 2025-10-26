// PostitApp/Features/ActivePins/ActivePinsView.swift

import SwiftUI

struct Tab1View: View {
    @EnvironmentObject var viewModel: ActivePinsViewModel
    @Environment(\.displaySharedView) var displaySharedView
    
    var body: some View {
        NavigationStack {
            // ⭐️ 1. List -> ScrollView로 변경 (토스 카드 스타일)
            ScrollView {
                VStack(spacing: 12) { // ⭐️ 카드 간 간격
                    if viewModel.activePins.isEmpty {
                        EmptyStateView()
                            .padding(.top, 100) // ⭐️ 빈 화면일 때 상단 여백
                    } else {
                        ForEach(Array(viewModel.activePins.enumerated()), id: \.element.id) { index, pin in
                            PinListRow(pin: pin, onDelete: {
                                await viewModel.removePin(at: IndexSet(integer: index))
                            })
                        }
                    }
                }
                .padding(.horizontal, 16) // ⭐️ 카드 좌우 여백
                .padding(.top, 12)        // ⭐️ 네비게이션 바 아래 여백
                .padding(.bottom, 100)    // ⭐️ 플로팅 탭바를 위한 하단 여백
            }
            // ⭐️ 2. 배경색은 ContentView의 .systemGroupedBackground를 따름
            .background(Color.clear)
            .navigationTitle("대시보드") // ⭐️ "핀" 제거 (간결하게)
            
            // ⭐️⭐️⭐️ [수정된 부분] ⭐️⭐️⭐️
            // 네비게이션 타이틀을 항상 인라인으로 표시
            .navigationBarTitleDisplayMode(.inline)
            
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.isShowingEditor = true
                    } label: {
                        // ⭐️ 3. 플러스 버튼 아이콘 스타일 변경
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingEditor) {
            PinEditorView(onCommit: displaySharedView)
                .environmentObject(viewModel)
        }
    }
}

// MARK: - ⭐️ Helper Views (토스 카드 스타일 적용)
private struct PinListRow: View {
    let pin: Pin
    var onDelete: () async -> Void
    
    private var endDate: Date { pin.creationDate.addingTimeInterval(8 * 60 * 60) } // 8시간

    var body: some View {
        HStack(spacing: 12) { // ⭐️ 내부 컨텐츠 간격
            // 1. 핀 콘텐츠 (VStack)
            VStack(alignment: .leading, spacing: 6) {
                PinRowView(pin: pin) // ⭐️ PinContentView 재사용
                
                // 2. 남은 시간 타이머
                HStack(spacing: 4) {
                    Image(systemName: "hourglass")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TimelineView(.periodic(from: .now, by: 1.0)) { _ in
                        Text(endDate, style: .timer)
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // 3. ⭐️ 삭제 버튼 (X 아이콘으로 변경)
            Button(action: {
                Task {
                    await onDelete()
                }
            }) {
                Image(systemName: "xmark.circle.fill") // ⭐️ 아이콘 변경
                    .font(.title2)
                    .foregroundColor(Color(uiColor: .systemGray3)) // ⭐️ 회색으로 변경
            }
            .buttonStyle(.plain)
        }
        .padding(16) // ⭐️ 카드 내부 패딩
        .background(Color(uiColor: .systemBackground)) // ⭐️ 흰색 카드 배경
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // ⭐️ 둥근 모서리
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2) // ⭐️ 은은한 그림자
    }
}

// ⭐️ EmptyStateView (토스 스타일 적용)
private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) { // ⭐️ 간격 증가
            Image(systemName: "pin.slash")
                .font(.system(size: 40, weight: .medium)) // ⭐️ 아이콘 크기/굵기
                .foregroundColor(Color(uiColor: .systemGray3)) // ⭐️ 아이콘 색상
            
            Text("고정된 핀이 없어요")
                .font(.title2.weight(.bold)) // ⭐️ 과감한 타이포그래피
            
            Text("오른쪽 상단의 + 버튼을 눌러\n새로운 핀을 추가해 보세요.")
                .font(.callout) // ⭐️ 폰트 크기
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 60)
    }
}

// MARK: - SwiftUI Preview (변경 없음)
#Preview {
    Tab1View()
        .environmentObject(ActivePinsViewModel())
}
