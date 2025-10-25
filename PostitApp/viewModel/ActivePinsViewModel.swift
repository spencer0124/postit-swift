// PostitApp/viewModel/ActivePinsViewModel.swift

import Foundation
import ActivityKit
import SwiftUI

@MainActor
class ActivePinsViewModel: ObservableObject {

    @Published var activePins: [Pin] = []
    @Published var isShowingEditor = false // isShowingEditor 사용
    private var liveActivities: [UUID: Activity<PinActivityAttributes>] = [:]

    // MARK: - Shared Pin Processing State
    @Published var sharedPinProcessingState: SharedPinProcessingState = .idle
    @Published var processedContentForPreview: ProcessedContent? = nil
    @Published var isProcessingManualPin: Bool = false // 중복 실행 방지 플래그

    // Equatable 직접 채택, 에러는 String
    enum SharedPinProcessingState: Equatable {
        case idle, loading, success, error(String) // ⭐️ 에러는 String

        static func == (lhs: ActivePinsViewModel.SharedPinProcessingState, rhs: ActivePinsViewModel.SharedPinProcessingState) -> Bool {
             switch (lhs, rhs) {
             case (.idle, .idle), (.loading, .loading), (.success, .success): return true
             case let (.error(lMsg), .error(rMsg)): return lMsg == rMsg // 에러 메시지 비교
             default: return false
             }
         }
        var description: String {
            switch self {
            case .idle: return "idle"
            case .loading: return "loading"
            case .success: return "success"
            case .error(let msg): return "error(\(msg))" // String 사용
            }
        }
    }

    // MARK: - Pin & Activity 관리 (addPin 함수 사용)

    // Pin 추가 및 LA 시작 (롤백 버전)
    @discardableResult
    func addPin(processedContent: ProcessedContent) -> Activity<PinActivityAttributes>? {
        if activePins.contains(where: { $0.content == processedContent.originalContent }) {
            print("addPin: Pin already exists.")
            return nil
        }
        let newPin = Pin(content: processedContent.originalContent, pinType: processedContent.pinType)
        activePins.insert(newPin, at: 0) // ⭐️ 먼저 추가 (롤백 로직 필요)
        guard let activity = LiveActivityService.start(pin: newPin, processedContent: processedContent) else {
            print("addPin: LiveActivityService.start failed.")
            activePins.removeAll { $0.id == newPin.id } // ⭐️ 롤백
            return nil
        }
        liveActivities[newPin.id] = activity
        Task { await listenForActivityEnd(activity: activity, pinID: newPin.id) }
        print("addPin: Successfully added pin and started LA.")
        return activity
    }

    // ContentProcessorService 호출 (addPin 사용)
    func addPinAndProcess(content: String) async -> Result<Activity<PinActivityAttributes>?, ContentProcessingError> {
        let result = await ContentProcessorService.processContent(content)
        switch result {
        case .success(let processed):
            if let activity = addPin(processedContent: processed) {
                return .success(activity)
            } else {
                return .failure(.liveActivityStartFailed) // 일반 실패
            }
        case .failure(let error):
            return .failure(error)
        }
    }

    // 앱 내부 핀 삭제 (변경 없음)
    func removePin(at offsets: IndexSet) { /* ... 이전 코드와 동일 ... */ }
    // LA 종료 감지 (변경 없음)
    private func listenForActivityEnd(activity: Activity<PinActivityAttributes>, pinID: UUID) async { /* ... 이전 코드와 동일 ... */ }
    // LA 종료 시 앱 상태 정리 (변경 없음)
    private func removePinFromApp(id: UUID) { /* ... 이전 코드와 동일 ... */ }


    // MARK: - Shared Pin 로직 (isProcessingManualPin 플래그 사용, String 에러)
    func processAndPinSharedContent(_ content: String) async {
        guard !isProcessingManualPin else {
            print("SharedPinView: processAndPinSharedContent skipped. Already processing.")
            return
        }
        isProcessingManualPin = true

        guard sharedPinProcessingState == .idle || sharedPinProcessingState == .loading else {
            print("SharedPinView: processAndPinSharedContent started unexpectedly when state was \(sharedPinProcessingState.description). Resetting flag and exiting.")
            isProcessingManualPin = false
            return
        }

        print("SharedPinView: processAndPinSharedContent started. Current state: \(sharedPinProcessingState.description)")
        sharedPinProcessingState = .loading
        processedContentForPreview = nil
        print("SharedPinView: State set to loading.")

        let result = await ContentProcessorService.processContent(content)

        guard isProcessingManualPin else {
             print("SharedPinView: Processing flag became false during content processing. Aborting state update.")
             return
        }

        switch result {
        case .success(let processed):
            print("SharedPinView: Content processing success.")
            self.processedContentForPreview = processed // 미리보기 설정 먼저
            let addResult = addPin(processedContent: processed) // addPin 호출

            if addResult != nil { // 성공
                 print("SharedPinView: addPin returned non-nil activity. Setting state to SUCCESS.")
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    sharedPinProcessingState = .success
                }
                print("SharedPinView: State successfully set to .success")
            } else { // 실패 (중복 또는 LA 시작 실패)
                 print("SharedPinView: addPin returned nil. Setting state to ERROR or SUCCESS (if duplicate).")
                withAnimation {
                    // ⭐️ 중복인지 activePins 배열로 다시 확인 (addPin에서 nil 반환했어도 배열엔 있을 수 있음)
                    if activePins.contains(where: {$0.content == processed.originalContent }) {
                         print("SharedPinView: Pin already exists, showing success anyway for manual add flow.")
                         // self.processedContentForPreview = processed // 이미 위에서 설정됨
                         withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                             sharedPinProcessingState = .success // 중복도 성공으로 처리
                         }
                         print("SharedPinView: State set to .success (duplicate treated as success)")
                    } else {
                        // 중복이 아니면 LA 시작 실패
                        // ⭐️ String 에러 메시지 사용
                        sharedPinProcessingState = .error(ContentProcessingError.liveActivityStartFailed.localizedDescription)
                        print("SharedPinView: State set to .error because addPin was nil (not a duplicate).")
                    }
                }
            }
        case .failure(let error): // 콘텐츠 처리 실패
             print("SharedPinView: Content processing failed: \(error.localizedDescription). Setting state to ERROR.")
            withAnimation {
                // ⭐️ String 에러 메시지 사용
                sharedPinProcessingState = .error(error.localizedDescription)
            }
             print("SharedPinView: State set to .error due to processing failure.")
        }
         print("SharedPinView: processAndPinSharedContent finished. Final state: \(sharedPinProcessingState.description)")
    }

    // 상태 초기화 함수 (isProcessingManualPin 플래그 리셋 포함)
    func resetSharedPinProcessingState() {
        print("SharedPinView: resetSharedPinProcessingState called. Setting state to idle.")
        sharedPinProcessingState = .idle
        processedContentForPreview = nil
        isProcessingManualPin = false // 플래그 리셋
        print("SharedPinView: isProcessingManualPin reset to false.")
    }
}

