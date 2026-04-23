import SwiftUI
import CoreLocation
import Combine

struct ServiceListView: View {
    @ObservedObject var viewModel: ServiceListViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                locationBanner
                searchBar
                categoryFilter
                contentArea
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadServices()
            }
        }
        .accessibilityIdentifier("serviceListScreen")
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Find Services")
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.accentColor)
            }
            .accessibilityLabel("App Logo")
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    @ViewBuilder
    private var locationBanner: some View {
        switch viewModel.authorizationStatus {
        case .notDetermined:
            permissionPromptBanner
        case .denied, .restricted:
            permissionDeniedBanner
        case .authorized:
            EmptyView()
        }
    }
    
    private var permissionPromptBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(.accentColor)
                    .accessibilityHidden(true)
                Text("Find services near you")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            Text("Share your location to see distance and sort services by proximity.")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Allow location access") {
                viewModel.requestLocationPermission()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .accessibilityIdentifier("requestLocationButton")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.08))
        .accessibilityIdentifier("locationPermissionBanner")
    }
    
    private var permissionDeniedBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "location.slash.fill")
                .foregroundColor(.orange)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Location access disabled")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("Enable in Settings to see distances.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.1))
        .accessibilityIdentifier("locationDeniedBanner")
        .accessibilityElement(children: .combine)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            TextField("Search services", text: $viewModel.searchText)
                .accessibilityIdentifier("searchField")
                .accessibilityLabel("Search services")
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .accessibilityIdentifier("clearSearchButton")
                .accessibilityLabel("Clear search")
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(
                    title: "All",
                    isSelected: viewModel.selectedCategory == nil,
                    action: { viewModel.selectedCategory = nil }
                )
                .accessibilityIdentifier("categoryChip_all")
                
                ForEach(ServiceCategory.allCases) { category in
                    CategoryChip(
                        title: category.rawValue,
                        isSelected: viewModel.selectedCategory == category,
                        action: {
                            viewModel.selectedCategory =
                                viewModel.selectedCategory == category ? nil : category
                        }
                    )
                    .accessibilityIdentifier("categoryChip_\(category.rawValue.replacingOccurrences(of: " ", with: "_"))")
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private var contentArea: some View {
        if viewModel.isLoading {
            loadingView
        } else if let errorMessage = viewModel.errorMessage {
            errorView(message: errorMessage)
        } else if viewModel.filteredServices.isEmpty {
            emptyView
        } else {
            serviceList
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
                .scaleEffect(1.4)
            Text("Loading services...")
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("loadingIndicator")
        .accessibilityLabel("Loading services")
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
                .accessibilityHidden(true)
            Text("Something went wrong")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Try Again") {
                Task { await viewModel.loadServices() }
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("retryButton")
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("errorView")
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
            Text("No services found")
                .font(.headline)
            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button("Clear filters") {
                viewModel.clearFilters()
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("clearFiltersButton")
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("emptyView")
    }
    
    private var serviceList: some View {
        List(viewModel.filteredServices) { service in
            NavigationLink(value: service) {
                ServiceRow(
                    service: service,
                    distanceText: viewModel.distanceString(for: service)
                )
            }
            .accessibilityIdentifier("serviceRow_\(service.name)")
        }
        .listStyle(.plain)
        .accessibilityIdentifier("servicesList")
        .navigationDestination(for: Service.self) { service in
            ServiceDetailView(
                service: service,
                distanceText: viewModel.distanceString(for: service)
            )
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct ServiceRow: View {
    let service: Service
    let distanceText: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: service.category.iconName)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(service.name)
                    .font(.headline)
                    .lineLimit(2)
                Text(service.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(distanceText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(service.name), \(service.category.rawValue), \(distanceText)")
        .accessibilityHint("Double tap to view details")
    }
}

#if DEBUG
final class MockLocationProvider: LocationProviding {
    static let acworthLocation = CLLocation(latitude: 34.0654, longitude: -84.6771)

    @Published private var _authorizationStatus: LocationAuthorizationStatus
    @Published private var _currentLocation: CLLocation?

    var authorizationStatus: LocationAuthorizationStatus { _authorizationStatus }
    var currentLocation: CLLocation? { _currentLocation }

    var authorizationStatusPublisher: AnyPublisher<LocationAuthorizationStatus, Never> {
        $_authorizationStatus.eraseToAnyPublisher()
    }

    var locationPublisher: AnyPublisher<CLLocation?, Never> {
        $_currentLocation.eraseToAnyPublisher()
    }

    init(initialStatus: LocationAuthorizationStatus = .notDetermined, initialLocation: CLLocation? = nil) {
        _authorizationStatus = initialStatus
        _currentLocation = initialLocation
    }

    func requestAuthorization() {
        _authorizationStatus = .authorized
    }

    func requestLocation() {}
}
#endif

#Preview {
    ServiceListView(
        viewModel: ServiceListViewModel(
            locationProvider: MockLocationProvider(
                initialStatus: .authorized,
                initialLocation: MockLocationProvider.acworthLocation
            )
        )
    )
}
