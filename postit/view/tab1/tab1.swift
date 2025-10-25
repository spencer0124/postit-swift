//
//  Tab1View.swift
//  postit
//
//  Created by SeungYong on 10/20/25.
//

import SwiftUI

struct Tab1View: View {
    // ★★★ 수정된 부분 (3/3) ★★★
    // @StateObject 대신 @EnvironmentObject로 viewModel을 받습니다.
    @EnvironmentObject var viewModel: ActivePinsViewModel
    
    var body: some View {
        // Tab1View의 나머지 UI 코드는 변경 없습니다.
        NavigationStack {
            List {
                ForEach(viewModel.activePins) { pin in
                    PinRowView(pin: pin)
                }
                .onDelete { indexSet in
                    viewModel.removePin(at: indexSet)
                }
            }
            .navigationTitle("현재 고정됨")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.isShowingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingEditor) {
                // 이제 PinEditorView는 viewModel을 @EnvironmentObject로 받습니다.
                PinEditorView()
            }
        }
    }
}

// MARK: - SwiftUI Preview
#Preview {
    Tab1View()
}
