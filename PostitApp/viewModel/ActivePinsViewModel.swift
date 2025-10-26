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

    // Pin 추가 및 LA 시작 (⭐️ 수정된 버전)
    @discardableResult
    // ⭐️ 1. 함수를 async로 변경
    func addPin(processedContent: ProcessedContent) async -> Activity<PinActivityAttributes>? {
        
        // ⭐️ 2. 중복 핀 확인 로직 수정
        if let existingPin = activePins.first(where: { $0.content == processedContent.originalContent }) {
            print("addPin: Duplicate pin found. Re-pinning (End old, Start new).")
            
            // ⭐️ 3. 딕셔너리에서 기존 Activity 찾기
            if let existingActivity = liveActivities[existingPin.id] {
                // ⭐️ 4. Task{}로 감싸지 않고, 'await'로 직접 호출하여 종료를 기다림
                await existingActivity.end(nil, dismissalPolicy: .immediate)
                print("addPin: Successfully ended old activity \(existingActivity.id)")
            }
            
            // ⭐️ 5. ViewModel에서 기존 Pin/Activity 참조 제거
            liveActivities.removeValue(forKey: existingPin.id)
            activePins.removeAll { $0.id == existingPin.id }
        }

        // --- 이하 코드는 신규 핀 추가 로직 ---
        print("addPin: Creating new pin.")
        
        let newPin = Pin(content: processedContent.originalContent, pinType: processedContent.pinType)
        activePins.insert(newPin, at: 0)
        
        guard let activity = LiveActivityService.start(pin: newPin, processedContent: processedContent) else {
            print("addPin: LiveActivityService.start failed.")
            activePins.removeAll { $0.id == newPin.id } // 롤백
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
            // ⭐️ 'addPin'이 async가 되었으므로 'await' 추가
            if let activity = await addPin(processedContent: processed) {
                return .success(activity)
            } else {
                return .failure(.liveActivityStartFailed) // 일반 실패
            }
        case .failure(let error):
            return .failure(error)
        }
    }

    // 앱 내부 핀 삭제 (변경 없음)
    func removePin(at offsets: IndexSet) {
        let pinsToRemove = offsets.compactMap { activePins[$0] }
        activePins.remove(atOffsets: offsets)
        
        for pin in pinsToRemove {
            if let activity = liveActivities[pin.id] {
                Task {
                    await activity.end(nil, dismissalPolicy: .immediate)
                    print("Live Activity가 수동으로 종료되었습니다: \(activity.id)")
                }
                liveActivities.removeValue(forKey: pin.id)
            }
        }
    }
    
    // LA 종료 감지 (변경 없음)
    private func listenForActivityEnd(activity: Activity<PinActivityAttributes>, pinID: UUID) async {
        await ActivityStateObserver(activity: activity).activityStateUpdates()
        
        // Activity가 어떤 이유로든 종료되었을 때 (예: 8시간 만료)
        print("Live Activity가 종료되었습니다 (감지됨): \(activity.id)")
        removePinFromApp(id: pinID)
    }
    
    // LA 종료 시 앱 상태 정리 (변경 없음)
    @MainActor
    private func removePinFromApp(id: UUID) {
        activePins.removeAll { $0.id == id }
        liveActivities.removeValue(forKey: id)
        print("앱 내부 데이터 정리 완료: \(id)")
    }


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
            
            // ⭐️ 'addPin'이 async가 되었으므로 'await' 추가
            let addResult = await addPin(processedContent: processed) // addPin 호출

            if addResult != nil { // 성공 (신규 또는 중복 리셋 성공)
                 print("SharedPinView: addPin returned non-nil activity. Setting state to SUCCESS.")
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    sharedPinProcessingState = .success
                }
                print("SharedPinView: State successfully set to .success")
            } else { // 실패 (LA 시작 실패 등)
                 print("SharedPinView: addPin returned nil. Setting state to ERROR.")
                withAnimation {
                    // ⭐️ String 에러 메시지 사용
                    sharedPinProcessingState = .error(ContentProcessingError.liveActivityStartFailed.localizedDescription)
                    print("SharedPinView: State set to .error because addPin was nil (not a duplicate).")
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
} // ⭐️ ActivePinsViewModel 클래스 끝


// MARK: - ⭐️ ActivityStateObserver (변경 없이 유지) ⭐️
struct ActivityStateObserver {
    let activity: Activity<PinActivityAttributes>

    init(activity: Activity<PinActivityAttributes>) {
        self.activity = activity
    }

    func activityStateUpdates() async {
        for await state in activity.activityStateUpdates {
            if state == .dismissed || state == .ended {
                print("ActivityStateObserver: Activity \(activity.id) is \(state). Stopping observer.")
                return
            }
             print("ActivityStateObserver: Activity \(activity.id) state updated to \(state). Continuing observer.")
        }
         print("ActivityStateObserver: Activity \(activity.id) stream ended.")
    }
}
