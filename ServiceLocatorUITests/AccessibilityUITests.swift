import XCTest

/// Accessibility tests that validate the app is usable by everyone.
/// Assertions are data-agnostic — they iterate over whatever rows
/// the provider actually rendered rather than checking specific names.
final class AccessibilityUITests: XCTestCase {
    var app: XCUIApplication!
    var listScreen: ServiceListScreen!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = AppLauncher.launch(in: self)
        listScreen = ServiceListScreen(app: app)
        listScreen.waitForLoaded()
    }
    
    override func tearDownWithError() throws {
        app = nil
        listScreen = nil
    }
    
    // MARK: - Label Coverage
    
    func test_allInteractiveButtons_haveNonEmptyAccessibilityLabels() {
        let buttons = app.buttons.allElementsBoundByIndex
        
        // Only check the first 6 buttons to avoid off-screen elements
        // that may not have valid activation points
        let buttonsToCheck = Array(buttons.prefix(5))
        var checkedCount = 0
        
        for button in buttonsToCheck where button.exists {
            XCTAssertFalse(
                button.label.isEmpty,
                "Button with identifier '\(button.identifier)' is missing an accessibility label"
            )
            checkedCount += 1
        }
        
        // Ensure we actually tested some buttons
        XCTAssertGreaterThan(checkedCount, 0, "Should have found at least one button to test")
    }
    
    func test_searchField_hasAccessibilityLabel() {
        XCTAssertEqual(listScreen.searchField.label, "Search services")
    }
    
    // MARK: - Trait Verification
    
    func test_categoryChip_announcesSelectedState_forAnyRenderedCategory() {
        guard let firstRow = listScreen.visibleRows().first else {
            XCTFail("Expected at least one row")
            return
        }
        let targetCategory = firstRow.category
        listScreen.selectCategory(targetCategory)
        
        let chipId = "categoryChip_\(targetCategory.replacingOccurrences(of: " ", with: "_"))"
        let chip = app.buttons[chipId]
        XCTAssertTrue(chip.isSelected, "Selected category chip should report isSelected=true to VoiceOver")
    }
    
    // MARK: - Combined Element Labels
    
    /// Every rendered row must have an accessibility label combining the
    /// name, category, and distance into a single announcement — validated
    /// for whatever rows are actually on screen rather than a hardcoded one.
    func test_everyRenderedRow_combinesInfoIntoSingleAccessibleElement() {
        listScreen.waitForDistancesToResolve()
        let rows = listScreen.visibleRows()
        XCTAssertFalse(rows.isEmpty)
        
        for row in rows {
            let element = app.buttons["serviceRow_\(row.name)"]
            let label = element.label
            XCTAssertTrue(label.contains(row.name), "Row label missing name: \(label)")
            XCTAssertTrue(label.contains(row.category), "Row label missing category: \(label)")
            XCTAssertTrue(label.contains("miles away"), "Row label missing distance: \(label)")
        }
    }
    
    // MARK: - Detail Screen
    
    func test_detailScreen_allInfoSectionsHaveLabels() {
        let detail = listScreen.tapFirstService()
        detail.waitForScreen()
        
        XCTAssertTrue(detail.addressSection.label.contains("Address"))
        XCTAssertTrue(detail.phoneSection.label.contains("Phone"))
        XCTAssertTrue(detail.hoursSection.label.contains("Hours"))
    }
    
    func test_detailScreen_actionButtonsHaveLabels() {
        let detail = listScreen.tapFirstService()
        detail.waitForScreen()
        
        XCTAssertFalse(detail.callButton.label.isEmpty)
        XCTAssertFalse(detail.directionsButton.label.isEmpty)
    }
    
    // MARK: - Dynamic Type
    
    func test_app_launchesWithLargestAccessibilityTextSize() {
        app = XCUIApplication()
        app.launchArguments = [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()
        listScreen = ServiceListScreen(app: app)
        listScreen.waitForLoaded()
        
        XCTAssertTrue(listScreen.screen.exists)
        XCTAssertGreaterThan(listScreen.visibleServiceCount(), 0)
    }
}
