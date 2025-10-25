//
//  MetadataService.swift
//  postit
//
//  Created by SeungYong on 10/20/25.
//

import Foundation
import LinkPresentation
import UIKit

class MetadataService {

    // Metadata 구조체에서 description 제거
    struct Metadata {
        let title: String?
        let faviconData: Data?
        // let description: String? // <- 제거됨
    }

    static func fetchMetadata(for urlString: String, completion: @escaping (Metadata?) -> Void) {
        guard let url = URL(string: urlString) else {
            print("MetadataService: 유효하지 않은 URL입니다.")
            completion(nil)
            return
        }
        
        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: url) { metadata, error in
            if let error = error {
                print("MetadataService: Fetch 실패 - \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let metadata = metadata else {
                completion(nil)
                return
            }
            
            let title = metadata.title
            // let description = metadata.summary // <- 제거됨
            
            if let iconProvider = metadata.iconProvider {
                iconProvider.loadObject(ofClass: UIImage.self) { imageObject, error in
                    guard let image = imageObject as? UIImage else {
                        // 아이콘 실패해도 제목은 전달 (description 제거)
                        let result = Metadata(title: title, faviconData: nil) // <- 수정
                        print("MetadataService: Favicon 로드 실패")
                        completion(result)
                        return
                    }
                    
                    Task {
                        let faviconData = await resizeImage(image: image, targetSize: CGSize(width: 60, height: 60))
                        // 결과에 description 제거
                        let result = Metadata(title: title, faviconData: faviconData) // <- 수정
                        print("MetadataService: Favicon 로드 및 리사이즈 성공")
                        completion(result)
                    }
                }
            } else {
                // 아이콘 프로바이더 없는 경우 (description 제거)
                let result = Metadata(title: title, faviconData: nil) // <- 수정
                completion(result)
            }
        }
    }

    // 리사이즈 헬퍼 함수 (변경 없음)
    static private func resizeImage(image: UIImage, targetSize: CGSize) async -> Data? {
        let thumbnail = await image.preparingThumbnail(of: targetSize)
        return thumbnail?.jpegData(compressionQuality: 0.8)
    }
}
