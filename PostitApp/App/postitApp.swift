//
//  postitApp.swift
//  postit
//
//  Created by SeungYong on 10/20/25.
//

import SwiftUI

@main
struct postitApp: App {
    @StateObject private var viewModel = ActivePinsViewModel()
    @State private var sharedContent: String?
    
    // 앱의 상태(활성, 비활성, 백그라운드)를 감지하기 위한 변수
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .fullScreenCover(item: $sharedContent,
                       // 팝업을 수동으로 닫을 때를 위한 onDismiss는 그대로 둡니다.
                       onDismiss: {
                           sharedContent = nil
                       }) { content in
                    SharedPinView(content: content)
                        .environmentObject(viewModel)
                }
                // ★★★ 수정된 부분 ★★★
                // 앱의 scenePhase가 바뀔 때마다 이 코드가 실행됩니다.
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    // 앱이 '활성(active)' 상태였다가, '비활성(inactive)' 또는 '백그라운드'로
                    // 전환될 때만 팝업을 닫습니다.
                    // 이렇게 하면 딥링크로 처음 진입할 때는 팝업이 닫히지 않습니다.
                    if oldPhase == .active && (newPhase == .inactive || newPhase == .background) {
                        // 팝업을 띄우는 상태 변수를 nil로 초기화합니다.
                        sharedContent = nil
                    }
                }
        }
    }
    
    // URL을 처리하는 로직
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "postit", url.host == "share-sheet" else { return }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let content = components?.queryItems?.first(where: { $0.name == "content" })?.value {
            print("메인 앱: 수신된 콘텐츠 - \(content)")
            self.sharedContent = content.removingPercentEncoding ?? ""
        }
    }
}

// String이 .sheet의 item으로 사용될 수 있도록 Identifiable 프로토콜을 따르게 합니다.
extension String: Identifiable {
    public var id: String { self }
}

