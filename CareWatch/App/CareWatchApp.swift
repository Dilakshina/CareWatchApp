import SwiftUI
import CoreData
import UserNotifications
import FirebaseCore

@main
struct CareWatchApp: App {
    let persistence = PersistenceController.shared

    init() {
        FirebaseApp.configure()
        SampleData.seedIfNeeded(in: persistence.container.viewContext)
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
