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

    static func launch(in testCase: XCTestCase) -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
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
