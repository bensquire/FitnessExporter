import Foundation
import Security

/// A Keychain call that failed, with the system's own explanation of its status.
struct KeychainError: LocalizedError, Equatable, Sendable {
    let status: OSStatus

    var errorDescription: String? {
        // /documentation/security/seccopyerrormessagestring(_:_:)
        SecCopyErrorMessageString(status, nil) as String? ?? "Keychain error \(status)"
    }
}

struct KeychainService: Sendable {
    /// The Security calls a save makes. Tests hand in their own to reach the failures a
    /// real keychain won't produce on demand; the unhosted test bundle has no keychain
    /// access at all (errSecMissingEntitlement).
    struct Calls: Sendable {
        var update: @Sendable (CFDictionary, CFDictionary) -> OSStatus = { SecItemUpdate($0, $1) }
        var add: @Sendable (CFDictionary) -> OSStatus = { SecItemAdd($0, nil) }
        var delete: @Sendable (CFDictionary) -> OSStatus = { SecItemDelete($0) }
    }

    private let service = "com.bengsfort.FitnessExporter"
    private let calls: Calls

    init(calls: Calls = Calls()) {
        self.calls = calls
    }

    private func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }

    /// Stores `value` under `key`, or removes the item when `value` is empty. The
    /// existing item is updated in place, never deleted first, so a write that fails
    /// leaves the previous value where it was.
    /// /documentation/security/updating-and-deleting-keychain-items
    func save(key: String, value: String) throws(KeychainError) {
        let query = baseQuery(for: key)

        guard !value.isEmpty else {
            let status = calls.delete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw KeychainError(status: status)
            }
            return
        }

        let data = Data(value.utf8)
        let update = [kSecValueData as String: data]
        let updateStatus = calls.update(query as CFDictionary, update as CFDictionary)
        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var add = query
            add[kSecValueData as String] = data
            add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            let addStatus = calls.add(add as CFDictionary)
            guard addStatus == errSecSuccess else { throw KeychainError(status: addStatus) }
        default:
            throw KeychainError(status: updateStatus)
        }
    }

    func load(key: String) -> String {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return ""
        }
        return String(data: data, encoding: .utf8) ?? ""
    }
}
