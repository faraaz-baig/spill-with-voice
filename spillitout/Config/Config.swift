import Foundation

/// Application configuration that reads from xcconfig files
/// Values are automatically set based on build configuration (Debug/Release)
enum Config {
    /// Base URL for the API
    /// - Debug: http://localhost:3000/api
    /// - Release: https://api.yourapp.com/api
    static var apiBaseURL: String {
        // Try to read from Info.plist first
        if let urlString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           !urlString.isEmpty,
           urlString != "$(API_BASE_URL)" {
            print("DEBUG: Using API_BASE_URL from Info.plist: '\(urlString)'")
            return urlString
        }

        // Fallback to hardcoded URLs based on build configuration
        #if DEBUG
        let fallbackURL = "http://localhost:3000/api"
        #else
        let fallbackURL = "https://api.yourapp.com/api"
        #endif

        print("DEBUG: Using fallback API_BASE_URL: '\(fallbackURL)'")
        return fallbackURL
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
