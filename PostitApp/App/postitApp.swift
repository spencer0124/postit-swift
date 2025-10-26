// PostitApp/App/postitApp.swift

import SwiftUI
import SwiftData // 1. Import

// Identifiable 래퍼 구조체 정의
struct IdentifiableSourceContent: Identifiable {
    let id = UUID()
    let content: String
    let source: SourceType
}

@main
struct postitApp: App {
    // 2. VM들을 @StateObject로 생성
    @StateObject private var viewModel = ActivePinsViewModel()
    @StateObject private var historyViewModel = HistoryViewModel() // ⭐️ HistoryVM 생성
    
    @State private var contentForSharedView: IdentifiableSourceContent? = nil
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: ContentView.Tab = .dashboard

    // ⭐️ 3. VM 생성 시점 (init)에서 두 VM을 연결
    init() {
        viewModel.setHistoryViewModel(historyViewModel)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(selectedTab: $selectedTab)
                .environmentObject(viewModel)
                .environmentObject(historyViewModel) // ⭐️ HistoryVM 주입
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .fullScreenCover(item: $contentForSharedView,
                                 onDismiss: {
                                     contentForSharedView = nil
                                     viewModel.resetSharedPinProcessingState()
                                 }) { item in
                    SharedPinView(content: item.content, source: item.source)
                        .environmentObject(viewModel)
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if contentForSharedView?.source == .shareSheet && oldPhase == .active && (newPhase == .inactive || newPhase == .background) {
                        contentForSharedView = nil
                    }
                }
                .environment(\.displaySharedView) { content in
                    self.viewModel.isShowingEditor = false
                    Task {
                        try? await Task.sleep(nanoseconds: 200_000_000)
                        await MainActor.run {
                            self.contentForSharedView = IdentifiableSourceContent(content: content, source: .manualAdd)
                        }
                    }
                }
        }
        // ⭐️ 4. SwiftData ModelContainer 설정
        .modelContainer(for: Pin.self)
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
