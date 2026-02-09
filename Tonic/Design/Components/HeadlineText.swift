import SwiftUI
import UIKit

/// A text view that renders headline text with a precise line-height multiplier.
/// SwiftUI's `.lineSpacing()` cannot reduce below the font default,
/// so this uses NSAttributedString paragraph style for exact control.
struct HeadlineText: View {
    let text: String
    var alignment: TextAlignment = .leading

    private static let fontSize: CGFloat = 28

    var body: some View {
        Text(attributed)
            .multilineTextAlignment(alignment)
    }

    private var attributed: AttributedString {
        let font = UIFont(name: "Geist-Light", size: Self.fontSize)
            ?? UIFont.systemFont(ofSize: Self.fontSize, weight: .light)

        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = 0.78
        style.alignment = alignment.nsAlignment

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: style,
            .foregroundColor: UIColor(DesignTokens.textPrimary)
        ]

        return AttributedString(
            NSAttributedString(string: text, attributes: attributes)
        )
    }
}

private extension TextAlignment {
    var nsAlignment: NSTextAlignment {
        switch self {
        case .leading: .left
        case .center: .center
        case .trailing: .right
        }
    }
}
