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

// LA와 앱 내 미리보기에서 모두 사용하는 '공통 UI'입니다.
// ActivityKit에 의존하지 않고, 순수 데이터만 받아서 그립니다.
struct PinContentView: View {
    let content: String
    let pinType: PinType
    let metadataTitle: String?
    let metadataFaviconData: Data?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("📌 고정된 메모")
                .font(.caption)
                .foregroundColor(.secondary)

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
