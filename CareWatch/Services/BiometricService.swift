import Foundation
import LocalAuthentication

// Face ID unlock. goes back to the iPhone passcode if Face ID fails.
enum BiometricService {

    // checking the Face ID set up on this device
    static var isAvailable: Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    // Shows the Face ID prompt. Returns true if the person was recognised.
    static func authenticate(reason: String = "Unlock CareWatch") async -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Use passcode"
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }
}
