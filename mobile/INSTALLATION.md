# NOVA PLAY — build and installation

## Android (test installation)
1. Open the repository's **Actions** tab.
2. Open the latest successful **Build Android APK and App Bundle** run on branch `mobile-app`.
3. In **Artifacts**, download `nova-play-android-release`.
4. Extract the ZIP and install `app-release.apk` on the Android phone. If Android asks, allow installation from the browser/file manager used to open the APK.
5. The `.aab` file is for Google Play publishing; it is not installed by tapping it.

The APK is a test/release build. Play Store publication still requires a signed upload key, Play Console account, store listing, privacy policy, and compliance review.

## iPhone
The workflow currently creates an **unsigned** iOS build. It cannot be installed on a normal iPhone as-is. Installation/TestFlight/App Store distribution requires Apple signing with a valid Apple Developer account and provisioning profile, normally through Xcode on macOS.

## Build locally
Install Flutter stable, then run:
```sh
cd mobile
flutter pub get
flutter analyze
flutter build apk --release
flutter build appbundle --release
```

## Project status
The source is in the `mobile-app` branch. The Android workflow builds both APK and AAB. A successful Actions run is required before treating either artifact as ready to install or publish.
