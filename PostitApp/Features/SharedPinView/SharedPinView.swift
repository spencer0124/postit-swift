// PostitApp/Features/SharedPinView/SharedPinView.swift

import SwiftUI
import UIKit // UINotificationFeedbackGenerator

// MARK: - 공유 완료 화면 UI (ViewModel 로직 분리됨)
struct SharedPinView: View {
    @EnvironmentObject var viewModel: ActivePinsViewModel
    let content: String

    @Environment(\.dismiss) var dismiss

    // 코너 힌트 애니메이션 상태는 View에 유지
    @State private var showCornerHint = false
    @State private var cornerHintAnimating = false

    var body: some View {
        GeometryReader { reader in
            ZStack(alignment: .topLeading) {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

                VStack {
                    Spacer()

                    // --- 상태별 UI 분기 (ViewModel 상태 참조) ---
                    switch viewModel.sharedPinProcessingState {
                    case .idle, .loading:
                        VStack(spacing: 20) {
                            ProgressView()
                            Text("포스트잇 처리 중...")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 100)
                        .padding(.bottom, reader.size.height * 0.7)

                    case .success:
                        VStack(spacing: 10) {
                            SuccessHeaderView()
                            iPhoneMockupView(
                                processedContent: viewModel.processedContentForPreview,
                                reader: reader,
                                isPinVisible: .constant(true)
                            )
                            .frame(maxHeight: reader.size.height * 0.7)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .center)))
                        .onAppear {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            Task {
                                try? await Task.sleep(nanoseconds: 2_800_000_000)
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    showCornerHint = true
                                }
                            }
                        }

                    case .error(let message):
                        VStack(spacing: 10) {
                            ErrorHeaderView(errorMessage: message)
                            Spacer()
                        }
                        .frame(maxHeight: .infinity)
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .center)))
                        .onTapGesture {
                             dismiss()
                        }
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // --- '탭하여 돌아가기' 힌트 ---
                if case .success = viewModel.sharedPinProcessingState, showCornerHint {
                     HStack(spacing: 6) {
                         Image(systemName: "arrow.up.left")
                             .font(.footnote.weight(.bold))
                         Text("사용하던 앱으로 돌아가기")
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
            // --- View가 나타날 때 ViewModel 함수 호출 ---
            .onAppear {
                Task {
                    await viewModel.processAndPinSharedContent(content)
                }
            }
            // --- View가 사라질 때 ViewModel 상태 초기화 ---
            .onDisappear {
                 viewModel.resetSharedPinProcessingState()
            }
        }
    }
}

// --- Helper Views ---
private struct SuccessHeaderView: View {
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
        .frame(height: 100)
    }
}

private struct ErrorHeaderView: View {
    let errorMessage: String

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
        .frame(height: 100)
    }
}

// MARK: - Preview


#Preview("Success State") {
    let successViewModel = ActivePinsViewModel()
    successViewModel.sharedPinProcessingState = .success
    successViewModel.processedContentForPreview = ProcessedContent(
        originalContent: "https://www.apple.com/kr/",
        pinType: .url,
        metadataTitle: "Apple (대한민국) - 미리보기",
        metadataFaviconData: UIImage(systemName: "apple.logo")?.pngData()
    )

    return SharedPinView(content: "https://www.apple.com/kr/")
        .environmentObject(successViewModel)
}
