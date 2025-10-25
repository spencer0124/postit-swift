//
//  PinEditorView.swift
//  postit
//
//  Created by SeungYong on 10/20/25.
//

import SwiftUI

struct PinEditorView: View {
    let onCommit: (String) -> Void
    // ⭐️ viewModel 참조는 유지 (isShowingEditor 제어용)
    @EnvironmentObject var viewModel: ActivePinsViewModel
    @State private var text: String = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $text)
                    .frame(height: 150)
                    .border(Color.gray.opacity(0.2), width: 1)
                    .padding()
                Spacer()
            }
            .navigationTitle("새 포스트잇")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        // 취소 시에는 dismiss 또는 viewModel 상태 변경
                        viewModel.isShowingEditor = false
                        // dismiss() // 직접 dismiss 대신 viewModel 상태 변경 사용 권장
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("고정") {
                        // ⭐️ onCommit만 호출 (dismiss 없음)
                        onCommit(text)
                    }
                    .disabled(text.isEmpty)
                }
            }
        }
    }
}

// Preview
#Preview {
    PinEditorView(onCommit: { content in print("Preview Commit: \(content)") })
        .environmentObject(ActivePinsViewModel())
}
