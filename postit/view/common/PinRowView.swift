//
//  PinRowView.swift
//  postit
//
//  Created by SeungYong on 10/20/25.
//

import SwiftUI


struct PinRowView: View {
    let pin: Pin
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if pin.pinType == .url {
                // TODO: URL 메타데이터(파비콘, 제목)를 표시하는 카드 UI
                HStack {
                    Image(systemName: "link.circle.fill")
                        .foregroundColor(.blue)
                    Text(pin.content)
                        .lineLimit(1)
                }
                Text("웹사이트 링크")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text(pin.content)
            }
        }
        .padding(.vertical, 5)
    }
}
