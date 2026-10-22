import SwiftUI
import CoreData
import UserNotifications
import FirebaseCore

@main
struct CareWatchApp: App {
    let persistence = PersistenceController.shared
    @StateObject private var auth: AuthService

    init() {
        FirebaseApp.configure()                       // must run before AuthService uses Firebase
        _auth = StateObject(wrappedValue: AuthService())
        SampleData.seedIfNeeded(in: persistence.container.viewContext)
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
