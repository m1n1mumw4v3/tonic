import SwiftUI

// MARK: - Inline Product Card

struct InlineProductCardView: View {
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
                // Pick label badge
                if let pickLabel = score.pickLabel {
                    Text(pickLabel.uppercased())
                        .font(DesignTokens.smallMono)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            score.pickRank == 1 ? DesignTokens.positive : DesignTokens.info
                        )
                        .clipShape(Capsule())
                }

                // Image left, text right
                HStack(alignment: .top, spacing: DesignTokens.spacing12) {
                    // Square image placeholder
                    RoundedRectangle(cornerRadius: DesignTokens.radiusSmall)
                        .fill(DesignTokens.bgElevated)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "pill.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(DesignTokens.textTertiary)
                        )

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

                        // Score chip (outlined)
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
                }

                // Stats row
                statsGrid
                    .padding(.top, DesignTokens.spacing4)
            }
            .frame(width: 260)
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

// MARK: - See All Product Card

struct SeeAllProductCard: View {
    let supplementName: String
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            HapticManager.selection()
            onTap?()
        } label: {
            VStack(spacing: DesignTokens.spacing12) {
                Spacer()

                Image(systemName: "bag")
                    .font(.system(size: 24))
                    .foregroundStyle(DesignTokens.positive)

                VStack(spacing: 2) {
                    Text("See all")
                        .font(DesignTokens.captionFont)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignTokens.positive)

                    Text(supplementName)
                        .font(DesignTokens.smallMono)
                        .foregroundStyle(DesignTokens.positive.opacity(0.7))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }

                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DesignTokens.positive)

                Spacer()
            }
            .frame(width: 130)
            .padding(DesignTokens.spacing12)
            .background(DesignTokens.positive.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                    .stroke(DesignTokens.positive.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
