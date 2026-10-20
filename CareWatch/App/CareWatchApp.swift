import SwiftUI
import CoreData

@main
struct CareWatchApp: App {
    let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
