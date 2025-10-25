//
//  PinEditorView.swift
//  postit
//
//  Created by SeungYong on 10/20/25
//

import SwiftUI

struct PinEditorView: View {
    let onCommit: (String) -> Void
    @EnvironmentObject var viewModel: ActivePinsViewModel
    @State private var text: String = ""

    // ⭐️ 1. 'private' 제거
    var screenBackground: Color = Color(uiColor: .systemGroupedBackground)

    var body: some View {
        ZStack(alignment: .bottom) {
            screenBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Use the HeaderView (now not private)
                HeaderView {
                    viewModel.isShowingEditor = false
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 15)

                TextEditor(text: $text)
                    .frame(height: 150)
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal)

                Spacer()
            }

            // Use the BottomButton (now not private)
            BottomButton(text: $text, onCommit: onCommit)
                .padding(.horizontal)
                .padding(.bottom)
        }
//        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// MARK: - Helper Views (private removed)

struct HeaderView: View {
    var onCancel: () -> Void

    var body: some View {
        HStack {
            Text("새 핀")
                .font(.headline.weight(.semibold))
            Spacer()
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(8)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }
        }
    }
}

struct BottomButton: View {
    @Binding var text: String
    let onCommit: (String) -> Void

    var body: some View {
        Button {
            onCommit(text)
        } label: {
            Text("고정")
                .font(.headline.weight(.semibold))
                .foregroundColor(text.isEmpty ? .white.opacity(0.5) : .white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(text.isEmpty ? Color.blue.opacity(0.5) : Color.blue)
                .cornerRadius(15)
        }
        .disabled(text.isEmpty)
        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
    }
}


// Preview
#Preview {
    PinEditorView(onCommit: { content in print("Preview Commit: \(content)") })
        .environmentObject(ActivePinsViewModel())
}
