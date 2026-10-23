import Foundation
import Combine
import CoreLocation
import CoreData

// Finds the current location and records arriving at / leaving home
// Location stays on the iPhone.
@MainActor
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    @Published private(set) var authorization: CLAuthorizationStatus = .notDetermined
    @Published private(set) var currentLocation: CLLocationCoordinate2D?

    private let manager = CLLocationManager()
    private let regionID = "carewatch-home"

    override init() {
        super.init()
        manager.delegate = self
        authorization = manager.authorizationStatus
    }

    // One-off "where am I now?"
    func requestCurrentLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    // Starts watching a circle around home. Needs "Always" permission to work while the app is closed.
    func startMonitoring(latitude: Double, longitude: Double, radius: Double) {
        stopMonitoring()
        manager.requestAlwaysAuthorization()
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = CLCircularRegion(center: center, radius: radius, identifier: regionID)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        manager.startMonitoring(for: region)
    }

    func stopMonitoring() {
        for region in manager.monitoredRegions where region.identifier == regionID {
            manager.stopMonitoring(for: region)
        }
    }


    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in self.authorization = status }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        Task { @MainActor in self.currentLocation = coordinate }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in self.record(arrived: true) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Task { @MainActor in self.record(arrived: false) }
    }

    //Adds "Arrived home" / "Left home" to the care history, if the user turned that on
    private func record(arrived: Bool) {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<HomeLocation> = HomeLocation.fetchRequest()
        guard let home = try? context.fetch(request).first else { return }
        if arrived && !home.recordArrival { return }
        if !arrived && !home.recordDeparture { return }
        CareEvent.record(arrived ? "arrivedHome" : "leftHome",
                         summary: arrived ? "Arrived home" : "Left home",
                         in: context)
        try? context.save()
    }
}
