# Development Roadmap

> **Document Companion** — Open-source document scanner & manager built with Flutter.
> MIT Licensed. Contributions welcome.

---

## Current State

See [CURRENT_STATUS.md](CURRENT_STATUS.md) for the up-to-date list of what works, what has been verified on a device and what is still missing before a store release.

In short: scanning, folders, document management and the PDF tools work on Android (Flutter 3.47). Phase 0 is mostly done and Phase 1 is done. iOS is lower priority for now. OCR, annotations, signatures and backup are not implemented.

---

## Roadmap

### Phase 0 — Bug Fixes & Technical Debt

> Fix what's broken before building new things.
> **Estimated effort:** 2-3 weeks
> **Labels:** `phase-0`, `bug`, `good-first-issue`, `technical-debt`

| # | Task | Difficulty | Labels |
|---|------|-----------|--------|
| 0.1 | ✅ **Fix `deleteCurrentImage()` missing WHERE clause** — Can delete all rows instead of one — *the table is session-only; clearing it is intended and now awaited, and single pages can be removed* | Easy | `bug`, `critical`, `good-first-issue` |
| 0.2 | ✅ **Fix `bool.fromEnvironment` misuse** in `CurrentImageDatabaseHandler` — Should be `== 'true'` string comparison — *column removed in schema version 6* | Easy | `bug`, `good-first-issue` |
| 0.3 | ✅ **Add missing `await`** on `FolderTableHandler.insertFolder` | Easy | `bug`, `good-first-issue` |
| 0.4 | ✅ **Fix `FolderBloc.updateFolder`** — `firstWhere` without `orElse` throws if folder not found | Easy | `bug`, `good-first-issue` |
| 0.5 | **Dispose StreamControllers** in all custom BLoCs (`FolderBloc`, `ImageBloc`, `TagBloc`, `RecentDocumentsBloc`, `CurrentImageBloc`) | Easy | `bug`, `memory-leak` |
| 0.6 | ✅ **Rename database** from `"test.db"` to `"document_companion.db"` with migration | Easy | `technical-debt`, `good-first-issue` |
| 0.7 | ✅ **Fix "Eco" filter** — Currently identical to "Gray". Implement actual eco filter (e.g., reduced contrast grayscale or light threshold) — *replaced by Enhance and B&W filters* | Easy | `bug`, `scanner` |
| 0.8 | **Add `FolderModel.fromMap`** factory constructor — `toMap` exists but no deserialization | Easy | `technical-debt`, `good-first-issue` |
| 0.9 | **Extract duplicate `_parseColor`** into shared `ColorUtils` — Duplicated in 4+ widgets | Easy | `technical-debt`, `good-first-issue` |
| 0.10 | ✅ **Fix `SaveImageBloc` force-unwrap** — `CustomKey.navigatorKey.currentContext!` can crash | Medium | `bug` |
| 0.11 | ✅ **Remove hardcoded ad unit IDs** — Move to a config/constants file, use test IDs in debug builds — *debug builds use test ad units* | Medium | `technical-debt`, `ads` |
| 0.12 | ✅ **Replace placeholder widget test** with actual tests for at least `FolderBloc` and `ImageBloc` — *tests cover image processing, storage, migration and PDF tools; BLoC tests still missing* | Medium | `testing` |
| 0.13 | **Unify state management** — Migrate custom stream-based BLoCs to `flutter_bloc` pattern (matching scanner module) or document why both exist | Hard | `technical-debt`, `architecture` |

**Exit criteria:** All critical bugs fixed, no data-loss risks, StreamControllers properly disposed.

---

### Phase 1 — Scanner Foundation

> Make edge detection and perspective correction actually work.
> **Estimated effort:** 2-4 weeks
> **Labels:** `phase-1`, `scanner`, `enhancement`
> **Depends on:** Phase 0

This is the most impactful phase. The app's core promise (document scanning) currently doesn't deliver on edge detection or perspective correction.

#### Option A: Google ML Kit Document Scanner (Recommended)

The fastest path. Google's Document Scanner API handles edge detection, perspective correction, and image enhancement out of the box.

