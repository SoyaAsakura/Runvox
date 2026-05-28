import SwiftUI

/// 質問投稿画面のカテゴリ選択タイル
struct CategoryTile: View {
    let category: QuestionCategory
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.systemIcon)
                    .font(.system(size: 22))
                Text(category.displayName)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
            }
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var textColor: Color {
        isSelected ? RunvoxColors.primaryDark : RunvoxColors.inkSoft
    }

    private var backgroundColor: Color {
        isSelected ? RunvoxColors.bgTint : RunvoxColors.bgPage
    }

    private var borderColor: Color {
        isSelected ? RunvoxColors.primary : RunvoxColors.border
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
        ForEach(QuestionCategory.allCases) { category in
            CategoryTile(
                category: category,
                isSelected: category == .training,
                action: {}
            )
        }
    }
    .padding()
    .background(.white)
}
