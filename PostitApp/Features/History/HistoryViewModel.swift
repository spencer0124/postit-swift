// PostitApp/Features/History/HistoryViewModel.swift

import Foundation
import SwiftData // 1. Import
import SwiftUI // 2. Import

@MainActor
class HistoryViewModel: ObservableObject {
    
    // 3. modelContext를 저장할 프라이빗 변수
    private var modelContext: ModelContext?
    
    @Published var archivedPins: [Pin] = []
    
    // 4. modelContext를 주입받는 함수
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchHistory() // ⭐️ 컨텍스트가 설정되면 즉시 데이터 로드
    }
    
    // 5. ⭐️ 보관함 데이터 로드 (전략대로)
    func fetchHistory() {
        guard let modelContext else {
            print("HistoryViewModel: ModelContext is nil.")
            return
        }
        
        let now = Date.now
        // 5-1. 보관함에 표시할 시간이 '지금'보다 과거인 것
        let predicate = #Predicate<Pin> { pin in
            pin.showInHistoryAt <= now
        }
        
        // 5-2. 보관된 날짜(표시된 날짜) 기준 최신순 정렬
        let sortDescriptor = SortDescriptor(\Pin.showInHistoryAt, order: .reverse)
        
        let descriptor = FetchDescriptor(predicate: predicate, sortBy: [sortDescriptor])
        
        do {
            archivedPins = try modelContext.fetch(descriptor)
            print("HistoryViewModel: 보관함 데이터 로드 완료 (\(archivedPins.count)개)")
        } catch {
            print("HistoryViewModel: 보관함 데이터 로드 실패 - \(error.localizedDescription)")
        }
    }
    
    // 6. ⭐️ (스와이프) 영구 삭제
    func deleteFromHistory(at offsets: IndexSet) {
        guard let modelContext else { return }
        
        let pinsToDelete = offsets.compactMap { archivedPins[$0] }
        
        for pin in pinsToDelete {
            modelContext.delete(pin) // (DB) 삭제
        }
        
        archivedPins.remove(atOffsets: offsets) // (In-Memory) 삭제
    }

    // 7. ⭐️ (툴바 버튼) 전체 삭제
    func clearAllHistory() {
        guard let modelContext else { return }
        
        do {
            // 7-1. (DB) 현재 보관함에 표시되는 모든 핀 삭제
            let now = Date.now
            try modelContext.delete(model: Pin.self, where: #Predicate { pin in
                pin.showInHistoryAt <= now
            })
            
            // 7-2. (In-Memory) 배열 비우기
            archivedPins = []
            print("HistoryViewModel: 보관함 전체 삭제 완료")
        } catch {
            print("HistoryViewModel: 보관함 전체 삭제 실패 - \(error.localizedDescription)")
        }
    }
}
