# Local built-in Kotlin support

Based on the published `android_id` 0.5.2+1 package:
https://pub.dev/packages/android_id/versions/0.5.2+1
Upstream: https://github.com/fluttercommunity/android_id

The upstream MIT license is retained in `LICENSE`.

## Changes

- Removed the conditional legacy Kotlin Gradle Plugin application from
  `android/build.gradle`. This app requires AGP 9 and built-in Kotlin, so the
  fallback is unnecessary. Flutter 3.47 scans Gradle files with a regular
  expression and warns even when this fallback is never executed.
- Updated the minimum SDK requirements to Flutter 3.44 / Dart 3.12.
- Kept the Dart API, Android identifier implementation and upstream tests unchanged.
- Omitted the upstream example app.

To return to the published package, replace the path dependency in the app's
`pubspec.yaml` with a version whose Gradle configuration no longer triggers
Flutter's legacy KGP warning (or use a Flutter version with corrected detection).
Run `flutter pub get`, build the Android app, and verify Android ID retrieval
before removing this directory.
