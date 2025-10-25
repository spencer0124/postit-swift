// PostitApp/Services/MetadataService.swift

import Foundation
import LinkPresentation
import UIKit
import UniformTypeIdentifiers // ⭐️ UTType 사용을 위해 import 추가

class MetadataService {

    struct Metadata {
        let title: String?
        let faviconData: Data?
    }

    static func fetchMetadata(for urlString: String) async -> Metadata? {
        guard let url = URL(string: urlString) else {
            print("MetadataService: 유효하지 않은 URL입니다.")
            return nil
        }

        let provider = LPMetadataProvider()

        do {
            let metadata = try await provider.startFetchingMetadata(for: url)
            let title = metadata.title
            var faviconData: Data? = nil

            // ⭐️ 변경: iconProvider 처리 부분을 loadItem(forTypeIdentifier:) async 버전으로 수정
            if let iconProvider = metadata.iconProvider {
                // 아이콘 프로바이더가 어떤 타입을 지원하는지 확인 (UIImage 관련 타입)
                // iOS 14 이상에서는 UTType 사용 권장
                let imageType = UTType.image.identifier // 가장 일반적인 이미지 타입 식별자

                do {
                    // 지정된 타입으로 아이템 로드를 시도
                    // loadItem은 NSItemProviderReading?, Error? 를 반환하므로 옵셔널 처리 필요
                    // 결과 타입을 NSSecureCoding으로 캐스팅 시도
                    if let item = try await iconProvider.loadItem(forTypeIdentifier: imageType, options: nil) as? NSSecureCoding {

                        // UIImage 데이터로 변환 시도 (다양한 이미지 표현 고려)
                        var image: UIImage? = nil
                        if let img = item as? UIImage { // 직접 UIImage인 경우
                            image = img
                        } else if let data = item as? Data, let img = UIImage(data: data) { // Data인 경우
                            image = img
                        } else if let imageURL = item as? URL, let data = try? Data(contentsOf: imageURL), let img = UIImage(data: data) { // 이미지 URL인 경우
                             image = img
                        }
                        // 다른 가능한 타입(e.g., CIImage) 처리 추가 가능

                        // UIImage 변환 성공 시 리사이즈
                        if let finalImage = image {
                            faviconData = await resizeImage(image: finalImage, targetSize: CGSize(width: 60, height: 60))
                            if faviconData != nil {
                                print("MetadataService: Favicon 로드 및 리사이즈 성공")
                            } else {
                                print("MetadataService: Favicon 리사이즈 실패")
                            }
                        } else {
                            print("MetadataService: Favicon 로드 실패 (UIImage 변환 불가)")
                        }
                    } else {
                         print("MetadataService: Favicon 로드 실패 (NSSecureCoding 변환 불가 또는 항목 없음)")
                    }
                } catch {
                    print("MetadataService: Favicon 로드 실패(loadItem) - \(error.localizedDescription)")
                }

            } else {
                print("MetadataService: Favicon Provider 없음")
            }

            return Metadata(title: title, faviconData: faviconData)

        } catch {
            print("MetadataService: Fetch 실패 - \(error.localizedDescription)")
            return nil
        }
    }

    // 리사이즈 헬퍼 함수 (변경 없음)
    static private func resizeImage(image: UIImage, targetSize: CGSize) async -> Data? {
        let thumbnail = image.preparingThumbnail(of: targetSize)
        return thumbnail?.jpegData(compressionQuality: 0.8)
    }
}
