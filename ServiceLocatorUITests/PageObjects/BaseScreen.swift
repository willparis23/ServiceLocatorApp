import XCTest

class BaseScreen {
    let app: XCUIApplication
    let defaultTimeout: TimeInterval = 5.0
    
    init(app: XCUIApplication) {
        self.app = app
    }

    func waitForElement(
        _ element: XCUIElement,
        timeout: TimeInterval? = nil,
        file: StaticString = #file,
        line: UInt = #line) -> Bool {
        let exists = element.waitForExistence(timeout: timeout ?? defaultTimeout)
        if !exists {
            XCTFail("Element \(element) did not appear within timeout", file: file, line: line)
        }
        return exists
    }
    
    func waitForDisappearance(
        _ element: XCUIElement,
        timeout: TimeInterval? = nil) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(
            for: [expectation],
            timeout: timeout ?? defaultTimeout
        )
        return result == .completed
    }
}
