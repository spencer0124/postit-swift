// PostitApp/Features/SharedPinView/SharedPinView.swift

import SwiftUI
import UIKit

struct SharedPinView: View {
    @EnvironmentObject var viewModel: ActivePinsViewModel
    let content: String
    let source: SourceType

    @Environment(\.dismiss) var dismiss
    @State private var showCornerHint = false
    @State private var cornerHintAnimating = false

    var body: some View {
        GeometryReader { reader in
            ZStack(alignment: .bottom) {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

                // --- 메인 콘텐츠 VStack ---
                VStack {
                    Spacer()
                    switch viewModel.sharedPinProcessingState {
                    case .idle, .loading:
                        VStack(spacing: 20) {
                            ProgressView()
                            Text("포스트잇 처리 중...").font(.headline).foregroundColor(.secondary)
                        }.frame(height: 100)
                         .padding(.bottom, reader.size.height * (source == .manualAdd ? 0.6 : 0.7))

                    case .success:
                        VStack(spacing: 10) {
                            SuccessHeaderView()
                            iPhoneMockupView(
                                processedContent: viewModel.processedContentForPreview,
                                reader: reader,
                                isPinVisible: .constant(true)
                            ).frame(maxHeight: reader.size.height * 0.7)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .center)))
                        .onAppear {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            if source == .shareSheet {
                                Task {
                                    try? await Task.sleep(nanoseconds: 2_800_000_000)
                                    withAnimation(.easeInOut(duration: 0.5)) { showCornerHint = true }
                                }
                            }
                        }

                    case .error(let message):
                        VStack(spacing: 10) {
                            ErrorHeaderView(errorMessage: message)
                            Spacer()
                        }.frame(maxHeight: .infinity)
                         .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .center)))
                         .onTapGesture { dismiss() }
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, (viewModel.sharedPinProcessingState == .success || viewModel.sharedPinProcessingState.isError) && source == .manualAdd ? 80 : 0)

                // --- Group으로 감싸기 (Conditional UI) ---
                Group {
                    if source == .shareSheet && viewModel.sharedPinProcessingState == .success && showCornerHint {
                         HStack(spacing: 6) { /* ... 코너 힌트 ... */
                             Image(systemName: "arrow.up.left").font(.footnote.weight(.bold))
                             Text("사용하던 앱으로 돌아가기").font(.caption.bold())
                         }
                         .foregroundColor(.secondary).padding(.vertical, 8).padding(.horizontal, 12)
                         .background(Color(uiColor: .systemGray5)).clipShape(Capsule())
                         .offset(x: cornerHintAnimating ? -5 : 5).transition(.opacity.animation(.easeIn))
                         .padding(.leading, 12).padding(.top, 12)
                         .onAppear { withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { cornerHintAnimating.toggle() } }
                         .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                    }
                    else if source == .manualAdd && (viewModel.sharedPinProcessingState == .success || viewModel.sharedPinProcessingState.isError) {
                         Button { dismiss() } label: { /* ... 확인 버튼 ... */
                             Text("확인")
                                 .font(.headline.weight(.semibold)).foregroundColor(.white)
                                 .frame(maxWidth: .infinity).padding().background(Color.blue).cornerRadius(15)
                         }
                         .padding(.horizontal).padding(.bottom, 30)
                         .transition(.move(edge: .bottom).combined(with: .opacity))
                         .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                    else { EmptyView() }
                } // --- Group 끝 ---
            } // ZStack 끝
            .onAppear {
                print("SharedPinView: onAppear called.") // ⭐️ onAppear 로그
                Task { await viewModel.processAndPinSharedContent(content) }
            }
            .onDisappear {
                 print("SharedPinView: onDisappear called. Resetting state.") // ⭐️ onDisappear 로그
                 viewModel.resetSharedPinProcessingState()
            }
        } // GeometryReader 끝
    } // body 끝
} // SharedPinView 끝

// ViewModel State Enum helper (변경 없음)
extension ActivePinsViewModel.SharedPinProcessingState {
    var isError: Bool { if case .error = self { return true }; return false }
}
// Equatable conformance (변경 없음)
// extension ActivePinsViewModel.SharedPinProcessingState: Equatable {} // ViewModel에서 직접 채택


// --- Helper Views (변경 없음) ---
// ... SuccessHeaderView, ErrorHeaderView ...
private struct SuccessHeaderView: View { /*...*/
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 48, weight: .bold)).symbolRenderingMode(.palette).foregroundStyle(.green, Color(uiColor: .systemGray4))
            Text("알림센터에 저장했어요").font(.headline).foregroundColor(.secondary)
        }.frame(height: 100)
    }
}
private struct ErrorHeaderView: View { /*...*/
    let errorMessage: String
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "xmark.circle.fill").font(.system(size: 48, weight: .bold)).symbolRenderingMode(.palette).foregroundStyle(.red, Color(uiColor: .systemGray4))
            Text("오류 발생").font(.headline).foregroundColor(.secondary)
            Text(errorMessage).font(.caption).foregroundColor(.red).multilineTextAlignment(.center).padding(.horizontal)
        }.frame(height: 100)
    }
}


// MARK: - Preview (주석 처리 유지 또는 수정)
/*
#Preview("Success State (Share Sheet)") { ... }
#Preview("Success State (Manual Add)") { ... }
#Preview("Error State (Manual Add)") { ... }
*/
