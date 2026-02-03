# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Tranquiz** (formerly Serenity) is a cross-platform mental health companion app that provides AI-powered therapeutic conversation support with crisis detection, multiple AI provider support, and secure local data persistence.

**Repository Type**: Monorepo containing iOS/macOS and Android implementations

### Platforms

- **iOS/macOS** (`Serenity/` folder) - SwiftUI-based implementation
- **Android** (`Tranquiz Android/` folder) - Kotlin-based implementation with Material Design

---

## Repository Structure

```
.
├── Serenity/                    # iOS/macOS project source
├── Serenity.xcodeproj/          # Legacy Xcode project (deprecated)
├── Tranquiz.xcodeproj/          # Current iOS/macOS Xcode project
├── Tranquiz Android/            # Android project
│   ├── app/                     # Android app module
│   ├── build.gradle             # Root Gradle build file
│   ├── settings.gradle          # Gradle settings
│   ├── README.md                # Android-specific documentation
│   └── SETUP_INSTRUCTIONS.md    # Android setup guide
├── TranquizApp.icon/            # macOS Icon Composer bundle
├── app_store_*.txt              # App Store submission materials
├── privacy_policy.html          # Privacy policy
├── support.html                 # Support page
└── CLAUDE.md                    # This file
```

---

## iOS/macOS Project

### Build Commands

```bash
# Open in Xcode
open Tranquiz.xcodeproj

# Build from command line
xcodebuild -project Tranquiz.xcodeproj -scheme Tranquiz -configuration Debug build

# Build for specific platform
xcodebuild -project Tranquiz.xcodeproj -scheme Tranquiz -destination "platform=iOS Simulator,name=iPhone 15" build

# Run unit tests
xcodebuild test -project Tranquiz.xcodeproj -scheme TranquizTests -destination "platform=iOS Simulator,name=iPhone 15"
```

### Architecture

**Tech Stack**: SwiftUI, SwiftData (Core Data backing), Swift Concurrency
**Min Version**: iOS 18.0+, macOS 15.5+, visionOS 26.0+

**Core Components**:
- **AI Provider System** (`AIProvider.swift`, `AIService`) - Multi-provider LLM abstraction (OpenAI, Mistral, Groq)
- **Crisis Safety** (`CrisisDetection.swift`) - Real-time keyword detection with emergency intervention
- **Therapeutic Framework** (`TherapeuticPrompt.swift`) - System prompt for empathetic conversations
- **Data Persistence** (`Models.swift`) - SwiftData models: `Conversation`, `ChatMessage`, `MemorySummary`, `Attachment`
- **Chat Interface** (`ChatView.swift`) - Main conversation UI with streaming support

**Key Features**:
- Multi-provider AI support (OpenAI GPT, Mistral, Groq)
- Crisis intervention with automatic detection
- Image support via Vision-capable models
- Local-only storage with Keychain for API keys
- Memory system with automatic summarization
- Export functionality

**File Count**: ~34 Swift files

---

## Android Project

### Build Commands

```bash
# Navigate to Android folder
cd "Tranquiz Android"

# Build with Gradle
./gradlew build

# Install on connected device/emulator
./gradlew installDebug

# Run tests
./gradlew test

# Clean build
./gradlew clean build

# Open in Android Studio
# File → Open → Select "Tranquiz Android" folder
```

### Architecture

**Tech Stack**: Kotlin, Jetpack (Room, ViewModel, LiveData), Retrofit, Coroutines
**Min SDK**: 24 (Android 7.0), Target SDK: 34, Compile SDK: 34
**Pattern**: MVVM (Model-View-ViewModel)

**Project Structure**:
```
app/src/main/java/com/tranquiz/app/
├── data/                    # Data Layer
│   ├── api/                 # Retrofit services & API client
│   ├── catalog/             # Model catalog management
│   ├── database/            # Room database & DAOs
│   ├── gateway/             # Proxy gateway handling (Marilena worker)
│   ├── model/               # Data models & enums
│   ├── preferences/         # Encrypted preferences (AES256-GCM)
│   ├── repository/          # Repository pattern
│   └── therapeutic/         # Safety & therapeutic prompts
├── ui/                      # Presentation Layer
│   ├── adapter/             # RecyclerView adapters
│   ├── onboarding/          # Onboarding flow
│   ├── viewmodel/           # ViewModels
│   ├── MainActivity.kt      # Main chat activity
│   ├── SettingsActivity.kt  # Settings
│   └── SafetyActivity.kt    # Emergency resources
└── util/                    # Constants & utilities
```

**Key Components**:
- **API Layer** (`ApiClient.kt`, `ChatApiService.kt`) - Multi-provider support (OpenAI, Anthropic, Perplexity, Groq)
- **Database** - Room database v2: `tranquiz_database` with `Message` entity
- **Security** - `SecurePreferences` with EncryptedSharedPreferences (AES256-GCM)
- **Safety** - `SafetyClassifierPrompt` for crisis detection (returns "BLOCK" or "OK")
- **Onboarding** - 3-step flow (name, mood, goal)

**Key Features**:
- Gateway/Worker support (Marilena proxy)
- Multi-provider AI (OpenAI, Anthropic, Perplexity, Groq)
- Crisis detection with conversation blocking
- Material Design with custom theme
- Encrypted local storage
- WhatsApp/Telegram-like chat UI

**File Count**: ~23 Kotlin files

