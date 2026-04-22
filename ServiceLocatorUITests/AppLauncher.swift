import XCTest

/// Launches the app and handles the real iOS location permission dialog.
///
/// Because we use the real CoreLocationProvider in tests, the system
/// permissions alert appears on first launch. XCUITest handles this via
/// addUIInterruptionMonitor, which fires when the app loses focus to an
/// alert. The monitor only runs when we interact with the app afterward,
/// so we call app.tap() to nudge it.
///
/// Set the simulator location before running these tests:
///   xcrun simctl location booted set 34.0662,-84.6769    (Acworth, GA)
///
/// Or use a GPX file in the scheme's Options tab.
struct AppLauncher {
    
    /// Launches the app with an interruption monitor that auto-taps
    /// "Allow Once" on the system location permission alert if it appears.
    /// Pass `handleLocationPermission: false` to suppress the auto-grant
    /// (e.g. when testing the in-app permission banner).
    static func launch(
        in testCase: XCTestCase,
        handleLocationPermission: Bool = true
    ) -> XCUIApplication {
        let app = XCUIApplication()
        
        if handleLocationPermission {
            installLocationPermissionHandler(in: testCase)
        }
        
        app.launch()
        
        // Nudge the app so the interruption monitor fires if an alert
        // is already on screen. This is XCUITest's documented pattern.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.0)).tap()
        
        return app
    }
    
    private static func installLocationPermissionHandler(in testCase: XCTestCase) {
        _ = testCase.addUIInterruptionMonitor(withDescription: "Location Permission") { alert in
            let allowButtons = [
                "Allow Once",
                "Allow While Using App",
                "Allow"
            ]
            for label in allowButtons {
                let button = alert.buttons[label]
                if button.exists {
                    button.tap()
                    return true
                }
            }
            return false
        }
    }
}
