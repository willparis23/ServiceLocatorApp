import Foundation
import SwiftUI
import CoreLocation
import Combine

@MainActor
final class ServiceListViewModel: ObservableObject {
    @Published private(set) var services: [Service] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published var selectedCategory: ServiceCategory?
    @Published var searchText: String = ""
    
    @Published private(set) var authorizationStatus: LocationAuthorizationStatus = .notDetermined
    @Published private(set) var userLocation: CLLocation?
    
    private let serviceProvider: ServiceProviding
    private let locationProvider: LocationProviding
    private var cancellables = Set<AnyCancellable>()
    
    init(
        serviceProvider: ServiceProviding = MockServiceProvider(),
        locationProvider: LocationProviding = CoreLocationProvider()
    ) {
        self.serviceProvider = serviceProvider
        self.locationProvider = locationProvider
        
        self.authorizationStatus = locationProvider.authorizationStatus
        self.userLocation = locationProvider.currentLocation
        
        locationProvider.authorizationStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.authorizationStatus = status
                if status == .authorized {
                    self?.locationProvider.requestLocation()
                }
            }
            .store(in: &cancellables)
        
        locationProvider.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.userLocation = location
            }
            .store(in: &cancellables)
    }
    
    var filteredServices: [Service] {
        let filtered = services.filter { service in
            let matchesCategory = selectedCategory == nil || service.category == selectedCategory
            let matchesSearch = searchText.isEmpty ||
                service.name.localizedCaseInsensitiveContains(searchText) ||
                service.description.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
        
        if let userLocation {
            return filtered.sorted {
                $0.distanceInMiles(from: userLocation) < $1.distanceInMiles(from: userLocation)
            }
        }
        return filtered
    }
    
    func distanceString(for service: Service) -> String {
        guard let userLocation else { return "Distance unavailable" }
        let miles = service.distanceInMiles(from: userLocation)
        return String(format: "%.1f miles away", miles)
    }
    
    func requestLocationPermission() {
        locationProvider.requestAuthorization()
    }
    
    func loadServices() async {
        isLoading = true
        errorMessage = nil
        
        do {
            services = try await serviceProvider.fetchServices()
        } catch {
            errorMessage = error.localizedDescription
            services = []
        }
        
        isLoading = false
    }
    
    func clearFilters() {
        selectedCategory = nil
        searchText = ""
    }
}
