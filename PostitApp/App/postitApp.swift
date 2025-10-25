// PostitApp/App/postitApp.swift

import SwiftUI

// Identifiable 래퍼 구조체 정의
struct IdentifiableSourceContent: Identifiable {
    let id = UUID()
    let content: String
    let source: SourceType
}

@main
struct postitApp: App {
    @StateObject private var viewModel = ActivePinsViewModel()
    @State private var contentForSharedView: IdentifiableSourceContent? = nil
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: ContentView.Tab = .dashboard

    var body: some Scene {
        WindowGroup {
            ContentView(selectedTab: $selectedTab)
                .environmentObject(viewModel)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .fullScreenCover(item: $contentForSharedView,
                                 onDismiss: {
                                     contentForSharedView = nil
                                 }) { item in
                    SharedPinView(content: item.content, source: item.source)
                        .environmentObject(viewModel)
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if contentForSharedView?.source == .shareSheet && oldPhase == .active && (newPhase == .inactive || newPhase == .background) {
                        contentForSharedView = nil
                    }
                }
                // ⭐️ displaySharedView 클로저 수정
                .environment(\.displaySharedView) { content in
                    // 1. 먼저 시트를 닫도록 상태 변경
                    self.viewModel.isShowingEditor = false
                    
                    // ⭐️ 2. 아주 짧게 지연시킨 후 커버를 띄우도록 상태 변경
                    Task {
                        // 0.1초 정도 딜레이 (시트 닫힐 시간)
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        // 메인 액터에서 상태 업데이트 보장
                        await MainActor.run {
                            self.contentForSharedView = IdentifiableSourceContent(content: content, source: .manualAdd)
                        }
                    }
                }
        }
    }

    // URL 처리 로직 (변경 없음)
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == AppConstants.urlScheme else { return }
        switch url.host {
        case AppConstants.shareSheetHost:
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let contentValue = components?.queryItems?.first(where: { $0.name == AppConstants.contentQueryItemName })?.value,
               let decodedContent = contentValue.removingPercentEncoding {
                self.contentForSharedView = IdentifiableSourceContent(content: decodedContent, source: .shareSheet)
            }
        case AppConstants.openDashboardHost:
            self.selectedTab = .dashboard
        default: break
        }
    }
}

// Environment Key/Value 정의 (변경 없음)
private struct DisplaySharedViewKey: EnvironmentKey {
    static let defaultValue: (String) -> Void = { _ in }
}
extension EnvironmentValues {
    var displaySharedView: (String) -> Void {
        get { self[DisplaySharedViewKey.self] }
        set { self[DisplaySharedViewKey.self] = newValue }
    }
}
