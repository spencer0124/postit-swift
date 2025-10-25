//
//  ShareDataManager.swift
//  postit
//
//  Created by SeungYong on 10/20/25.
//

import Foundation

// Share Extension과 메인 앱이 데이터를 주고받기 위한 모델
struct SharedPin: Codable {
    let content: String
    let type: PinType
}

// App Group UserDefaults를 관리하는 클래스
class ShareDataManager {
    // ★★★ 중요 ★★★: 이전 단계에서 만드신 App Group ID로 이 값을 꼭 변경하세요!
    static let suiteName = "group.zoyoong.postit"
    static let key = "newSharedPin"
    
    // 공유 UserDefaults에 Pin 정보를 저장하는 함수
    static func savePin(_ pin: SharedPin) {
        guard let userDefaults = UserDefaults(suiteName: suiteName) else { return }
        
        do {
            let data = try JSONEncoder().encode(pin)
            userDefaults.set(data, forKey: key)
            print("ShareDataManager: Pin 저장 성공 - \(pin.content)")
        } catch {
            print("ShareDataManager: Pin 저장 실패 - \(error.localizedDescription)")
        }
    }
    
    // ★★★ 추가된 함수 ★★★
    // 공유 UserDefaults에서 Pin 정보를 '읽고 바로 삭제'하는 함수
    // (한 번 처리한 데이터를 중복으로 또 처리하지 않기 위함)
    static func readAndClearPin() -> SharedPin? {
        guard let userDefaults = UserDefaults(suiteName: suiteName) else { return nil }
        
        // 1. 데이터를 읽어옵니다.
        guard let data = userDefaults.data(forKey: key) else { return nil }
        
        // 2. 읽어온 데이터를 즉시 삭제합니다.
        userDefaults.removeObject(forKey: key)
        
        // 3. 데이터를 SharedPin 모델로 디코딩하여 반환합니다.
        do {
            let pin = try JSONDecoder().decode(SharedPin.self, from: data)
            print("ShareDataManager: Pin 읽기 성공 - \(pin.content)")
            return pin
        } catch {
            print("ShareDataManager: Pin 읽기 실패 - \(error.localizedDescription)")
            return nil
        }
    }
}
