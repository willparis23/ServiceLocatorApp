import XCTest

final class ServiceDetailScreen: BaseScreen {
    
    // MARK: - Elements
    
    var screen: XCUIElement {
        app.scrollViews["serviceDetailScreen"]
    }
    
    var serviceNameLabel: XCUIElement {
        app.staticTexts["serviceNameLabel"]
    }
    
    var serviceCategoryLabel: XCUIElement {
        app.staticTexts["serviceCategoryLabel"]
    }
    
    var serviceDistanceLabel: XCUIElement {
        app.staticTexts["serviceDistanceLabel"]
    }
    
    var addressSection: XCUIElement {
        app.staticTexts["addressSection"]
    }
    
    var phoneSection: XCUIElement {
        app.staticTexts["phoneSection"]
    }
    
    var hoursSection: XCUIElement {
        app.staticTexts["hoursSection"]
    }
    
    var descriptionSection: XCUIElement {
        app.staticTexts["descriptionSection"]
    }
    
    var callButton: XCUIElement {
        app.buttons["callButton"]
    }
    
    var directionsButton: XCUIElement {
        app.buttons["directionsButton"]
    }
    
    var backButton: XCUIElement {
        app.buttons["BackButton"]
    }
    
    // MARK: - Actions

    func waitForScreen() {
        _ = waitForElement(screen)
    }

    func goBack() {
        backButton.tap()
    }

    func tapCall() {
        callButton.tap()
    }

    func tapDirections() {
        directionsButton.tap()
    }
}
