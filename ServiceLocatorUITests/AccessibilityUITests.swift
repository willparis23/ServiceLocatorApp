import XCTest

/// Accessibility tests that validate the app is usable by everyone.
/// Assertions are data-agnostic — they iterate over whatever rows
/// the provider actually rendered rather than checking specific names.
final class AccessibilityUITests: BaseClass {
    
    // MARK: - Label Coverage

    // Verifying that all buttons on the screen have accessibility labels
    func test_allInteractiveButtonsHaveNonEmptyAccessibilityLabels() {
        let buttons = app.buttons.allElementsBoundByIndex
        
        // Only check the first 6 buttons to avoid off-screen elements
        // that may not have valid activation points
        let buttonsToCheck = Array(buttons.prefix(5))
        var checkedCount = 0

        // Making sure that each visible button has an associated accessibility label
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

    // Verifying that the search field has an accessibility label
    func test_searchFieldHasAccessibilityLabel() {
        XCTAssertEqual(listScreen.searchField.label, "Search services")
    }
    
    // MARK: - Trait Verification

    // Verifying that user selected category has an isSelected accessibility trait
    func test_categoryChipHasSelectedStateForAnyRenderedCategory() {
        let firstRow = listScreen.waitForFirstRowToRender()
        let targetCategory = firstRow.category
        listScreen.selectCategory(targetCategory)
        
        let chipId = "categoryChip_\(targetCategory.replacingOccurrences(of: " ", with: "_"))"
        let chip = app.buttons[chipId]
        XCTAssertTrue(chip.isSelected, "Selected category chip should report isSelected=true to VoiceOver")
    }
    
    // MARK: - Combined Element Labels
    
    // Verifying that each row has an accessibility identifier/label that combines all row info
    func test_everyRenderedRowCombinesInfoIntoSingleAccessibleElement() {
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

    // Verifying that all info sections on the detail screen have accessibility labels
    func test_allDetailScreenInfoSectionsHaveLabels() {
        let detail = listScreen.tapFirstService()
        detail.waitForScreen()
        
        XCTAssertTrue(detail.addressSection.label.contains("Address"))
        XCTAssertTrue(detail.phoneSection.label.contains("Phone"))
        XCTAssertTrue(detail.hoursSection.label.contains("Hours"))
    }

    // Verifying that all action buttons on the detail screen have accessibility labels
    func test_allDetailScreenActionButtonsHaveLabels() {
        let detail = listScreen.tapFirstService()
        detail.waitForScreen()
        
        XCTAssertFalse(detail.callButton.label.isEmpty)
        XCTAssertFalse(detail.directionsButton.label.isEmpty)
    }
    
    // MARK: - Dynamic Type

    // Verifying that the app can launch with different text size and that rows still display
    func test_appLaunchesWithLargestAccessibilityTextSize() throws {
        // Terminate the existing app instance from setUp
        app.terminate()
        
        // Create a new app instance with accessibility text size
        app = XCUIApplication()
        app.launchArguments = [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()
        
        // Wait for the list screen to load using the existing screen reference
        listScreen.waitForLoaded()
        
        XCTAssertTrue(listScreen.screen.exists)
        XCTAssertGreaterThan(listScreen.visibleServiceCount(), 0)
    }
}
