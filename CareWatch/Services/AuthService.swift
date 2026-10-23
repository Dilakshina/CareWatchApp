import Foundation
import Combine
import FirebaseAuth
// Handles the account: sign in, create account, reset password, sign out.
// Only identity goes to Firebase. Care records stay in Core Data on the iPhone.
@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var uid: String?
    @Published private(set) var email: String?

    var isSignedIn: Bool { uid != nil }

    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        let current = Auth.auth().currentUser
        uid = current?.uid
        email = current?.email

        // Firebase tells us whenever the user signs in or out
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            let uid = user?.uid
            let email = user?.email
            Task { @MainActor in
                self?.uid = uid
                self?.email = email
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func createAccount(email: String, password: String) async throws {
        try await Auth.auth().createUser(withEmail: email, password: password)
    }

    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    /// Turns Firebase error codes into friendly messages for older users
    static func message(for error: Error) -> String {
        switch (error as NSError).code {
        case 17004, 17009: return "Email or password is incorrect."
        case 17011:        return "No account found with this email."
        case 17008:        return "That email address doesn't look right."
        case 17007:        return "An account with this email already exists. Try signing in."
        case 17026:        return "Password must be at least 6 characters."
        case 17020:        return "No internet connection. Please try again."
        case 17010:        return "Too many attempts. Please wait a moment and try again."
        default:           return error.localizedDescription
        }
    }
}
