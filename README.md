# AquaTrack

A simple, polished iOS water intake tracking app built with SwiftUI by **Ai2Life Technologies**.

## Features
- Set your daily water goal (default 64 oz / ~1893 ml)
- Quick-log common amounts (8 oz, 12 oz, 16 oz) or custom amount
- Visual progress ring / bar for today's intake
- List of today's water logs with timestamps
- Automatic daily reset
- Local persistence via UserDefaults
- Clean blue water-themed modern UI

## Intended App Store Price
**$0.99** (one-time purchase)

## Build and Test

Open `AquaTrack.xcodeproj`, select the AquaTrack scheme, and choose an iPhone or iPad simulator. Run the app with **Product > Run** and the regression tests with **Product > Test**. The app targets iOS and iPadOS 17 or later and builds with Xcode 27.2.

For a signed device or App Store build, choose your Apple Developer team in the app target's Signing & Capabilities tab.

## Project Structure
- `AquaTrackApp.swift` – App entry point
- `ContentView.swift` – Main user interface
- `WaterEntry.swift` – Data model
- `WaterTrackerViewModel.swift` – Business logic & persistence

## License
MIT – free to use and modify. Built for Ai2Life Technologies.

---

*Track your hydration. Stay healthy.*