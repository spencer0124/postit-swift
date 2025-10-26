// PostitApp/viewModel/ActivePinsViewModel.swift

import Foundation
import ActivityKit
import SwiftUI
import SwiftData // 1. Import

@MainActor
class ActivePinsViewModel: ObservableObject {

    @Published var activePins: [Pin] = [] // 활성 핀 (In-Memory)
    @Published var isShowingEditor = false
    
    private var modelContext: ModelContext?
    
    // ⭐️ [문제 2 수정] HistoryViewModel 참조 추가
    private var historyViewModel: HistoryViewModel?
    
    // ⭐️ [문제 2 수정] HistoryViewModel 주입 함수
    func setHistoryViewModel(_ historyVM: HistoryViewModel) {
        self.historyViewModel = historyVM
    }
    
    // ⭐️ initialize (async)
    func initialize(modelContext: ModelContext) async {
        // ... (내용 변경 없음) ...
        self.modelContext = modelContext
        
        print("ActivePinsVM: Initializing...")
        
        let systemLAs = Activity<PinActivityAttributes>.activities
        let systemLAIDs = Set(systemLAs.map { $0.id })
        print("ActivePinsVM: Found \(systemLAIDs.count) active LAs in system.")

        let now = Date.now
        let predicate = #Predicate<Pin> { $0.showInHistoryAt > now }
        
        let sort = SortDescriptor(\Pin.creationDate, order: .reverse)
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [sort])
        
        guard let dbActivePins = try? modelContext.fetch(descriptor) else {
            print("ActivePinsVM: Failed to fetch active pins from DB.")
            return
        }
        print("ActivePinsVM: Found \(dbActivePins.count) 'active' pins in DB.")
        
        var reconciledActivePins: [Pin] = []

        for pin in dbActivePins {
            guard let activityID = pin.activityID,
                  systemLAIDs.contains(activityID),
                  let activity = systemLAs.first(where: { $0.id == activityID })
            else {
                print("ActivePinsVM: Reconciling pin \(pin.id). LA not found. Moving to history.")
                pin.showInHistoryAt = .now
                pin.activityID = nil
                continue
            }
            
            print("ActivePinsVM: Reconciling pin \(pin.id). LA found. Restoring to dashboard.")
            pin.associatedActivity = activity
            reconciledActivePins.append(pin)
            
            Task {
                await listenForActivityEnd(activity: activity, pin: pin)
            }
        }
        
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

    // Pin 추가 및 LA 시작 (⭐️ [문제 1 수정])
    @discardableResult
    func addPin(processedContent: ProcessedContent) async -> Activity<PinActivityAttributes>? {
        
        guard let modelContext else {
            print("addPin: ModelContext is nil.")
            return nil
        }
        
        // ⭐️ 6. [문제 1 수정] 중복 핀 로직
        if let existingPin = activePins.first(where: { $0.content == processedContent.originalContent }) {
            print("addPin: Duplicate pin found. Re-pinning (End old, Start new).")
            
            // ⭐️ 6-1. [FIX] (In-Memory) 배열에서 *먼저* 제거
            withAnimation {
                activePins.removeAll { $0.id == existingPin.id }
            }
            
            // 6-2. 기존 LA 종료 (await)
            await existingPin.associatedActivity?.end(nil, dismissalPolicy: .immediate)
            print("addPin: Successfully ended old activity \(existingPin.id)")

            // 6-3. (DB) 기존 Pin 객체 데이터 업데이트
            existingPin.creationDate = .now
            existingPin.showInHistoryAt = .now.addingTimeInterval(8 * 60 * 60)
            existingPin.metadataTitle = processedContent.metadataTitle
            existingPin.metadataFaviconData = processedContent.metadataFaviconData
            
            // 6-4. 새 LA 시작
            guard let activity = LiveActivityService.start(pin: existingPin, processedContent: processedContent) else {
                print("addPin: LiveActivityService.start failed for re-pin.")
                // 롤백: 제거했던 핀을 다시 배열에 돌려놓음 (안전 장치)
                activePins.insert(existingPin, at: 0)
                return nil
            }
            
            // 6-5. (In-Memory) 새 Activity 연결
            existingPin.associatedActivity = activity
            existingPin.activityID = activity.id // ⭐️ DB에 Activity ID 저장
            
            // ⭐️ 6-6. [FIX] (In-Memory) 배열 *맨 위에* 다시 추가
            withAnimation {
                activePins.insert(existingPin, at: 0)
            }
            
            Task { await listenForActivityEnd(activity: activity, pin: existingPin) }
            
            print("addPin: Successfully re-pinned and updated LA.")
            return activity
        }

        // --- 7. 신규 핀 추가 로직 (변경 없음) ---
        print("addPin: Creating new pin.")
        
        let newPin = Pin(
            content: processedContent.originalContent,
            pinType: processedContent.pinType,
            metadataTitle: processedContent.metadataTitle,
            metadataFaviconData: processedContent.metadataFaviconData,
            creationDate: .now
        )
        
        modelContext.insert(newPin)
        activePins.insert(newPin, at: 0) // ⭐️ 신규 추가는 기본으로 0번에 insert
        
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

    // ⭐️ 9. 앱 내부 핀 삭제 (수동) (⭐️ [문제 2 수정])
    func removePin(at offsets: IndexSet) async { // async
        let pinsToRemove = offsets.compactMap { activePins[$0] }
        
        // 9-1. (In-Memory) 배열에서 제거 (애니메이션 적용)
        withAnimation(.spring()) {
            activePins.remove(atOffsets: offsets)
        }
        
        for pin in pinsToRemove {
            // 9-2. (DB) "보여줄 시점"을 즉시로 업데이트
            pin.showInHistoryAt = .now
            print("Pin \(pin.id) moved to history (showInHistoryAt set to now)")
            
            // 9-3. ⭐️ [FIX] HistoryViewModel에 새로고침 요청
            historyViewModel?.fetchHistory()
            
            // 9-4. LA 종료 (직접 await)
            await pin.associatedActivity?.end(nil, dismissalPolicy: .immediate)
            print("Live Activity가 수동으로 종료되었습니다: \(pin.id)")
            
            pin.associatedActivity = nil
            pin.activityID = nil
        }
    }
    
    // 10. LA 종료 감지 (변경 없음)
    private func listenForActivityEnd(activity: Activity<PinActivityAttributes>, pin: Pin) async {
        await ActivityStateObserver(activity: activity).activityStateUpdates()
        
        // Activity가 어떤 이유로든 종료되었을 때 (예: 8시간 만료 / 스와이프)
        print("Live Activity가 종료되었습니다 (감지됨): \(pin.id)")
        removePinFromApp(pin: pin)
    }
    
    // ⭐️ 11. LA 종료 시 앱 상태 정리 (⭐️ [문제 2 수정])
    @MainActor
    private func removePinFromApp(pin: Pin) {
        // (In-Memory) 활성 배열에서만 제거
        activePins.removeAll { $0.id == pin.id }
        
        // (DB) [FIX] LA가 스와이프로 종료되어도 보관함에 즉시 표시되도록 시간 업데이트
        pin.showInHistoryAt = .now
        print("Pin \(pin.id) moved to history (LA ended/dismissed)")

        pin.associatedActivity = nil
        pin.activityID = nil
        
        // ⭐️ [FIX] HistoryViewModel에 새로고침 요청
        historyViewModel?.fetchHistory()
        
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
