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
    
    // ⭐️ 3. setModelContext -> initialize (async)
    // 앱 실행 시 DB와 시스템 LA 목록을 동기화(Reconcile)합니다.
    func initialize(modelContext: ModelContext) async {
        self.modelContext = modelContext
        
        print("ActivePinsVM: Initializing...")
        
        // 1. 현재 시스템에 떠 있는 모든 LA 목록을 가져옴
        let systemLAs = Activity<PinActivityAttributes>.activities
        let systemLAIDs = Set(systemLAs.map { $0.id })
        print("ActivePinsVM: Found \(systemLAIDs.count) active LAs in system.")

        // 2. DB에서 '활성 상태여야 하는' 핀 목록을 가져옴 (만료되지 않은 핀)
        
        // ⭐️ [오류 수정] #Predicate 매크로 밖에서 'now' 값을 캡처
        let now = Date.now
        let predicate = #Predicate<Pin> { $0.showInHistoryAt > now } // 캡처한 'now' 변수 사용
        
        let sort = SortDescriptor(\Pin.creationDate, order: .reverse)
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [sort])
        
        guard let dbActivePins = try? modelContext.fetch(descriptor) else {
            print("ActivePinsVM: Failed to fetch active pins from DB.")
            return
        }
        print("ActivePinsVM: Found \(dbActivePins.count) 'active' pins in DB.")
        
        var reconciledActivePins: [Pin] = []

        // 3. DB 핀 목록을 기준으로 시스템 LA와 대조
        for pin in dbActivePins {
            // 3-1. DB에 activityID가 있고, 시스템 LA 목록에도 해당 ID가 존재하는가?
            guard let activityID = pin.activityID,
                  systemLAIDs.contains(activityID),
                  let activity = systemLAs.first(where: { $0.id == activityID })
            else {
                // 3-2. (동기화) DB에는 '활성'이어야 한다고 되어있지만,
                //      실제 LA가 없음 (앱이 꺼진 사이 만료/삭제됨)
                print("ActivePinsVM: Reconciling pin \(pin.id). LA not found. Moving to history.")
                pin.showInHistoryAt = .now // 보관함으로 이동
                pin.activityID = nil
                continue // 활성 핀 목록에 추가하지 않음
            }
            
            // 3-3. (동기화) 유효한 LA를 찾음.
            print("ActivePinsVM: Reconciling pin \(pin.id). LA found. Restoring to dashboard.")
            pin.associatedActivity = activity // (In-Memory) LA 연결
            reconciledActivePins.append(pin) // (In-Memory) 활성 핀 배열에 추가
            
            // 3-4. ⭐️ 이 LA의 종료 이벤트를 다시 감지 시작
            Task {
                await listenForActivityEnd(activity: activity, pin: pin)
            }
        }
        
        // 4. 동기화된 목록을 UI에 최종 반영
        self.activePins = reconciledActivePins
        print("ActivePinsVM: Initialization complete. \(reconciledActivePins.count) pins restored.")
    }

    // MARK: - Shared Pin Processing State
    @Published var sharedPinProcessingState: SharedPinProcessingState = .idle
    @Published var processedContentForPreview: ProcessedContent? = nil
    @Published var isProcessingManualPin: Bool = false

    // Equatable 직접 채택, 에러는 String
    enum SharedPinProcessingState: Equatable {
        // ... (내용 변경 없음) ...
        case idle, loading, success, error(String)

        static func == (lhs: ActivePinsViewModel.SharedPinProcessingState, rhs: ActivePinsViewModel.SharedPinProcessingState) -> Bool {
             switch (lhs, rhs) {
             case (.idle, .idle), (.loading, .loading), (.success, .success): return true
             case let (.error(lMsg), .error(rMsg)): return lMsg == rMsg
             default: return false
             }
         }
        var description: String {
            switch self {
            case .idle: return "idle"
            case .loading: return "loading"
            case .success: return "success"
            case .error(let msg): return "error(\(msg))"
            }
        }
    }

    // MARK: - Pin & Activity 관리 (addPin 함수 사용)

    // Pin 추가 및 LA 시작 (변경 없음)
    @discardableResult
    func addPin(processedContent: ProcessedContent) async -> Activity<PinActivityAttributes>? {
        
        guard let modelContext else {
            print("addPin: ModelContext is nil.")
            return nil
        }
        
        if let existingPin = activePins.first(where: { $0.content == processedContent.originalContent }) {
            print("addPin: Duplicate pin found. Re-pinning (End old, Start new).")
            
            await existingPin.associatedActivity?.end(nil, dismissalPolicy: .immediate)
            print("addPin: Successfully ended old activity \(existingPin.id)")

            existingPin.creationDate = .now
            existingPin.showInHistoryAt = .now.addingTimeInterval(8 * 60 * 60)
            existingPin.metadataTitle = processedContent.metadataTitle
            existingPin.metadataFaviconData = processedContent.metadataFaviconData
            
            guard let activity = LiveActivityService.start(pin: existingPin, processedContent: processedContent) else {
                print("addPin: LiveActivityService.start failed for re-pin.")
                return nil
            }
            
            existingPin.associatedActivity = activity
            existingPin.activityID = activity.id
            
            Task { await listenForActivityEnd(activity: activity, pin: existingPin) }
            
            print("addPin: Successfully re-pinned and updated LA.")
            return activity
        }

        print("addPin: Creating new pin.")
        
        let newPin = Pin(
            content: processedContent.originalContent,
            pinType: processedContent.pinType,
            metadataTitle: processedContent.metadataTitle,
            metadataFaviconData: processedContent.metadataFaviconData,
            creationDate: .now
        )
        
        modelContext.insert(newPin)
        activePins.insert(newPin, at: 0)
        
        guard let activity = LiveActivityService.start(pin: newPin, processedContent: processedContent) else {
            print("addPin: LiveActivityService.start failed.")
            activePins.removeAll { $0.id == newPin.id }
            modelContext.delete(newPin)
            return nil
        }
        
        newPin.associatedActivity = activity
        newPin.activityID = activity.id
        
        Task { await listenForActivityEnd(activity: activity, pin: newPin) }
        
        print("addPin: Successfully added pin, inserted to DB, and started LA.")
        return activity
    }
    
    // '다시 핀하기' (Restore) 함수 (변경 없음)
    func restorePin(_ pin: Pin) async {
        guard modelContext != nil else {
            print("restorePin: ModelContext is nil.")
            return
        }

        print("restorePin: Restoring pin \(pin.id)")
        
        if let existingActivePin = activePins.first(where: { $0.id == pin.id }) {
            print("RestorePin: Pin is already active. Re-pinning.")
            await existingActivePin.associatedActivity?.end(nil, dismissalPolicy: .immediate)
        } else {
            print("RestorePin: Pin is not active. Restoring to active array.")
            activePins.insert(pin, at: 0)
        }
        
        pin.creationDate = .now
        pin.showInHistoryAt = .now.addingTimeInterval(8 * 60 * 60)
        
        let processed = ProcessedContent(
            originalContent: pin.content,
            pinType: pin.pinType,
            metadataTitle: pin.metadataTitle,
            metadataFaviconData: pin.metadataFaviconData
        )
        
        guard let activity = LiveActivityService.start(pin: pin, processedContent: processed) else {
            print("RestorePin: LiveActivityService.start failed.")
            return
        }
        pin.associatedActivity = activity
        pin.activityID = activity.id
        
        Task { await listenForActivityEnd(activity: activity, pin: pin) }
        print("RestorePin: Successfully restored pin and started LA.")
    }


    // ContentProcessorService 호출 (addPin 사용) (변경 없음)
    func addPinAndProcess(content: String) async -> Result<Activity<PinActivityAttributes>?, ContentProcessingError> {
        let result = await ContentProcessorService.processContent(content)
        switch result {
        case .success(let processed):
            if let activity = await addPin(processedContent: processed) {
                return .success(activity)
            } else {
                return .failure(.liveActivityStartFailed)
            }
        case .failure(let error):
            return .failure(error)
        }
    }

    // ⭐️ 9. [문제 1 수정] 앱 내부 핀 삭제 (async 함수로 변경)
    func removePin(at offsets: IndexSet) async { // ⭐️ async
        let pinsToRemove = offsets.compactMap { activePins[$0] }
        
        // 9-1. (In-Memory) 배열에서 먼저 제거
        activePins.remove(atOffsets: offsets)
        
        for pin in pinsToRemove {
            // 9-2. ⭐️ (DB) "보여줄 시점"을 즉시로 업데이트
            pin.showInHistoryAt = .now
            print("Pin \(pin.id) moved to history (showInHistoryAt set to now)")
            
            // 9-3. ⭐️ LA 종료 (Task 래퍼 제거, 직접 await)
            await pin.associatedActivity?.end(nil, dismissalPolicy: .immediate)
            print("Live Activity가 수동으로 종료되었습니다: \(pin.id)")
            
            pin.associatedActivity = nil
            pin.activityID = nil // ⭐️ DB의 Activity ID 제거
        }
    }
    
    // 10. LA 종료 감지 (변경 없음)
    private func listenForActivityEnd(activity: Activity<PinActivityAttributes>, pin: Pin) async {
        await ActivityStateObserver(activity: activity).activityStateUpdates()
        
        // Activity가 어떤 이유로든 종료되었을 때 (예: 8시간 만료 / 스와이프)
        print("Live Activity가 종료되었습니다 (감지됨): \(pin.id)")
        removePinFromApp(pin: pin)
    }
    
    // ⭐️ 11. [문제 2 수정] LA 종료 시 앱 상태 정리 (DB에 보관함 이동 로직 추가)
    @MainActor
    private func removePinFromApp(pin: Pin) {
        // (In-Memory) 활성 배열에서만 제거
        activePins.removeAll { $0.id == pin.id }
        
        // ⭐️ (DB) [FIX] LA가 스와이프로 종료되어도 보관함에 즉시 표시되도록 시간 업데이트
        pin.showInHistoryAt = .now
        print("Pin \(pin.id) moved to history (LA ended/dismissed)")

        pin.associatedActivity = nil
        pin.activityID = nil
        
        print("앱 내부 데이터 정리 완료 (In-Memory + DB): \(pin.id)")
    }


    // MARK: - Shared Pin 로직 (변경 없음)
    func processAndPinSharedContent(_ content: String) async {
        // ... (내용 변경 없음) ...
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
            self.processedContentForPreview = processed
            
            let addResult = await addPin(processedContent: processed)

            if addResult != nil {
                 print("SharedPinView: addPin returned non-nil activity. Setting state to SUCCESS.")
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    sharedPinProcessingState = .success
                }
                print("SharedPinView: State successfully set to .success")
            } else {
                 print("SharedPinView: addPin returned nil. Setting state to ERROR.")
                withAnimation {
                    sharedPinProcessingState = .error(ContentProcessingError.liveActivityStartFailed.localizedDescription)
                    print("SharedPinView: State set to .error because addPin was nil (not a duplicate).")
                }
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
        // ... (내용 변경 없음) ...
        print("SharedPinView: resetSharedPinProcessingState called. Setting state to idle.")
        sharedPinProcessingState = .idle
        processedContentForPreview = nil
        isProcessingManualPin = false
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
