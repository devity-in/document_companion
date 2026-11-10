# Current Status

> See [DEVELOPMENT_ROADMAP.md](DEVELOPMENT_ROADMAP.md) for the full roadmap.

Built and tested with **Flutter 3.47.7 / Dart 3.13.5**. Android is the primary target; iOS builds but is currently lower priority and less tested.

## Features

| Feature | Status | Notes |
|---------|--------|-------|
| Scanning (Android) | Working | Google ML Kit document scanner: live edge detection, auto-capture, perspective correction, multi-page, gallery import. Needs Google Play services |
| Scanning (built-in) | Working | Camera → crop → filter flow. Used on iOS and as a fallback on Android when the ML Kit scanner is unavailable |
| Edge detection (built-in) | Working, basic | Pure Dart. Finds a bright page on a darker background; otherwise starts with a full-frame crop to adjust by hand |
| Perspective correction (built-in) | Working | Pure Dart projective warp of the four crop corners |
| Image filters (built-in) | Working | Original, Enhance (even lighting, white paper), Gray, B&W |
| Folder management | Working | Create, rename, delete, tags, search, sort, date filters |
| Document management | Working | Save to folders, grid/list view, viewer with zoom/pan, rename, move, share |
| Import images | Working | From gallery into the preview, or straight into a folder |
| PDF — create from images | Working | Multi-page; save anywhere via the system picker, share or print |
| PDF — merge / split | Working | Lossless (pages are copied, text stays selectable). Falls back to rasterising if a file cannot be parsed |
| PDF — compress | Working | Re-renders pages as JPEG at Low/Medium/High quality |
| PDF — import to folder | Working | Each page becomes a document |
| PDF — to Word | Working | Text extraction + .docx generation (text only, no layout) |
| Batch operations | Working | Multi-select, batch delete/move/convert |
| Recent documents | Working | With real thumbnails |
| Dark mode | Working | Remembered between launches |
| Ads | Working | Banner, interstitial, rewarded. Debug builds use Google's test ad units. Watching a rewarded ad removes ads for 24 hours |
| OCR | **Not implemented** | Shown as "coming soon" in the app |
| Annotations, signatures, backup | **Not implemented** | Shown as "coming soon" in the app |

## Storage

Document images are stored as files under the app's documents directory (`documents/`, with unsaved scans in `pending/`). SQLite (`document_companion.db`, schema version 6) holds metadata and a small thumbnail per document. Databases from earlier builds, which stored images as BLOBs in `test.db`, are migrated on first launch.

## Tests

`flutter test` covers image processing (corner detection, perspective warp, filters), storage and the version 5 → 6 migration, and PDF merge/split. There are no widget or BLoC tests yet.

## What has been verified on a device

On an Android emulator (debug build): startup, folder creation, the built-in scanner (capture, crop, straighten, filter, save), folder and document views, recent documents, the ML Kit fallback path, PDF picking and split.

Not yet verified on a device:

- The ML Kit scanner itself — its Play services module would not load on the emulator used. It needs a run on a real phone.
- Gallery import, PDF compress / import / merge / PDF-to-Word, and the rewarded-ad flow.
- A release build (code shrinking with the new dependencies).
- Anything on iOS beyond compiling (see below).

## Known gaps before a store release

- **iOS**: `Info.plist` has no camera or photo-library usage descriptions, so the app will crash when the camera opens. No privacy manifest.
- **Android release signing**: release builds are still signed with the debug key.
- **Ads compliance**: no consent flow (UMP / ATT) yet.
- **Privacy policy**: none.
- **Syncfusion licence**: `syncfusion_flutter_pdf` (merge, split, text extraction) requires a Syncfusion community or commercial licence.
- Custom stream-based BLoCs in `modules/home` are global singletons and are never disposed.
- Most UI strings are hardcoded rather than localised.
- No CI for `flutter analyze` / `flutter test`.

---

*Last updated: 2026-11-10*
