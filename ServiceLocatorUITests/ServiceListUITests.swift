import XCTest

/// UI tests that assert against the actual data rendered by the app
/// at runtime. Row content is harvested from the accessibility tree —
/// no hardcoded service names appear in assertions. These tests would
/// continue to work if the data source changes (e.g., when a real
/// HSDS/211 provider replaces the current in-memory one).
///
/// Requires simulator location set to Acworth, GA (34.0662, -84.6769)
/// before running. See README for setup.
final class ServiceListUITests: BaseClass {
    
    // MARK: - Happy Path

    // Verifying that app launches with at least one row visible to user
    func test_serviceListRendersAtLeastOneRow() {
        let rows = listScreen.visibleRows()
        XCTAssertFalse(rows.isEmpty, "Expected at least one service row to render")
    }

    // Verifying that every service row has an associated name and category
    func test_everyRenderedRowHasNameAndCategory() {
        listScreen.waitForDistancesToResolve()
        let rows = listScreen.visibleRows()
        XCTAssertFalse(rows.isEmpty)
        for row in rows {
            XCTAssertFalse(row.name.isEmpty, "Row rendered with empty name")
            XCTAssertFalse(row.category.isEmpty, "Row for '\(row.name)' rendered with empty category")
        }
    }

    // Verifying that every row has an associated distance that is displayed
    func test_everyRenderedRowHasResolvedDistance() {
        listScreen.waitForDistancesToResolve()
        let rows = listScreen.visibleRows()
        for row in rows {
            XCTAssertNotNil(row.distanceMiles, "Row for '\(row.name)' did not render a distance with location authorized")
        }
    }

    // Verifying that each row has a category contained in the list of known categories
    func test_renderedCategoriesAreFromKnownCategorySet() {
        listScreen.waitForDistancesToResolve()

        // taking the list of category chips excluding the "all" chip
        let chipPredicate = NSPredicate(format: "identifier BEGINSWITH 'categoryChip_' AND NOT identifier ENDSWITH 'all'")
        let renderedCategoryChips = app.buttons.matching(chipPredicate).allElementsBoundByIndex.map { $0.label }
        let knownCategories = Set(renderedCategoryChips)
        XCTAssertFalse(knownCategories.isEmpty, "Expected category chips to be rendered")

        // taking the list of visible rows and verifying that each row has a category that is contained in the list of known categories
        let rows = listScreen.visibleRows()
        for row in rows {
            XCTAssertTrue(
                knownCategories.contains(row.category),
                "Row for '\(row.name)' had category '\(row.category)' which is not in the known set: \(knownCategories)"
            )
        }
    }
    
    // MARK: - Search

    // Verifying that using search to filter results reduces the count of rows returned
    func test_searchReducesRowCount() {
        let initialCount = listScreen.visibleServiceCount()
        let firstRow = listScreen.waitForFirstRowToRender()
        
        // Use the first word of the first row's name as a search term
        // guaranteed to match that row and likely to filter out others
        let searchTerm = firstRow.name.components(separatedBy: " ").first ?? firstRow.name
        listScreen.search(for: searchTerm)

        // verifying that filtered rows aren't increasing results but also return some results (not zero results)
        let filteredCount = listScreen.visibleServiceCount()
        XCTAssertLessThanOrEqual(filteredCount, initialCount, "Searching should not increase the number of visible rows")
        XCTAssertGreaterThan(filteredCount, 0, "Searching for a term drawn from an existing row should return at least that row")
    }

    // Verifying that each filtered search row contains the search term applied
    func test_searchMatchingRowsContainSearchTerm() {
        let firstRow = listScreen.waitForFirstRowToRender()
        let searchTerm = firstRow.name.components(separatedBy: " ").first ?? firstRow.name
        listScreen.search(for: searchTerm)

        // taking the rows from the resulting filtered search list
        let rows = listScreen.visibleRows()

        // verifying list is not empty
        XCTAssertFalse(rows.isEmpty)

        // verifying that row name contains search term
        for row in rows {
            XCTAssertTrue(
                row.name.localizedCaseInsensitiveContains(searchTerm),
                "Row '\(row.name)' does not contain search term '\(searchTerm)'"
            )
        }
    }

    // Verifying the emoty state for search when there is no results for a search term
    func test_searchShowsEmptyStateForNoMatches() {
        listScreen.search(for: "no match for this term")
        XCTAssertTrue(listScreen.emptyView.waitForExistence(timeout: 2))
    }

    // Verifying that clearing the search text field restores the full list of service rows
    func test_searchClearButtonRestoresFullList() {
        // taking the count of initial rows
        let initialCount = listScreen.visibleServiceCount()
        let firstRow = listScreen.waitForFirstRowToRender()

        // searching by the first rows name to filter out the results
        let searchTerm = firstRow.name.components(separatedBy: " ").first ?? firstRow.name
        listScreen.search(for: searchTerm)

        // making sure that searching updates the count of rows
        let updatedCount = listScreen.visibleServiceCount()
        XCTAssertNotEqual(initialCount, updatedCount)

        // clearing the search field and verifying the count equals the initial count of rows
        listScreen.clearSearch()
        XCTAssertEqual(
            listScreen.visibleServiceCount(),
            initialCount,
            "Clearing the search should restore the original row count"
        )
    }
    