| # | Task | Difficulty | Labels |
|---|------|-----------|--------|
| 1.1 | ✅ **Evaluate `google_mlkit_document_scanner`** — Test on Android (API 21+) and iOS, document limitations | Medium | `research`, `scanner` |
| 1.2 | ✅ **Integrate ML Kit Document Scanner** — Add dependency, implement native setup for both platforms | Medium | `scanner`, `feature` |
| 1.3 | ✅ **Connect ML Kit output to existing crop/edit flow** — Feed detected corners into `CropBloc`, feed corrected image into `EditBloc` — *ML Kit results go to the preview/save flow; the built-in crop/edit flow is the fallback* | Medium | `scanner` |
| 1.4 | ✅ **Remove or gate broken MethodChannel calls** — Clean up `findContourPhoto`, `adjustingPerspective` native calls that do nothing | Easy | `scanner`, `cleanup` |
| 1.5 | **Test scanner end-to-end** — Verify: capture → detect edges → crop → perspective correct → filter → save | Medium | `scanner`, `testing` |

#### Option B: OpenCV via FFI (More control, more effort)

If ML Kit is too opinionated or doesn't support a target platform.

| # | Task | Difficulty | Labels |
|---|------|-----------|--------|
| 1.1b | **Add `opencv_dart` or implement native OpenCV** on Android (Kotlin) and iOS (Swift) | Hard | `scanner`, `native` |
| 1.2b | ✅ **Implement `findContourPhoto`** natively — Canny edge detection → find contours → approximate polygon → return 4 corners — *done in pure Dart instead of OpenCV* | Hard | `scanner`, `native` |
| 1.3b | ✅ **Implement `adjustingPerspective`** natively — `getPerspectiveTransform` + `warpPerspective` — *done in pure Dart instead of OpenCV* | Hard | `scanner`, `native` |
| 1.4b | ✅ **Implement `applyFilter`** natively — Adaptive threshold, color enhancement, sharpen — *done in pure Dart instead of OpenCV* | Medium | `scanner`, `native` |
| 1.5b | **Test on both platforms** | Medium | `scanner`, `testing` |

**Exit criteria:** Taking a photo of a document on a table produces a properly cropped, perspective-corrected rectangular image.

**Status:** Done with a hybrid of both options — ML Kit on Android, and a pure-Dart corner detector and perspective warp in the built-in scanner (iOS and fallback). Still open: 1.5 end-to-end testing of the ML Kit scanner on a real device.

---

### Phase 2 — Modern Scanner UX

> Real-time edge detection overlay and auto-capture — the features that differentiate a good scanner from a great one.
> **Estimated effort:** 4-6 weeks
> **Labels:** `phase-2`, `scanner`, `enhancement`
> **Depends on:** Phase 1

| # | Task | Difficulty | Labels |
|---|------|-----------|--------|
| 2.1 | **Real-time camera frame processing** — Hook into `CameraController.startImageStream()`, process every Nth frame | Hard | `scanner`, `performance` |
| 2.2 | **Live contour overlay** — Draw detected document edges on camera preview using `CustomPainter`. Handle coordinate mapping between camera resolution and screen size | Hard | `scanner`, `ui` |
| 2.3 | **Contour stabilization** — Debounce/smooth the detected corners across frames to prevent jittering | Medium | `scanner` |
| 2.4 | **Auto-capture** — When contour is stable for ~1.5 seconds, auto-trigger capture. Show countdown/progress indicator. Haptic feedback on capture | Medium | `scanner`, `ux` |
| 2.5 | **Visual feedback** — Contour overlay color changes (red → yellow → green) as stability improves. Pulsing animation when ready to capture | Medium | `scanner`, `ui` |
| 2.6 | **Manual/Auto toggle** — Let users switch between manual tap and auto-capture modes | Easy | `scanner`, `ux` |
| 2.7 | **Flash improvements** — Auto-flash in low light, flash mode persistence across scans | Easy | `scanner`, `ux` |
| 2.8 | **Focus tap** — Tap-to-focus on camera preview | Easy | `scanner`, `ux` |
| 2.9 | **Grid overlay toggle** — Optional rule-of-thirds or document alignment grid | Easy | `scanner`, `ui` |

