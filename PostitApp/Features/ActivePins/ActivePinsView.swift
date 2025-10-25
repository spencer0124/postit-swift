//
//  Tab1View.swift
//  postit
//
//  Created by SeungYong on 10/20/25.
//

import SwiftUI

struct Tab1View: View {
    @EnvironmentObject var viewModel: ActivePinsViewModel
    @Environment(\.displaySharedView) var displaySharedView
    
    var body: some View {
        // ⭐️ 1. NavigationStack에 .toolbar를 적용합니다.
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.activePins.isEmpty {
                    EmptyStateView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(Array(viewModel.activePins.enumerated()), id: \.element.id) { index, pin in
                            PinListRow(pin: pin, onDelete: {
                                viewModel.removePin(at: IndexSet(integer: index))
                            })
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("핀 대시보드") // VStack에도 적용 가능 (선택)
            // ⭐️ 2. .toolbar를 NavigationStack 레벨로 이동
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
            PinEditorView(onCommit: displaySharedView)
                .environmentObject(viewModel)
        }
    }
}

// MARK: - Helper Views (변경 없음)
private struct PinListRow: View {
    let pin: Pin
    var onDelete: () -> Void
    private var endDate: Date { pin.creationDate.addingTimeInterval(28800) }

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
            Button(action: { withAnimation(.spring()) { onDelete() } }) {
                Image(systemName: "minus.circle.fill").font(.title2).foregroundColor(.red)
            }.buttonStyle(.plain)
        }.padding(.vertical, 4)
    }
}
private struct EmptyStateView: View {
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
