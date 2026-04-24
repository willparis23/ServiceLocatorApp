import XCTest

/// Represents a single row as it was actually rendered on screen,
/// parsed from the accessibility label. Tests assert against these
/// values rather than hardcoded service names.
struct RenderedServiceRow: Equatable {
    let name: String
    let category: String
    let distanceMiles: Double?
    
    /// Parses rows of the form: "Name, Category, 12.3 miles away"
    /// or "Name, Category, Distance unavailable".
    init?(identifier: String, label: String) {
        // Verify this is a service row by checking the identifier prefix
        // Returns nil if this isn't a service row element
        guard identifier.hasPrefix("serviceRow_") else { return nil }
        
        // Extract the service name from the identifier
        // Example: "serviceRow_Food_Bank" → "Food_Bank"
        self.name = String(identifier.dropFirst("serviceRow_".count))
        
        // The accessibility label combines name, category, and distance
        // Format: "Name, Category, 12.3 miles away"
        // Split by ", " to extract individual components
        let parts = label.components(separatedBy: ", ")
        
        // Extract the category from the second part (index 1)
        // Example: ["Food Bank", "Food", "12.3 miles away"] → "Food"
        self.category = parts.count >= 2 ? parts[1] : ""
        
        // Extract the distance from the last part of the label
        if let last = parts.last {
            // Regex pattern matches distances like "12.3 miles away" or "5 miles away"
            // \d+ matches one or more digits (whole number part)
            // (?:\.\d+)? optionally matches a decimal point and fractional part
            // Parentheses create a capture group to extract just the number
            let pattern = #"(\d+(?:\.\d+)?) miles away"#
            
            if
                // Attempt to create a regex from the pattern
                let regex = try? NSRegularExpression(pattern: pattern),
                // Find the first match in the string
                let match = regex.firstMatch(in: last, range: NSRange(last.startIndex..., in: last)),
                // Extract the captured group (the numeric value)
                let range = Range(match.range(at: 1), in: last),
                // Convert the extracted string to a Double
                let miles = Double(last[range])
            {
                // Successfully parsed the distance
                self.distanceMiles = miles
            } else {
                // Distance not available or couldn't be parsed
                self.distanceMiles = nil
            }
        } else {
            // No last part found in the label
            self.distanceMiles = nil
        }
    }
}

final class ServiceListScreen {
    
    let app: XCUIApplication
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
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
    
    var allCategoriesButton: XCUIElement {
        app.buttons["categoryChip_all"]
    }
    
    // MARK: - Actions

    // waits for the app to load by verifying dissaperance of loading indicator
    func waitForLoaded() {
        let utility = ElementUtility()
        _ = utility.waitForDisappearance(loadingIndicator, timeout: 10)
    }

    // waits for distances to show up for services before proceeding
    func waitForDistancesToResolve(timeout: TimeInterval = 15) {
        let predicate = NSPredicate(format: "label CONTAINS 'miles away'")
        let anyDistanceRow = app.buttons.matching(predicate).firstMatch
        let exists = anyDistanceRow.waitForExistence(timeout: timeout)
        if !exists {
            XCTFail("Timed out waiting for distance calculations.")
        }
    }

    // searching for services
    func search(for text: String) {
        searchField.tap()
        searchField.typeText(text)
    }

    // clearing the search field
    func clearSearch() {
        if clearSearchButton.exists {
            clearSearchButton.tap()
        }
    }

    // selecting a category from the list of service categories
    func selectCategory(_ category: String) {
        let identifier = "categoryChip_\(category.replacingOccurrences(of: " ", with: "_"))"
        let chip = app.buttons[identifier]
        _ = ElementUtility().waitForElement(chip)
        chip.tap()
    }

    // tapping the all categories button
    func tapAllCategoriesChip() {
        allCategoriesButton.tap()
    }

    // tapping the clear filters button
    func tapClearFilters() {
        clearFiltersButton.tap()
    }

    // tapping on a specific service
    func tapService(named name: String) -> ServiceDetailScreen {
        let row = app.buttons["serviceRow_\(name)"]
        _ = ElementUtility().waitForElement(row)
        row.tap()
        return ServiceDetailScreen(app: app)
    }

    // tapping on the first service
    func tapFirstService() -> ServiceDetailScreen {
        let row = firstVisibleRow()
        XCTAssertNotNil(row, "Expected at least one service row to be visible")
        row?.tap()
        return ServiceDetailScreen(app: app)
    }
    
    // returning each row with the rows name, category, and distance
    func visibleRows() -> [RenderedServiceRow] {
        let predicate = NSPredicate(format: "identifier BEGINSWITH 'serviceRow_'")
        return app.buttons.matching(predicate).allElementsBoundByIndex
            .compactMap { element in
                guard element.exists else { return nil }
                return RenderedServiceRow(identifier: element.identifier, label: element.label)
            }
    }

    // returning the first row in the hierarchy
    func firstVisibleRow() -> XCUIElement? {
        let predicate = NSPredicate(format: "identifier BEGINSWITH 'serviceRow_'")
        let match = app.buttons.matching(predicate).firstMatch
        return match.exists ? match : nil
    }
    
    // returning the count of service rows that are visible on the screen
    func visibleServiceCount() -> Int {
        let predicate = NSPredicate(format: "identifier BEGINSWITH 'serviceRow_'")
        return app.buttons.matching(predicate).count
    }

    // verifying that a certain service row exists
    func serviceRowExists(named name: String) -> Bool {
        app.buttons["serviceRow_\(name)"].exists
    }
    
    // waits for and returns the first rendered row, failing the test if none exists
    func waitForFirstRowToRender() -> RenderedServiceRow {
        guard let firstRow = visibleRows().first else {
            XCTFail("Expected at least one row")
            fatalError("Test precondition failed: no rows available")
        }
        return firstRow
    }
}
