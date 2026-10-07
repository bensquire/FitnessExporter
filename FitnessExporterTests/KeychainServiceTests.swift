import Foundation
import Security
import Synchronization
import Testing

/// Stands in for the Security calls: each answers with the status a test sets, and
/// every call is logged by name. The test bundle runs without the app's entitlements,
/// so the real keychain refuses it (errSecMissingEntitlement); nothing here touches it.
final class FakeKeychainCalls: Sendable {
    private let log = Mutex<[String]>([])
    /// The value and accessibility of the last item added; the rest of the query is fixed.
    private let lastAdd = Mutex<(value: Data?, accessible: String?)?>(nil)

    var calls: [String] { log.withLock { $0 } }
    var addedItem: (value: Data?, accessible: String?)? { lastAdd.withLock { $0 } }

    func make(
        update: OSStatus = errSecSuccess, add: OSStatus = errSecSuccess, delete: OSStatus = errSecSuccess
    )
        -> KeychainService.Calls
    {
        KeychainService.Calls(
            update: { _, _ in
                self.log.withLock { $0.append("update") }
                return update
            },
            add: { item in
                self.log.withLock { $0.append("add") }
                let fields = item as? [String: Any]
                let added = (
                    value: fields?[kSecValueData as String] as? Data,
                    accessible: fields?[kSecAttrAccessible as String] as? String
                )
                self.lastAdd.withLock { $0 = added }
                return add
            },
            delete: { _ in
                self.log.withLock { $0.append("delete") }
                return delete
            }
        )
    }
}

struct KeychainServiceTests {
    @Test func aRefusedUpdateKeepsTheOldTokenAndReportsWhy() {
        // Arrange
        let fake = FakeKeychainCalls()
        let keychain = KeychainService(calls: fake.make(update: errSecInteractionNotAllowed))

        // Act
        #expect(throws: KeychainError(status: errSecInteractionNotAllowed)) {
            try keychain.save(key: "httpToken", value: "new")
        }

        // Assert — nothing that could remove the stored token was attempted
        #expect(fake.calls == ["update"])
    }

    @Test func updatesAnExistingTokenInPlace() throws {
        // Arrange
        let fake = FakeKeychainCalls()
        let keychain = KeychainService(calls: fake.make(update: errSecSuccess))

        // Act
        try keychain.save(key: "httpToken", value: "new")

        // Assert
        #expect(fake.calls == ["update"])
    }

    @Test func addsATokenSavedForTheFirstTime() throws {
        // Arrange
        let fake = FakeKeychainCalls()
        let keychain = KeychainService(calls: fake.make(update: errSecItemNotFound))

        // Act
        try keychain.save(key: "httpToken", value: "new")

        // Assert
        let item = try #require(fake.addedItem)
        #expect(fake.calls == ["update", "add"])
        #expect(item.value == Data("new".utf8))
        #expect(item.accessible == kSecAttrAccessibleAfterFirstUnlock as String)
    }

    @Test func reportsAFailedAdd() {
        // Arrange
        let fake = FakeKeychainCalls()
        let keychain = KeychainService(calls: fake.make(update: errSecItemNotFound, add: errSecDuplicateItem))

        // Act & Assert
        #expect(throws: KeychainError(status: errSecDuplicateItem)) {
            try keychain.save(key: "httpToken", value: "new")
        }
    }

    @Test(arguments: [errSecSuccess, errSecItemNotFound])
    func anEmptyTokenRemovesTheStoredOne(deleteStatus: OSStatus) throws {
        // Arrange — a token that was never saved is already removed, so not-found is fine
        let fake = FakeKeychainCalls()
        let keychain = KeychainService(calls: fake.make(delete: deleteStatus))

        // Act
        try keychain.save(key: "httpToken", value: "")

        // Assert
        #expect(fake.calls == ["delete"], "delete answered \(deleteStatus)")
    }

    @Test func aFailureCarriesTheSystemsExplanation() {
        // Act
        let message = KeychainError(status: errSecInteractionNotAllowed).localizedDescription

        // Assert — the text comes from SecCopyErrorMessageString, not a bare status code
        #expect(!message.contains("-25308"))
        #expect(!message.isEmpty)
    }
}
