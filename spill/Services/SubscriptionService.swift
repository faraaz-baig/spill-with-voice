import Foundation

class SubscriptionService {
    static let shared = SubscriptionService()

    private var baseURL: String {
        return Config.apiBaseURL
    }

    private init() {}

    struct SubscriptionStatus: Codable {
        let hasSubscription: Bool
        let status: String?
        let deviceId: String
        let currentPeriodEnd: String?
        let cancelAtPeriodEnd: Bool?
    }

    /// Check if device has an active subscription
    func checkSubscription(deviceId: String) async throws -> Bool {
        let urlString = "\(baseURL)/subscription/status/\(deviceId)"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let subscriptionStatus = try JSONDecoder().decode(SubscriptionStatus.self, from: data)
        return subscriptionStatus.hasSubscription
    }
}
