import SwiftUI

struct TastySearchField: View {
    @Binding var text: String
    var prompt: String = "搜索店名、菜系、标签"

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(TastyTheme.secondaryInk)

            TextField(prompt, text: $text)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(TastyTheme.secondaryInk.opacity(0.70))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("清除搜索")
            }
        }
        .padding(.horizontal, 13)
        .frame(height: 43)
        .background(TastyTheme.raisedPaper)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(TastyTheme.hairline.opacity(0.80), lineWidth: 1)
        }
    }
}
