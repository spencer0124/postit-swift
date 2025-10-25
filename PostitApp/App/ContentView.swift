//
//  ContentView.swift
//  postit
//
//  Created by SeungYong on 10/20/25.
//

import SwiftUI

// ContentView와 Tab1View가 viewModel을 @EnvironmentObject로 받도록 수정합니다.
struct ContentView: View {
    var body: some View {
        TabView {
            Tab1View() // 이제 viewModel을 직접 전달할 필요가 없습니다.
                .tabItem {
                    Label("현재", systemImage: "pin.fill")
                }
            
//             TODO: Pro 기능
             Tab2View()
                 .tabItem {
                     Label("기록", systemImage: "archivebox.fill")
                 }
        }
    }
}

#Preview {
    ContentView()
}
