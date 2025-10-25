// PostitApp/viewModel/ActivePinsViewModel.swift

import Foundation
import ActivityKit
import SwiftUI

@MainActor
class ActivePinsViewModel: ObservableObject {

    @Published var activePins: [Pin] = []
    @Published var isShowingEditor = false

    private var liveActivities: [UUID: Activity<PinActivityAttributes>] = [:]

    // MARK: - Shared Pin Processing State
    // SharedPinView가 관찰할 상태 변수들 추가
    @Published var sharedPinProcessingState: SharedPinProcessingState = .idle
    @Published var processedContentForPreview: ProcessedContent? = nil // 미리보기용 처리 결과 저장

    // SharedPinView의 상태를 정의하는 Enum (기존 SharedPinView에서 가져옴)
    enum SharedPinProcessingState {
        case idle // 초기 상태
        case loading // 처리 중
        case success // 성공
        case error(String) // 실패 (에러 메시지 포함)
    }

    // ProcessedContent를 받아서 Pin 추가 및 LA 시작 (핵심 함수)
    @discardableResult
    func addPin(processedContent: ProcessedContent) -> Activity<PinActivityAttributes>? {
        if activePins.contains(where: { $0.content == processedContent.originalContent }) {
            return nil // 중복 방지
        }

        let newPin = Pin(
            content: processedContent.originalContent,
            pinType: processedContent.pinType

        )
        activePins.insert(newPin, at: 0)

        // LA 시작 (처리된 메타데이터 포함)
        guard let activity = LiveActivityService.start(pin: newPin, processedContent: processedContent) else {
            activePins.removeAll { $0.id == newPin.id } // 롤백
            return nil
        }

        liveActivities[newPin.id] = activity
        Task { await listenForActivityEnd(activity: activity, pinID: newPin.id) }

        return activity
    }

    // --- 직접 입력 시 호출될 함수 (수정됨) ---
    // ContentProcessorService를 호출하도록 변경
    func addPinAndProcess(content: String) async -> Result<Activity<PinActivityAttributes>?, ContentProcessingError> {
        // 1. 입력된 content 처리 시도
        let result = await ContentProcessorService.processContent(content)

        switch result {
        case .success(let processed):
            // 2. 처리 성공 시 Pin 추가 및 LA 시작
            if let activity = addPin(processedContent: processed) {
                return .success(activity) // 성공 시 Activity 반환
            } else {
                return .failure(.liveActivityStartFailed) // LA 시작 실패
            }
        case .failure(let error):
            // 처리 실패 시 에러 반환
            return .failure(error)
        }
    }

    // --- Shared Pin 처리 로직 함수 추가 ---
    // SharedPinView의 processAndPinContent 로직을 이 함수로 이동
    func processAndPinSharedContent(_ content: String) async {
        // 이미 처리 중이면 중복 실행 방지 (선택 사항)
        // guard sharedPinProcessingState == .idle else { return }

        sharedPinProcessingState = .loading // 로딩 상태 시작
        processedContentForPreview = nil // 이전 미리보기 내용 초기화

        // 1. ContentProcessorService 호출
        let result = await ContentProcessorService.processContent(content)

        switch result {
        case .success(let processed):
            // 2. 처리 성공 시, Pin 추가 및 LA 시작 (기존 addPin 호출)
            if addPin(processedContent: processed) != nil {
                // 3. LA 시작 성공 시
                self.processedContentForPreview = processed // 결과 저장 for 목업
                // @MainActor 함수 내에서는 Main Thread 보장되므로 withAnimation 바로 사용 가능
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    sharedPinProcessingState = .success // 성공 UI 표시
                }
                // 햅틱 피드백은 View에서 처리하는 것이 더 적합할 수 있음 (선택 사항)
                // UINotificationFeedbackGenerator().notificationOccurred(.success)

                // 성공 상태를 잠시 보여준 후 자동으로 닫히게 하려면 여기에 Task.sleep 추가 가능
                // try? await Task.sleep(nanoseconds: 3_000_000_000) // 3초 대기
                // dismiss() // ViewModel에서는 dismiss 직접 호출 불가, View에서 처리해야 함

            } else {
                // LA 시작 실패 시
                withAnimation {
                    sharedPinProcessingState = .error(ContentProcessingError.liveActivityStartFailed.localizedDescription)
                }
            }

        case .failure(let error):
            // 처리 실패 시
            withAnimation {
                sharedPinProcessingState = .error(error.localizedDescription)
            }
        }
    }

    // SharedPinView가 닫힐 때 상태 초기화하는 함수 (선택 사항)
    func resetSharedPinProcessingState() {
        sharedPinProcessingState = .idle
        processedContentForPreview = nil
    }


    // --- 나머지 함수 (변경 없음) ---
    private func listenForActivityEnd(activity: Activity<PinActivityAttributes>, pinID: UUID) async { /* ... */ }
    @MainActor private func removePinFromApp(id: UUID) { /* ... */ }
    func removePin(at offsets: IndexSet) { /* ... */ }
}
