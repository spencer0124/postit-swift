//
//  HistoryViewModel.swift
//  postit
//
//  Created by SeungYong on 10/20/25.
//

import Foundation


@MainActor
class HistoryViewModel: ObservableObject {
    @Published var archivedPins: [Pin] = [
        // 예시 데이터
        Pin(content: "지난 프로젝트 참고 링크", pinType: .url)
    ]
    
    // TODO: Pin 복원, 영구 삭제 로직 구현
}
