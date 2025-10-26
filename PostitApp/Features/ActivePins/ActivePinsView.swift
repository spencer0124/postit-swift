// PostitApp/Features/ActivePins/ActivePinsView.swift

import SwiftUI

struct Tab1View: View {
    @EnvironmentObject var viewModel: ActivePinsViewModel
    // ⭐️ displaySharedView 환경 값 받기
    @Environment(\.displaySharedView) var displaySharedView
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.activePins.isEmpty {
                    EmptyStateView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        // ForEach 수정 (async onDelete 전달)
                        ForEach(Array(viewModel.activePins.enumerated()), id: \.element.id) { index, pin in
                            PinListRow(pin: pin, onDelete: {
                                // ⭐️ async 함수 호출
                                await viewModel.removePin(at: IndexSet(integer: index))
                            })
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("핀 대시보드")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.isShowingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingEditor) {
            // ⭐️ PinEditorView에 displaySharedView 클로저 전달
            PinEditorView(onCommit: displaySharedView)
                .environmentObject(viewModel)
        }
    }
}

// MARK: - Helper Views
private struct PinListRow: View {
    let pin: Pin
    // ⭐️ onDelete 클로저는 async 유지
    var onDelete: () async -> Void
    
    private var endDate: Date { pin.creationDate.addingTimeInterval(8 * 60 * 60) } // 8시간

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                PinRowView(pin: pin)
                HStack(spacing: 4) {
                    Image(systemName: "hourglass").font(.caption2).foregroundColor(.secondary)
                    TimelineView(.periodic(from: .now, by: 1.0)) { _ in
                        Text(endDate, style: .timer).font(.caption.monospacedDigit()).foregroundColor(.secondary).lineLimit(1)
                    }
                }
            }
            Spacer()
            // ⭐️ [오류 수정] Button의 action에서 withAnimation 제거
            Button(action: {
                Task {
                    await onDelete() // ⭐️ async 함수만 호출
                }
            }) {
                Image(systemName: "minus.circle.fill").font(.title2).foregroundColor(.red)
            }.buttonStyle(.plain)
        }.padding(.vertical, 4)
    }
}

private struct EmptyStateView: View {
    // ... (내용 변경 없음) ...
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "pin.slash").font(.system(size: 48, weight: .light)).foregroundColor(.secondary)
            Text("고정된 핀이 없어요").font(.headline.weight(.medium))
            Text("오른쪽 상단의 + 버튼을 눌러\n새로운 핀을 추가해 보세요.").font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
        }.padding(.bottom, 60)
    }
}

// MARK: - SwiftUI Preview (변경 없음)
#Preview {
    Tab1View()
        .environmentObject(ActivePinsViewModel())
}
