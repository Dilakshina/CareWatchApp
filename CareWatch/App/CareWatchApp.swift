import SwiftUI
import CoreData
import UserNotifications

@main
struct CareWatchApp: App {
    let persistence = PersistenceController.shared
    
    init() {
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
