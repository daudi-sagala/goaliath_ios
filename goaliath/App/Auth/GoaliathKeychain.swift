import Foundation
import Security

struct GoaliathKeychain {
    private let service = "com.goaliath.ios.auth"
    private let account = "better-auth-bearer"

    private var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    func loadToken() throws -> String? {
        var lookup = query
        lookup[kSecReturnData as String] = true
        lookup[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(lookup as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw GoaliathKeychainError.failure(status)
        }
        return token
    }

    func saveToken(_ token: String) throws {
        let payload = Data(token.utf8)
        let update: [String: Any] = [
            kSecValueData as String: payload,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if status == errSecItemNotFound {
            var attributes = query
            attributes.merge(update) { _, new in new }
            let addStatus = SecItemAdd(attributes as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw GoaliathKeychainError.failure(addStatus)
            }
        } else if status != errSecSuccess {
            throw GoaliathKeychainError.failure(status)
        }
    }

    /// Remove credentials from the superseded OTP/Apple authentication stack.
    /// They are not compatible with the current single email/password authority.
    func clearLegacyToken() {
        let oldKey: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.goaliath.auth.better-auth",
            kSecAttrAccount as String: "session"
        ]
        SecItemDelete(oldKey as CFDictionary)
    }

    func deleteToken() throws {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw GoaliathKeychainError.failure(status)
        }
    }
}

enum GoaliathKeychainError: LocalizedError {
    case failure(OSStatus)

    var errorDescription: String? {
        "Unable to access secure sign-in storage on this device."
    }
}
