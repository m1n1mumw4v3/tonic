import SwiftUI

struct ProductListCard: View {
    let rankedProduct: RankedProduct
    var onTap: (() -> Void)? = nil

    private var product: DBProduct { rankedProduct.product }
    private var score: DBProductScore { rankedProduct.score }

    var body: some View {
        Button {
            HapticManager.selection()
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
                // Pick label badge — always rendered so list rows align
                Text((score.pickLabel ?? "Estus Approved").uppercased())
                    .font(DesignTokens.smallMono)
                    .foregroundStyle(badgeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .overlay(
                        Capsule()
                            .stroke(badgeColor, lineWidth: 1)
                    )
                    .clipShape(Capsule())

                // Main row: image | text | chevron
                HStack(alignment: .center, spacing: DesignTokens.spacing12) {
                    ProductImageView(imageUrl: product.imageUrl, size: 80, placeholderIconSize: 20)

                    VStack(alignment: .leading, spacing: 4) {
                        // Brand
                        Text(product.brand.uppercased())
                            .font(DesignTokens.labelMono)
                            .foregroundStyle(DesignTokens.textSecondary)
                            .lineLimit(1)

                        // Product name
                        Text(product.name)
                            .font(DesignTokens.captionFont)
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignTokens.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        // Score chip
                        HStack(spacing: 4) {
                            Circle()
                                .fill(score.scoreColor)
                                .frame(width: 6, height: 6)

                            Text(String(format: "%.1f", score.estusScore))
                                .font(.custom("Geist-Bold", size: 11))
                                .foregroundStyle(score.scoreColor)

                            Text(score.scoreLabel)
                                .font(DesignTokens.smallMono)
                                .foregroundStyle(DesignTokens.textPrimary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(DesignTokens.borderDefault, lineWidth: 1)
                        )
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DesignTokens.textTertiary)
                }

                // Stats row
                statsGrid
                    .padding(.top, DesignTokens.spacing4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignTokens.spacing12)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                    .stroke(DesignTokens.borderDefault, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var badgeColor: Color {
        guard score.pickLabel != nil else { return DesignTokens.accentEnergyDark }
        return score.pickRank == 1 ? DesignTokens.positive : DesignTokens.info
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        HStack(spacing: 0) {
            if let servings = product.servingsPerContainer {
                miniStat(label: "Servings", value: "\(servings)")
            }
            if let pps = rankedProduct.bestPricePerServing {
                miniStat(label: "Price/serv", value: String(format: "$%.2f", pps))
            }
            if let price = rankedProduct.bestPrice {
                miniStat(label: "From", value: String(format: "$%.2f", price))
            }
            if let format = product.format {
                miniStat(label: "Format", value: format.capitalized)
            }
        }
    }

    private func miniStat(label: String, value: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(DesignTokens.smallMono)
                .foregroundStyle(DesignTokens.textPrimary)
            Text(label.uppercased())
                .font(.custom("GeistMono-Regular", size: 8))
                .foregroundStyle(DesignTokens.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
