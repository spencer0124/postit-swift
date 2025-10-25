//
//  Tab1View.swift
//  postit
//
//  Created by SeungYong on 10/20/25.
//

import SwiftUI

struct Tab1View: View {
    @EnvironmentObject var viewModel: ActivePinsViewModel
    
    var body: some View {
        NavigationStack {
            // 1. if/else 분기로 인한 툴바 오류를 막기 위해 VStack으로 감쌉니다.
            VStack(spacing: 0) {
                if viewModel.activePins.isEmpty {
                    EmptyStateView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 2. Apple 기본 List 컴포넌트를 사용합니다.
                    List {
                        // 3. 인덱스와 핀을 함께 가져옵니다.
                        ForEach(Array(viewModel.activePins.enumerated()), id: \.element.id) { index, pin in
                            // 4. 삭제 버튼과 타이머가 포함된 커스텀 행(Row)을 사용합니다.
                            PinListRow(pin: pin, onDelete: {
                                viewModel.removePin(at: IndexSet(integer: index))
                            })
                        }
                    }
                    // 5. '흰색' 배경을 위해 .listStyle(.plain)을 적용합니다.
                    .listStyle(.plain)
                }
            }
            // 6. '핀 대시보드' 제목을 고정합니다.
            .navigationTitle("핀 대시보드")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // 7. '+' 버튼을 기본 이미지로 설정하여 제목과 수평 정렬시킵니다.
                    Button {
                        viewModel.isShowingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingEditor) {
            PinEditorView()
                .environmentObject(viewModel)
        }
    }
}

// MARK: - Helper Views

/// ⭐️ 8. 삭제 버튼과 8시간 타이머가 포함된 커스텀 리스트 행
private struct PinListRow: View {
    let pin: Pin
    var onDelete: () -> Void // 삭제 액션을 받을 클로저

    // ⭐️ 8시간(초) = 8 * 60 * 60 = 28800초
    private var endDate: Date {
        pin.creationDate.addingTimeInterval(28800)
    }

    var body: some View {
        HStack {
            // ⭐️ 9. 핀 내용과 타이머를 수직으로 쌓는 VStack
            VStack(alignment: .leading, spacing: 6) {
                PinRowView(pin: pin)
                
                // --- ⭐️ 10. 8시간 카운트다운 타이머 뷰 ---
                HStack(spacing: 4) {
                    Image(systemName: "hourglass")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    // 1초마다 뷰를 갱신하는 TimelineView
                    TimelineView(.periodic(from: .now, by: 1.0)) { _ in
                        // endDate까지 남은 시간을 .timer 스타일로 표시
                        Text(endDate, style: .timer)
                            .font(.caption.monospacedDigit()) // 숫자가 흔들리지 않음
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                // --- 타이머 뷰 끝 ---
            }
            
            Spacer()
            
            // 9. 항상 보이는 삭제 버튼 (스와이프 불필요)
            Button(action: {
                withAnimation(.spring()) { // 부드러운 삭제 애니메이션
                    onDelete()
                }
            }) {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain) // List 안에서 버튼이 제대로 동작하도록 함
        }
        .padding(.vertical, 4) // 행의 수직 패딩
    }
}

/// 핀이 없을 때 표시되는 뷰 (변경 없음)
private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "pin.slash")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary)
            Text("고정된 핀이 없어요")
                .font(.headline.weight(.medium))
            Text("오른쪽 상단의 + 버튼을 눌러\n새로운 핀을 추가해 보세요.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 60)
    }
}

// MARK: - SwiftUI Preview
#Preview {
    Tab1View()
        .environmentObject(ActivePinsViewModel())
}
