//
//  PinEditorView.swift
//  postit
//
//  Created by SeungYong on 10/20/25.
//

import SwiftUI

struct PinEditorView: View {
    // ViewModel은 EnvironmentObject로 받습니다.
    @EnvironmentObject var viewModel: ActivePinsViewModel
    
    // 텍스트 입력을 위한 상태 변수
    @State private var text: String = ""
    // 에러 메시지를 표시하기 위한 상태 변수
    @State private var errorMessage: String?
    // 로딩 상태를 표시하기 위한 상태 변수
    @State private var isLoading: Bool = false
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                // 텍스트 입력 필드
                TextEditor(text: $text) // Use TextEditor for multi-line input
                    .frame(height: 150) // Adjust height as needed
                    .border(Color.gray.opacity(0.2), width: 1)
                    .padding()
                
                // 에러 메시지 표시
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("새 포스트잇")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    // 로딩 중이면 버튼 비활성화
                    Button("고정") {
                        // ★★★ 수정된 부분 ★★★
                        // 'addPinAndProcess' 함수를 비동기적으로 호출합니다.
                        Task {
                            isLoading = true // 로딩 시작
                            errorMessage = nil // 이전 에러 메시지 초기화
                            
                            let result = await viewModel.addPinAndProcess(content: text)
                            
                            isLoading = false // 로딩 종료
                            
                            switch result {
                            case .success:
                                dismiss() // 성공 시 뷰 닫기
                            case .failure(let error):
                                errorMessage = error.localizedDescription // 실패 시 에러 메시지 표시
                            }
                        }
                    }
                    .disabled(isLoading || text.isEmpty) // 로딩 중이거나 텍스트가 비어있으면 비활성화
                }
            }
            // 로딩 인디케이터 오버레이
            .overlay {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                        .tint(.primary)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

// Preview
#Preview {
    PinEditorView()
        .environmentObject(ActivePinsViewModel())
}
