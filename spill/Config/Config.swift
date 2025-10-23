import Foundation

/// Application configuration that reads from xcconfig files
/// Values are automatically set based on build configuration (Debug/Release)
enum Config {
    /// Base URL for the API
    static var apiBaseURL: String {
        return "https://ghq.rathoreactual.com/spill/api"
    }

    /// Current build configuration
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    /// Current environment name for logging
    static var environmentName: String {
        return isDebug ? "Development" : "Production"
    }
}
