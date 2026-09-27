#!/usr/bin/env bash
# Builds the release APK inside the Docker container.
#
# The android/ folder checked into this repo is a best-effort scaffold.
# Gradle/AGP/NDK version compatibility is tightly coupled to the exact
# Flutter SDK version used to build, so on first run this script asks
# Flutter itself to (re)generate the platform folder for whatever
# Flutter version is actually installed in the image. This is
# idempotent and safe to run repeatedly: `flutter create` only fills in
# missing/outdated platform boilerplate, it never touches lib/, test/,
# integration_test/, assets/, or pubspec.yaml.
set -euo pipefail

echo "==> Fetching packages"
flutter pub get

echo "==> Ensuring the android/ platform scaffold matches this Flutter SDK"
flutter create --platforms=android --org com.example --project-name popover_pro .

echo "==> Running analyzer"
flutter analyze || true

echo "==> Running widget tests"
flutter test

echo "==> Building release APK"
flutter build apk --release

echo "==> Done. APK at build/app/outputs/flutter-apk/app-release.apk"
