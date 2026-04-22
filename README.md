# ServiceLocator

A civic tech iOS app that helps people find nearby social services — food assistance, housing support, mental health resources, healthcare, and employment help — in the Atlanta metro area.

Built as a showcase of SwiftUI architecture and XCUITest automation practices, with a specific focus on real-system integration, accessibility, and honest tradeoffs.

## Why This App

When software serves people in vulnerable moments, quality is not just a technical concern — it is part of how you treat people. This project demonstrates that belief through both the product and the tests.

## Architecture

### Protocol-Oriented Services

Two protocols sit at the core of the app:

- `ServiceProviding` abstracts where service data comes from
- `LocationProviding` abstracts how we get the user's location

`CoreLocationProvider` is the production implementation backed by `CLLocationManager`. Tests run against this real provider, exercising the actual permission flow and the real distance calculation pipeline end to end.

### MVVM with Combine

`ServiceListViewModel` owns all state and filtering logic. Views are thin renderers that bind to published properties. This separation keeps view code declarative and business logic directly unit-testable.

### Real Distance Calculation

Services are stored with latitude and longitude. When the user's location is available, the view model sorts the service list by real-world proximity using `CLLocation.distance(from:)`. When it is not available, results are shown without distances.

## Project Structure

```
ServiceLocator/
├── Models/              Service with CoreLocation coordinates
├── ViewModels/          ServiceListViewModel (Combine + location state)
├── Views/               ServiceListView, ServiceDetailView
└── Services/
    ├── ServiceProvider  ServiceProviding + MockServiceProvider
    └── LocationProvider LocationProviding + CoreLocationProvider

ServiceLocatorUITests/
├── AppLauncher                  Launches app and handles system permission alert
├── PageObjects/                 BaseScreen, ServiceListScreen, ServiceDetailScreen
├── ServiceListUITests           Happy path, search, filter, navigation, proximity sorting
├── LocationPermissionUITests    Real permission dialog flow
└── AccessibilityUITests         Label coverage, traits, Dynamic Type

scripts/
└── setup-simulator.sh           Configures simulator location and privacy
```

## A Note on Data

The civic tech standard for social services data is Open Referral HSDS (Human Services Data Specification), used by 211 providers and many city governments. There is no free nationwide endpoint — each locality runs its own, and most require partnership agreements.

Rather than forcing a lower-quality API integration, this app uses a curated set of real Atlanta-metro services (MUST Ministries, Atlanta Community Food Bank, Grady, Covenant House, and others) with accurate addresses and coordinates. The data is served through the `ServiceProviding` protocol, so swapping in an `HSDSNetworkProvider` against a real 211 endpoint is a one-file change.

## Test Strategy

### Real Core Location, Real Permission Flow

The UI test suite does not mock location. Tests run against `CoreLocationProvider`, use the simulator's configured location, and tap through the real iOS permissions alert via `addUIInterruptionMonitor`. This approach validates the full location pipeline — permission handling, fix acquisition, distance calculation, and sorted rendering — end to end.

This is a deliberate choice. It trades some determinism for realism: the same code paths that run in production also run in tests.

### Page Object Model

All element queries live in screen objects. Tests read like user stories and stay stable when UI changes.

### Coverage Areas

- Happy path — loading, displaying, and navigating the service list
- Search — filtering by name, clearing, empty states
- Category filtering — selection, deselection, restoration
- Navigation — list-to-detail and back
- Proximity sorting — verifying Cobb County services appear before downtown Atlanta services when the user is in Acworth
- Distance calculation accuracy — verifying computed mileage is within expected ranges
- Real location permission flow — system alert auto-tapped via interruption monitor
- Accessibility — label completeness, selected-state announcements, Dynamic Type, combined elements

## Running the Tests

### First-Time Setup

Before running the suite, configure the simulator:

```bash
./scripts/setup-simulator.sh
```

This sets the simulator location to Acworth, GA (34.0662, -84.6769) and resets the app's location privacy so the permission alert appears on first launch.

You can also do this manually:

```bash
xcrun simctl location booted set 34.0662,-84.6769
xcrun simctl privacy booted reset location com.example.ServiceLocator
```

### Run the Tests

Open `ServiceLocator.xcodeproj` in Xcode, then:

```
Cmd + U
```

Or from the command line:

```bash
xcodebuild test \
  -project ServiceLocator.xcodeproj \
  -scheme ServiceLocator \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Troubleshooting

### Permission alert is not being dismissed

`addUIInterruptionMonitor` only fires after the next user interaction, so `AppLauncher` calls `app.tap()` right after launch. If the alert still lingers:

- Confirm the simulator language is English (alert button labels depend on locale)
- Try resetting privacy: `xcrun simctl privacy booted reset location com.example.ServiceLocator`
- On some Xcode versions the monitor is flaky on first install — a second run usually succeeds

### Distance rows never appear

This typically means the simulator does not have a location set. Run:

```bash
xcrun simctl location booted set 34.0662,-84.6769
```

Or open Features → Location → Custom Location in the simulator menu bar.

### Proximity test fails

Check that the simulator location is actually Acworth. If it reports a different city, reset and re-run `setup-simulator.sh`.

## What I Would Add With More Time

- A real `HSDSNetworkProvider` against a partner 211 endpoint
- Snapshot tests for visual regression
- GitHub Actions CI with an automated pre-test step to configure the simulator
- Unit tests for `ServiceListViewModel` (testing business logic in isolation complements the end-to-end UI tests)
- Localization (Spanish at minimum)
- Apple Maps integration for the Directions button
- Offline caching
