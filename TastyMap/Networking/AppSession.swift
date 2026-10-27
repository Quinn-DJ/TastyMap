import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class AppSession {
    enum State: Equatable {
        case launching
        case signedOut
        case signedIn(UserProfile)
    }

    private(set) var state: State
    private(set) var token: String?
    var isLoggingIn = false
    var isSyncing = false
    var loginError: String?
    var syncError: String?
    var lastSyncedAt: Date?

    private let apiClient: TastyAPIClient
    private let syncService: PlaceSyncService
    private let profileKey = "tastymap.cached-profile"
    private var didRestore = false

    init(apiClient: TastyAPIClient = TastyAPIClient()) {
        self.apiClient = apiClient
        syncService = PlaceSyncService(apiClient: apiClient)
        state = .launching
    }

    var currentUser: UserProfile? {
        guard case let .signedIn(user) = state else { return nil }
        return user
    }

    var isAuthenticated: Bool {
        currentUser != nil
    }

    func restore() async {
        guard !didRestore else { return }
        didRestore = true

        guard let storedToken = KeychainStore.readToken() else {
            state = .signedOut
            return
        }

        token = storedToken
        if let cachedProfile = loadCachedProfile() {
            state = .signedIn(cachedProfile)
        }

        do {
            let response = try await apiClient.refresh(token: storedToken)
            apply(response)
        } catch let error as TastyAPIError {
            if case let .server(status, _) = error, status == 401 {
                clearAuthentication()
            } else if currentUser == nil {
                state = .signedOut
                syncError = error.localizedDescription
            }
        } catch {
            if currentUser == nil {
                state = .signedOut
                syncError = error.localizedDescription
            }
        }
    }

    func login(email: String, password: String) async {
        guard !isLoggingIn else { return }
        isLoggingIn = true
        loginError = nil
        defer { isLoggingIn = false }

        do {
            let response = try await apiClient.login(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            apply(response)
        } catch {
            loginError = error.localizedDescription
        }
    }

    func logout() {
        clearAuthentication()
    }

    func synchronize(context: ModelContext) async {
        guard
            let token,
            let user = currentUser,
            !isSyncing
        else {
            return
        }

        isSyncing = true
        syncError = nil
        defer { isSyncing = false }

        do {
            try await syncService.synchronize(
                context: context,
                token: token,
                ownerID: user.id
            )
            lastSyncedAt = .now
        } catch let error as TastyAPIError {
            if error.isUnauthorized {
                clearAuthentication()
            } else {
                syncError = error.localizedDescription
            }
        } catch {
            syncError = error.localizedDescription
        }
    }

    private func apply(_ response: AuthResponse) {
        token = response.token
        let profile = response.record.profile
        state = .signedIn(profile)
        loginError = nil
        cache(profile)

        do {
            try KeychainStore.saveToken(response.token)
        } catch {
            loginError = error.localizedDescription
        }
    }

    private func clearAuthentication() {
        token = nil
        state = .signedOut
        try? KeychainStore.deleteToken()
        UserDefaults.standard.removeObject(forKey: profileKey)
    }

    private func cache(_ profile: UserProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: profileKey)
    }

    private func loadCachedProfile() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: profileKey) else {
            return nil
        }
        return try? JSONDecoder().decode(UserProfile.self, from: data)
    }
}
