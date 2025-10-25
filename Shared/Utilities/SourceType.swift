// Shared/Utilities/SourceType.swift

import Foundation

// SharedPinView가 어디서 열렸는지 구분하기 위한 타입
// ⭐️ 이 파일에만 정의되어야 합니다!
enum SourceType {
    case shareSheet // 공유 시트
    case manualAdd  // 앱 내부 '+' 버튼
}
