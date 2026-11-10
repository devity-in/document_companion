# 📄 Document Companion

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey)

A powerful Flutter application for scanning documents, organizing them into folders, and converting images to PDF with ease.

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Contributing](#-contributing) • [License](#-license)

</div>

---

## 📋 Table of Contents

- [About](#-about)
- [Features](#-features)
- [Screenshots](#-screenshots)
- [Tech Stack](#-tech-stack)
- [Installation](#-installation)
- [Usage](#-usage)
- [Project Structure](#-project-structure)
- [Development](#-development)
- [Contributing](#-contributing)
- [Design Guidelines](#-design-guidelines)
- [License](#-license)

## 🎯 About

Document Companion is an open-source document scanner and manager built with Flutter. Android is the primary platform; iOS builds but is less tested. See [CURRENT_STATUS.md](CURRENT_STATUS.md) for exactly what works today. It allows users to:

- 📸 Scan documents using device camera
- 📁 Organize documents into folders with tags
- 🔍 Filter and search documents by tags
- 📄 Convert images to PDF format
- ✏️ Edit and enhance scanned documents
- 🎨 Beautiful, modern UI with dark mode support

## ✨ Features

### Core Features

- **📸 Document Scanner**
  - Android: Google ML Kit document scanner with live edge detection, auto-capture, perspective correction and multi-page scans
  - Built-in camera scanner (iOS, and Android devices without Google Play services) with corner detection, adjustable four-corner crop and perspective correction
  - Filters: Original, Enhance, Gray, B&W
  - Import images from the gallery

- **📁 Folder Management**
  - Create custom folders for organization
  - Tag-based folder categorization
  - Filter folders by tags
  - Sort and organize documents efficiently

- **📄 PDF Conversion**
  - Convert scans and images to PDF; save, share or print
  - Merge and split PDFs without quality loss
  - Compress PDFs, import PDF pages into folders, extract text to Word

- **🎨 User Interface**
  - Modern, intuitive design
  - Dark mode support
  - Smooth animations and transitions
  - Responsive layout for all screen sizes

### Roadmap

See [DEVELOPMENT_ROADMAP.md](DEVELOPMENT_ROADMAP.md) for the full phased roadmap, including:
- Scanner improvements (edge detection, auto-capture, real-time overlay)
- OCR & text recognition
- Advanced filters & image enhancement
- Document editing & annotations
- Cloud sync & collaboration

## 📸 Screenshots

> **Note:** Screenshots coming soon. Check out the [Design Guidelines](#-design-guidelines) for UI reference.

## 🛠 Tech Stack

- **Framework:** [Flutter](https://flutter.dev/)
- **Language:** [Dart](https://dart.dev/)
- **State Management:** [BLoC](https://bloclibrary.dev/)
- **Local Database:** [SQLite](https://www.sqlite.org/) via `sqflite`
- **Camera:** [camera](https://pub.dev/packages/camera)
- **PDF Generation:** [pdf](https://pub.dev/packages/pdf), [printing](https://pub.dev/packages/printing)
- **Scanning:** [google_mlkit_document_scanner](https://pub.dev/packages/google_mlkit_document_scanner) on Android, plus a pure-Dart pipeline built on [image](https://pub.dev/packages/image)
- **PDF merge / split / text extraction:** [syncfusion_flutter_pdf](https://pub.dev/packages/syncfusion_flutter_pdf) (requires a Syncfusion community or commercial licence)
- **Ads:** [google_mobile_ads](https://pub.dev/packages/google_mobile_ads)
- **Internationalization:** [intl](https://pub.dev/packages/intl)

## 📦 Installation

### Prerequisites

- Flutter SDK 3.47 or higher (Dart 3.13 or higher)
- JDK 17
- Android Studio / Xcode (for mobile development)
- Git

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/devity-in/document_companion.git
   cd document_companion
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android

- Minimum SDK: 24 (Android 7.0), the Flutter default
- Android Gradle Plugin 9.1, Gradle 9.3.1, Kotlin 2.4
- The ML Kit scanner needs Google Play services; without it the built-in scanner is used
- Debug builds load Google's test ad units, never the live ones

#### iOS

- Minimum iOS version: 15.0
- iOS is currently lower priority. `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` still need to be added to `ios/Runner/Info.plist` before the camera or gallery can be used

## 🚀 Usage

### Scanning Documents

1. Tap the **Create** button on the home screen
2. Select **Scan**
3. Grant camera permission if prompted
4. Hold the phone over the document; on Android it is captured automatically once the edges are found
5. Adjust the crop and pick a filter if needed, and add more pages
6. In the preview, **Save** the pages to one or more folders, or turn them into a **PDF**

Scanning from inside a folder saves the pages straight into it.

### Creating Folders

1. Tap the **Create** button
2. Select **Folder**
3. Enter a folder name and tap **Create**
4. Add tags from the folder's menu if you want to filter by them later

### Converting to PDF

1. Open a folder
2. Long-press to select the documents you want to convert
3. Tap the **PDF** icon
4. Save, share or print the PDF

## 📁 Project Structure

```
lib/
├── config/              # App configuration
│   ├── custom_colors.dart
│   ├── custom_key.dart
│   ├── custom_theme.dart
│   └── route_generator.dart
├── generated/          # Generated files (l10n)
│   └── intl/
├── l10n/               # Localization files
│   └── intl_en.arb
├── local_database/      # Storage layer
│   ├── document_file_store.dart   # Image files + thumbnails
│   ├── document_repository.dart   # Creates documents (file + row)
│   ├── handler/        # SQLite table handlers
│   └── models/         # Database models
├── main.dart           # App entry point
├── modules/            # Feature modules
│   ├── home/           # Home screen
│   │   ├── bloc/       # Business logic
│   │   ├── models/     # View models
│   │   ├── services/   # PDF, import, ads, batch operations
│   │   ├── view/       # Screens
│   │   └── widgets/    # Shared widgets
│   ├── scan/           # Scan entry point (picks ML Kit or built-in scanner)
│   ├── settings/       # Settings screen
│   └── scanner/        # Built-in document scanner
│       ├── bloc/       # Scanner BLoCs
│       ├── models/     # Scanner models
│       ├── ui/         # Scanner UI
│       └── utils/      # Corner detection, perspective warp, filters
└── utils/              # Utility functions
    ├── constants/
    └── models/
```

## 💻 Development

### Running Tests

```bash
flutter test
```

### Code Analysis

```bash
flutter analyze
```

### Building for Production

#### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

Release builds are currently signed with the debug key; configure your own signing in `android/app/build.gradle.kts` before publishing.

### Code Style

This project follows the [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide. Run the formatter:

```bash
dart format .
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Quick Start for Contributors

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Commit your changes (`git commit -m 'Add some amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

### Reporting Issues

Found a bug? Have a feature request? Please [open an issue](https://github.com/devity-in/document_companion/issues) with:
- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Screenshots (if applicable)
- Device/OS information

## 🎨 Design Guidelines

The app design follows the guidelines available at:
[Adobe XD Design](https://xd.adobe.com/view/391c110a-5b76-4bc5-bd93-438ad9b5706b-6c4f/)

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- All contributors and open-source packages used
- Design inspiration from the community

## 📞 Contact & Support

- **Issues:** [GitHub Issues](https://github.com/devity-in/document_companion/issues)
- **Discussions:** [GitHub Discussions](https://github.com/devity-in/document_companion/discussions)

---

<div align="center">

Made with ❤️ using Flutter

⭐ Star this repo if you find it helpful!

</div>
