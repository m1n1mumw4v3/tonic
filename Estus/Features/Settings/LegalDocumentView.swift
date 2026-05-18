import SwiftUI

enum LegalDocument: String, Identifiable {
    case privacyPolicy = "PrivacyPolicy"
    case termsOfService = "TermsOfService"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacyPolicy: return "Privacy Policy"
        case .termsOfService: return "Terms of Service"
        }
    }
}

struct LegalDocumentView: View {
    let document: LegalDocument
    @Environment(\.dismiss) private var dismiss

    private var markdown: String {
        guard let url = Bundle.main.url(forResource: document.rawValue, withExtension: "md"),
              let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return "Unable to load document."
        }
        return contents
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.spacing16) {
                    ForEach(Array(parsedBlocks().enumerated()), id: \.offset) { _, block in
                        blockView(block)
                    }
                }
                .padding(.horizontal, DesignTokens.screenMargin)
                .padding(.vertical, DesignTokens.spacing24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(DesignTokens.bgDeepest)
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DesignTokens.textPrimary)
                }
            }
        }
    }

    @ViewBuilder
    private func blockView(_ block: Block) -> some View {
        switch block {
        case .heading1(let text):
            Text(text)
                .font(DesignTokens.titleFont)
                .foregroundStyle(DesignTokens.textPrimary)
                .padding(.top, DesignTokens.spacing8)
        case .heading2(let text):
            Text(text)
                .font(DesignTokens.ctaFont)
                .foregroundStyle(DesignTokens.textPrimary)
                .padding(.top, DesignTokens.spacing12)
        case .heading3(let text):
            Text(text)
                .font(DesignTokens.sectionHeader)
                .foregroundStyle(DesignTokens.textPrimary)
                .padding(.top, DesignTokens.spacing8)
        case .paragraph(let attributed):
            Text(attributed)
                .font(DesignTokens.captionFont)
                .foregroundStyle(DesignTokens.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        case .bullet(let attributed):
            HStack(alignment: .firstTextBaseline, spacing: DesignTokens.spacing8) {
                Text("•")
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textSecondary)
                Text(attributed)
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, DesignTokens.spacing4)
        }
    }

    private enum Block {
        case heading1(String)
        case heading2(String)
        case heading3(String)
        case paragraph(AttributedString)
        case bullet(AttributedString)
    }

    private func parsedBlocks() -> [Block] {
        var blocks: [Block] = []
        var paragraphBuffer: [String] = []

        func flushParagraph() {
            guard !paragraphBuffer.isEmpty else { return }
            let joined = paragraphBuffer.joined(separator: " ")
            blocks.append(.paragraph(attributedFrom(joined)))
            paragraphBuffer.removeAll()
        }

        for rawLine in markdown.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.isEmpty {
                flushParagraph()
            } else if line.hasPrefix("### ") {
                flushParagraph()
                blocks.append(.heading3(String(line.dropFirst(4))))
            } else if line.hasPrefix("## ") {
                flushParagraph()
                blocks.append(.heading2(String(line.dropFirst(3))))
            } else if line.hasPrefix("# ") {
                flushParagraph()
                blocks.append(.heading1(String(line.dropFirst(2))))
            } else if line.hasPrefix("- ") {
                flushParagraph()
                blocks.append(.bullet(attributedFrom(String(line.dropFirst(2)))))
            } else {
                paragraphBuffer.append(line)
            }
        }
        flushParagraph()
        return blocks
    }

    private func attributedFrom(_ text: String) -> AttributedString {
        if let attributed = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return attributed
        }
        return AttributedString(text)
    }
}
