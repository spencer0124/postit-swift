// PostitApp/Features/SharedPinView/SharedPinView.swift

import SwiftUI
import UIKit

struct SharedPinView: View {
    @EnvironmentObject var viewModel: ActivePinsViewModel
    let content: String
    let source: SourceType

    @Environment(\.dismiss) var dismiss
    // navigateToDashboard는 최대 개수 초과 시에만 필요하므로,
    // 이 롤백 버전에서는 제거해도 무방합니다. 필요하면 다시 추가하겠습니다.
    // @Environment(\.navigateToDashboard) var navigateToDashboard

    @State private var showCornerHint = false
    @State private var cornerHintAnimating = false
    @State private var isPinVisibleForMockup = false

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
                                isPinVisible: $isPinVisibleForMockup
                            ).frame(maxHeight: reader.size.height * 0.7)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .center)))
                        .onAppear {
                            withAnimation(.spring().delay(0.2)) { isPinVisibleForMockup = true }
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            if source == .shareSheet {
                                Task {
                                    try? await Task.sleep(nanoseconds: 2_800_000_000)
                                    withAnimation(.easeInOut(duration: 0.5)) { showCornerHint = true }
                                }
                            }
                        }

                    // 에러 케이스 (String 메시지, 버튼 없음)
                    case .error(let message):
                        VStack(spacing: 10) {
                            ErrorHeaderView(errorMessage: message) // 메시지만 표시
                            Spacer()
                        }.frame(maxHeight: .infinity)
                         .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .center)))
                         .onTapGesture { dismiss() } // 탭하면 닫기
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // 확인 버튼 영역만큼 하단 패딩 (성공/오류 & 수동 추가 시)
                .padding(.bottom, (viewModel.sharedPinProcessingState == .success || viewModel.sharedPinProcessingState.isError) && source == .manualAdd ? 80 : 0)

                // --- ⭐️ Group: 코너 힌트 또는 하단 확인 버튼 (복구된 코드) ---
                Group {
                    // 조건 1: Share Sheet 성공 시 코너 힌트
                    if source == .shareSheet && viewModel.sharedPinProcessingState == .success && showCornerHint {
                         HStack(spacing: 6) {
                             Image(systemName: "arrow.up.left").font(.footnote.weight(.bold))
                             Text("사용하던 앱으로 돌아가기").font(.caption.bold())
                         }
                         .foregroundColor(.secondary)
                         .padding(.vertical, 8).padding(.horizontal, 12)
                         .background(Color(uiColor: .systemGray5))
                         .clipShape(Capsule())
                         .offset(x: cornerHintAnimating ? -5 : 5)
                         .transition(.opacity.animation(.easeIn))
                         .padding(.leading, 12).padding(.top, 12)
                         .onAppear {
                             withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                                 cornerHintAnimating.toggle()
                             }
                         }
                         // ZStack 내에서 상단 좌측 정렬
                         .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                    }
                    // 조건 2: Manual Add 성공 또는 에러 시 확인 버튼
                    else if source == .manualAdd && (viewModel.sharedPinProcessingState == .success || viewModel.sharedPinProcessingState.isError) {
                         Button { dismiss() } label: {
                             Text("확인")
                                 .font(.headline.weight(.semibold))
                                 .foregroundColor(.white)
                                 .frame(maxWidth: .infinity)
                                 .padding()
                                 .background(Color.blue)
                                 .cornerRadius(15)
                         }
                         .padding(.horizontal)
                         .padding(.bottom, 30) // 하단 여백
                         .transition(.move(edge: .bottom).combined(with: .opacity))
                         // ZStack 내에서 하단 정렬
                         .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                    // 조건 3: 그 외의 경우
                    else {
                         EmptyView() // 아무것도 표시하지 않음
                    }
                } // --- Group 끝 ---
            } // ZStack 끝
            // ⭐️ onAppear에서 processAndPinSharedContent 호출 (롤백된 버전 확인)
            .onAppear { Task { await viewModel.processAndPinSharedContent(content) } }
//            .onDisappear { viewModel.resetSharedPinProcessingState() }
        } // GeometryReader 끝
    } // body 끝
} // SharedPinView 끝

// ViewModel State Enum helper (isError 확인)
extension ActivePinsViewModel.SharedPinProcessingState {
    var isError: Bool { if case .error = self { return true }; return false }
}
// Equatable conformance (ViewModel에서 처리)


// --- Helper Views (변경 없음) ---
private struct SuccessHeaderView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 48, weight: .bold)).symbolRenderingMode(.palette).foregroundStyle(.green, Color(uiColor: .systemGray4))
            Text("알림센터에 저장했어요").font(.headline).foregroundColor(.secondary)
        }.frame(height: 100)
    }
}
private struct ErrorHeaderView: View {
    let errorMessage: String
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "xmark.circle.fill").font(.system(size: 48, weight: .bold)).symbolRenderingMode(.palette).foregroundStyle(.red, Color(uiColor: .systemGray4))
            Text("오류 발생").font(.headline).foregroundColor(.secondary)
            Text(errorMessage).font(.caption).foregroundColor(.red).multilineTextAlignment(.center).padding(.horizontal)
        }.frame(height: 100)
    }
}

// MARK: - Preview (주석 처리 또는 수정)
/*
#Preview("Success State (Share Sheet)") { ... }
#Preview("Success State (Manual Add)") { ... }
#Preview("Error State (Manual Add)") { ... }
*/