    // MARK: - Category Filtering

    // Verifying that a filtered category shows only rows that are in that specific category
    func test_categoryFilterShowsOnlyRowsWithSelectedCategory() {
        listScreen.waitForDistancesToResolve()
        
        // Pick whichever category the first row has, so we know at least
        // one service will match after filtering
        let firstRow = listScreen.waitForFirstRowToRender()
        let targetCategory = firstRow.category

        // selecting the first rows target category
        listScreen.selectCategory(targetCategory)

        // verifying that filtered rows show only the category that is filtered by
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

    // Verifying that tapping the "All" categroy chip shows all categories
    func test_categoryFilterAllChipRestoresFullList() {
        listScreen.waitForDistancesToResolve()
        let initialCount = listScreen.visibleServiceCount()

        // selecting first rows associated category, taking count after filtering
        let firstRow = listScreen.waitForFirstRowToRender()
        listScreen.selectCategory(firstRow.category)
        let countAfterFilter = listScreen.visibleServiceCount()

        // verifying that count changed, tapping the "All" categories button
        XCTAssertNotEqual(initialCount, countAfterFilter, "Count should change after filtering")
        listScreen.tapAllCategoriesChip()

        // verifying that tapping "All" button restores rows to pre-filtered state
        XCTAssertEqual(listScreen.visibleServiceCount(), initialCount, "Tapping 'All' should restore the original row count")
    }
    
    // MARK: - Location-Based Sorting
    
    // Verifying that each row is displayed by distance in ascending order (closest to farthest)
    func test_rowsAreSortedByAscendingDistance() {
        // storing each rows disatnce and making sure each row displays a distance
        listScreen.waitForDistancesToResolve()
        let rows = listScreen.visibleRows()
        let distances = rows.compactMap { $0.distanceMiles }
        XCTAssertEqual(distances.count, rows.count, "Expected every row to have a resolved distance")
        
        // Iterate through distances starting from the second element (index 1)
        // and compare each distance with its predecessor to ensure ascending order
        for i in 1..<distances.count {
            // Verify that the previous distance is less than or equal to the current distance
            // This ensures the list is sorted from closest to farthest service
            XCTAssertLessThanOrEqual(
                distances[i - 1],
                distances[i],
                "Rows are not in ascending distance order at position \(i): \(distances[i - 1]) came before \(distances[i])"
            )
        }
    }
    
    // Verifying that each distance is within at least 50 miles of the user
    func test_closestServiceIsWithinReasonableDistance() {
        listScreen.waitForDistancesToResolve()
        let rows = listScreen.visibleRows()
        guard let closest = rows.first?.distanceMiles else {
            XCTFail("No rows with distance rendered")
            return
        }
        XCTAssertLessThan(closest, 50.0, "Closest service is \(closest) miles away — simulator location may be wrong")
    }
    
    // MARK: - Navigation
    
    // Verifying that clicking on a row displays detail screen with matching name/category
    func test_tappingRowOpensDetailWithSameValuesAsRow() {
        listScreen.waitForDistancesToResolve()
        let firstRow = listScreen.waitForFirstRowToRender()

        // tapping on first service row available
        let detail = listScreen.tapFirstService()
        detail.waitForScreen()

        // verifying that service name in detail screen matches the same name as the row clicked on the search screen
        XCTAssertTrue(detail.serviceNameLabel.exists)
        XCTAssertEqual(
            detail.serviceNameLabel.label,
            firstRow.name,
            "Detail screen name does not match the row that was tapped"
        )

        // verifying that category label in detail screen matches the same category as the row clicked on the search screen
        XCTAssertEqual(
            detail.serviceCategoryLabel.label,
            firstRow.category,
            "Detail screen category does not match the row that was tapped"
        )

        // verifying that distance in detail screen matches the same distance as the row clicked on the search screen
        let distanceString = detail.serviceDistanceLabel.label
        let extractedDistance = distanceString.components(separatedBy: " ").first.flatMap { Double($0) }
        XCTAssertEqual(
            extractedDistance,
            firstRow.distanceMiles,
            "Detail screen distance does not match the row that was tapped"
        )

        // verifying that the detail screen contains the appropriate sections
        XCTAssertTrue(detail.addressSection.exists)
        XCTAssertTrue(detail.phoneSection.exists)
        XCTAssertTrue(detail.hoursSection.exists)
    }

    // Verifying that pressing the back button on the detail screen returns user to search screen
    func test_backNavigationReturnsToList() {
        let detail = listScreen.tapFirstService()
        detail.waitForScreen()
        detail.goBack()
        XCTAssertTrue(listScreen.screen.waitForExistence(timeout: 2))
    }
}
