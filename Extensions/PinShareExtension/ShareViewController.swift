// Extensions/PinShareExtension/ShareViewController.swift

import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear // 배경은 투명하게 유지

        Task {
            guard let sharedContent = await getSharedContent(),
                  let encodedContent = sharedContent.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            else {
                // 콘텐츠 가져오기 실패 시 즉시 종료 (정상)
                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                return
            }

            // URL 생성
            let urlString = "\(AppConstants.urlScheme)://\(AppConstants.shareSheetHost)?\(AppConstants.contentQueryItemName)=\(encodedContent)"
            guard let url = URL(string: urlString) else {
                print("Share Extension: URL 생성 실패")
                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                return
            }

            // 메인 앱 열기 시도
            let didOpen = openURL(url) // openURL 함수 자체는 Bool을 반환
            
            if didOpen {
                // ⭐️⭐️⭐️ 수정된 부분: 앱 열기 성공 시 잠시 대기 ⭐️⭐️⭐️
                // 메인 앱으로 전환될 시간을 벌어주기 위해 0.5초 대기합니다.
                // (단위: 나노초, 0.5초 = 500,000,000 나노초)
                try? await Task.sleep(nanoseconds: 500_000_000)
                print("Share Extension: 0.5초 대기 후 종료")
            } else {
                // 앱 열기 실패 시 즉시 종료 (정상)
                print("Share Extension: 앱 열기 실패, 즉시 종료")
            }
            
            // Extension 종료 요청
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    // openURL 함수는 변경 없음
    @objc private func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                print("Share Extension: UIApplication.open 호출 성공!")
                return true
            }
            responder = responder?.next
        }
        print("Share Extension: UIApplication을 찾지 못해 open 호출 실패.")
        return false
    }

    // getSharedContent 함수는 변경 없음
    private func getSharedContent() async -> String? {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            return nil
        }

        if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            if let url = try? await itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
                return url.absoluteString
            }
        }

        if itemProvider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
            if let text = try? await itemProvider.loadItem(forTypeIdentifier: UTType.text.identifier) as? String {
                return text
            }
        }

        return nil
    }
}
