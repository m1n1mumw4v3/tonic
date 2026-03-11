import SwiftUI

struct ShopLinksSheet: View {
    let product: DBProduct
    let pricing: DBProductPricing?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing16) {
            // Header
            VStack(alignment: .leading, spacing: DesignTokens.spacing4) {
                Text(product.brand)
                    .font(DesignTokens.labelMono)
                    .foregroundStyle(DesignTokens.textSecondary)

                Text(product.name)
                    .font(DesignTokens.bodyFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .lineLimit(2)
            }

            Divider()

            // Amazon link
            if let amazonUrl = pricing?.amazonUrl, let url = URL(string: amazonUrl) {
                shopRow(
                    icon: "cart.fill",
                    label: "Buy on Amazon",
                    price: pricing?.amazonPrice,
                    pricePerServing: pricing?.amazonPricePerServing,
                    url: url
                )
            }

            // Manufacturer link
            if let mfrUrl = pricing?.mfrUrl, let url = URL(string: mfrUrl) {
                shopRow(
                    icon: "storefront.fill",
                    label: "Buy Direct",
                    price: pricing?.mfrPrice,
                    pricePerServing: pricing?.mfrPricePerServing,
                    url: url
                )
            }

            // Product page link
            if let productUrl = product.productUrl, let url = URL(string: productUrl) {
                if pricing?.amazonUrl == nil && pricing?.mfrUrl == nil {
                    shopRow(
                        icon: "globe",
                        label: "View Product",
                        price: nil,
                        pricePerServing: nil,
                        url: url
                    )
                }
            }

            Divider()

            Text("Estus does not participate in affiliate programs.")
                .font(DesignTokens.smallMono)
                .foregroundStyle(DesignTokens.textTertiary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(DesignTokens.spacing24)
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Shop Row

    private func shopRow(icon: String, label: String, price: Double?, pricePerServing: Double?, url: URL) -> some View {
        Button {
            UIApplication.shared.open(url)
        } label: {
            HStack(spacing: DesignTokens.spacing12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(DesignTokens.textPrimary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(DesignTokens.textPrimary)

                    HStack(spacing: 6) {
                        if let price {
                            Text(String(format: "$%.2f", price))
                                .font(DesignTokens.labelMono)
                                .foregroundStyle(DesignTokens.textSecondary)
                        }
                        if let pps = pricePerServing {
                            Text(String(format: "$%.2f/serv", pps))
                                .font(DesignTokens.smallMono)
                                .foregroundStyle(DesignTokens.textTertiary)
                        }
                    }
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("Visit site")
                        .font(DesignTokens.labelMono)
                        .foregroundStyle(DesignTokens.info)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10))
                        .foregroundStyle(DesignTokens.info)
                }
            }
            .padding(DesignTokens.spacing12)
            .background(DesignTokens.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusSmall))
        }
        .buttonStyle(.plain)
    }
}
