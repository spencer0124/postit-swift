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
    
    // ⭐️ 1. 자동 포커스를 위한 FocusState
    @FocusState private var isEditorFocused: Bool

    // ⭐️ 2. 토스 스타일의 기본 배경색
    var screenBackground: Color = Color(uiColor: .systemGroupedBackground)

    var body: some View {
        ZStack {
            // ⭐️ 3. 배경색을 ZStack의 맨 뒤에 배치
            screenBackground.ignoresSafeArea()

            // ⭐️ 4. 키보드를 피하는 메인 VStack
            VStack(spacing: 0) {
                // 4-1. 헤더 (토스 스타일)
                HeaderView {
                    viewModel.isShowingEditor = false
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // 4-2. 텍스트 에디터 카드 (토스 스타일)
                TextEditorCardView(text: $text, isEditorFocused: $isEditorFocused)
                    .padding(.horizontal, 16)
                    .padding(.top, 8) // 헤더와의 간격

                Spacer() // ⭐️ 버튼을 하단으로 밀어내는 Spacer

                // 4-3. 하단 버튼 (토스 스타일)
                BottomButton(text: $text, onCommit: onCommit)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16) // ⭐️ 하단 Safe Area 여백
            }
        }
        .onAppear {
            // ⭐️ 5. 뷰가 나타나면 0.5초 후 자동으로 키보드 올리기
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isEditorFocused = true
            }
        }
    }
}

// MARK: - ⭐️ Helper Views (토스 스타일로 수정됨)

private struct HeaderView: View {
    var onCancel: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            // ⭐️ 1. 과감한 타이틀
            Text("새 핀")
                .font(.title.weight(.bold))
            
            Spacer()
            
            // ⭐️ 2. X 버튼 (배경색 변경)
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary.opacity(0.8))
                    .padding(10) // ⭐️ 탭 영역 확장
                    .background(Color(uiColor: .systemGray5))
                    .clipShape(Circle())
            }
        }
    }
}

// ⭐️ 3. 텍스트 에디터 카드 뷰 (신규)
private struct TextEditorCardView: View {
    @Binding var text: String
    var isEditorFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 3-1. 카드 소제목
            Text("무엇을 핀할까요?")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)

            // 3-2. 텍스트 에디터
            TextEditor(text: $text)
                .focused(isEditorFocused) // ⭐️ FocusState 바인딩
                .font(.body)
                .frame(height: 150)
                .tint(.blue) // ⭐️ 커서 색상
                .scrollContentBackground(.hidden) // ⭐️ TextEditor 기본 배경 제거
        }
        .padding(16) // ⭐️ 카드 내부 패딩
        .background(Color(uiColor: .systemBackground)) // ⭐️ 흰색 카드 배경
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // ⭐️ 둥근 모서리
    }
}


private struct BottomButton: View {
    @Binding var text: String
    let onCommit: (String) -> Void
    
    // ⭐️ 부드러운 스프링 애니메이션
    private let animation = Animation.spring(response: 0.3, dampingFraction: 0.7)

    var body: some View {
        Button {
            onCommit(text)
        } label: {
            Text("고정")
                .font(.headline.weight(.bold)) // ⭐️ 폰트 굵게
                // ⭐️ 비활성 상태 명확하게
                .foregroundColor(text.isEmpty ? .white.opacity(0.7) : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16) // ⭐️ 패딩 조정
                // ⭐️ 비활성 상태 명확하게
                .background(text.isEmpty ? Color.blue.opacity(0.4) : Color.blue)
                // ⭐️ 카드와 동일한 모서리 반경
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(text.isEmpty)
        .animation(animation, value: text.isEmpty)
    }
}


// Preview
#Preview {
    PinEditorView(onCommit: { content in print("Preview Commit: \(content)") })
        .environmentObject(ActivePinsViewModel())
}