**Dependencies**:
- Jetpack: AppCompat, Lifecycle, Room, Fragment, Preference, Security-Crypto
- Networking: Retrofit 2.9, OkHttp
- UI: Material Design, ConstraintLayout, RecyclerView
- Async: Coroutines
- Utils: PrettyTime

---

## Common Features (Both Platforms)

### AI Provider Support
- OpenAI GPT models (GPT-4, GPT-3.5)
- Anthropic Claude models
- Mistral AI models
- Groq models
- Perplexity models (Android only)

### Crisis Detection System
- Italian language keyword/phrase detection
- Real-time monitoring during conversations
- Automatic intervention with emergency resources
- Conversation termination on crisis detection
- Emergency contact information display

### Therapeutic Framework
- Empathetic, non-directive conversation style
- Professional therapeutic techniques:
  - Reflective listening
  - Validation
  - Normalization
  - Reframing
- Strict boundaries: no clinical diagnosis or medical advice
- Emphasis on professional help referral when needed

### Security & Privacy
- API keys stored securely:
  - iOS/macOS: System Keychain
  - Android: EncryptedSharedPreferences (AES256-GCM)
- Local-only data storage
- No cloud sync of conversations
- Client-side crisis detection before AI calls
- Secure attachment storage

### Conversation Features
- Persistent conversation history
- Message export functionality
- Typing indicators
- Error handling with user-friendly messages
- Image/attachment support (iOS with Vision models)
- Memory/summarization system (iOS)

---

## Development Notes

### Cross-Platform Considerations
- Both platforms implement the same therapeutic AI assistant concept
- Crisis detection keywords are synchronized between platforms
- Therapeutic system prompts maintain consistency across platforms
- API provider interfaces are compatible but platform-native

### Platform-Specific Differences
| Feature | iOS/macOS | Android |
|---------|-----------|---------|
| **UI Framework** | SwiftUI | Jetpack Compose XML |
| **Database** | SwiftData (Core Data) | Room Database |
| **Min Version** | iOS 18.0 / macOS 15.5 | Android 7.0 (API 24) |
| **Languages** | Swift 5.0+ | Kotlin 1.9+ |
| **Image Support** | Vision models | Planned |
| **Memory System** | Automatic summarization | Planned |
| **Gateway Support** | Direct API only | Marilena worker proxy |

### Git Repository Status
- **Current Branch**: `main`
- **Working Tree**: Clean
- **Recent Activity**:
  - Android-iOS feature alignment
  - Monorepo configuration
  - Onboarding implementation
  - App Store submission materials

---

## App Store / Play Store Materials

The repository includes prepared submission materials:
- `app_store_description.txt` - App Store listing description
- `app_store_metadata.txt` - Metadata and keywords
- `app_store_final_summary.md` - Submission summary
- `app_store_steps.txt` - Submission checklist
- `privacy_policy.html` - Privacy policy (required)
- `support.html` - Support contact page (required)

---

## Testing

### iOS/macOS
```bash
# Unit tests
xcodebuild test -project Tranquiz.xcodeproj -scheme TranquizTests

# UI tests
xcodebuild test -project Tranquiz.xcodeproj -scheme TranquizUITests

# Crisis detection tests
# See: Serenity/CrisisDetectionTest.swift
```

### Android
```bash
cd "Tranquiz Android"

# Unit tests
./gradlew test

# Instrumented tests (requires device/emulator)
./gradlew connectedAndroidTest

# Specific test class
./gradlew test --tests "com.tranquiz.app.YourTestClass"
```

---

## Compliance & Safety

### Therapeutic Boundaries (Both Platforms)
- ✅ Empathetic support and life coaching
- ✅ Emotional validation and active listening
- ✅ Coping strategy suggestions
- ✅ Immediate crisis intervention
- ❌ No clinical diagnosis
- ❌ No medical advice or prescriptions
- ❌ No emergency service replacement
- ❌ No therapy session replacement

### Crisis Intervention Protocol
1. Real-time message monitoring for crisis keywords
2. Immediate conversation termination on detection
3. Display emergency resources (suicide hotline, local emergency services)
4. Clear messaging that app is not a substitute for professional help
5. Persistent emergency resources access via SafetyActivity/CrisisOverlay

---

## Configuration Files

### iOS/macOS
- `Info.plist` - App metadata and permissions
- `Tranquiz.xcodeproj/` - Xcode project configuration

### Android
- `app/build.gradle` - App module configuration
- `build.gradle` - Root project configuration
- `gradle.properties` - Gradle settings
- `app/src/main/res/values/strings.xml` - Gateway/API configuration
- `app/src/main/AndroidManifest.xml` - App manifest

---

## Known Issues & Notes

1. **Xcode Project**: Two Xcode projects exist (`Serenity.xcodeproj` is deprecated, use `Tranquiz.xcodeproj`)
2. **Android Gateway**: Supports optional Marilena worker proxy for API calls
3. **iOS Min Version**: High minimum (iOS 18.0) due to SwiftData requirements
4. **Build Logs**: `build.log` and `firebase-debug.log` present in root (should be gitignored)

---

## Further Reading

- **Android Setup**: `Tranquiz Android/SETUP_INSTRUCTIONS.md`
- **Android Features**: `Tranquiz Android/README.md`
- **iOS Architecture**: Individual Swift file documentation in `Serenity/`
- **Privacy Policy**: `privacy_policy.html`
- **Support Info**: `support.html`

---

*Last Updated*: January 27, 2026 (aligned with recent commits: Android-iOS alignment, monorepo setup)
