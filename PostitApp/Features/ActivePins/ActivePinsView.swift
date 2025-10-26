// PostitApp/Features/ActivePins/ActivePinsView.swift

import SwiftUI
import UIKit // ⭐️ UIApplication 사용

struct Tab1View: View {
    @EnvironmentObject var viewModel: ActivePinsViewModel
    @Environment(\.displaySharedView) var displaySharedView
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    
                    // ⭐️ 1. 클립보드 붙여넣기 버튼 (신규)
                    ClipboardPasteButtonDashboard(
                        clipboardPreviewText: $viewModel.clipboardPreviewText,
                        onPaste: {
                            viewModel.pasteFromClipboardToEditor()
                        }
                    )
                    
                    // ⭐️ 2. 기존 콘텐츠
                    if viewModel.activePins.isEmpty {
                        EmptyStateView()
                            .padding(.top, clipboardPreviewIsEmpty ? 100 : 60) // ⭐️ 버튼 유무에 따라 패딩 조정
                    } else {
                        ForEach(Array(viewModel.activePins.enumerated()), id: \.element.id) { index, pin in
                            PinListRow(pin: pin, onDelete: {
                                await viewModel.removePin(at: IndexSet(integer: index))
                            })
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
            .background(Color.clear)
            .navigationTitle("대시보드")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { viewModel.isShowingEditor = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .medium)).foregroundColor(.blue)
                    }
                }
             }
            // ⭐️ 3. ViewModel에 displaySharedView Action 주입
            .onAppear {
                viewModel.displaySharedViewAction = displaySharedView
                viewModel.checkClipboardForDashboard() // ⭐️ 탭 나타날 때 클립보드 확인
            }
            // ⭐️ 4. 앱 활성화 시 클립보드 확인
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                viewModel.checkClipboardForDashboard()
            }
        }
        .sheet(isPresented: $viewModel.isShowingEditor) {
            PinEditorView(onCommit: displaySharedView)
                .environmentObject(viewModel)
        }
    }
    
    // ⭐️ 클립보드 미리보기 버튼 표시 여부 계산 프로퍼티
    private var clipboardPreviewIsEmpty: Bool {
        viewModel.clipboardPreviewText == nil
    }
}

// MARK: - ⭐️ Helper Views (ClipboardPasteButtonDashboard 추가)

// ⭐️ 5. 대시보드용 클립보드 붙여넣기 버튼 (신규)
private struct ClipboardPasteButtonDashboard: View {
    @Binding var clipboardPreviewText: String?
    var onPaste: () -> Void

    var body: some View {
        // clipboardPreviewText가 nil이 아닐 때만 버튼 표시
        if let previewText = clipboardPreviewText {
            Button(action: onPaste) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.on.clipboard") // ⭐️ 아이콘 추가
                        .font(.subheadline.weight(.medium))
                    Text(previewText)
                        .font(.subheadline.weight(.medium)) // ⭐️ 폰트 조정
                        .lineLimit(1)
                    Spacer() // ⭐️ Hstack 내에서 왼쪽 정렬
                }
                .foregroundColor(.blue) // ⭐️ 파란색 텍스트/아이콘
                .padding(14)            // ⭐️ 카드 내부 패딩
                .background(Color(uiColor: .systemBackground)) // ⭐️ 흰색 카드 배경
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // ⭐️ 둥근 모서리
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2) // ⭐️ 은은한 그림자
            }
            .buttonStyle(.plain) // 기본 버튼 스타일 제거
            .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: clipboardPreviewText) // ⭐️ 애니메이션 조정
        }
    }
}


private struct PinListRow: View {
    let pin: Pin
    var onDelete: () async -> Void
    private var endDate: Date { pin.creationDate.addingTimeInterval(8 * 60 * 60) }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                PinRowView(pin: pin)
                HStack(spacing: 4) { Image(systemName: "hourglass").font(.caption2).foregroundColor(.secondary); TimelineView(.periodic(from: .now, by: 1.0)) { _ in Text(endDate, style: .timer).font(.caption.monospacedDigit()).foregroundColor(.secondary).lineLimit(1) } }
            }
            Spacer()
            Button(action: { Task { await onDelete() } }) { Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(Color(uiColor: .systemGray3)) }.buttonStyle(.plain)
        }
        .padding(16).background(Color(uiColor: .systemBackground)).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)).shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) { Image(systemName: "pin.slash").font(.system(size: 40, weight: .medium)).foregroundColor(Color(uiColor: .systemGray3)); Text("고정된 핀이 없어요").font(.title2.weight(.bold)); Text("오른쪽 상단의 + 버튼을 눌러\n새로운 핀을 추가해 보세요.").font(.callout).foregroundColor(.secondary).multilineTextAlignment(.center) }.padding(.bottom, 60)
    }
}

// MARK: - SwiftUI Preview
#Preview {
    Tab1View()
        .environmentObject(ActivePinsViewModel())
}
