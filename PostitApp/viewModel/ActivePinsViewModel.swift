// PostitApp/viewModel/ActivePinsViewModel.swift

import Foundation
import ActivityKit
import SwiftUI
import SwiftData
import UIKit // ⭐️ UIPasteboard 사용

@MainActor
class ActivePinsViewModel: ObservableObject {

    @Published var activePins: [Pin] = []
    @Published var isShowingEditor = false
    
    // ⭐️ 1. 클립보드 미리보기 상태 추가
    @Published var clipboardPreviewText: String? = nil
    
    // ⭐️ 2. displaySharedView Action을 저장할 변수 추가
    // (ContentView의 .environment(\.displaySharedView) 클로저가 여기에 저장됨)
    var displaySharedViewAction: ((String) -> Void)?
    
    private var modelContext: ModelContext?
    private var historyViewModel: HistoryViewModel?
    
    func setHistoryViewModel(_ historyVM: HistoryViewModel) {
        self.historyViewModel = historyVM
    }
    
    func initialize(modelContext: ModelContext) async {
        self.modelContext = modelContext
        
        print("ActivePinsVM: Initializing...")
        
        // 1. 현재 시스템에 떠 있는 모든 LA 목록을 가져옴
        let systemLAs = Activity<PinActivityAttributes>.activities
        let systemLAIDs = Set(systemLAs.map { $0.id })
        print("ActivePinsVM: Found \(systemLAIDs.count) active LAs in system.")

        // 2. DB에서 '활성 상태여야 하는' 핀 목록을 가져옴 (만료되지 않은 핀)
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

        // 3. DB 핀 목록을 기준으로 시스템 LA와 대조
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
        
        // 4. 동기화된 목록을 UI에 최종 반영
        self.activePins = reconciledActivePins
        print("ActivePinsVM: Initialization complete. \(reconciledActivePins.count) pins restored.")
        
        // ⭐️ 초기화 시 클립보드 확인
        checkClipboardForDashboard()
    }
    
    // ⭐️ 3. 대시보드용 클립보드 확인 함수
    func checkClipboardForDashboard() {
        if UIPasteboard.general.hasStrings, let content = UIPasteboard.general.string, !content.isEmpty {
            // 이미 활성 핀에 동일한 내용이 있는지 확인 (선택사항: 중복이면 버튼 숨김)
            // let isAlreadyPinned = activePins.contains { $0.content == content }
            // if !isAlreadyPinned { ... }
            
            let preview = String(content.prefix(20))
            clipboardPreviewText = "'\(preview)\(content.count > 20 ? "..." : "")' 핀하기"
        } else {
            clipboardPreviewText = nil
        }
    }

    // ⭐️ 4. 클립보드 내용으로 Editor 열기 함수
    func pasteFromClipboardToEditor() {
        guard let clipboardContent = UIPasteboard.general.string, !clipboardContent.isEmpty else { return }
        
        // 저장된 displaySharedViewAction을 호출하여 Editor를 엽니다.
        // 이 클로저는 ContentView -> Tab1View -> ViewModel로 주입됩니다.
        displaySharedViewAction?(clipboardContent)
        
        // 붙여넣기 후 미리보기 버튼 숨김
        clipboardPreviewText = nil
    }

