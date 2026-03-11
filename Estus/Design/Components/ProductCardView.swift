import SwiftUI

struct ProductCardView: View {
    let rankedProduct: RankedProduct
    var onShopTapped: (() -> Void)? = nil

    @State private var isExpanded = false
    @State private var expandedNoteIndex: Int? = nil

    private var product: DBProduct { rankedProduct.product }
    private var score: DBProductScore { rankedProduct.score }
    private var certifications: [DBProductCertification] { rankedProduct.certifications }

    var body: some View {
        VStack(spacing: 0) {
            // Always-visible collapsed content
            collapsedContent

            // Expanded breakdown
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
        }
        .padding(DesignTokens.spacing16)
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(DesignTokens.borderDefault, lineWidth: 1)
        )
        .shadow(color: DesignTokens.cardShadowColor, radius: DesignTokens.cardShadowRadius, x: 0, y: DesignTokens.cardShadowY)
        .onTapGesture {
            HapticManager.selection()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isExpanded.toggle()
                if !isExpanded { expandedNoteIndex = nil }
            }
        }
    }

    // MARK: - Collapsed Content

    private var collapsedContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
            // Pick label + score row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DesignTokens.spacing4) {
                    // Pick label badge
                    if let pickLabel = score.pickLabel {
                        Text(pickLabel.uppercased())
                            .font(DesignTokens.smallMono)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                (score.pickRank == 1 ? DesignTokens.positive : DesignTokens.info)
                            )
                            .clipShape(Capsule())
                    }

                    // Product name + brand
                    Text(product.name)
                        .font(DesignTokens.bodyFont)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignTokens.textPrimary)
                        .lineLimit(2)

                    Text(product.brand)
                        .font(DesignTokens.labelMono)
                        .foregroundStyle(DesignTokens.textSecondary)
                }

                Spacer()

                // Estus Score badge
                scoreBadge
            }

            // Stats row
            statsRow

            // Actions row
            HStack(spacing: DesignTokens.spacing8) {
                if onShopTapped != nil {
                    Button {
                        HapticManager.selection()
                        onShopTapped?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "bag")
                                .font(.system(size: 11))
                            Text("SHOP")
                                .font(DesignTokens.smallMono)
                        }
                        .foregroundStyle(DesignTokens.positive)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(DesignTokens.positive.opacity(0.08))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(DesignTokens.positive.opacity(0.25), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                // Top certifications
                certificationBadges
            }

            // Expand hint
            HStack(spacing: 4) {
                Text(isExpanded ? "LESS" : "SCORE BREAKDOWN")
                    .font(DesignTokens.smallMono)
                    .foregroundStyle(DesignTokens.textTertiary)
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(DesignTokens.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, DesignTokens.spacing4)
        }
    }

    // MARK: - Score Badge

    private var scoreBadge: some View {
        VStack(spacing: 2) {
            Text(String(format: "%.1f", score.estusScore))
                .font(.custom("Geist-Bold", size: 16))
                .foregroundStyle(score.scoreColor)

            Text(score.scoreLabel)
                .font(DesignTokens.smallMono)
                .foregroundStyle(score.scoreColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(score.scoreColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusSmall))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusSmall)
                .stroke(score.scoreColor.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            if let servings = product.servingsPerContainer {
                statItem(label: "Servings", value: "\(servings)")
            }

            if let pps = rankedProduct.bestPricePerServing {
                statItem(label: "Per serving", value: String(format: "$%.2f", pps))
            }

            if let price = rankedProduct.bestPrice {
                statItem(label: "From", value: String(format: "$%.2f", price))
            }

            if let format = product.format {
                statItem(label: "Format", value: format.capitalized)
            }
        }
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(DesignTokens.labelMono)
                .foregroundStyle(DesignTokens.textPrimary)
            Text(label.uppercased())
                .font(DesignTokens.smallMono)
                .foregroundStyle(DesignTokens.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Certification Badges

    private var certificationBadges: some View {
        HStack(spacing: 4) {
            ForEach(certifications.prefix(3)) { cert in
                HStack(spacing: 3) {
                    Image(systemName: cert.certificationType.icon)
                        .font(.system(size: 9))
                    Text(cert.certificationType.label)
                        .font(DesignTokens.smallMono)
                }
                .foregroundStyle(DesignTokens.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(DesignTokens.bgElevated)
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
            Divider()
                .padding(.vertical, DesignTokens.spacing4)

            // Score breakdown header
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(DesignTokens.textSecondary)
                Text("ESTUS SCORE BREAKDOWN")
                    .font(DesignTokens.sectionHeader)
                    .tracking(1.2)
                    .foregroundStyle(DesignTokens.textSecondary)
            }

            // Category rows
            ForEach(Array(score.categoryBreakdowns.enumerated()), id: \.offset) { index, breakdown in
                categoryRow(
                    index: index,
                    label: breakdown.label,
                    score: breakdown.score,
                    notes: breakdown.notes
                )
            }

            // Full certifications list
            if !certifications.isEmpty {
                Divider()
                    .padding(.vertical, DesignTokens.spacing4)

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.textSecondary)
                    Text("CERTIFICATIONS")
                        .font(DesignTokens.sectionHeader)
                        .tracking(1.2)
                        .foregroundStyle(DesignTokens.textSecondary)
                }

                ForEach(certifications) { cert in
                    HStack(spacing: DesignTokens.spacing8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(DesignTokens.positive)
                            .frame(width: 16)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(cert.certificationType.label)
                                .font(DesignTokens.captionFont)
                                .fontWeight(.semibold)
                                .foregroundStyle(DesignTokens.textPrimary)

                            if let body = cert.certifyingBody {
                                Text(body)
                                    .font(DesignTokens.smallMono)
                                    .foregroundStyle(DesignTokens.textTertiary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Category Row

    private func categoryRow(index: Int, label: String, score: Double?, notes: String?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    expandedNoteIndex = expandedNoteIndex == index ? nil : index
                }
            } label: {
                HStack(spacing: DesignTokens.spacing8) {
                    Text(label)
                        .font(DesignTokens.captionFont)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignTokens.textPrimary)

                    Spacer()

                    if let score {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(score.categoryScoreColor)
                                .frame(width: 6, height: 6)

                            Text(String(format: "%.1f", score))
                                .font(DesignTokens.labelMono)
                                .foregroundStyle(score.categoryScoreColor)

                            Text(score.categoryScoreLabel)
                                .font(DesignTokens.smallMono)
                                .foregroundStyle(score.categoryScoreColor)
                        }
                    } else {
                        Text("N/A")
                            .font(DesignTokens.labelMono)
                            .foregroundStyle(DesignTokens.textTertiary)
                    }

                    if notes != nil {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(DesignTokens.textTertiary)
                            .rotationEffect(.degrees(expandedNoteIndex == index ? 90 : 0))
                    }
                }
            }
            .buttonStyle(.plain)

            // Expanded notes
            if expandedNoteIndex == index, let notes {
                Text(notes)
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textSecondary)
                    .padding(.top, DesignTokens.spacing4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
