//
//  iPhoneMockupView.swift
//  postit
//
//  Created by Gemini on 10/22/25.
//

import SwiftUI
import UIKit // UIBezierPath를 위해 import




// MARK: - 아이폰 목업 뷰 
struct iPhoneMockupView: View {
    // --- 새 로직 (유지) ---
    let processedContent: ProcessedContent? // 옵셔널로 받아 로딩 중 처리
    let reader: GeometryProxy
    @Binding var isPinVisible: Bool // '뿅' 애니메이션 상태 바인딩

    // --- '소름돋는 디테일': 현재 시간/날짜 (복원) ---
    @State private var currentTime: String = ""
    @State private var currentDate: String = ""
    
    // --- Dynamic Island 스타일 상수 (복원) ---
    private let islandCornerRadius: CGFloat = 24.0
    
    // --- 날짜/시간 포맷터 (복원) ---
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm" // "9:41" 형식
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, M월 d일" // "화요일, 10월 20일" 형식
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    var body: some View {
        // --- '좋은 UI' (복원) ---
        VStack {
            // 1. Phone Body (Outer Frame)
            ZStack {
                // 하단 모서리 직각
                RoundedCorner(radius: 54, corners: [.topLeft, .topRight])
                    .fill(Color(uiColor: .darkGray))
                    .shadow(color: .black.opacity(0.3), radius: 15, y: 10)
                    .overlay(
                        RoundedCorner(radius: 54, corners: [.topLeft, .topRight])
                            .stroke(Color.black.opacity(0.5), lineWidth: 2)
                    )
                
                // 2. Screen Area
                VStack(spacing: 0) {
                    // Dynamic Island
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.black)
                        .frame(width: 130, height: 36)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                    
                    // 실시간 날짜 및 시간
                    VStack(spacing: 4) {
                        Text(currentTime) // 실시간 시간
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(radius: 2)
                        Text(currentDate) // 실시간 날짜
                            .font(.title2.weight(.medium))
                            .foregroundColor(.white.opacity(0.7))
                            .shadow(radius: 2)
                    }
                    .padding(.bottom, 30)
                    
                    // 알림
                    VStack(spacing: 12) {
                        
                        
                        // --- '뿅' 하고 나타날 포스트잇 (새 로직 적용) ---
                        if isPinVisible, let content = processedContent {
                            PinContentView(
                                content: content.originalContent,
                                pinType: content.pinType,
                                metadataTitle: content.metadataTitle,
                                metadataFaviconData: content.metadataFaviconData
                            )
                            .padding()
                            .frame(maxWidth: 380, minHeight: 90)
                            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: islandCornerRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: islandCornerRadius, style: .continuous)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.25), radius: 20, y: 8)
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                        }
                        FakeNotificationView()
                        FakeNotificationView()
                        
                        Spacer() // 알림과 LA를 위로, Spacer가 하단 공간 차지
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 15)
                }
                .overlay(
                    VStack {
                        Spacer()
                        // --- ★★★ 수정된 부분 (컴파일 오류 수정) ★★★ ---
                        LinearGradient(
                            colors: [
                                .clear,
                                Color(uiColor: .darkGray).opacity(0.8), // .darkGray -> Color(uiColor: .darkGray)
                                Color(uiColor: .darkGray)                // .darkGray -> Color(uiColor: .darkGray)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 60)
                        // --- ★★★ 수정 끝 ★★★ ---
                    }
                )
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.6), Color.black.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
                )
                .clipShape(RoundedCorner(radius: 44, corners: [.topLeft, .topRight]))
                // 하단 베젤(테두리) 제거
                .padding([.top, .horizontal], 10)
            }
            .frame(width: reader.size.width * 0.8) // 좌우 패딩을 위한 너비 설정
            .clipShape(RoundedCorner(radius: 54, corners: [.topLeft, .topRight]))
        }
        .padding(.top, 10)
        .onAppear(perform: updateDateTime) // 뷰가 나타날 때 시간 업데이트
    }
    
    /// 현재 시간을 업데이트하는 함수
    private func updateDateTime() {
        let now = Date()
        self.currentTime = Self.timeFormatter.string(from: now)
        self.currentDate = Self.dateFormatter.string(from: now)
    }
}

// MARK: - Preview (새 로직에 맞게 수정됨)
#Preview {
    struct PreviewWrapper: View {
        @State private var isPinVisible = true
        // 가짜 ProcessedContent 생성
        let previewContent = ProcessedContent(
            originalContent: "https://www.apple.com",
            pinType: .url,
            metadataTitle: "Apple (Preview)",
            metadataFaviconData: nil
        )

        var body: some View {
            GeometryReader { proxy in
                ZStack {
                    Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                    VStack { // 하단 정렬을 위한 VStack
                        Spacer()
                        iPhoneMockupView(
                            processedContent: previewContent, // ProcessedContent 전달
                            reader: proxy,
                            isPinVisible: $isPinVisible
                        )
                        .frame(height: proxy.size.height * 0.7)
                    }
                }
            }
        }
    }
    return PreviewWrapper()
        .environmentObject(ActivePinsViewModel())
}
