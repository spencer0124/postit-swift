// PostitApp/viewModel/ActivePinsViewModel.swift

import Foundation
import ActivityKit
import SwiftUI

@MainActor
class ActivePinsViewModel: ObservableObject {

    @Published var activePins: [Pin] = []
    @Published var isShowingEditor = false

    // ⭐️ 1. LA 관리를 위해 [Pin.ID: Activity] 딕셔너리 사용
    private var liveActivities: [UUID: Activity<PinActivityAttributes>] = [:]

    // MARK: - Shared Pin Processing State
    @Published var sharedPinProcessingState: SharedPinProcessingState = .idle
    @Published var processedContentForPreview: ProcessedContent? = nil

    enum SharedPinProcessingState {
        case idle, loading, success, error(String)
    }

    // MARK: - Pin & Activity 관리 (핵심 로직)

    @discardableResult
    func addPin(processedContent: ProcessedContent) -> Activity<PinActivityAttributes>? {
        if activePins.contains(where: { $0.content == processedContent.originalContent }) {
            return nil
        }

        let newPin = Pin(
            content: processedContent.originalContent,
            pinType: processedContent.pinType
        )
        activePins.insert(newPin, at: 0)

        guard let activity = LiveActivityService.start(pin: newPin, processedContent: processedContent) else {
            activePins.removeAll { $0.id == newPin.id }
            return nil
        }

        // ⭐️ 2. 생성된 Activity를 핀의 ID와 함께 저장
        liveActivities[newPin.id] = activity
        
        // ⭐️ 3. LA가 종료되는지 감시 시작 (스와이프 등)
        Task { await listenForActivityEnd(activity: activity, pinID: newPin.id) }

        return activity
    }

    func addPinAndProcess(content: String) async -> Result<Activity<PinActivityAttributes>?, ContentProcessingError> {
        let result = await ContentProcessorService.processContent(content)

        switch result {
        case .success(let processed):
            if let activity = addPin(processedContent: processed) {
                return .success(activity)
            } else {
                return .failure(.liveActivityStartFailed)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // --- ⭐️ 4. [수정됨] 앱 (대시보드)에서 핀을 삭제할 때 호출되는 함수 ---
    func removePin(at offsets: IndexSet) {
        // 1. 삭제할 핀들을 가져옵니다.
        let pinsToRemove = offsets.map { activePins[$0] }
        
        Task {
            for pin in pinsToRemove {
                // 2. 핀 ID로 추적 중인 Live Activity를 찾습니다.
                guard let activity = liveActivities[pin.id] else {
                    print("삭제할 핀(\(pin.id))에 해당하는 Live Activity를 찾을 수 없습니다.")
                    // LA가 없더라도 앱에서는 삭제되어야 하므로 MainActor에서 UI 업데이트
                    await MainActor.run {
                        activePins.removeAll { $0.id == pin.id }
                    }
                    continue // 다음 핀으로
                }
                
                // 3. 찾은 Live Activity를 즉시 종료시킵니다.
                await activity.end(nil, dismissalPolicy: .immediate)
                print("Live Activity \(activity.id)가 앱에서 종료되었습니다.")
                
                // 4. 앱 UI(activePins)와 추적 딕셔너리(liveActivities)에서 제거합니다.
                //    (이 작업은 removePinFromApp에서도 호출되지만, 여기서 선제적으로 수행)
                await MainActor.run {
                    activePins.removeAll { $0.id == pin.id }
                    liveActivities.removeValue(forKey: pin.id)
                }
            }
        }
    }


    // --- ⭐️ 5. [수정됨] LA가 시스템(스와이프 등)에 의해 종료되는 것을 감시하는 함수 ---
    private func listenForActivityEnd(activity: Activity<PinActivityAttributes>, pinID: UUID) async {
        // activityStateUpdates는 LA의 상태가 변경될 때마다 이벤트를 방출합니다.
        for await state in activity.activityStateUpdates {
            // 사용자가 스와이프 등으로 LA를 '종료'시켰는지 확인합니다.
            if state == .dismissed {
                print("Live Activity \(activity.id)가 시스템에서 종료(dismissed)되었습니다.")
                // LA가 종료되었으므로, 앱의 대시보드에서도 핀을 제거하도록 호출합니다.
                await removePinFromApp(id: pinID)
            }
        }
        
        // .dismissed 외에도 .ended (시간 초과 등) 상태에서도 정리가 필요할 수 있습니다.
        // LA가 활성 상태가 아니게 되면(not .active) 무조건 정리합니다.
        if activity.activityState != .active {
             await removePinFromApp(id: pinID)
        }
    }

    // --- ⭐️ 6. [수정됨] LA 종료에 따라 앱 내부 데이터를 정리하는 함수 ---
    @MainActor
    private func removePinFromApp(id: UUID) {
        // 1. activePins 배열에서 해당 ID의 핀을 찾아 제거 (UI 업데이트)
        //    (이미 앱에서 먼저 삭제되었을 수도 있으므로 firstIndex 사용)
        if let index = activePins.firstIndex(where: { $0.id == id }) {
            activePins.remove(at: index)
            print("앱 대시보드에서 핀 \(id)를 제거했습니다.")
        }
        
        // 2. liveActivities 딕셔너리에서도 해당 ID의 추적을 중지
        if liveActivities.removeValue(forKey: id) != nil {
             print("ViewModel에서 Activity \(id)의 추적을 중지합니다.")
        }
    }

    // MARK: - Shared Pin 로직 (변경 없음)
    
    func processAndPinSharedContent(_ content: String) async {
        sharedPinProcessingState = .loading
        processedContentForPreview = nil
        let result = await ContentProcessorService.processContent(content)

        switch result {
        case .success(let processed):
            if addPin(processedContent: processed) != nil {
                self.processedContentForPreview = processed
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    sharedPinProcessingState = .success
                }
            } else {
                withAnimation {
                    sharedPinProcessingState = .error(ContentProcessingError.liveActivityStartFailed.localizedDescription)
                }
            }
        case .failure(let error):
            withAnimation {
                sharedPinProcessingState = .error(error.localizedDescription)
            }
        }
    }
    
    func resetSharedPinProcessingState() {
        sharedPinProcessingState = .idle
        processedContentForPreview = nil
    }
}
