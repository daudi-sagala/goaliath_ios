import Foundation
import Security

/// ThisDeviceOnly avoids synchronizing bearer session credentials to other devices.
/// Unlike UserDefaults, Keychain is appropriate for storing an opaque session secret.
enum GoaliathAuthKeychain {
    private static let service = "com.goaliath.auth.better-auth"
    private static let account = "session"

    static func load() -> String? {
        let query: [String:Any] = [kSecClass as String:kSecClassGenericPassword,
            kSecAttrService as String:service,kSecAttrAccount as String:account,
            kSecReturnData as String:true,kSecMatchLimit as String:kSecMatchLimitOne]
        var value:CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary,&value)==errSecSuccess,
              let data=value as? Data else { return nil }
        return String(data:data,encoding:.utf8)
    }

    static func save(_ token:String) throws {
        let data=Data(token.utf8)
        let key:[String:Any]=[kSecClass as String:kSecClassGenericPassword,
            kSecAttrService as String:service,kSecAttrAccount as String:account]
        let update:[String:Any]=[kSecValueData as String:data,
            kSecAttrAccessible as String:kSecAttrAccessibleWhenUnlockedThisDeviceOnly]
        let code=SecItemUpdate(key as CFDictionary,update as CFDictionary)
        if code==errSecItemNotFound {
            var insert=key
            update.forEach { insert[$0.key]=$0.value }
            let status=SecItemAdd(insert as CFDictionary,nil)
            guard status==errSecSuccess else { throw GoaliathAPIError(status:Int(status),message:"Cannot securely save session") }
        } else if code != errSecSuccess {
            throw GoaliathAPIError(status:Int(code),message:"Cannot securely update session")
        }
    }

    static func clear() {
        let key:[String:Any]=[kSecClass as String:kSecClassGenericPassword,
            kSecAttrService as String:service,kSecAttrAccount as String:account]
        SecItemDelete(key as CFDictionary)
    }
}