**Exit criteria:** Camera preview shows live document edges. When held steady over a document, it auto-captures, crops, and perspective-corrects without user tapping anything.

---

### Phase 3 — Advanced Filters & Image Enhancement

> Make scanned documents look professional.
> **Estimated effort:** 2-3 weeks
> **Labels:** `phase-3`, `scanner`, `enhancement`
> **Depends on:** Phase 1 (Phase 2 is nice-to-have but not required)

| # | Task | Difficulty | Labels |
|---|------|-----------|--------|
| 3.1 | **Adaptive threshold B&W** — Clean black-and-white for text documents (not just grayscale) | Medium | `scanner`, `filters` |
| 3.2 | **Auto-enhance / Magic filter** — Auto-adjust brightness, contrast, sharpness for best readability | Medium | `scanner`, `filters` |
| 3.3 | **Shadow removal** — Normalize uneven lighting across the document | Hard | `scanner`, `filters` |
| 3.4 | **Sharpen filter** — Unsharp mask for crisp text | Easy | `scanner`, `filters`, `good-first-issue` |
| 3.5 | **Color document mode** — Enhanced color with white-balance correction | Medium | `scanner`, `filters` |
| 3.6 | **Filter preview thumbnails** — Show small previews of each filter effect before applying | Medium | `scanner`, `ui` |
| 3.7 | **Brightness/Contrast sliders** — Manual adjustment controls | Medium | `scanner`, `ui` |
| 3.8 | **Image rotation** — 90-degree rotation and free rotation | Easy | `scanner`, `good-first-issue` |

**Exit criteria:** At least 5 distinct, visually different filters. Auto-enhance produces clearly better output than the raw photo for text documents.

---

### Phase 4 — Multi-Page Scanning & Workflow

> Streamline the flow for scanning multi-page documents.
> **Estimated effort:** 2-3 weeks
> **Labels:** `phase-4`, `scanner`, `ux`
> **Depends on:** Phase 1

| # | Task | Difficulty | Labels |
|---|------|-----------|--------|
| 4.1 | **Continuous scan flow** — After saving a page, auto-return to camera for next page (skip the "Done" detour) | Medium | `scanner`, `ux` |
| 4.2 | **Page thumbnail strip** — Scrollable thumbnail strip at bottom of camera screen showing all scanned pages in session | Medium | `scanner`, `ui` |
| 4.3 | **Page reordering** — Drag-and-drop to reorder pages in preview | Medium | `ux` |
| 4.4 | **Re-crop / re-edit pages** — Tap a page in preview to go back to crop or edit for that specific page | Medium | `scanner` |
| 4.5 | **Delete individual pages** from batch before saving | Easy | `ux`, `good-first-issue` |
| 4.6 | **Page count badge** — Clear indicator on camera screen showing "3 pages scanned" | Easy | `ui`, `good-first-issue` |
| 4.7 | **Batch apply filter** — Apply same filter to all pages at once | Easy | `scanner`, `ux` |

**Exit criteria:** Scanning a 10-page document is a smooth, uninterrupted flow. User can reorder, re-edit, or delete individual pages before saving.

---

### Phase 5 — OCR & Smart Features

> Extract text from documents and make them searchable.
> **Estimated effort:** 3-4 weeks
> **Labels:** `phase-5`, `ocr`, `ml`, `feature`
> **Depends on:** Phase 1

| # | Task | Difficulty | Labels |
|---|------|-----------|--------|
| 5.1 | **Integrate `google_mlkit_text_recognition`** — Add dependency, platform setup | Medium | `ocr`, `feature` |
| 5.2 | **OCR processing pipeline** — Pre-process image (enhance for OCR), run recognition, post-process text | Medium | `ocr` |
| 5.3 | **OCR results UI** — Display recognized text overlaid on or alongside the document image. Copy-to-clipboard support | Medium | `ocr`, `ui` |
| 5.4 | **Store recognized text** in SQLite — Add text column to images table, enable full-text search | Medium | `ocr`, `database` |
| 5.5 | **Searchable PDFs** — Embed OCR text layer in generated PDFs | Hard | `ocr`, `pdf` |
| 5.6 | **Multi-language support** — Let users select OCR languages, download language packs | Medium | `ocr`, `i18n` |
| 5.7 | **Smart file naming** — Suggest document names based on OCR content (first line, date found, etc.) | Medium | `ocr`, `ux` |
| 5.8 | **Text export** — Export recognized text as .txt file | Easy | `ocr`, `good-first-issue` |

