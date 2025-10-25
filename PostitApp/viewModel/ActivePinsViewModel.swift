//
//  ActivePinsViewModel.swift
//  postit
//
//  Created by SeungYong on 10/20/25.
//

import Foundation
import ActivityKit
import SwiftUI

@MainActor
class ActivePinsViewModel: ObservableObject {
    
    @Published var activePins: [Pin] = []
    @Published var isShowingEditor = false
    
    private var liveActivities: [UUID: Activity<PinActivityAttributes>] = [:]
    
    
    
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
    
    // --- 나머지 함수 (변경 없음) ---
    private func listenForActivityEnd(activity: Activity<PinActivityAttributes>, pinID: UUID) async { /* ... */ }
    @MainActor private func removePinFromApp(id: UUID) { /* ... */ }
    func removePin(at offsets: IndexSet) { /* ... */ }
}
