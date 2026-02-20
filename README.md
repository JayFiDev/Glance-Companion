# Glance Companion

An example iOS companion app for the custom Glance firmware for the X4 e-ink reader. 
It syncs your calendar events and reminders from your iPhone to the X4 over Bluetooth Low Energy (BLE).

Big thanks to the [CrossPoint project](https://github.com/crosspoint-reader/crosspoint-reader) for there work!

This project is **not affiliated with Xteink**; it's built as a community project.

## Features

![Screenshot](https://github.com/user-attachments/assets/d33cdb24-0b4c-43e3-af93-03b5da1136c5)

- **Calendar sync** — Sends upcoming events (next 7 days) from selected calendars to the X4
- **Reminders sync** — Sends incomplete reminders from selected reminder lists
- **Two-way sync** — Reads back completed reminder IDs from the X4 and marks them done in Apple Reminders

## Requirements

- iOS 26
- Xcode 26
- An Xteink X4 e-ink display running compatible ESP32 firmware

## Getting Started

1. Open `Glance Companion.xcodeproj` in Xcode
2. Build and run on a physical device (BLE is not available in the Simulator)
3. Complete the onboarding flow to grant calendar, reminders, and Bluetooth permissions
4. Install the firmware on your X4, start it and press sync
5. Connect the app and sync your data

## Architecture

The app is built with SwiftUI and uses the `@Observable` macro for state management.

| File | Purpose |
|---|---|
| `BLEManager.swift` | CoreBluetooth central — scanning, connecting, chunked data transfer |
| `CalendarManager.swift` | EventKit integration — permissions, fetching, reminder completion |
| `AppState.swift` | Onboarding and app-wide settings |
| `DemoData.swift` | Sample events and reminders for testing without a device |
| `Views/` | SwiftUI views — main screen, onboarding, settings, source selection |

## BLE Protocol

The app communicates with the X4 using a single BLE service and characteristic:

- **Service UUID:** `12345678-1234-1234-1234-123456789012`
- **Characteristic UUID:** `87654321-4321-4321-4321-210987654321`

Data is sent as JSON in 512-byte chunks. The X4 responds with completed reminder IDs as JSON on read.