**Exit criteria:** User can scan a document, extract text, copy it, search across all documents by text content, and generate searchable PDFs.

---

### Phase 6 — Document Editing

> Post-scan editing capabilities.
> **Estimated effort:** 3-4 weeks
> **Labels:** `phase-6`, `editing`, `feature`
> **Depends on:** Phase 3

| # | Task | Difficulty | Labels |
|---|------|-----------|--------|
| 6.1 | **Image rotation** (90° and free) | Easy | `editing`, `good-first-issue` |
| 6.2 | **Image flip** — Horizontal and vertical | Easy | `editing`, `good-first-issue` |
| 6.3 | **Re-crop saved documents** — Open crop UI for already-saved images | Medium | `editing` |
| 6.4 | **Annotations** — Add text overlays, arrows, shapes, highlights | Hard | `editing`, `ui` |
| 6.5 | **Signature capture** — Draw or import signature, place on document | Hard | `editing` |
| 6.6 | **Watermark** — Add text or image watermark to documents | Medium | `editing` |
| 6.7 | **Undo/Redo** — Edit history with undo/redo stack | Medium | `editing` |
| 6.8 | **PDF annotation** — Add annotations directly on PDF pages | Hard | `editing`, `pdf` |

**Exit criteria:** Users can rotate, re-crop, annotate, and sign documents after saving.

---

### Phase 7 — Backup, Security & Privacy

> Protect user data and enable backup/restore.
> **Estimated effort:** 3-4 weeks
> **Labels:** `phase-7`, `security`, `feature`
> **Depends on:** Phase 0

| # | Task | Difficulty | Labels |
|---|------|-----------|--------|
| 7.1 | **Local backup** — Export all data (DB + images) as encrypted ZIP | Medium | `backup`, `feature` |
| 7.2 | **Restore from backup** — Import and restore from backup file | Medium | `backup` |
| 7.3 | **App lock** — PIN or biometric authentication to open app | Medium | `security` |
| 7.4 | **Encrypted storage** — Encrypt sensitive documents at rest | Hard | `security` |
| 7.5 | **Secure delete** — Overwrite file data on deletion | Easy | `security`, `good-first-issue` |
| 7.6 | **Auto-backup** — Scheduled automatic local backups | Medium | `backup` |
| 7.7 | **Configure release signing** (launch blocker) — Android release build currently uses debug signing | Medium | `security`, `build` |

**Exit criteria:** Users can back up and restore their entire document library. App can be locked with biometrics.

---

### Phase 8 — Platform Polish & Quality

> Production readiness, performance, and platform-specific features.
> **Estimated effort:** 3-4 weeks (ongoing)
> **Labels:** `phase-8`, `performance`, `platform`
> **Can start anytime alongside other phases**

| # | Task | Difficulty | Labels |
|---|------|-----------|--------|
| 8.1 | **Break up large files** — `homepage.dart` (~850 lines), `folder_page.dart` (~850 lines), `pdf_service.dart` (~1250 lines) into smaller focused widgets/classes | Medium | `technical-debt`, `good-first-issue` |
| 8.2 | **Localize all hardcoded strings** — Complete l10n setup, move all UI strings to ARB files | Medium | `i18n` |
| 8.3 | **Image loading performance** — Thumbnail generation, progressive loading, memory management for large libraries | Medium | `performance` |
| 8.4 | **Onboarding flow** — First-launch tutorial showing key features | Medium | `ux` |
| 8.5 | **Empty state illustrations** — Custom graphics for empty folders, no search results, etc. | Easy | `ui`, `design`, `good-first-issue` |
| 8.6 | **Accessibility** — Screen reader support, semantic labels, contrast ratios | Medium | `a11y` |
| 8.7 | **Android widget** — Home screen widget for quick scan | Hard | `platform`, `android` |
| 8.8 | **iOS Share Extension** — Receive shared images/PDFs from other apps | Hard | `platform`, `ios` |
| 8.9 | **Keyboard shortcuts** — For desktop platforms | Easy | `platform`, `desktop`, `good-first-issue` |
| 8.10 | **Unit & widget test coverage** — Target 60%+ coverage for BLoCs and services | Hard | `testing` |
| 8.11 | **CI pipeline** — GitHub Actions for `flutter analyze`, `flutter test`, build checks on PRs | Medium | `ci`, `infrastructure` |

