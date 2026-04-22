import XCTest

/// UI tests that assert against the actual data rendered by the app
/// at runtime. Row content is harvested from the accessibility tree —
/// no hardcoded service names appear in assertions. These tests would
/// continue to work if the data source changes (e.g., when a real
/// HSDS/211 provider replaces the current in-memory one).
///
/// Requires simulator location set to Acworth, GA (34.0662, -84.6769)
/// before running. See README for setup.
final class ServiceListUITests: XCTestCase {
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
    
    // MARK: - Happy Path
    
    func test_serviceList_rendersAtLeastOneRow() {
        let rows = listScreen.visibleRows()
        XCTAssertFalse(rows.isEmpty, "Expected at least one service row to render")
    }
    
    func test_everyRenderedRow_hasNameAndCategory() {
        listScreen.waitForDistancesToResolve()
        let rows = listScreen.visibleRows()
        XCTAssertFalse(rows.isEmpty)
        for row in rows {
            XCTAssertFalse(row.name.isEmpty, "Row rendered with empty name")
            XCTAssertFalse(row.category.isEmpty, "Row for '\(row.name)' rendered with empty category")
        }
    }
    
    func test_everyRenderedRow_hasResolvedDistance() {
        listScreen.waitForDistancesToResolve()
        let rows = listScreen.visibleRows()
        for row in rows {
            XCTAssertNotNil(
                row.distanceMiles,
                "Row for '\(row.name)' did not render a distance with location authorized"
            )
        }
    }
    
    func test_renderedCategories_areFromKnownCategorySet() {
        // The category chips are the source of truth for what categories
        // exist. Any rendered row category must appear among them.
        listScreen.waitForDistancesToResolve()
        
        let chipPredicate = NSPredicate(format: "identifier BEGINSWITH 'categoryChip_' AND NOT identifier ENDSWITH 'all'")
        let renderedCategoryChips = app.buttons.matching(chipPredicate)
            .allElementsBoundByIndex
            .map { $0.label }
        let knownCategories = Set(renderedCategoryChips)
        XCTAssertFalse(knownCategories.isEmpty, "Expected category chips to be rendered")
        
        let rows = listScreen.visibleRows()
        for row in rows {
            XCTAssertTrue(
                knownCategories.contains(row.category),
                "Row for '\(row.name)' had category '\(row.category)' which is not in the known set: \(knownCategories)"
            )
        }
    }
    
    // MARK: - Search
    
    func test_search_reducesRowCount() {
        let initialCount = listScreen.visibleServiceCount()
        guard let firstRow = listScreen.visibleRows().first else {
            XCTFail("Expected at least one row before searching")
            return
        }
        
        // Use the first word of the first row's name as a search term —
        // guaranteed to match that row and likely to filter out others.
        let searchTerm = firstRow.name.components(separatedBy: " ").first ?? firstRow.name
        listScreen.search(for: searchTerm)
        
        let filteredCount = listScreen.visibleServiceCount()
        XCTAssertLessThanOrEqual(
            filteredCount,
            initialCount,
            "Searching should not increase the number of visible rows"
        )
        XCTAssertGreaterThan(
            filteredCount,
            0,
            "Searching for a term drawn from an existing row should return at least that row"
        )
    }
    
    func test_search_matchingRowsContainSearchTerm() {
        guard let firstRow = listScreen.visibleRows().first else {
            XCTFail("Expected at least one row")
            return
        }
        let searchTerm = firstRow.name.components(separatedBy: " ").first ?? firstRow.name
        listScreen.search(for: searchTerm)
        
        let rows = listScreen.visibleRows()
        XCTAssertFalse(rows.isEmpty)
        for row in rows {
            XCTAssertTrue(
                row.name.localizedCaseInsensitiveContains(searchTerm),
                "Row '\(row.name)' does not contain search term '\(searchTerm)'"
            )
        }
    }
    
    func test_search_showsEmptyStateForNoMatches() {
        listScreen.search(for: "zzzzz-impossible-match-zzzzz")
        XCTAssertTrue(listScreen.emptyView.waitForExistence(timeout: 2))
    }
    
