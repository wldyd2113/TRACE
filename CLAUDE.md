# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TRACE is an iOS travel planning application built with Swift and UIKit. The project uses Xcode's modern project structure with Swift Package Manager for dependencies.

## Project Structure

```
TRACE/
├── TRACE/                    # Main app source code
│   ├── Model/               # Data models (KaKaoPlace)
│   ├── View/                # View controllers organized by feature
│   │   └── TravelPlan/      # Travel planning related views
│   ├── Font/                # Custom font files (온글잎 의연체.ttf)
│   ├── Realm/               # Realm database files (if any)
│   ├── Assets.xcassets/     # App icons, colors, and other assets
│   ├── Base.lproj/          # Localization files
│   ├── AppDelegate.swift    # App lifecycle management
│   ├── SceneDelegate.swift  # Scene-based app lifecycle
│   ├── ViewController.swift # Main view controller
│   ├── APIKey.swift         # API key storage (excluded from git)
│   └── Info.plist          # App configuration with custom font support
└── TRACE.xcodeproj/         # Xcode project files
```

## Dependencies

The project uses Swift Package Manager with the following dependencies:
- **RxSwift & RxCocoa**: Reactive programming
- **SnapKit**: Auto Layout DSL
- **RealmSwift**: Local database
- **Alamofire**: Networking
- **Kingfisher**: Image loading and caching

## Development Commands

### Build and Run
```bash
# Open project in Xcode
open TRACE.xcodeproj

# Build from command line (requires xcode-tools)
xcodebuild -project TRACE.xcodeproj -scheme TRACE build
```

### Testing
```bash
# Run tests from command line
xcodebuild test -project TRACE.xcodeproj -scheme TRACE -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Architecture Notes

- **MVC Pattern**: The app follows the Model-View-Controller pattern typical for iOS apps
- **Feature-based Organization**: Views are organized by feature (e.g., TravelPlan)
- **Custom Font Integration**: Uses "온글잎 의연체" font, registered in Info.plist
- **API Key Management**: APIKey.swift is gitignored for security
- **Reactive Architecture**: Prepared for reactive programming with RxSwift
- **Local Storage**: RealmSwift integration for offline data persistence

## Key Files to Understand

- `AppDelegate.swift`: App lifecycle and initialization
- `SceneDelegate.swift`: Scene management for modern iOS apps
- `Model/KaKaoPlace.swift`: Data model for places (likely integrates with Kakao API)
- `View/TravelPlan/TravelPlanMainViewController.swift`: Main travel planning interface
- `APIKey.swift`: Contains API keys (create this file when needed)

## Development Notes

- The project is set up for Korean localization (font choice suggests Korean target audience)
- Kakao integration suggests Korean map/place services
- Modern iOS development practices with Scene-based lifecycle
- Ready for reactive programming patterns with RxSwift
- Database layer prepared with Realm for offline functionality