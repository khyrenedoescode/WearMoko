# WearMoko

**WearMoko: A Real-Time Monitoring Application and Emergency Assistance Tool**

WearMoko is a Flutter mobile application built for an IoT-based wearable safety device. It pairs with a wearable sling unit (Raspberry Pi Zero 2 W + ESP32, GPS module, camera module, and a push alert button) to let authorized users track the wearer's real-time location, view recorded video, and receive instant emergency alerts.

A capstone project developed at Holy Cross of Davao College — College of Engineering and Technology, BS Information Technology (2026).

---

## Tech Stack

- **Flutter** `^3.5.3` — cross-platform app framework
- **Firebase** — backend (auth, database, storage, cloud functions)
- **Node.js** — Firebase Cloud Functions runtime

## System Requirements

| Requirement | Minimum |
|---|---|
| OS | Windows 10+ \| macOS 10.15+ \| Linux |
| RAM | 8 GB (16 GB recommended) |
| Free Storage | 20 GB+ |
| Internet | Required (Firebase, packages, dependencies) |

## Prerequisites

Install these before setup:

1. **[Flutter SDK](https://flutter.dev/docs/get-started/install)** (v3.5.3+) — Dart SDK is bundled, no separate install needed
2. **[Git](https://git-scm.com/)**
3. **Code Editor** — [VS Code](https://code.visualstudio.com/) (recommended, with Flutter/Dart/Firebase extensions) or [Android Studio](https://developer.android.com/studio)
4. **Android tools** (for Android builds) — Android Studio with Android SDK 21+, JDK 11+, and a physical device or emulator
5. **iOS tools** (macOS only) — Xcode 12+, CocoaPods
6. **[Node.js](https://nodejs.org/)** (LTS) — for Firebase backend functions

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/khyrenedoescode/WearMoko.git
cd wearmokoapp
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

- Create/select a project at the [Firebase Console](https://console.firebase.google.com/)
- Add an Android app using package name `com.example.wearmokoapp`
- Download `google-services.json` and place it in `android/app/`
- Repeat for iOS if needed, using the same bundle ID

### 4. Set up environment variables

Create/edit the `.env` file in the project root:

```
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_bucket.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
```

> ⚠️ Never commit or share your `.env` file. Make sure it's listed in `.gitignore`.

### 5. Verify your setup

```bash
flutter doctor
```

Resolve any ✗ or ! before proceeding.

## Running the App

**Android emulator**
```bash
flutter emulators --launch Pixel_4_API_30
flutter run
```

**Physical Android device** — enable Developer Mode + USB Debugging, connect via USB, then:
```bash
flutter run
```

**iOS Simulator** (macOS only)
```bash
open -a Simulator
flutter run
```

**Debug mode with detailed logs**
```bash
flutter run -v
```

## Building for Release

| Target | Command | Output |
|---|---|---|
| Android APK | `flutter build apk --release` | `build/app/outputs/flutter-apk/app-release.apk` |
| Android App Bundle | `flutter build appbundle --release` | `build/app/outputs/bundle/release/app-release.aab` |
| Windows | `flutter build windows --release` | `build/windows/runner/Release/` |
| Web | `flutter build web --release` | `build/web/` |

> Windows builds require Visual Studio 2022 with the "Desktop development with C++" workload.

## Firebase Backend

**Local emulator (optional, for testing)**
```bash
npm install -g firebase-tools
firebase login
firebase emulators:start
```

**Deploy functions**
```bash
cd functions
npm install
firebase deploy --only functions
```

## App Permissions (Android)

| Permission | Purpose |
|---|---|
| Location | Real-time device/wearer tracking |
| Camera | Profile pictures and in-app photos |
| Contacts | Emergency contact sharing |
| Notifications | Real-time alerts |
| Storage | Accessing files, images, and videos |

## Troubleshooting

| Issue | Fix |
|---|---|
| `flutter` command not found | Add Flutter's `bin` folder to your PATH |
| Android SDK not found | `flutter config --android-sdk /path/to/android-sdk` |
| Gradle build fails | `flutter clean && flutter pub get && flutter build apk` |
| Missing `google-services.json` | Place it in `android/app/`, then `flutter clean` |
| Firebase init fails | Check `.env` values, confirm `google-services.json` location and active Firebase project |
| App crashes on startup | `flutter run -v`, check `adb logcat` for Android |
| Location permission denied | Enable Location/Camera/Contacts in device app settings |
| Cannot connect to Firebase | Check internet, `.env` credentials, and Firebase security rules |
| iOS build fails | `cd ios && pod repo update && pod install && cd .. && flutter clean && flutter pub get && flutter run` |

## Resources

- [Flutter Docs](https://flutter.dev/docs)
- [Firebase Flutter Setup](https://firebase.flutter.dev/)
- [Android Development](https://developer.android.com/)
- [iOS Development](https://developer.apple.com/ios/)

---

## Authors

Khyrene Mae Utanes · Alexander Grant Rebusora · Ladyly Biyo
BS Information Technology — Holy Cross of Davao College (2026)
