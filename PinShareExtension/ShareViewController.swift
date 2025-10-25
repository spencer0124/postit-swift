//
//  ShareViewController.swift
//  PinShareExtension
//
//  Created by SeungYong on 10/20/25.
//

import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 이 뷰를 투명하게 만들어, 앱이 열리는 동안 사용자가 아무것도 보지 못하게 합니다.
        self.view.backgroundColor = .clear
        
        Task {
            // 1. 공유된 콘텐츠(텍스트 또는 URL)를 가져옵니다.
            guard let sharedContent = await getSharedContent(),
                  // 2. 콘텐츠를 URL에 포함될 수 있도록 인코딩합니다.
                  let encodedContent = sharedContent.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  // 3. 메인 앱을 호출할 커스텀 URL을 생성합니다.
                  let url = URL(string: "postit://share-sheet?content=\(encodedContent)")
            else {
                // 처리할 콘텐츠가 없으면 조용히 종료합니다.
                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                return
            }
            
            // 4. 생성된 URL로 메인 앱을 호출합니다.
            openURL(url)
            
            // 5. 호출 후 즉시 Extension을 닫습니다.
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
    
    // "응답 사슬(Responder Chain)"을 거슬러 올라가 UIApplication을 찾는 함수
    @objc private func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                // UIApplication을 찾으면, open 메소드를 호출하여 앱을 엽니다.
                application.open(url, options: [:], completionHandler: nil)
                print("Share Extension: UIApplication.open 호출 성공!")
                return true
            }
            responder = responder?.next
        }
        print("Share Extension: UIApplication을 찾지 못해 open 호출 실패.")
        return false
    }

    // 공유 컨텍스트에서 텍스트나 URL을 추출하는 함수
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
