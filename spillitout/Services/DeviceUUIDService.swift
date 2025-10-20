//
//  DeviceUUIDService.swift
//  spillitout
//
//  Manages device UUID stored securely in Keychain
//

import Foundation
import Security

class DeviceUUIDService {
    static let shared = DeviceUUIDService()

    private let service = "com.spillitout.device"
    private let account = "device-uuid"

    private init() {}

    /// Get or create a device UUID stored in Keychain
    func getOrCreateDeviceUUID() -> String {
        // Try to get existing UUID from Keychain
        if let existingUUID = getUUIDFromKeychain() {
            return existingUUID
        }

        // Create new UUID and save to Keychain
        let newUUID = UUID().uuidString
        saveUUIDToKeychain(newUUID)
        return newUUID
    }

    // MARK: - Private Keychain Methods

    private func getUUIDFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess,
           let data = dataTypeRef as? Data,
           let uuid = String(data: data, encoding: .utf8) {
            return uuid
        }

        return nil
    }

    private func saveUUIDToKeychain(_ uuid: String) {
        guard let data = uuid.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        // Delete any existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            print("Failed to save UUID to Keychain: \(status)")
        }
    }
}