---

### Phase 9 — Cloud & Collaboration (Future)

> Cloud sync and multi-device support. Significant infrastructure effort.
> **Estimated effort:** 6-8 weeks
> **Labels:** `phase-9`, `cloud`, `feature`
> **Depends on:** Phase 7

| # | Task | Difficulty | Labels |
|---|------|-----------|--------|
| 9.1 | **Cloud storage backend** — Firebase Storage or similar for document sync | Hard | `cloud`, `infrastructure` |
| 9.2 | **User authentication** — Sign in with Google/Apple for cloud features | Hard | `cloud`, `auth` |
| 9.3 | **Cross-device sync** — Sync folders, documents, and metadata across devices | Hard | `cloud`, `sync` |
| 9.4 | **Shared folders** — Share folders with other users via link or email | Hard | `cloud`, `collaboration` |
| 9.5 | **QR code sharing** — Generate QR code to share document/folder links | Medium | `sharing` |
| 9.6 | **Version history** — Track document edit history with cloud storage | Hard | `cloud` |

---

### Phase 10 — AI & Intelligence (Future)

> ML-powered features for automatic organization and insights.
> **Estimated effort:** 4-6 weeks
> **Labels:** `phase-10`, `ml`, `feature`
> **Depends on:** Phase 5

| # | Task | Difficulty | Labels |
|---|------|-----------|--------|
| 10.1 | **Document type detection** — Auto-classify as receipt, ID, letter, invoice, etc. | Hard | `ml` |
| 10.2 | **Auto-categorization** — Suggest folders based on document content | Hard | `ml` |
| 10.3 | **Receipt data extraction** — Parse total, date, vendor from receipts | Hard | `ml` |
| 10.4 | **Business card scanning** — Extract name, phone, email, company | Hard | `ml` |
| 10.5 | **Duplicate detection** — Flag similar/duplicate documents | Medium | `ml` |
| 10.6 | **Document summarization** — AI-generated summary of long documents | Hard | `ml` |

---

## For Contributors

### Getting started

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup instructions.

### Picking work

1. Look at the **current phase** being worked on (check issue milestones)
2. Filter issues by `good-first-issue` for easy entry points
3. Comment on an issue to claim it before starting work
4. One issue per contributor at a time to avoid conflicts

### Issue labels

| Label | Meaning |
|-------|---------|
| `good-first-issue` | Great for new contributors |
| `bug` | Something broken |
| `critical` | Data loss or crash risk |
| `feature` | New functionality |
| `technical-debt` | Code quality improvement |
| `scanner` | Scanner module |
| `ocr` | Text recognition |
| `ui` | Visual/interface changes |
| `ux` | User experience/workflow |
| `performance` | Speed/memory improvements |
| `testing` | Tests |
| `platform` | Platform-specific (Android/iOS/Desktop) |

### Branch naming

```
feature/phase1-ml-kit-scanner
fix/phase0-delete-where-clause
refactor/phase0-unify-bloc-pattern
```

### Phase dependencies

```
Phase 0 (Bug Fixes)
  └─> Phase 1 (Scanner Foundation) ← START HERE after Phase 0
        ├─> Phase 2 (Real-time UX)
        ├─> Phase 3 (Filters) ─> Phase 6 (Editing)
        ├─> Phase 4 (Multi-page)
        └─> Phase 5 (OCR) ─> Phase 10 (AI)
  └─> Phase 7 (Backup/Security) ─> Phase 9 (Cloud)
  └─> Phase 8 (Polish) — can run in parallel anytime
```

---

*Last updated: 2026-11-10*
*Version: 1.0.0*
