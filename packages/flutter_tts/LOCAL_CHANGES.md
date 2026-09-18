# Local Swift Package Manager support

Based on the published `flutter_tts` 4.2.5 package:
https://pub.dev/packages/flutter_tts/versions/4.2.5
Upstream: https://github.com/dlutton/flutter_tts

The upstream MIT license is retained in `LICENSE`.

## Changes

- Added `ios/flutter_tts/Package.swift` and moved the iOS Swift sources into
  `ios/flutter_tts/Sources/flutter_tts`.
- Renamed `SwiftFlutterTtsPlugin` to `FlutterTtsPlugin` and exposed that class to
  Objective-C directly, preserving Flutter's registered plugin name without the
  old Objective-C forwarding wrapper. SwiftPM cannot mix Swift and Objective-C
  sources in one target.
- Omitted the iOS podspec and Objective-C wrapper, which are no longer needed.
- Kept the upstream Dart API and other platform implementations unchanged.
- Migrated the Android build to AGP 9.0.1 and built-in Kotlin, removing the
  explicit Kotlin plugin and standard library dependencies. Uses the
  `compilerOptions` DSL, preserving the Java/Kotlin 11 bytecode target.
- Requires Flutter 3.44 / Dart 3.12 or later for the migrated plugin build;
  the host app requires Flutter 3.47 with built-in Kotlin enabled.
- Omitted the upstream example app from this vendored copy.

This local copy can be removed when a published upstream version supports SPM
on iOS. Replace the path dependency in the root `pubspec.yaml`, run
`flutter pub get`, and verify an iOS build before deleting this directory.
