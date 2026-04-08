# QR Scanner App - University of Dar es Salaam

A modern, feature-rich QR code scanner and generator app built with Flutter, designed with UDSM's official branding and colors.

## ✨ Features

### Interactive QR Data Handling
The app automatically detects different types of QR code content and provides interactive functionality:

- **🔗 Website Links**: Automatically detects HTTP/HTTPS URLs and opens them in your default browser
- **📧 Email Addresses**: Recognizes email addresses and opens your email app to compose a message
- **📞 Phone Numbers**: Detects phone numbers and opens your phone app to make a call
- **🖼️ Image URLs**: Identifies image URLs and displays a preview of the image inline
- **📍 Coordinates**: Recognizes latitude/longitude coordinates and opens them in your maps app
- **📶 WiFi Configurations**: Handles WiFi QR codes for easy network connection
- **📝 Plain Text**: Displays regular text with proper formatting

### QR Code Generation
- **Custom QR Codes**: Generate QR codes from any text, URL, or data
- **Save & Share**: Export generated QR codes as images

### Screenshot / Capture
- **Take Shot**: Capture and save QR scan results as screenshots


### Smart Features
- **Scan History**: Keep track of all your scanned QR codes with timestamps and locations
- **Location Services**: Automatically records where each QR code was scanned
- **Search & Filter**: Easily find previous scans in your history
- **Offline Support**: Works without internet connection for basic QR scanning
- **Persistent Preferences**: Remembers your settings across sessions


## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK (3.8.1 or higher)
- Android Studio / VS Code
- Android SDK (API level 21+) for Android development
- Xcode for iOS development (macOS only)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/isaka-12/qrscan_app.git
cd qrscan_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## 📱 Supported Platforms

- ✅ Android (API level 21+)
- ✅ iOS (iOS 11.0+)
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 🔧 Dependencies

Key packages used in this project:

| Package | Version | Purpose |
|---|---|---|
| `mobile_scanner` | ^5.0.0 | QR code scanning |
| `provider` | ^6.1.5+1 | State management |
| `sqflite` | ^2.4.1 | Local database storage |
| `geolocator` | ^14.0.2 | Location services |
| `geocoding` | ^4.0.0 | Address resolution |
| `url_launcher` | ^6.3.0 | External app launching |
| `cached_network_image` | ^3.4.1 | Image caching and display |
| `shared_preferences` | ^2.5.3 | Persistent key-value storage |
| `http` | ^1.5.0 | Network requests |
| `path` | ^1.9.0 | File path utilities |

## 🏗️ Architecture

The app follows Clean Architecture principles:

```
lib/
├── core/                   # Core utilities and shared infrastructure
│   ├── database/           # SQLite database helper (sqflite)
│   ├── errors/             # Error handling
│   ├── network/            # Network utilities
│   ├── providers/          # Global providers (theme, etc.)
│   ├── theme/              # UDSM theme system
│   └── utils/              # Shared utilities
├── features/               # Feature modules (Clean Architecture)
│   ├── qrscan/             # QR scanning feature
│   │   ├── data/           # Data layer (repositories, models)
│   │   ├── domain/         # Domain layer (entities, use cases)
│   │   └── presentation/   # UI layer (pages, widgets, providers)
│   ├── qr_generate/        # QR code generation feature
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── take_shot/          # Screenshot capture feature
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── splash/             # Splash / onboarding screen
└── main.dart               # App entry point
```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