    // --- 이하 기존 ViewModel 코드 (변경 없음) ---
    // MARK: - Shared Pin Processing State
    @Published var sharedPinProcessingState: SharedPinProcessingState = .idle
    @Published var processedContentForPreview: ProcessedContent? = nil
    @Published var isProcessingManualPin: Bool = false
    enum SharedPinProcessingState: Equatable {
        case idle, loading, success, error(String)
        static func == (lhs: Self, rhs: Self) -> Bool {
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
    // MARK: - Pin & Activity 관리
    @discardableResult
    func addPin(processedContent: ProcessedContent) async -> Activity<PinActivityAttributes>? {
        guard let modelContext else { print("addPin: ModelContext is nil."); return nil }
        if let existingPin = activePins.first(where: { $0.content == processedContent.originalContent }) {
            print("addPin: Duplicate pin found. Re-pinning (End old, Start new).")
            withAnimation { activePins.removeAll { $0.id == existingPin.id } }
            await existingPin.associatedActivity?.end(nil, dismissalPolicy: .immediate)
            print("addPin: Successfully ended old activity \(existingPin.id)")
            existingPin.creationDate = .now
            existingPin.showInHistoryAt = .now.addingTimeInterval(8 * 60 * 60)
            existingPin.metadataTitle = processedContent.metadataTitle
            existingPin.metadataFaviconData = processedContent.metadataFaviconData
            guard let activity = LiveActivityService.start(pin: existingPin, processedContent: processedContent) else {
                print("addPin: LiveActivityService.start failed for re-pin."); activePins.insert(existingPin, at: 0); return nil
            }
            existingPin.associatedActivity = activity; existingPin.activityID = activity.id
            withAnimation { activePins.insert(existingPin, at: 0) }
            Task { await listenForActivityEnd(activity: activity, pin: existingPin) }
            print("addPin: Successfully re-pinned and updated LA."); return activity
        }
        print("addPin: Creating new pin.")
        let newPin = Pin(content: processedContent.originalContent, pinType: processedContent.pinType, metadataTitle: processedContent.metadataTitle, metadataFaviconData: processedContent.metadataFaviconData, creationDate: .now)
        modelContext.insert(newPin); activePins.insert(newPin, at: 0)
        guard let activity = LiveActivityService.start(pin: newPin, processedContent: processedContent) else {
            print("addPin: LiveActivityService.start failed."); activePins.removeAll { $0.id == newPin.id }; modelContext.delete(newPin); return nil
        }
        newPin.associatedActivity = activity; newPin.activityID = activity.id
        Task { await listenForActivityEnd(activity: activity, pin: newPin) }
        print("addPin: Successfully added pin, inserted to DB, and started LA."); return activity
     }
    func restorePin(_ pin: Pin) async {
        guard modelContext != nil else { print("restorePin: ModelContext is nil."); return }
        print("restorePin: Restoring pin \(pin.id)")
        if let existingActivePin = activePins.first(where: { $0.id == pin.id }) {
            print("RestorePin: Pin is already active. Re-pinning."); await existingActivePin.associatedActivity?.end(nil, dismissalPolicy: .immediate)
        } else { print("RestorePin: Pin is not active. Restoring to active array."); activePins.insert(pin, at: 0) }
        pin.creationDate = .now; pin.showInHistoryAt = .now.addingTimeInterval(8 * 60 * 60)
        let processed = ProcessedContent(originalContent: pin.content, pinType: pin.pinType, metadataTitle: pin.metadataTitle, metadataFaviconData: pin.metadataFaviconData)
        guard let activity = LiveActivityService.start(pin: pin, processedContent: processed) else { print("RestorePin: LiveActivityService.start failed."); return }
        pin.associatedActivity = activity; pin.activityID = activity.id
        Task { await listenForActivityEnd(activity: activity, pin: pin) }; print("RestorePin: Successfully restored pin and started LA.")
     }
    func addPinAndProcess(content: String) async -> Result<Activity<PinActivityAttributes>?, ContentProcessingError> {
        let result = await ContentProcessorService.processContent(content)
        switch result { case .success(let processed): if let activity = await addPin(processedContent: processed) { return .success(activity) } else { return .failure(.liveActivityStartFailed) }; case .failure(let error): return .failure(error) }
     }
    func removePin(at offsets: IndexSet) async {
        let pinsToRemove = offsets.compactMap { activePins[$0] }
        withAnimation(.spring()) { activePins.remove(atOffsets: offsets) }
        for pin in pinsToRemove { pin.showInHistoryAt = .now; print("Pin \(pin.id) moved to history (showInHistoryAt set to now)"); historyViewModel?.fetchHistory(); await pin.associatedActivity?.end(nil, dismissalPolicy: .immediate); print("Live Activity가 수동으로 종료되었습니다: \(pin.id)"); pin.associatedActivity = nil; pin.activityID = nil }
     }
    private func listenForActivityEnd(activity: Activity<PinActivityAttributes>, pin: Pin) async {
        await ActivityStateObserver(activity: activity).activityStateUpdates(); print("Live Activity가 종료되었습니다 (감지됨): \(pin.id)"); removePinFromApp(pin: pin)
     }
    @MainActor
    private func removePinFromApp(pin: Pin) {
        activePins.removeAll { $0.id == pin.id }; pin.showInHistoryAt = .now; print("Pin \(pin.id) moved to history (LA ended/dismissed)"); pin.associatedActivity = nil; pin.activityID = nil; historyViewModel?.fetchHistory(); print("앱 내부 데이터 정리 완료 (In-Memory + DB): \(pin.id)")
     }
    // MARK: - Shared Pin 로직
    func processAndPinSharedContent(_ content: String) async {
        guard !isProcessingManualPin else { print("SharedPinView: processAndPinSharedContent skipped. Already processing."); return }
        isProcessingManualPin = true
        guard sharedPinProcessingState == .idle || sharedPinProcessingState == .loading else { print("SharedPinView: processAndPinSharedContent started unexpectedly when state was \(sharedPinProcessingState.description). Resetting flag and exiting."); isProcessingManualPin = false; return }
        print("SharedPinView: processAndPinSharedContent started. Current state: \(sharedPinProcessingState.description)"); sharedPinProcessingState = .loading; processedContentForPreview = nil; print("SharedPinView: State set to loading.")
        let result = await ContentProcessorService.processContent(content)
        guard isProcessingManualPin else { print("SharedPinView: Processing flag became false during content processing. Aborting state update."); return }
        switch result { case .success(let processed): print("SharedPinView: Content processing success."); self.processedContentForPreview = processed; let addResult = await addPin(processedContent: processed); if addResult != nil { print("SharedPinView: addPin returned non-nil activity. Setting state to SUCCESS."); withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { sharedPinProcessingState = .success }; print("SharedPinView: State successfully set to .success") } else { print("SharedPinView: addPin returned nil. Setting state to ERROR."); withAnimation { sharedPinProcessingState = .error(ContentProcessingError.liveActivityStartFailed.localizedDescription); print("SharedPinView: State set to .error because addPin was nil (not a duplicate).") } } case .failure(let error): print("SharedPinView: Content processing failed: \(error.localizedDescription). Setting state to ERROR."); withAnimation { sharedPinProcessingState = .error(error.localizedDescription) }; print("SharedPinView: State set to .error due to processing failure.") }
        print("SharedPinView: processAndPinSharedContent finished. Final state: \(sharedPinProcessingState.description)")
     }
    func resetSharedPinProcessingState() {
        print("SharedPinView: resetSharedPinProcessingState called. Setting state to idle."); sharedPinProcessingState = .idle; processedContentForPreview = nil; isProcessingManualPin = false; print("SharedPinView: isProcessingManualPin reset to false.")
     }
}
// MARK: - ActivityStateObserver
struct ActivityStateObserver {
    let activity: Activity<PinActivityAttributes>; init(activity: Activity<PinActivityAttributes>) { self.activity = activity }
    func activityStateUpdates() async { for await state in activity.activityStateUpdates { if state == .dismissed || state == .ended { print("ActivityStateObserver: Activity \(activity.id) is \(state). Stopping observer."); return }; print("ActivityStateObserver: Activity \(activity.id) state updated to \(state). Continuing observer.") }; print("ActivityStateObserver: Activity \(activity.id) stream ended.") }
}
