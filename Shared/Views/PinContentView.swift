//
//  PinContentView.swift
//  postit
//
//  Created by SeungYong on 10/21/25.
//


//
//  PinContentView.swift
//  postit
//
//  Created by SeungYong on 10/20/25.
//

import SwiftUI
import UIKit


struct PinContentView: View {
    let content: String
    let pinType: PinType
    let metadataTitle: String?
    let metadataFaviconData: Data?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
//            Text("📌 고정된 메모")
//                .font(.caption)
//                .foregroundColor(.secondary)

            if pinType == .url {
                // --- URL 타입일 경우 ---
                HStack {
                    if let data = metadataFaviconData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        Image(systemName: "link.circle.fill")
                            .font(.title3)
                            .frame(width: 20, height: 20)
                    }
                    Text(metadataTitle ?? content)
                        .font(.headline)
                        .lineLimit(1)
                }

                if metadataTitle != nil {
                    Text(content)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            } else {
                // --- 텍스트 타입일 경우 ---
                Text(content)
                    .font(.headline)
                    .lineLimit(3)
            }
        }
        // ★★★ 너비 문제 해결 ★★★
        // 이 뷰가 항상 최대 너비를 차지하고 왼쪽 정렬되도록 합니다.
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - SwiftUI Preview

#Preview("Text Pin") {
    PinContentView(
        content: "간단한 텍스트 메모입니다. 최대 3줄까지 보일 수 있어요.",
        pinType: .text,
        metadataTitle: nil,
        metadataFaviconData: nil
    )
    .padding() // 패딩을 추가하여 컨텐츠 주변 여백 확인
    .background(Color.gray.opacity(0.1)) // 배경색 추가
}

#Preview("URL Pin (With Metadata)") {
    PinContentView(
        content: "https://www.apple.com/kr/", // 원본 URL
        pinType: .url,
        metadataTitle: "Apple (대한민국)", // 가져온 제목
        // 실제 앱에서는 MetadataService에서 가져온 이미지 데이터를 사용해야 함
        // 여기서는 임시 SF Symbol 이미지 데이터 사용 (미리보기용)
        metadataFaviconData: UIImage(systemName: "apple.logo")?.pngData()
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("URL Pin (No Metadata)") {
    PinContentView(
        content: "https://some-unknown-url.com", // 원본 URL
        pinType: .url,
        metadataTitle: nil, // 제목 가져오기 실패
        metadataFaviconData: nil // 아이콘 가져오기 실패
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
