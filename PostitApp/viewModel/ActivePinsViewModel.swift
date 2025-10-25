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
    @Published var sharedPinProcessingState: SharedPinProcessingState = .idle
    @Published var processedContentForPreview: ProcessedContent? = nil

    enum SharedPinProcessingState: Equatable {
        case idle, loading, success, error(String)
        // ... (Equatable == 구현 동일) ...
        static func == (lhs: ActivePinsViewModel.SharedPinProcessingState, rhs: ActivePinsViewModel.SharedPinProcessingState) -> Bool {
             switch (lhs, rhs) {
             case (.idle, .idle), (.loading, .loading), (.success, .success): return true
             case let (.error(lMsg), .error(rMsg)): return lMsg == rMsg
             default: return false
             }
         }
        var description: String { /* ... (description 동일) ... */
            switch self {
            case .idle: return "idle"
            case .loading: return "loading"
            case .success: return "success"
            case .error(let msg): return "error(\(msg))"
            }
        }
    }

    // MARK: - Pin & Activity 관리
    // ... (addPin, addPinAndProcess, removePin, listenForActivityEnd, removePinFromApp 변경 없음) ...
    @discardableResult
    func addPin(processedContent: ProcessedContent) -> Activity<PinActivityAttributes>? { /* 이전 코드와 동일 */
        if activePins.contains(where: { $0.content == processedContent.originalContent }) { return nil }
        let newPin = Pin(content: processedContent.originalContent, pinType: processedContent.pinType)
        activePins.insert(newPin, at: 0)
        guard let activity = LiveActivityService.start(pin: newPin, processedContent: processedContent) else {
            activePins.removeAll { $0.id == newPin.id }
            return nil
        }
        liveActivities[newPin.id] = activity
        Task { await listenForActivityEnd(activity: activity, pinID: newPin.id) }
        return activity
    }
    func addPinAndProcess(content: String) async -> Result<Activity<PinActivityAttributes>?, ContentProcessingError> { /* 이전 코드와 동일 */
        let result = await ContentProcessorService.processContent(content)
        switch result {
        case .success(let processed):
            if let activity = addPin(processedContent: processed) { return .success(activity) }
            else { return .failure(.liveActivityStartFailed) }
        case .failure(let error): return .failure(error)
        }
    }
    func removePin(at offsets: IndexSet) { /* 이전 코드와 동일 */
        let pinsToRemove = offsets.map { activePins[$0] }
        Task {
            for pin in pinsToRemove {
                guard let activity = liveActivities[pin.id] else {
                    await MainActor.run { activePins.removeAll { $0.id == pin.id } }
                    continue
                }
                await activity.end(nil, dismissalPolicy: .immediate)
                await MainActor.run {
                    activePins.removeAll { $0.id == pin.id }
                    liveActivities.removeValue(forKey: pin.id)
                }
            }
        }
    }
    private func listenForActivityEnd(activity: Activity<PinActivityAttributes>, pinID: UUID) async { /* 이전 코드와 동일 */
        for await state in activity.activityStateUpdates {
            if state == .dismissed { await removePinFromApp(id: pinID) }
        }
        if activity.activityState != .active { await removePinFromApp(id: pinID) }
    }
    private func removePinFromApp(id: UUID) { /* 이전 코드와 동일 */
        if let index = activePins.firstIndex(where: { $0.id == id }) { activePins.remove(at: index) }
        if liveActivities.removeValue(forKey: id) != nil { print("ViewModel에서 Activity \(id)의 추적을 중지합니다.") }
    }


    // MARK: - Shared Pin 로직 (⭐️ Guard 추가)
    func processAndPinSharedContent(_ content: String) async {
        // ⭐️⭐️⭐️ Guard 추가: 이미 처리 중이거나 완료/에러 상태면 실행하지 않음 ⭐️⭐️⭐️
        guard sharedPinProcessingState == .idle else {
            print("SharedPinView: processAndPinSharedContent skipped. State is already \(sharedPinProcessingState.description)")
            return
        }
        
        print("SharedPinView: processAndPinSharedContent started. Current state: \(sharedPinProcessingState.description)")
        sharedPinProcessingState = .loading
        processedContentForPreview = nil
        print("SharedPinView: State set to loading.")

        let result = await ContentProcessorService.processContent(content)

        switch result {
        case .success(let processed):
            print("SharedPinView: Content processing success.")
            let addResult = addPin(processedContent: processed)

            if addResult != nil {
                 print("SharedPinView: addPin returned non-nil activity. Setting state to SUCCESS.")
                self.processedContentForPreview = processed
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    sharedPinProcessingState = .success
                }
                print("SharedPinView: State successfully set to .success")
            } else {
                 print("SharedPinView: addPin returned nil. Setting state to ERROR.")
                withAnimation {
                    sharedPinProcessingState = .error(ContentProcessingError.liveActivityStartFailed.localizedDescription)
                }
                 print("SharedPinView: State set to .error because addPin was nil.")
            }
        case .failure(let error):
             print("SharedPinView: Content processing failed: \(error.localizedDescription). Setting state to ERROR.")
            withAnimation {
                sharedPinProcessingState = .error(error.localizedDescription)
            }
             print("SharedPinView: State set to .error due to processing failure.")
        }
         print("SharedPinView: processAndPinSharedContent finished. Final state: \(sharedPinProcessingState.description)")
    }
    
    // 상태 초기화 함수 (변경 없음)
    func resetSharedPinProcessingState() {
        print("SharedPinView: resetSharedPinProcessingState called. Setting state to idle.")
        sharedPinProcessingState = .idle
        processedContentForPreview = nil
    }
}
