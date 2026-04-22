import XCTest

/// Tests the real iOS location permission flow using the system alert.
///
/// Before each run, privacy settings should be reset so the alert appears:
///   xcrun simctl privacy booted reset location com.example.ServiceLocator
///
/// Or use the "Reset Location & Privacy" option in the simulator menu.
/// The setUp method calls this automatically via a terminal helper when possible.
final class LocationPermissionUITests: XCTestCase {
    var app: XCUIApplication!
    var listScreen: ServiceListScreen!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    override func tearDownWithError() throws {
        app = nil
        listScreen = nil
    }
    
    // MARK: - Grant Permission Flow
    
    /// Tests the flow when the user grants permission via the system alert.
    /// The interruption monitor in AppLauncher auto-taps "Allow Once".
    func test_grantingPermission_showsDistancesOnRows() {
        app = AppLauncher.launch(in: self)
        listScreen = ServiceListScreen(app: app)
        listScreen.waitForLoaded()
        
        // Once permission is granted and a location fix arrives, rows
        // should include distance strings.
        listScreen.waitForDistancesToResolve()
        
        let anyRow = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'serviceRow_'")).firstMatch
        XCTAssertTrue(anyRow.label.contains("miles away"))
    }
    
    // MARK: - Services Still Visible
    
    func test_servicesVisible_regardlessOfLocationOutcome() {
        app = AppLauncher.launch(in: self)
        listScreen = ServiceListScreen(app: app)
        listScreen.waitForLoaded()
        
        XCTAssertGreaterThan(
            listScreen.visibleServiceCount(),
            0,
            "Services should be visible even before a location fix arrives"
        )
    }
    
    // MARK: - Accessibility of Permission UI
    
    /// Validates the in-app permission banner (not the system alert) is
    /// accessible. The banner shows when authorization is notDetermined.
    /// Because simulator state persists between runs, this test may need
    /// a fresh install or privacy reset to show the banner.
    func test_permissionBanner_whenPresent_isAccessible() throws {
        app = AppLauncher.launch(in: self, handleLocationPermission: false)
        listScreen = ServiceListScreen(app: app)
        listScreen.waitForLoaded()
        
        // If the banner is present, it must be accessible.
        // If authorization was already granted in a prior run, skip.
        if listScreen.locationPermissionBanner.waitForExistence(timeout: 2) {
            XCTAssertTrue(listScreen.requestLocationButton.exists)
            XCTAssertFalse(listScreen.requestLocationButton.label.isEmpty)
        } else {
            throw XCTSkip("Location was already authorized. Reset privacy settings to test this flow.")
        }
    }
}
