//
//  Pin.swift
//  postit
//
//  Created by SeungYong on 10/20/25.
//
import Foundation

struct Pin: Identifiable, Hashable {
    let id = UUID()
    let content: String
    let pinType: PinType
    let creationDate: Date = .now
    // ... URL 메타데이터 등 추가 정보
}

enum PinType: String, Codable, Hashable {
    case text
    case url
}
