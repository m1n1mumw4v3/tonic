import SwiftUI

struct ProductDetailScreen: View {
    let productId: UUID
    let resolveProduct: (UUID) -> RankedProduct?

    @Environment(\.dismiss) private var dismiss
    @State private var expandedNoteIndex: Int? = nil

    private var rankedProduct: RankedProduct? {
        resolveProduct(productId)
    }

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            if let rankedProduct {
                productContent(rankedProduct)
            } else {
                notFoundState
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Product Content

    private func productContent(_ rankedProduct: RankedProduct) -> some View {
        let product = rankedProduct.product
        let score = rankedProduct.score
        let certifications = rankedProduct.certifications

        return ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.spacing16) {
                // Header with back navigation
                headerSection(product: product, score: score)

                SpectrumBar(height: 2)

                // Stats row
                statsRow(rankedProduct: rankedProduct)

                // Shop buttons
                shopButtons(rankedProduct: rankedProduct)

                // Certification badges (top 3)
                if !certifications.isEmpty {
                    certificationChips(certifications: certifications)
                }

                // Score breakdown
                scoreBreakdownSection(score: score)

                // Full certifications list
                if !certifications.isEmpty {
                    fullCertificationsList(certifications: certifications)
                }
            }
            .padding(.horizontal, DesignTokens.screenMargin)
            .padding(.bottom, DesignTokens.spacing32)
        }
    }

    // MARK: - Header

    private func headerSection(product: DBProduct, score: DBProductScore) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
            // Back button
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(DesignTokens.textSecondary)
            }
            .buttonStyle(.plain)

            // Image + product info row
            HStack(alignment: .top, spacing: DesignTokens.spacing16) {
                // Product image
                RoundedRectangle(cornerRadius: DesignTokens.radiusSmall)
                    .fill(DesignTokens.bgElevated)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "pill.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(DesignTokens.textTertiary)
                    )

                // Product details
                VStack(alignment: .leading, spacing: DesignTokens.spacing4) {
                    Text(product.brand.uppercased())
                        .font(DesignTokens.captionFont)
                        .tracking(0.8)
                        .foregroundStyle(DesignTokens.textSecondary)

                    Text(product.name)
                        .font(DesignTokens.titleFont)
                        .foregroundStyle(DesignTokens.textPrimary)
                        .lineLimit(3)

                    // Score badge
                    HStack(spacing: 4) {
                        Text(String(format: "%.1f", score.estusScore))
                            .font(.custom("Geist-Bold", size: 14))
                            .foregroundStyle(score.scoreColor)

                        Text(score.scoreLabel)
                            .font(DesignTokens.smallMono)
                            .foregroundStyle(score.scoreColor)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(score.scoreColor.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(score.scoreColor.opacity(0.2), lineWidth: 1)
                    )

                }
            }
        }
        .padding(.top, DesignTokens.spacing8)
    }

    // MARK: - Stats Row

    private func statsRow(rankedProduct: RankedProduct) -> some View {
        HStack(spacing: 0) {
            if let servings = rankedProduct.product.servingsPerContainer {
                statItem(label: "Servings", value: "\(servings)")
            }

            if let pps = rankedProduct.bestPricePerServing {
                statItem(label: "Per serving", value: String(format: "$%.2f", pps))
            }

            if let price = rankedProduct.bestPrice {
                statItem(label: "From", value: String(format: "$%.2f", price))
            }

            if let format = rankedProduct.product.format {
                statItem(label: "Format", value: format.capitalized)
            }
        }
        .padding(DesignTokens.spacing12)
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(DesignTokens.borderDefault, lineWidth: 1)
        )
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

    // MARK: - Shop Buttons

    @ViewBuilder
    private func shopButtons(rankedProduct: RankedProduct) -> some View {
        let pricing = rankedProduct.pricing
        let hasAmazon = pricing?.amazonUrl != nil
        let hasDirect = pricing?.mfrUrl != nil

        if hasAmazon || hasDirect {
            HStack(spacing: DesignTokens.spacing12) {
                if let amazonUrl = pricing?.amazonUrl, let url = URL(string: amazonUrl) {
                    amazonButton(url: url)
                }

                if let mfrUrl = pricing?.mfrUrl, let url = URL(string: mfrUrl) {
                    directButton(url: url)
                }
            }
        } else if let productUrl = rankedProduct.product.productUrl, let url = URL(string: productUrl) {
            directButton(url: url, label: "View Product")
        }
    }

    private func amazonButton(url: URL) -> some View {
        Button {
            HapticManager.selection()
            UIApplication.shared.open(url)
        } label: {
            HStack(spacing: DesignTokens.spacing8) {
                Image("AmazonLogo")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 18)
                Text("Buy on Amazon")
                    .font(DesignTokens.bodyFont)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(Color(red: 0.17, green: 0.17, blue: 0.17))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color(red: 1.0, green: 0.72, blue: 0.17))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
        }
        .buttonStyle(.plain)
    }

    private func directButton(url: URL, label: String = "Buy Direct") -> some View {
        Button {
            HapticManager.selection()
            UIApplication.shared.open(url)
        } label: {
            HStack(spacing: DesignTokens.spacing8) {
                Image(systemName: "bag")
                    .font(.system(size: 14))
                Text(label)
                    .font(DesignTokens.bodyFont)
                    .fontWeight(.semibold)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Certification Chips

    private func certificationChips(certifications: [DBProductCertification]) -> some View {
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

    // MARK: - Score Breakdown

    private func scoreBreakdownSection(score: DBProductScore) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(DesignTokens.textSecondary)
                Text("ESTUS SCORE BREAKDOWN")
                    .font(DesignTokens.sectionHeader)
                    .tracking(1.2)
                    .foregroundStyle(DesignTokens.textSecondary)
            }

            ForEach(Array(score.categoryBreakdowns.enumerated()), id: \.offset) { index, breakdown in
                categoryRow(
                    index: index,
                    label: breakdown.label,
                    score: breakdown.score,
                    notes: breakdown.notes
                )
            }
        }
        .padding(DesignTokens.spacing16)
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(DesignTokens.borderDefault, lineWidth: 1)
        )
    }

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

            if expandedNoteIndex == index, let notes {
                Text(notes)
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textSecondary)
                    .padding(.top, DesignTokens.spacing4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Full Certifications List

    private func fullCertificationsList(certifications: [DBProductCertification]) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing16) {
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
                HStack(alignment: .center, spacing: DesignTokens.spacing12) {
                    // Certification icon
                    RoundedRectangle(cornerRadius: DesignTokens.radiusSmall)
                        .fill(DesignTokens.bgElevated)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: cert.certificationType.icon)
                                .font(.system(size: 18))
                                .foregroundStyle(DesignTokens.textSecondary)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(cert.certificationType.label)
                            .font(DesignTokens.captionFont)
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignTokens.textPrimary)

                        Text(cert.certificationType.description)
                            .font(DesignTokens.captionFont)
                            .foregroundStyle(DesignTokens.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.spacing16)
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(DesignTokens.borderDefault, lineWidth: 1)
        )
    }

    // MARK: - Not Found State

    private var notFoundState: some View {
        VStack(spacing: DesignTokens.spacing12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(DesignTokens.textTertiary)

            Text("Product not found")
                .font(DesignTokens.bodyFont)
                .foregroundStyle(DesignTokens.textPrimary)

            Button {
                dismiss()
            } label: {
                Text("Go Back")
                    .font(DesignTokens.captionFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignTokens.info)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DesignTokens.spacing48)
    }
}
