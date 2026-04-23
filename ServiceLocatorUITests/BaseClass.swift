import XCTest

/// Base class for all UI tests, providing common setup and teardown logic.
/// Launches the app and initializes the service list screen before each test.
class BaseClass: XCTestCase {
    var app: XCUIApplication!
    var listScreen: ServiceListScreen!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        listScreen = ServiceListScreen(app: app)
        listScreen.waitForLoaded()
    }
    
    override func tearDownWithError() throws {
        app = nil
        listScreen = nil
    }
}
