# DueDesk on iPhone and iPad

DueDesk uses the same Flutter app and local demo data on Android and iOS. The Apple target supports **iOS 15.0 and later**, iPhone and iPad. It includes the current compact glass interface, adaptive navigation, documents, pins and templates.

## Requirements

- A Mac with Xcode and an installed iOS simulator runtime.
- Flutter **3.47.6 stable** (Dart 3.13.5), matching `pubspec.lock`.
- Internet access during the first build to download Flutter engine artifacts, Swift packages and the PDFium XCFramework.
- An Apple ID/development team only for physical-device signing; simulator builds need no Apple account.

All native dependencies use **Swift Package Manager**, enabled in `pubspec.yaml`. CocoaPods is not required for the current dependency set. The generated package under `ios/Flutter/ephemeral/` must not be committed. Run Flutter once before opening the Xcode workspace so generated configuration and packages exist.

## Run on a simulator

```bash
git clone https://github.com/phravins/APP.git
cd APP
flutter pub get
open -a Simulator
flutter devices
flutter run -d <simulator-id> --dart-define=APP_ENV=demo
```

Choose **Continue in demo mode**. All demo records and evidence stay in the app's sandbox. To create a simulator build without launching:

```bash
flutter build ios --simulator --debug --dart-define=APP_ENV=demo
```

The output is `build/ios/iphonesimulator/Runner.app`. A simulator `.app` is not an iPhone-installable IPA.

## Run on your iPhone

1. Connect your iPhone to the Mac, trust the computer, and enable Developer Mode on the phone if requested.
2. Run `flutter pub get` and `flutter build ios --config-only --no-codesign`.
3. Open `ios/Runner.xcworkspace` in Xcode.
4. Select **Runner → Signing & Capabilities**, choose your Apple development team and leave **Automatically manage signing** enabled. Use a bundle identifier available to your team; the default is `app.duedesk.duedesk`.
5. Select the connected iPhone and press Run in Xcode, or run:

```bash
flutter run -d <iphone-id> --dart-define=APP_ENV=demo
```

The project includes app-scoped Keychain entitlements for secure authentication storage. Do not remove these when configuring signing. Photo-library access is requested for profile/company images; supporting files are selected and exported with the system document picker. No camera or microphone permission is requested by DueDesk's current flows.

## TestFlight / App Store

An Apple Developer Program membership, App Store Connect app record, registered bundle identifier and distribution signing are required. After signing is configured:

```bash
flutter build ipa --release --dart-define=APP_ENV=demo
```

For the connected production service instead:

```bash
flutter build ipa --release \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://your-api.example.com/api/v1
```

Upload the signed archive through Xcode Organizer or Transporter. Set the app's actual privacy disclosures, policy URLs and production notification services before public distribution. No certificates, provisioning profiles or Apple credentials are stored in this repository.

## Automated Apple checks

The [iOS build and simulator workflow](https://github.com/phravins/APP/actions/workflows/ios.yml) uses a macOS runner. It runs analysis/unit/widget tests, compiles an unsigned release binary for iPhone, builds a simulator app, and executes `integration_test/ios_smoke_test.dart` on an iPhone simulator.

The integration check uses real plugins for Keychain write/read/delete, PDFium page rendering, persisted demo login, and navigation through Due, Calendar, Documents and More. Run it only on a dedicated simulator:

```bash
flutter test integration_test/ios_smoke_test.dart -d <simulator-id>
```

On a successful workflow, download the `DueDesk-iOS-Simulator` artifact. Unzip it and install on a compatible simulator:

```bash
xcrun simctl install booted Runner.app
xcrun simctl launch booted app.duedesk.duedesk
```

Check the workflow's result for the exact commit; a checked-in workflow is not proof of a successful Apple build. Physical-device signing and native photo/file picker interactions require an actual iPhone test.

## Deep links

With the simulator app installed:

```bash
xcrun simctl openurl booted 'duedesk://due/gst'
```

This opens the demo GST obligation, preserving authentication guards. Universal links require production domain association and are not enabled by the custom scheme alone.
