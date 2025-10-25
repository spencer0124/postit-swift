//
//  tab2.swift
//  postit
//
//  Created by SeungYong on 10/20/25.
//

import SwiftUI

struct Tab2View: View {
    @StateObject private var viewModel = HistoryViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.archivedPins) { pin in
                    // History용 Row View는 디자인이 약간 다를 수 있음
                    PinRowView(pin: pin)
                }
            }
            .navigationTitle("기록")
            .overlay {
                if viewModel.archivedPins.isEmpty {
                    Text("보관된 기록이 없습니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("모두 지우기") {
                        // TODO: 전체 삭제 로직
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}

#Preview {
    Tab2View()
}
