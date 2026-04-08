# QR Scanner App - University of Dar es Salaam

A modern, feature-rich QR code scanner app built with Flutter, designed with UDSM's official branding and colors.

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

### Modern UI Design
- **UDSM Branding**: Official University of Dar es Salaam colors and styling
- **Material 3 Design**: Modern, clean interface following Google's latest design principles
- **Dark/Light Theme**: Automatic theme switching based on system preferences
- **Responsive Layout**: Optimized for different screen sizes

### Smart Features
- **Scan History**: Keep track of all your scanned QR codes with timestamps and locations
- **Location Services**: Automatically records where each QR code was scanned
- **Search & Filter**: Easily find previous scans in your history
- **Offline Support**: Works without internet connection for basic QR scanning

## 🎨 UDSM Theme Colors

The app uses the official University of Dar es Salaam color palette:

- **Primary Blue**: #1E3A8A (UDSM Blue)
- **Accent Gold**: #F59E0B (UDSM Gold)
- **Success Green**: #059669
- **Error Red**: #DC2626
- **Warning Orange**: #D97706

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Android Studio / VS Code
- Android SDK for Android development
- Xcode for iOS development (macOS only)

### Installation

1. Clone the repository:
```bash
git clone <repository_url>
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

- `mobile_scanner`: QR code scanning functionality
- `provider`: State management
- `sqflite`: Local database storage
- `geolocator`: Location services
- `geocoding`: Address resolution
- `url_launcher`: External app launching
- `cached_network_image`: Image caching and display

## 🏗️ Architecture

The app follows Clean Architecture principles:

```
lib/
├── core/           # Core utilities and themes
│   ├── database/   # Database configurations
│   ├── theme/      # UDSM theme system
│   └── utils/      # Utility functions
├── features/       # Feature modules
│   ├── qrscan/     # QR scanning feature
│   └── splash/     # Splash screen
└── main.dart       # App entry point
```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🎓 About UDSM

The University of Dar es Salaam (UDSM) is Tanzania's premier institution of higher learning, established in 1970. This app reflects the university's commitment to innovation and technology in education.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
