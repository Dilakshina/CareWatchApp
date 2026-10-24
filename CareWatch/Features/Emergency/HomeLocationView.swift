import SwiftUI
import MapKit
import CoreData

//  Home location: set home on a map, choose an area, record arrival / departure
struct HomeLocationView: View {
    @Environment(\.managedObjectContext) private var context
    @ObservedObject private var location = LocationService.shared
    @FetchRequest(sortDescriptors: []) private var homes: FetchedResults<HomeLocation>

    @State private var position: MapCameraPosition = .automatic
    @State private var pin: CLLocationCoordinate2D?
    @State private var label = ""
    @State private var radius: Double = 200
    @State private var recordArrival = true
    @State private var recordDeparture = false
    @State private var showToast = false

    // Colombo 07, used until a home is chosen
    private let defaultCenter = CLLocationCoordinate2D(latitude: 6.9147, longitude: 79.8730)

    // Lays out the map, location controls, check-in area options and save button
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Set where home is for arrival check-ins")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)

                mapCard

                Button { location.requestCurrentLocation() } label: {
                    Label("Use my current location", systemImage: "location.fill")
                        .font(.headline)
                        .foregroundStyle(AppColors.brandTeal)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(AppColors.mint, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)

                FormField(label: "Name or address (optional)", text: $label,
                          placeholder: "e.g. No. 24, Flower Road, Colombo 07")

                Text("Check-in area")
                    .font(.headline)
                    .foregroundStyle(AppColors.ink)

                HStack(spacing: 10) {
                    ForEach([100.0, 200.0, 500.0], id: \.self) { value in
                        Button { radius = value } label: {
                            Text("\(Int(value)) m")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(radius == value ? .white : AppColors.brandTeal)
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(radius == value ? AppColors.brandTeal : AppColors.mint,
                                            in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(radius == value ? .isSelected : [])
                    }
                }

                CardView {
                    VStack(spacing: 12) {
                        Toggle("Record arrival", isOn: $recordArrival)
                        Divider()
                        Toggle("Record departure", isOn: $recordDeparture)
                    }
                    .font(.headline)
                    .foregroundStyle(AppColors.ink)
                    .tint(AppColors.brandTeal)
                }

                PrimaryButton(title: "Save home location", action: save)
                    .disabled(pin == nil)
                    .opacity(pin == nil ? 0.5 : 1)

                Text("Location stays on this iPhone. iOS may delay arrival and departure events.")
                    .font(.footnote)
                    .foregroundStyle(AppColors.secondaryText)

                if !homes.isEmpty {
                    Button("Remove home location", role: .destructive, action: remove)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
        }
        .background(AppColors.background)
        .navigationTitle("Home location")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
        .onChange(of: location.currentLocation?.latitude) {
            if let current = location.currentLocation {
                pin = current
                position = .region(MKCoordinateRegion(center: current,
                                                      latitudinalMeters: 1200, longitudinalMeters: 1200))
            }
        }
        .overlay(alignment: .top) {
            if showToast {
                ToastBanner(title: "Home location saved", message: "\(Int(radius)) m check-in area")
            }
        }
        .task(id: showToast) {
            guard showToast else { return }
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation { showToast = false }
        }
    }
    // Shows the interactive map with the home pin and check-in radius circle
    private var mapCard: some View {
        MapReader { proxy in
            Map(position: $position) {
                if let pin {
                    Annotation("Home", coordinate: pin) {
                        Image(systemName: "house.fill")
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(AppColors.brandTeal, in: Circle())
                    }
                    MapCircle(center: pin, radius: radius)
                        .foregroundStyle(AppColors.brandTeal.opacity(0.15))
                        .stroke(AppColors.brandTeal, lineWidth: 2)
                }
            }
            .onTapGesture { point in
                if let coordinate = proxy.convert(point, from: .local) {
                    pin = coordinate
                }
            }
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(alignment: .bottomLeading) {
            Text(pin == nil ? "Tap the map to place your home" : "Tap the map to move the pin")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.white, in: Capsule())
                .padding(10)
        }
    }

    // Fill the screen with the saved home, or centre on Colombo
    private func load() {
        guard let home = homes.first else {
            position = .region(MKCoordinateRegion(center: defaultCenter,
                                                  latitudinalMeters: 2000, longitudinalMeters: 2000))
            return
        }
        let saved = CLLocationCoordinate2D(latitude: home.latitude, longitude: home.longitude)
        pin = saved
        label = home.address ?? ""
        radius = home.radius
        recordArrival = home.recordArrival
        recordDeparture = home.recordDeparture
        position = .region(MKCoordinateRegion(center: saved,
                                              latitudinalMeters: 1200, longitudinalMeters: 1200))
    }

    // Saves the home location and starts or stops geofence monitoring based on the toggles
    private func save() {
        guard let pin else { return }
        let home = homes.first ?? HomeLocation(context: context)
        home.latitude = pin.latitude
        home.longitude = pin.longitude
        home.address = label.isEmpty ? nil : label
        home.radius = radius
        home.recordArrival = recordArrival
        home.recordDeparture = recordDeparture
        CareEvent.record("homeSet", summary: "Home location saved · \(Int(radius)) m area", in: context)
        try? context.save()

        if recordArrival || recordDeparture {
            location.startMonitoring(latitude: pin.latitude, longitude: pin.longitude, radius: radius)
        } else {
            location.stopMonitoring()
        }
        withAnimation { showToast = true }
    }

    // Deletes the saved home location and stops geofence monitoring
    private func remove() {
        homes.forEach(context.delete)
        try? context.save()
        location.stopMonitoring()
        pin = nil
    }
}
