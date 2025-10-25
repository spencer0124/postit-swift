// Extensions/PinShareExtension/ShareViewController.swift

import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear

        Task {
            guard let sharedContent = await getSharedContent(),
                  let encodedContent = sharedContent.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            else {
                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                return
            }

            // ⭐️ 변경: URL 생성 시 AppConstants 사용
            let urlString = "\(AppConstants.urlScheme)://\(AppConstants.shareSheetHost)?\(AppConstants.contentQueryItemName)=\(encodedContent)"
            guard let url = URL(string: urlString) else {
                print("Share Extension: URL 생성 실패")
                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                return
            }

            openURL(url)
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

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
