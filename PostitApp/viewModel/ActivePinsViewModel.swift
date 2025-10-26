// PostitApp/viewModel/ActivePinsViewModel.swift

import Foundation
import ActivityKit
import SwiftUI
import SwiftData // 1. Import

@MainActor
class ActivePinsViewModel: ObservableObject {

    @Published var activePins: [Pin] = [] // 활성 핀 (In-Memory)
    @Published var isShowingEditor = false
    
    // ⭐️ 2. modelContext를 저장할 프라이빗 변수
    private var modelContext: ModelContext?
    
    // ⭐️ 3. modelContext를 주입받는 함수
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        // TODO: 앱 실행 시 활성화된 LA가 있다면 여기서 로드
    }
    
    // ⭐️ 4. liveActivities 딕셔너리 제거
    // (이제 Pin.associatedActivity 사용)

    // MARK: - Shared Pin Processing State
    @Published var sharedPinProcessingState: SharedPinProcessingState = .idle
    @Published var processedContentForPreview: ProcessedContent? = nil
    @Published var isProcessingManualPin: Bool = false

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
    func addPin(processedContent: ProcessedContent) async -> Activity<PinActivityAttributes>? {
        
        // ⭐️ 5. modelContext 가드
        guard let modelContext else {
            print("addPin: ModelContext is nil.")
            return nil
        }
        
        // ⭐️ 6. 중복 핀 확인 로직 수정 (DB 객체 업데이트)
        if let existingPin = activePins.first(where: { $0.content == processedContent.originalContent }) {
            print("addPin: Duplicate pin found. Re-pinning (End old, Start new).")
            
            // 6-1. 기존 LA 종료 (await)
            await existingPin.associatedActivity?.end(nil, dismissalPolicy: .immediate)
            print("addPin: Successfully ended old activity \(existingPin.id)")

            // 6-2. ⭐️ (DB) 기존 Pin 객체 데이터 업데이트
            existingPin.creationDate = .now
            existingPin.showInHistoryAt = .now.addingTimeInterval(8 * 60 * 60) // 8시간
            existingPin.metadataTitle = processedContent.metadataTitle
            existingPin.metadataFaviconData = processedContent.metadataFaviconData
            
            // 6-3. 새 LA 시작
            guard let activity = LiveActivityService.start(pin: existingPin, processedContent: processedContent) else {
                print("addPin: LiveActivityService.start failed for re-pin.")
                return nil
            }
            
            // 6-4. (In-Memory) 새 Activity 연결
            existingPin.associatedActivity = activity
            Task { await listenForActivityEnd(activity: activity, pin: existingPin) } // ⭐️ pin 객체 전달
            
            print("addPin: Successfully re-pinned and updated LA.")
            return activity
        }

        // --- ⭐️ 7. 신규 핀 추가 로직 (DB Insert) ---
        print("addPin: Creating new pin.")
        
        // 7-1. (DB) 새 Pin 객체 생성 (메타데이터 포함)
        let newPin = Pin(
            content: processedContent.originalContent,
            pinType: processedContent.pinType,
            metadataTitle: processedContent.metadataTitle,
            metadataFaviconData: processedContent.metadataFaviconData,
            creationDate: .now
        )
        
        // 7-2. ⭐️ (DB) modelContext에 삽입
        modelContext.insert(newPin)
        
        // 7-3. (In-Memory) 활성 핀 배열에 추가
        activePins.insert(newPin, at: 0)
        
        // 7-4. LA 시작
        guard let activity = LiveActivityService.start(pin: newPin, processedContent: processedContent) else {
            print("addPin: LiveActivityService.start failed.")
            // 롤백
            activePins.removeAll { $0.id == newPin.id }
            modelContext.delete(newPin) // ⭐️ DB 롤백
            return nil
        }
        
        // 7-5. (In-Memory) Activity 연결
        newPin.associatedActivity = activity
        Task { await listenForActivityEnd(activity: activity, pin: newPin) } // ⭐️ pin 객체 전달
        
        print("addPin: Successfully added pin, inserted to DB, and started LA.")
        return activity
    }
    
    // ⭐️ 8. '다시 핀하기' (Restore) 함수 추가
    func restorePin(_ pin: Pin) async {
        guard modelContext != nil else {
            print("restorePin: ModelContext is nil.")
            return
        }

        print("restorePin: Restoring pin \(pin.id)")
        
        // 8-1. 핀이 이미 활성 상태인지 확인
        if let existingActivePin = activePins.first(where: { $0.id == pin.id }) {
            // 이미 활성 상태면, 중복 핀 처리와 동일하게 LA만 갱신
            print("RestorePin: Pin is already active. Re-pinning.")
            await existingActivePin.associatedActivity?.end(nil, dismissalPolicy: .immediate)
        } else {
            // 활성 상태가 아니면, 활성 핀 배열에 추가
            print("RestorePin: Pin is not active. Restoring to active array.")
            activePins.insert(pin, at: 0)
        }
        
        // 8-2. (DB) 핀의 시간 갱신 (보관함 -> 활성)
        pin.creationDate = .now
        pin.showInHistoryAt = .now.addingTimeInterval(8 * 60 * 60)
        
        // 8-3. ProcessedContent 재구성 (DB 데이터 사용)
        let processed = ProcessedContent(
            originalContent: pin.content,
            pinType: pin.pinType,
            metadataTitle: pin.metadataTitle,
            metadataFaviconData: pin.metadataFaviconData
        )
        
        // 8-4. LA 시작 및 연결
        guard let activity = LiveActivityService.start(pin: pin, processedContent: processed) else {
            print("RestorePin: LiveActivityService.start failed.")
            return
        }
        pin.associatedActivity = activity
        Task { await listenForActivityEnd(activity: activity, pin: pin) }
        print("RestorePin: Successfully restored pin and started LA.")
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

    // ⭐️ 9. 앱 내부 핀 삭제 (수동) (DB Update 로직)
    func removePin(at offsets: IndexSet) {
        let pinsToRemove = offsets.compactMap { activePins[$0] }
        
        // 9-1. (In-Memory) 배열에서 먼저 제거
        activePins.remove(atOffsets: offsets)
        
        for pin in pinsToRemove {
            // 9-2. ⭐️ (DB) "보여줄 시점"을 즉시로 업데이트
            pin.showInHistoryAt = .now
            print("Pin \(pin.id) moved to history (showInHistoryAt set to now)")
            
            // 9-3. LA 종료
            Task {
                await pin.associatedActivity?.end(nil, dismissalPolicy: .immediate)
                print("Live Activity가 수동으로 종료되었습니다: \(pin.id)")
            }
            pin.associatedActivity = nil
        }
    }
    
    // ⭐️ 10. LA 종료 감지 (시그니처 변경)
    private func listenForActivityEnd(activity: Activity<PinActivityAttributes>, pin: Pin) async {
        await ActivityStateObserver(activity: activity).activityStateUpdates()
        
        // Activity가 어떤 이유로든 종료되었을 때 (예: 8시간 만료)
        print("Live Activity가 종료되었습니다 (감지됨): \(pin.id)")
        removePinFromApp(pin: pin)
    }
    
    // ⭐️ 11. LA 종료 시 앱 상태 정리 (DB 작업 불필요)
    @MainActor
    private func removePinFromApp(pin: Pin) {
        // (In-Memory) 활성 배열에서만 제거
        activePins.removeAll { $0.id == pin.id }
        pin.associatedActivity = nil
        
        // ⭐️ (DB) 작업 필요 없음. showInHistoryAt 시간이 자연 도래함.
        print("앱 내부 데이터 정리 완료 (In-Memory): \(pin.id)")
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
        // activity.activityStateUpdates는 AsyncStream<ActivityState> 타입입니다.
        // for await...in 루프를 사용해 상태 변경을 감시합니다.
        for await state in activity.activityStateUpdates {
            // Activity가 종료되거나(ended) 사용자에 의해 해제되면(dismissed) 루프를 종료합니다.
            if state == .dismissed || state == .ended {
                print("ActivityStateObserver: Activity \(activity.id) is \(state). Stopping observer.")
                return
            }
             print("ActivityStateObserver: Activity \(activity.id) state updated to \(state). Continuing observer.")
        }
        
        // 만약 스트림이 다른 이유로 종료되면 (예: Activity 자체가 파괴됨)
        // 이 지점에 도달할 수 있습니다.
         print("ActivityStateObserver: Activity \(activity.id) stream ended.")
    }
}
