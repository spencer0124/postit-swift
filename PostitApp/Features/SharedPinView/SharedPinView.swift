//
//  SharedPinView.swift
//  postit
//
//  Created by SeungYong on 10/20/25.
//

import SwiftUI
import UIKit // UIPasteboard를 사용하기 위해 import

// MARK: - 공유 완료 화면 UI (모듈화 + 상태 분기)
struct SharedPinView: View {
    @EnvironmentObject var viewModel: ActivePinsViewModel
    let content: String

    @Environment(\.dismiss) var dismiss

    // --- UI 상태를 관리하는 Enum ---
    enum ProcessingState {
        case idle // 초기 상태
        case loading // 처리 중
        case success // 성공
        case error(String) // 실패 (에러 메시지 포함)
    }

    // --- 상태 변수 ---
    @State private var processingState: ProcessingState = .idle
    @State private var processedContent: ProcessedContent? = nil // 처리된 결과 저장

    @State private var showCornerHint = false
    @State private var cornerHintAnimating = false

    var body: some View {
        GeometryReader { reader in
            ZStack(alignment: .topLeading) {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

                VStack {
                    Spacer()

                    // --- 상태별 UI 분기 ---
                    switch processingState {
                    case .idle, .loading:
                        VStack(spacing: 20) { // 로딩 상태 UI 개선
                            ProgressView()
                            Text("포스트잇 처리 중...")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 100) // 헤더 높이와 맞춤
                        // 로딩 중에는 목업 자리를 비워둡니다.
                        // 화면 크기에 따라 목업 높이가 달라지므로, 패딩을 사용합니다.
                        .padding(.bottom, reader.size.height * 0.7)


                    case .success:
                        // --- 성공 UI ---
                        VStack(spacing: 10) {
                            SuccessHeaderView() // 성공 헤더
                            // 성공 시에만 목업 표시, 처리된 결과 전달
                            iPhoneMockupView(
                                processedContent: processedContent, // <- 여기가 중요!
                                reader: reader,
                                isPinVisible: .constant(true)
                            )
                            // 목업이 남은 공간을 차지하도록 유연한 높이 설정
                            .frame(maxHeight: reader.size.height * 0.7)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .center)))

                    case .error(let message):
                        // --- 실패 UI ---
                        VStack(spacing: 10) {
                            ErrorHeaderView(errorMessage: message) // 실패 헤더
                            // 실패 시 목업은 보여주지 않음
                            Spacer() // 에러 메시지가 중앙에 오도록 Spacer 추가
                        }
                        .frame(maxHeight: .infinity) // 전체 높이 사용
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .center)))
                    }

                    Spacer() // 하단 정렬용 Spacer 제거 (VStack이 중앙 정렬되도록)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // VStack이 전체 공간 차지

                // --- '탭하여 돌아가기' 힌트 (성공 시에만 표시) ---
                if case .success = processingState, showCornerHint {
                     HStack(spacing: 6) {
                         Image(systemName: "arrow.up.left")
                             .font(.footnote.weight(.bold))
                         Text("사용하던 앱으로 돌아가기") // 텍스트 수정
                             .font(.caption.bold())
                     }
                     .foregroundColor(.secondary)
                     .padding(.vertical, 8)
                     .padding(.horizontal, 12)
                     .background(Color(uiColor: .systemGray5))
                     .clipShape(Capsule())
                     .offset(x: cornerHintAnimating ? -5 : 5)
                     .transition(.opacity.animation(.easeIn))
                     .padding(.leading, 12)
                     .padding(.top, 12)
                     .onAppear {
                         withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                             cornerHintAnimating.toggle()
                         }
                     }
                }
            }
            .onAppear(perform: processAndPinContent)
        }
        // 하단 Safe Area 무시 제거 (전체 화면 사용)
        // .ignoresSafeArea(.container, edges: .bottom)
    }

    // --- 콘텐츠 처리 및 Pin 추가 로직 ---
    private func processAndPinContent() {
        // 이미 처리 중이면 중복 실행 방지
//        guard processingState == ProcessingState.idle else { return } // <- 'ProcessingState.' 추가

        processingState = .loading // 로딩 상태 시작

        Task {
            // 1. ContentProcessorService 호출
            let result = await ContentProcessorService.processContent(content)

            switch result {
            case .success(let processed):
                // 2. 처리 성공 시, ViewModel에 Pin 추가 (LA 시작)
                if viewModel.addPin(processedContent: processed) != nil {
                    // 3. LA 시작 성공 시
                    self.processedContent = processed // 결과 저장 for 목업
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        processingState = .success // 성공 UI 표시
                    }
                    UINotificationFeedbackGenerator().notificationOccurred(.success) // 햅틱

                    // 4. 성공 애니메이션 후 돌아가기 힌트 표시
                    try? await Task.sleep(nanoseconds: 2_800_000_000) // 2.8초 대기
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showCornerHint = true
                    }
                } else {
                    // LA 시작 실패 시
                    withAnimation {
                        processingState = .error(ContentProcessingError.liveActivityStartFailed.localizedDescription)
                    }
                }

            case .failure(let error):
                // 처리 실패 시
                withAnimation {
                    processingState = .error(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - 성공/실패 헤더 뷰 (★★★ 코드 추가 ★★★)
private struct SuccessHeaderView: View {
    // 이제 View 프로토콜을 따릅니다.
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48, weight: .bold))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.green, Color(uiColor: .systemGray4))
            Text("알림센터에 저장했어요")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(height: 100) // 고정 높이
    }
}

private struct ErrorHeaderView: View {
    // 이제 View 프로토콜을 따릅니다.
    let errorMessage: String // errorMessage를 받도록 수정

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 48, weight: .bold))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.red, Color(uiColor: .systemGray4))
            Text("오류 발생")
                .font(.headline)
                .foregroundColor(.secondary)
            Text(errorMessage)
                .font(.caption)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(height: 100) // 고정 높이
    }
}

// MARK: - 아이폰 목업 뷰 (별도 파일 또는 여기에 포함)
// iPhoneMockupView.swift 파일이 따로 있다면 이 부분은 삭제해야 합니다.
// struct iPhoneMockupView: View { ... }

// --- PinContentView는 별도 공유 파일로 있어야 합니다 ---
// struct PinContentView: View { ... }

// MARK: - Preview (변경 없음)
// ...
#Preview {
    SharedPinView(content: "Apple Park 방문객을 위한 새로운 경험")
        .environmentObject(ActivePinsViewModel())
}
