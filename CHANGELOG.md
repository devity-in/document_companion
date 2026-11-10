# Changelog

All notable changes to Document Companion will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Android: scanning with Google's ML Kit document scanner (live edge detection, auto-capture, perspective correction, multi-page). The built-in scanner is offered as a fallback when it is unavailable.
- Built-in scanner: document corner detection and real perspective correction, implemented in Dart.
- Built-in scanner filters: Original, Enhance, Gray and B&W (replaces the "Eco" filter, which was identical to Gray).
- Scan preview: remove a single page, discard the whole scan, live page counter.
- Scanning or importing from inside a folder saves straight into that folder.
- "Save" for generated PDFs, using the system file picker.
- Settings: storage usage; dark mode is remembered between launches.
- Watching a rewarded ad now really removes banner and interstitial ads for 24 hours.
- Unit tests for image processing, storage, database migration and PDF merge/split.

### Changed
- Upgraded to Flutter 3.47 / Dart 3.13 and the latest major versions of all dependencies (camera 0.12, google_mobile_ads 9, file_picker 13, share_plus 13, syncfusion_flutter_pdf 35, equatable 3).
- Android build: AGP 9.1, Gradle 9.3.1, Kotlin 2.4. iOS: minimum iOS 15, UIScene lifecycle.
- Document images are stored as files with a thumbnail in the database, instead of full-size BLOBs in SQLite. Existing data is migrated automatically (database schema version 6).
- The database file is now `document_companion.db` (renamed from `test.db` on first launch).
- PDF merge and split copy pages losslessly instead of rasterising them.
- PDF compression and PDF import encode pages as JPEG instead of PNG.
- Debug builds use Google's test ad units.
- Ads are initialised in the background and no longer delay startup.

### Fixed
- Saved scans larger than about 2 MB could not be read back on Android.
- Edge detection, perspective correction and filters called a native channel that did not exist.
- Importing images did not open the preview afterwards; "Import" in an empty folder did nothing.
- Unsaved pages from an earlier session could not be discarded.
- Recent-document thumbnails were truncated image data.
- Folder cards kept showing a stale document count.
- Splitting a PDF into several parts opened one share sheet per part.
- Several unawaited database writes; a crash when renaming a folder that no longer exists.

### Removed
- Unused `permission_handler` and `file` dependencies.

### Planned
- PDF Editor and Creator
- Advanced folder tagging system
- Cloud storage integration
- OCR (Optical Character Recognition)
- Document sharing and collaboration features

## [1.0.0]

### Added
- Initial release of Document Companion
- Document scanning with camera
- Manual four-corner cropping
- Grayscale filter
- Folder creation and management
- Tag-based folder organization
- Filter folders by tags
- Convert images to PDF
- Dark mode support
- Local database storage using SQLite
- Android and iOS support
- Internationalization support

### Features
- 📸 High-quality document scanning
- 📁 Folder management with tags
- 📄 PDF conversion from images
- 🎨 Modern UI with dark mode
- 🔍 Filter and search functionality

[Unreleased]: https://github.com/devity-in/document_companion/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/devity-in/document_companion/releases/tag/v1.0.0

