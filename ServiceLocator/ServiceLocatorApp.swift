import SwiftUI

@main
struct ServiceLocatorApp: App {
    @StateObject private var viewModel: ServiceListViewModel
    
    init() {
        // Service data is still provided via MockServiceProvider because no
        // free nationwide HSDS endpoint exists. In production this would be
        // an HSDSNetworkProvider conforming to ServiceProviding. The protocol
        // boundary means the rest of the app does not change.
        let serviceProvider = MockServiceProvider()
        let locationProvider = CoreLocationProvider()
        
        _viewModel = StateObject(
            wrappedValue: ServiceListViewModel(
                serviceProvider: serviceProvider,
                locationProvider: locationProvider
            )
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ServiceListView(viewModel: viewModel)
        }
    }
}
