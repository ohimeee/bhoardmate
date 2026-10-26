# BhoardMate

A Flutter app that helps boarding house owners and boarders track rent, split electricity bills, and share announcements and concerns in one place. A way to converge technology into our business owners' workflow for convenience, efficiency and transparency.

## Members
- Bryan Kenth F. Estoesta ([@BryWick](https://github.com/BryWick))
- Johnmarc B. Jayme ([@ohimeee](https://github.com/ohimeee))

## Android APK builds

Use Flutter 3.44.x, the Android SDK and the project's configured Firebase app. The builds below were checked with Flutter 3.44.9 and Dart 3.12.2. Run these commands from the repository root:

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
```

The formatting command checks without changing files. If it reports changes, run `dart format lib test`, review the changes and repeat the checks.

| Build | Output | Purpose |
| --- | --- | --- |
| Debug | `build/app/outputs/flutter-apk/app-debug.apk` | Development build with debugging support; Flutter run supports hot reload. |
| Release | `build/app/outputs/flutter-apk/app-release.apk` | Optimized build for installation and the course submission; no hot reload or debugger support. |

Both builds hide Flutter's DEBUG banner because `debugShowCheckedModeBanner` is false. Banner visibility does not identify the build mode. Release compilation optimizes Dart code and removes unused icons; startup and runtime speed must be measured on a device rather than inferred from APK size.

Install either APK on the required Medium Phone API 36.1 emulator (Google Play x86_64, 1080 × 2400, portrait, light mode, default font/display sizes, English):

```powershell
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-release.apk
```

Install one build at a time. Both use `com.bj.bhoardmate`, so the second replaces the first. `-r` retains app data when the signing certificates match. The current Gradle release configuration uses the debug signing key; this is a release-mode APK, not a separately signed production release.

Before submission, check startup, owner and boarder login, navigation, permitted CRUD actions, profile permissions, live Firebase updates, holiday loading/offline states and validation on the emulator. Use the real demo accounts supplied by Johnmarc. Upload the verified release APK to Canvas; APKs are generated under the ignored `build/` directory and are not committed to Git.

### Build verification — October 26, 2026

- Source: merged app code from main commit `89315cf`, on `feature/docs` after merging main.
- Formatting: 55 Dart files checked, zero changes required.
- Analyzer: zero issues.
- Tests: all 82 existing automated tests passed. These do not establish a complete live Firebase walkthrough.
- Debug APK: built successfully; 184,067,396 bytes (175.54 MiB).
- Release APK: built successfully; 55,462,731 bytes (52.89 MiB), 69.9% smaller than debug. Both are universal APKs from the commands above.
- APK inspection: application ID `com.bj.bhoardmate`, label `BHoardMate`, version `1.0.0` (code 1), minimum API 24 and target API 36. The release manifest includes internet permission and the installed release is not debuggable. Both APK signatures verify and use the same Android Debug certificate.
- Emulator: Medium Phone, API 36.1, Google Play x86_64, 1080 × 2400; light mode and default density/font scale verified.
- Debug installation: blocked by `INSTALL_FAILED_INSUFFICIENT_STORAGE`. Android cache trimming did not free enough space; the newly built debug APK has not been launch-tested.
- Release installation: succeeded with `adb install -r`; cold launch succeeded and restored the existing boarder session. Home, Pay, News (including holidays) and Me opened successfully. No Flutter error or fatal exception appeared in the inspected logcat window. This was a startup/navigation check, not a full owner/boarder CRUD, offline or cross-device synchronization test.
- Evidence: [release boarder Home screenshot](docs/screenshots/release/2026-10-26_release-boarder-home.png), captured directly from the emulator in portrait at 1080 × 2400.
- Submission: Canvas upload and the full owner/boarder walkthrough remain pending. No runtime speed comparison was measured.

SHA-256 checksums for these APKs:

```text
app-debug.apk   6999df1bbbc75b507beec52ad1ca5008b65b9e8c36062a4d6667b97b0512d4f6
app-release.apk f0a20982964094f8a394e5d7d1c1aeb511cf1aa6170a72b373e7111d1589406c
```
