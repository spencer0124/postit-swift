//
//  RoundedCorner.swift
//  postit
//
//  Created by SeungYong on 10/25/25.
//


// Shared/Views/Helpers/RoundedCorner.swift
import SwiftUI
import UIKit // UIBezierPath 사용

// MARK: - 특정 모서리만 둥글게 하는 Shape
/// 특정 모서리만 둥글게 처리하기 위한 헬퍼 Shape
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
