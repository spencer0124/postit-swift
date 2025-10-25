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

    // ⭐️ 1. creationDate 및 관련 로직 모두 제거
    // init도 기본으로 복원
    
    var body: some View {
        // ⭐️ 2. ZStack 대신 기존 VStack으로 복원
        VStack(alignment: .leading, spacing: 5) {
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
        // ⭐️ 3. .frame과 .padding(.trailing) 제거
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - SwiftUI Preview

// ⭐️ 4. 프리뷰에서 creationDate 제거
#Preview("Text Pin") {
    PinContentView(
        content: "간단한 텍스트 메모입니다. 최대 3줄까지 보일 수 있어요.",
        pinType: .text,
        metadataTitle: nil,
        metadataFaviconData: nil
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("URL Pin (With Metadata)") {
    PinContentView(
        content: "https://www.apple.com/kr/", // 원본 URL
        pinType: .url,
        metadataTitle: "Apple (대한민국)", // 가져온 제목
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
