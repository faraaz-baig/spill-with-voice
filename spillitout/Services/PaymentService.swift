import Foundation
import AppKit

class PaymentService {
    static let shared = PaymentService()

    private var baseURL: String {
        return Config.apiBaseURL
    }

    private init() {}

    struct CheckoutSessionRequest: Codable {
        let deviceId: String
        let productId: String?
    }

    struct CheckoutSessionResponse: Codable {
        let sessionId: String
        let url: String
    }

    /// Create a checkout session and open it in the browser
    func createCheckoutSession(deviceId: String) async throws -> String {
        let urlString = "\(baseURL)/create-checkout-session"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = CheckoutSessionRequest(deviceId: deviceId, productId: nil)
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let checkoutResponse = try JSONDecoder().decode(CheckoutSessionResponse.self, from: data)

        // Open checkout URL in default browser
        if let checkoutURL = URL(string: checkoutResponse.url) {
            await MainActor.run {
                NSWorkspace.shared.open(checkoutURL)
            }
        }

        return checkoutResponse.sessionId
    }
}
