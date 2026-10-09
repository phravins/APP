# Verification record

Verified on 8 October 2026 in the supplied Linux cloud workspace.

Toolchain: Flutter **3.47.6 stable**, Dart **3.13.5**, JDK **21**, Android compile/target SDK **36**. Android minimum SDK: **24**. The generated iOS project targets iOS **15.0**.

| Check | Result |
| --- | --- |
| `flutter pub get` | Passed; lockfile included |
| `dart format .` | Passed; 44 Dart files formatted, no outstanding changes |
| `flutter analyze` | Passed; **no issues** |
| `flutter test --reporter expanded` | Passed; **53 tests** |
| `flutter build apk --debug` | Passed; universal debug APK generated |
| Android `apksigner verify` | Passed |
| `flutter build web` | Passed; WASM compatibility dry run also succeeded |
| Chromium browser smoke test | Passed: startup, accessible demo entry, onboarding skip, dashboard, remembered session after reload; no uncaught browser errors |
| iOS project XML/plist checks | Passed for Info.plist and Keychain entitlements |
| iOS compile/sign/device execution | Not run: this environment is Linux and has no Xcode or Apple signing identity |

## Test coverage

- Civil-date boundaries, organisation timezones, daylight-saving differences, status precedence, configurable reminder windows, and closed-history behavior.
- Weekly/monthly/quarterly/half-yearly/yearly/custom recurrence, month-end and leap-day handling.
- Search across all requested fields, combined filters, archive filtering, and dashboard counts.
- Create/edit/persistence, scoped membership access, denied direct repository operations, profile privilege preservation, member completion, and organisation-scoped deactivation.
- Atomic completion and successor creation, concurrent duplicate-completion protection, archived evidence retention, notes, invitations, category deactivation, and notification read state.
- Upload validation, replacement/removal counts, immutable completed evidence, actual Hive close/reopen persistence for records and file bytes.
- Demo credentials and registered-account re-login, salted password verifiers, logout/remember behavior, secure session-only tokens, API bearer/refresh/replay, friendly errors, and cross-account offline cache isolation.
- Login validation, live dashboard navigation, UI completion with renewal, required form validation, full create/edit/archive UI flow, debounced search, authentication guards, company/permission switching, and theme persistence.
- All private destinations at 360 px, tablet dashboard at 1024 px, and core screens on a 360 × 640 phone with 150% text scaling.

## Interface refresh checks

The complete suite passed with 53 tests. The final widget pass also passed all 17 widget/navigation tests after the last spacing adjustments. New checks exercise pin persistence and company isolation, template validation, calendar date links, and navigation-rail routing. Existing 360 px, 150% text and 1024 px tablet checks still pass.

Screenshots cover light/dark dashboards, compact obligation cards, monochrome empty states, templates, detail and calendar screens.

## Artifacts

- Android debug APK: `/workspace/DueDesk-debug.apk` (also `build/app/outputs/flutter-apk/app-debug.apk`).
- APK SHA-256: `d33a17d4fd0bd51f63fb32b8fa417ac02aa4e976799b28d3f222eca25cc2e0d8`
- Source archive: `/workspace/DueDesk-source.zip`.
- Screenshots: written to `artifacts/` (git-ignored) by `flutter test` and `tool/browser_smoke.cjs`.
- Logs: `artifacts/verification/`.

The Android build emits a compatibility advisory from the pinned `file_picker` plugin's legacy Kotlin Gradle integration. It builds successfully with this Flutter release. This is distinct from `flutter analyze`, which has no issues.

The cloud Gradle invocation used the environment's required HTTP proxy and system CA trust. These environment-specific JVM options are not embedded in application code or committed Gradle configuration.

No live Phoenix server, production notification provider, physical mobile device, or iOS runtime was available. Those integrations are not claimed as tested. Demo state transitions and persistence were verified without a backend. Release signing uses the operator's ignored `android/key.properties`; release builds do not silently use the debug key.
