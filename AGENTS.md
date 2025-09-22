# Repository Guidelines

## Project Structure & Module Organization
Serenity is a SwiftUI iOS app. Core views (`ChatView.swift`, `ContentView.swift`, `SettingsView.swift`) and model logic (`Models.swift`, `AIProvider.swift`, `KeychainService.swift`) live in `Serenity/`. Shared assets are under `Serenity/Assets.xcassets`, and `ModelCatalog.swift` centralises remote model identifiers. Keep SwiftData entities and storage helpers close to the features they support. Use `SerenityTests/` and `SerenityUITests/` for new unit and UI suites; mirror the app folder structure when you add files. `build.log` captures the latest `xcodebuild` run for troubleshooting.

## Build, Test, and Development Commands
Run `xed .` to open the workspace in Xcode with the configured schemes. Use `xcodebuild -project Serenity.xcodeproj -scheme Serenity -configuration Debug build` for a reproducible CI build. Trigger automated tests with `xcodebuild test -project Serenity.xcodeproj -scheme Serenity -destination 'platform=iOS Simulator,name=iPhone 15'`. Add `CODE_SIGNING_ALLOWED=NO` when scripting simulator builds to avoid signing prompts.

## Coding Style & Naming Conventions
Follow standard Swift formatting with four-space indentation and brace-on-same-line style; rely on Xcode’s Format command before committing. Name types with UpperCamelCase and functions, properties, and @State variables with lowerCamelCase to match existing files. Group view-specific helpers inside the view struct and prefer `// MARK:` comments for larger sections. Keep user-facing text localized in the view files until a localization pass lands.

## Testing Guidelines
Adopt XCTest for both logic and UI checks. Place unit tests in `SerenityTests/` and import the app module with `@testable import Serenity`; suffix each test class with `Tests` and each method with a `test` prefix. Record UI flows in `SerenityUITests/` using `XCTestCase` and `XCUIApplication`. Aim to cover new model logic and any safety-critical flows (crisis handling, keychain access) before merging.

## Commit & Pull Request Guidelines
Match the short, descriptive style already in history (e.g., “Aggiornamento completo...”); keep subject lines imperative and under ~72 characters, optionally in Italian if that helps clarity. Reference related issues in the body and mention affected modules. PRs should include a summary of user-visible changes, screenshots for UI tweaks, notes on new configuration keys, and confirmation that `xcodebuild` build/test commands pass locally.

## Security & Configuration Tips
API credentials are stored with `KeychainService`; never log or commit them. Document how to obtain keys and remind reviewers to add them via `SettingsView` rather than hard-coding values. When no keys are present the clients fall back to the Cloudflare proxy at `https://llm-proxy-gateway.mariomos94.workers.dev`, so onboarding works without secrets; still document when real keys are required for higher quotas or advanced models. When introducing a new provider, update `ModelCatalog.shared` and provide safe defaults before exposing toggles. Review crisis-response copy in `SettingsView` whenever behaviour changes to keep safety messaging aligned with product requirements.
