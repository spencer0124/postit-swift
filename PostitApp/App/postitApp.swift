// PostitApp/App/postitApp.swift

import SwiftUI

@main
struct postitApp: App {
    @StateObject private var viewModel = ActivePinsViewModel()
    @State private var sharedContent: String?
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .fullScreenCover(item: $sharedContent,
                       onDismiss: {
                           sharedContent = nil
                       }) { content in
                    SharedPinView(content: content)
                        .environmentObject(viewModel)
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if oldPhase == .active && (newPhase == .inactive || newPhase == .background) {
                        sharedContent = nil
                    }
                }
        }
    }

    // URL을 처리하는 로직
    private func handleIncomingURL(_ url: URL) {
        // ⭐️ 변경: guard 문에서 AppConstants 사용
        guard url.scheme == AppConstants.urlScheme, url.host == AppConstants.shareSheetHost else { return }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        // ⭐️ 변경: 쿼리 아이템 이름에 AppConstants 사용
        if let content = components?.queryItems?.first(where: { $0.name == AppConstants.contentQueryItemName })?.value {
            print("메인 앱: 수신된 콘텐츠 - \(content)")
            self.sharedContent = content.removingPercentEncoding ?? ""
        }
    }
}

extension String: Identifiable {
    public var id: String { self }
}