    func test_search_clearButtonRestoresFullList() {
        let initialCount = listScreen.visibleServiceCount()
        guard let firstRow = listScreen.visibleRows().first else {
            XCTFail("Expected at least one row")
            return
        }
        let searchTerm = firstRow.name.components(separatedBy: " ").first ?? firstRow.name
        listScreen.search(for: searchTerm)
        listScreen.clearSearch()
        
        XCTAssertEqual(
            listScreen.visibleServiceCount(),
            initialCount,
            "Clearing the search should restore the original row count"
        )
    }
    
    // MARK: - Category Filtering
    
    func test_categoryFilter_showsOnlyRowsWithSelectedCategory() {
        listScreen.waitForDistancesToResolve()
        
        // Pick whichever category the first row has, so we know at least
        // one service will match after filtering.
        guard let firstRow = listScreen.visibleRows().first else {
            XCTFail("Expected at least one row")
            return
        }
        let targetCategory = firstRow.category
        
        listScreen.selectCategory(targetCategory)
        
        let filteredRows = listScreen.visibleRows()
        XCTAssertFalse(filteredRows.isEmpty, "Filtering by '\(targetCategory)' returned no rows")
        for row in filteredRows {
            XCTAssertEqual(
                row.category,
                targetCategory,
                "Row '\(row.name)' has category '\(row.category)' but filter is '\(targetCategory)'"
            )
        }
    }
    
    func test_categoryFilter_allChipRestoresFullList() {
        listScreen.waitForDistancesToResolve()
        let initialCount = listScreen.visibleServiceCount()
        
        guard let firstRow = listScreen.visibleRows().first else {
            XCTFail("Expected at least one row")
            return
        }
        listScreen.selectCategory(firstRow.category)
        listScreen.tapAllCategoriesChip()
        
        XCTAssertEqual(
            listScreen.visibleServiceCount(),
            initialCount,
            "Tapping 'All' should restore the original row count"
        )
    }
    
    // MARK: - Location-Based Sorting
    
    /// Rather than asserting that a specific named service is first,
    /// this test asserts the contract: rows are in ascending distance order.
    func test_rows_areSortedByAscendingDistance() {
        listScreen.waitForDistancesToResolve()
        let rows = listScreen.visibleRows()
        let distances = rows.compactMap { $0.distanceMiles }
        
        XCTAssertEqual(
            distances.count,
            rows.count,
            "Expected every row to have a resolved distance"
        )
        
        for i in 1..<distances.count {
            XCTAssertLessThanOrEqual(
                distances[i - 1],
                distances[i],
                "Rows are not in ascending distance order at position \(i): \(distances[i - 1]) came before \(distances[i])"
            )
        }
    }
    
    /// Sanity-check: the closest rendered service should be within a
    /// reasonable driving distance for metro Atlanta. Catches GPS/sim
    /// misconfiguration without asserting on a specific service.
    func test_closestService_isWithinReasonableDistance() {
        listScreen.waitForDistancesToResolve()
        let rows = listScreen.visibleRows()
        guard let closest = rows.first?.distanceMiles else {
            XCTFail("No rows with distance rendered")
            return
        }
        XCTAssertLessThan(
            closest,
            50.0,
            "Closest service is \(closest) miles away — simulator location may be wrong"
        )
    }
    
    // MARK: - Navigation
    
    /// Asserts the detail screen shows the same values that were
    /// rendered in the list row — validating the navigation contract
    /// without depending on which specific service we tap.
    func test_tappingRow_opensDetailWithSameValuesAsRow() {
        listScreen.waitForDistancesToResolve()
        guard let firstRow = listScreen.visibleRows().first else {
            XCTFail("Expected at least one row")
            return
        }
        
        let detail = listScreen.tapFirstService()
        detail.waitForScreen()
        
        XCTAssertTrue(detail.serviceNameLabel.exists)
        XCTAssertEqual(
            detail.serviceNameLabel.label,
            firstRow.name,
            "Detail screen name does not match the row that was tapped"
        )
        XCTAssertEqual(
            detail.serviceCategoryLabel.label,
            firstRow.category,
            "Detail screen category does not match the row that was tapped"
        )
        XCTAssertTrue(detail.addressSection.exists)
        XCTAssertTrue(detail.phoneSection.exists)
        XCTAssertTrue(detail.hoursSection.exists)
    }
    
    func test_backNavigation_returnsToList() {
        let detail = listScreen.tapFirstService()
        detail.waitForScreen()
        detail.goBack()
        XCTAssertTrue(listScreen.screen.waitForExistence(timeout: 2))
    }
}
