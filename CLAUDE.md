# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build for iOS (when xcode-select is not configured)
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project BabyBuddySonnet.xcodeproj \
  -scheme BabyBuddySonnet \
  -destination 'generic/platform=iOS' \
  build

# Build for simulator
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project BabyBuddySonnet.xcodeproj \
  -scheme BabyBuddySonnet \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

There are no unit tests. The project has no `Package.swift` — all dependencies are system Apple frameworks only.

## Architecture

**MVVM with Swift 6 strict concurrency:**
- `Services/APIClient.swift` — `actor` for thread-safe HTTP. Single shared instance (`APIClient.shared`). Handles auth header injection, JSON snake_case↔camelCase conversion, and paginated responses.
- `ViewModels/*.swift` — All `@Observable @MainActor` classes. Fetch data, compute derived state (chart data, summaries, progress), expose CRUD actions to views.
- `Models/*.swift` — All `nonisolated struct ... Sendable`. Required so Codable conformances aren't main-actor-isolated when used from the `APIClient` actor.
- `Views/` — Pure SwiftUI. Feature folders: Dashboard, Feeding, Sleep, Diaper, Pumping, Settings, Setup, Shared.

**Key services:**
- `SettingsService.swift` — `@Observable`, backed by `NSUbiquitousKeyValueStore` (iCloud sync). Holds feeding/sleep targets, wake time, timezone, server URL.
- `KeychainService.swift` — Stores API token securely.

**Utilities (stateless static helpers):**
- `Utilities/DateFormatting.swift` — ISO8601 parsing, API date formatting, helper ranges (yesterday, tomorrow, sevenDaysAgo).
- `Utilities/Calculations.swift` — Business logic: feeding consumed total (bottles only), cumulative chart building, expected/average line calculation, feeding progress status.
- `Utilities/Constants.swift` — Default values (feeding target 24oz, sleep target 14h, frozen expiration 180d), timezone list, color mappings.
- `Services/APIEndpoints.swift` — Static API path strings.

## Swift 6 / Xcode 26 MainActor Isolation

The project sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so **every type** is `@MainActor` by default. Plain data types (models, input structs, enums, utility namespaces) **must** be marked `nonisolated` to avoid actor isolation conflicts with `Codable` and `Sendable`:

```swift
// Correct pattern for all models and input structs
nonisolated struct MyModel: Codable, Sendable { ... }
nonisolated enum MyEnum: String, Codable, Sendable { ... }
```

## API Conventions

- **Auth**: `Authorization: Token <token>` header, configured once in `AppViewModel.authenticate()`.
- **Date queries**: Use yesterday→tomorrow range, then filter client-side for "today" (handles timezone edge cases).
- **Diaper changes**: Filter params are `time_min`/`time_max` (not `start_min`/`start_max`).
- **Pumping milk category**: Stored as JSON in the `notes` field: `{"category":"to-be-consumed"}`.
- **Feeding consumed total**: Only feedings with `method == .bottle` count toward the daily consumed total.
- **Pagination**: `PaginatedResponse<T>` wraps all list responses. ViewModels request with `limit` param as needed.

## Xcode Project Notes

The project uses `PBXFileSystemSynchronizedRootGroup` — new Swift files added to `BabyBuddySonnet/BabyBuddySonnet/` are **automatically included** in the build without editing the `.xcodeproj`.
