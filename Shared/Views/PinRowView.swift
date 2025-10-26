// Shared/Views/PinRowView.swift

import SwiftUI

struct PinRowView: View {
    let pin: Pin
    
    var body: some View {
        // ⭐️ PinContentView를 재사용하여 메타데이터 표시
        PinContentView(
            content: pin.content,
            pinType: pin.pinType,
            metadataTitle: pin.metadataTitle,
            metadataFaviconData: pin.metadataFaviconData
        )
        // ⭐️ PinContentView는 자체 패딩이 없으므로,
        // 이 뷰를 사용하는 ListRow에서 .padding(.vertical, 5) 등을 추가
    }
}

// ⭐️ Preview 수정
#Preview("Text Pin (Row)") {
    PinRowView(pin: .init(
        content: "간단한 텍스트 메모입니다.",
        pinType: .text,
        metadataTitle: nil,
        metadataFaviconData: nil)
    )
}

#Preview("URL Pin (Row)") {
    PinRowView(pin: .init(
        content: "https://www.apple.com",
        pinType: .url,
        metadataTitle: "Apple (Row Preview)",
        metadataFaviconData: UIImage(systemName: "apple.logo")?.pngData())
    )
}
