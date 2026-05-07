import StoreKit
import Foundation
import Combine

// MARK: - Product IDs (must match App Store Connect exactly)
enum ProductID {
    static let premium = "com.yourname.lifesubtraction.premium"
}

// MARK: - Store Manager
@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()

    @Published var products: [Product] = []
    @Published var isPremium: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var updateListenerTask: Task<Void, Error>? = nil

    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await refreshPurchaseStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products from App Store Connect
    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: [ProductID.premium])
        } catch {
            errorMessage = "無法載入商品：\(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Purchase
    func purchase() async {
        guard let product = products.first else {
            errorMessage = "找不到商品"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshPurchaseStatus()
            case .userCancelled:
                break
            case .pending:
                errorMessage = "付款待確認（例如家長審核）"
            @unknown default:
                break
            }
        } catch {
            errorMessage = "購買失敗：\(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Restore Purchases
    func restore() async {
        isLoading = true
        do {
            try await AppStore.sync()
            await refreshPurchaseStatus()
        } catch {
            errorMessage = "還原失敗：\(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Check current entitlement
    func refreshPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == ProductID.premium,
               transaction.revocationDate == nil {
                isPremium = true
                return
            }
        }
        isPremium = false
    }

    // MARK: - Listen for transaction updates (renewals, refunds, etc.)
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.refreshPurchaseStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Verify transaction signature
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Formatted price helper
    var premiumProduct: Product? { products.first }

    var formattedPrice: String {
        guard let product = premiumProduct else { return "NT$90" }
        return product.displayPrice
    }
}
