import XCTest

/// Represents a single row as it was actually rendered on screen,
/// parsed from the accessibility label. Tests assert against these
/// values rather than hardcoded service names.
struct RenderedServiceRow {
    let name: String
    let category: String
    let distanceMiles: Double?
    
    /// Parses rows of the form: "Name, Category, 12.3 miles away"
    /// or "Name, Category, Distance unavailable".
    init?(identifier: String, label: String) {
        guard identifier.hasPrefix("serviceRow_") else { return nil }
        self.name = String(identifier.dropFirst("serviceRow_".count))
        
        // The label is a concatenation of the name, category, and distance,
        // joined by ", " per the SwiftUI combined accessibility label.
        let parts = label.components(separatedBy: ", ")
        self.category = parts.count >= 2 ? parts[1] : ""
        
        if let last = parts.last {
            let pattern = #"(\d+\.\d+) miles away"#
            if
                let regex = try? NSRegularExpression(pattern: pattern),
                let match = regex.firstMatch(in: last, range: NSRange(last.startIndex..., in: last)),
                let range = Range(match.range(at: 1), in: last),
                let miles = Double(last[range])
            {
                self.distanceMiles = miles
            } else {
                self.distanceMiles = nil
            }
        } else {
            self.distanceMiles = nil
        }
    }
}

final class ServiceListScreen: BaseScreen {
    
    // MARK: - Elements
    
    var screen: XCUIElement {
        app.otherElements["serviceListScreen"]
    }
    
    var searchField: XCUIElement {
        app.textFields["searchField"]
    }
    
    var clearSearchButton: XCUIElement {
        app.buttons["clearSearchButton"]
    }
    
    var servicesList: XCUIElement {
        app.collectionViews["servicesList"]
    }
    
    var loadingIndicator: XCUIElement {
        app.otherElements["loadingIndicator"]
    }
    
    var errorView: XCUIElement {
        app.otherElements["errorView"]
    }
    
    var emptyView: XCUIElement {
        app.staticTexts["No services found"]
    }
    
    var retryButton: XCUIElement {
        app.buttons["retryButton"]
    }
    
    var clearFiltersButton: XCUIElement {
        app.buttons["clearFiltersButton"]
    }
    
    var locationPermissionBanner: XCUIElement {
        app.otherElements["locationPermissionBanner"]
    }
    
    var locationDeniedBanner: XCUIElement {
        app.otherElements["locationDeniedBanner"]
    }
    
    var requestLocationButton: XCUIElement {
        app.buttons["requestLocationButton"]
    }
    
    // MARK: - Actions

    func waitForLoaded() {
        _ = waitForDisappearance(loadingIndicator, timeout: 10)
    }

    func waitForDistancesToResolve(timeout: TimeInterval = 15) {
        let predicate = NSPredicate(format: "label CONTAINS 'miles away'")
        let anyDistanceRow = app.buttons.matching(predicate).firstMatch
        let exists = anyDistanceRow.waitForExistence(timeout: timeout)
        if !exists {
            XCTFail("Timed out waiting for distance calculations. " +
                    "Make sure simulator location is set: " +
                    "xcrun simctl location booted set 34.0662,-84.6769")
        }
    }

    func search(for text: String) {
        searchField.tap()
        searchField.typeText(text)
    }

    func clearSearch() {
        if clearSearchButton.exists {
            clearSearchButton.tap()
        }
    }

    func selectCategory(_ category: String) {
        let identifier = "categoryChip_\(category.replacingOccurrences(of: " ", with: "_"))"
        let chip = app.buttons[identifier]
        _ = waitForElement(chip)
        chip.tap()
    }

    func tapAllCategoriesChip() {
        app.buttons["categoryChip_all"].tap()
    }

    func tapRetry() {
        retryButton.tap()
    }

    func tapClearFilters() {
        clearFiltersButton.tap()
    }

    func requestLocationAccess() {
        requestLocationButton.tap()
    }
    
    func tapService(named name: String) -> ServiceDetailScreen {
        let row = app.buttons["serviceRow_\(name)"]
        _ = waitForElement(row)
        row.tap()
        return ServiceDetailScreen(app: app)
    }
    
    func tapFirstService() -> ServiceDetailScreen {
        let row = firstVisibleRow()
        XCTAssertNotNil(row, "Expected at least one service row to be visible")
        row?.tap()
        return ServiceDetailScreen(app: app)
    }
    
    // MARK: - Row Harvesting
    
    /// Returns every currently-rendered row as a parsed struct. Does not
    /// scroll — these are only the rows in the visible window. Use
    /// harvestAllRows() if you need the full list.
    func visibleRows() -> [RenderedServiceRow] {
        let predicate = NSPredicate(format: "identifier BEGINSWITH 'serviceRow_'")
        return app.buttons.matching(predicate).allElementsBoundByIndex
            .compactMap { element in
                guard element.exists else { return nil }
                return RenderedServiceRow(identifier: element.identifier, label: element.label)
            }
    }
    
    func firstVisibleRow() -> XCUIElement? {
        let predicate = NSPredicate(format: "identifier BEGINSWITH 'serviceRow_'")
        let match = app.buttons.matching(predicate).firstMatch
        return match.exists ? match : nil
    }
    
    // MARK: - Queries (legacy — prefer harvestAllRows for data-driven tests)
    
    func visibleServiceCount() -> Int {
        let predicate = NSPredicate(format: "identifier BEGINSWITH 'serviceRow_'")
        return app.buttons.matching(predicate).count
    }
    
    func serviceRowExists(named name: String) -> Bool {
        app.buttons["serviceRow_\(name)"].exists
    }
}
