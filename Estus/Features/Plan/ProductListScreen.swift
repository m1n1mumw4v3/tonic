import SwiftUI

struct ProductListScreen: View {
    let supplementId: UUID
    let supplementName: String
    var cachedProducts: [RankedProduct]?
    var onProductTapped: ((RankedProduct) -> Void)? = nil
    var onShopTapped: ((RankedProduct) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var products: [RankedProduct] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.spacing16) {
                    // Header
                    header

                    SpectrumBar(height: 2)

                    if isLoading {
                        loadingState
                    } else if let errorMessage {
                        errorState(errorMessage)
                    } else if products.isEmpty {
                        emptyState
                    } else {
                        ForEach(products) { rankedProduct in
                            ProductListCard(
                                rankedProduct: rankedProduct,
                                onTap: {
                                    onProductTapped?(rankedProduct)
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.screenMargin)
                .padding(.bottom, DesignTokens.spacing32)
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadProducts()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing4) {
            Button {
                dismiss()
            } label: {
                HStack(spacing: DesignTokens.spacing8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(DesignTokens.textSecondary)

                    Text(supplementName)
                        .font(DesignTokens.headlineFont)
                        .foregroundStyle(DesignTokens.textPrimary)
                }
            }
            .buttonStyle(.plain)

            if !isLoading && products.count > 0 {
                Text("\(products.count) products")
                    .font(DesignTokens.labelMono)
                    .foregroundStyle(DesignTokens.textSecondary)
            }
        }
        .padding(.top, DesignTokens.spacing8)
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: DesignTokens.spacing16) {
            ProgressView()
                .tint(DesignTokens.textTertiary)
            Text("Loading products...")
                .font(DesignTokens.captionFont)
                .foregroundStyle(DesignTokens.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DesignTokens.spacing48)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: DesignTokens.spacing12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(DesignTokens.textTertiary)

            Text(message)
                .font(DesignTokens.captionFont)
                .foregroundStyle(DesignTokens.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await loadProducts() }
            } label: {
                Text("Try Again")
                    .font(DesignTokens.captionFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignTokens.info)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DesignTokens.spacing48)
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.spacing12) {
            Image(systemName: "bag")
                .font(.system(size: 32))
                .foregroundStyle(DesignTokens.textTertiary)

            Text("No scored products yet")
                .font(DesignTokens.bodyFont)
                .foregroundStyle(DesignTokens.textPrimary)

            Text("We're actively reviewing products for this supplement. Check back soon.")
                .font(DesignTokens.captionFont)
                .foregroundStyle(DesignTokens.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DesignTokens.spacing48)
    }

    // MARK: - Data Loading

    private func loadProducts() async {
        if let cachedProducts, !cachedProducts.isEmpty {
            products = cachedProducts
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            let service = SupplementService()
            products = try await service.fetchProducts(forSupplementId: supplementId)
            isLoading = false
        } catch {
            errorMessage = "Couldn't load products. Check your connection and try again."
            isLoading = false
        }
    }
}
