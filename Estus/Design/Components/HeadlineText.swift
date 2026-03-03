import SwiftUI
import UIKit

/// A text view that renders headline text with a precise line height.
/// Uses a `UILabel` via `UIViewRepresentable` because SwiftUI's `Text`
/// silently ignores `NSParagraphStyle` line-height attributes from `AttributedString`.
struct HeadlineText: View {
    let text: String
    var alignment: TextAlignment = .leading
    var fontSize: CGFloat? = nil

    var body: some View {
        HeadlineLabel(text: text, alignment: alignment, fontSize: fontSize)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct HeadlineLabel: UIViewRepresentable {
    let text: String
    let alignment: TextAlignment
    var fontSize: CGFloat? = nil

    static let defaultFontSize: CGFloat = 28
    static let defaultLineHeight: CGFloat = 32

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        label.attributedText = makeAttributedString()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UILabel, context: Context) -> CGSize? {
        let width = proposal.width ?? UIScreen.main.bounds.width
        let size = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return size
    }

    private func makeAttributedString() -> NSAttributedString {
        let size = fontSize ?? Self.defaultFontSize
        let lineHeight = fontSize != nil ? (fontSize! * (Self.defaultLineHeight / Self.defaultFontSize)).rounded() : Self.defaultLineHeight
        let font = UIFont(name: "Geist-Light", size: size)
            ?? UIFont.systemFont(ofSize: size, weight: .light)

        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        style.alignment = alignment.nsAlignment

        let baselineOffset = (lineHeight - font.lineHeight) / 2

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: style,
            .foregroundColor: UIColor(DesignTokens.textPrimary),
            .baselineOffset: baselineOffset
        ]

        return NSAttributedString(string: text, attributes: attributes)
    }
}

private extension TextAlignment {
    var nsAlignment: NSTextAlignment {
        switch self {
        case .leading: .natural
        case .center: .center
        case .trailing: .right
        }
    }
}
