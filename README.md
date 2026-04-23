# ServiceLocator

An iOS automation showcase project. The app is a civic-tech service locator for the Atlanta metro area — food assistance, housing support, mental health resources, healthcare, and employment help — but the focus of this repo is the test suite and CI pipeline around it.

The goal of this project is to demonstrate how I design an XCUITest automation suite from scratch: page object model, data-agnostic assertions, real system integration, and continuous integration with a reporting dashboard.

## The App (In Brief)

SwiftUI + MVVM, with a `LocationProviding` protocol abstracting Core Location and a `ServiceProviding` protocol abstracting the data source. The UI includes:

- A list of services with search and category filtering
- Distance-based sorting using `CLLocation.distance(from:)`
- A detail screen for each service
- Full VoiceOver / Dynamic Type accessibility support

Real Atlanta-metro services (MUST Ministries, Atlanta Community Food Bank, Grady, Covenant House, and others) with accurate coordinates are served in-memory through `MockServiceProvider`. Because `ServiceProviding` is a protocol, swapping in a real HSDS/211 network provider is a one-file change.

## Test Architecture

### Page Object Model

All element queries live in screen objects — `ServiceListScreen` and `ServiceDetailScreen`. Tests never touch `XCUIApplication` directly; they call methods on the screen objects. When the UI changes, updates happen in one place.

```
ServiceLocatorUITests/
├── BaseClass.swift             Shared setup/teardown (app launch, listScreen init)
├── PageObjects/
│   ├── ElementUtility.swift    waitForElement / waitForDisappearance helpers
│   ├── ServiceListScreen.swift List screen + RenderedServiceRow parser
│   └── ServiceDetailScreen.swift Detail screen elements and actions
├── ServiceListUITests.swift    Main functional coverage
└── AccessibilityUITests.swift  Accessibility-focused coverage
```

`BaseClass` extends `XCTestCase` and handles app launch, screen initialization, and the loading wait. Every test class inherits from it so individual tests stay focused on what they're asserting, not on setup boilerplate.

### Data-Agnostic Assertions

The test suite does not hardcode any service names. Instead, rows are harvested from the accessibility tree at runtime through a `RenderedServiceRow` struct that parses each row's accessibility label:

```
"MUST Ministries..., Food Assistance, 12.3 miles away"
  ↓
RenderedServiceRow(name: "MUST Ministries...", category: "Food Assistance", distanceMiles: 12.3)
```

Tests assert on **contracts** — "every row has a non-empty name", "rows are sorted in ascending distance order", "every rendered category is drawn from the known chip set". This means the suite continues to work if the underlying data source changes, which is exactly what we'd want when swapping in a real HSDS/211 provider.

### Real System Integration

The suite runs against the real `CLLocationManager` rather than a mocked location provider. The full permission → distance calculation → sort pipeline is exercised end to end. This catches bugs that mocks would miss — permission state handling, delegate callbacks, the moment a distance string actually appears on a row.

The CI pipeline pre-grants location permission silently before the test run (see below), so no dialog interaction is needed.

## Test Coverage

### Functional (`ServiceListUITests`)

| Area | Tests |
|------|-------|
| Happy path | Rows render; names, categories, and distances are populated; categories are from the known set |
| Search | Filtering reduces row count, filtered rows contain the search term, empty state on no match, clear restores list |
| Category filtering | Selecting a category shows only matching rows, "All" chip restores full list |
| Location sorting | Rows are in ascending distance order, closest service is within 50 miles (sanity check) |
| Navigation | Tapping a row opens the detail screen with matching name/category/distance, back returns to list |

### Accessibility (`AccessibilityUITests`)

| Area | Tests |
|------|-------|
| Label coverage | Every visible interactive button has a non-empty label, search field has a proper label |
| Traits | Selected category chip reports `isSelected=true` to VoiceOver |
| Combined elements | Every row combines name + category + distance into a single accessible announcement |
| Detail screen | All info sections and action buttons have meaningful labels |
| Dynamic Type | App launches and renders at the largest accessibility text size |

## Continuous Integration

`.github/workflows/ios-tests.yml` runs the full suite on a self-hosted macOS runner and uploads a static HTML dashboard summarizing results.

### Pipeline Stages

1. **Checkout** the repo
2. **Show environment** — runner hostname and Xcode version for debugging
3. **Open Simulator app** (non-headless — the simulator window is visible so the run can be watched)
4. **Boot simulator and set location** — boots iPhone 17 Pro and sets GPS to Acworth, GA
5. **Build app** — `xcodebuild build-for-testing`, output into `build/DerivedData`
6. **Install app and grant location** — installs the built app onto the simulator and calls `xcrun simctl privacy grant location` so no permission dialog ever appears during the test run
7. **Run UI tests** — `xcodebuild test-without-building` with `-parallel-testing-enabled NO` and result bundle output at `build/TestResults.xcresult`
8. **Generate dashboard** — Python script parses the xcresult bundle and renders an HTML summary
9. **Upload dashboard artifact** — the dashboard directory is uploaded as a workflow artifact available for 30 days

### Why This Shape

**Self-hosted runner** — iOS UI tests need a real macOS environment with Xcode and a simulator. A Mac mini at home is free, fast, and doesn't compete for GitHub's macOS runner minutes.

**Manual trigger only** (`workflow_dispatch`) — self-hosted runners on public repos are a security risk because a PR from anyone could run arbitrary code on the runner. Restricting to manual trigger means only the repo owner can run the workflow.

**Build once, test once** — splitting `build-for-testing` and `test-without-building` allows installing and configuring the app (granting location permission) between build and test. This is the standard pattern for avoiding permission dialog interaction in CI.

**Sequential execution** — `-parallel-testing-enabled NO` keeps the suite deterministic. For a suite this small, parallelization would add flake risk without saving meaningful time.

### Dashboard

The dashboard is a standalone `index.html` rendered by `scripts/generate-dashboard.py`. It parses the `.xcresult` bundle using `xcresulttool get test-results summary` (Xcode 16+) with a fallback to the legacy command.

It shows:

- Overall status banner — PASSING / FAILING / NO RESULTS
- Pass / fail / skipped / total counts as cards
- Pass rate with a progress bar
- Failure details (test name, target, message) for any failing tests
- Run metadata (commit, branch, run number, triggered by)

The dashboard is uploaded as a workflow artifact per run. It can be downloaded from the GitHub Actions page and opened locally.

## What I Would Add With More Time

- A real `HSDSNetworkProvider` against a partner 211 endpoint, demonstrating the test suite works unchanged across implementations
- GitHub Pages hosting for the dashboard instead of download-only artifacts
- Historical trend data on the dashboard (last N runs, pass-rate over time)
- Make the Call and Directions action buttons in the Service Detail screen functional
- Automating testing the app when location permissions are denied (currently flaky with Apple permission popups)

