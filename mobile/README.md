# NOVA PLAY — Mobile app

Flutter mini-games arcade targeting Android and iOS.

## Included in this first MVP
- Arabic-first RTL interface with Arabic, French and English language switching.
- Four playable mini-games: Tic-tac-toe, Memory Match, Quick Tap and Quiz.
- Local best-score persistence using SharedPreferences.
- Responsive dark arcade UI.

## Run locally
1. Install Flutter stable and Android Studio (Android) or Xcode (iOS).
2. From this directory run:
   `flutter pub get`
   `flutter run`

If platform folders are absent, generate them once:
`flutter create . --platforms android,ios`

## Android release
`flutter build apk --release`
`flutter build appbundle --release`

## iOS release
On macOS with Xcode:
`flutter build ios --release`
App Store distribution additionally requires Apple signing certificates, provisioning and an Apple Developer account.

This repository contains source code. It does not claim that signed store binaries have already been produced.
