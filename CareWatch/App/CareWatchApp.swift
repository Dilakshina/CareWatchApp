import SwiftUI
import CoreData

@main
struct CareWatchApp: App {
    let persistence = PersistenceController.shared
    
    init() {
         SampleData.seedIfNeeded(in: persistence.container.viewContext)
     }
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
