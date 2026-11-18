# CHRONOX — Future Task System

CHRONOX is a futuristic holographic task manager built with Flutter.

## Features
- Holographic dark interface with cyan and violet glow.
- Create task cards with title, notes, date and time.
- Three priorities: Necessary, Important and Critical.
- Adaptive local notification channels with vibration.
- Local SQLite database; no account or backend required.
- Lock and unlock individual task cards.
- Optional app PIN protected with secure storage.
- Arabic date formatting and RTL-friendly content.

## Build an Android APK
Every push to `main` starts **GitHub Actions → CHRONOX Android APK**.

1. Open the repository's **Actions** tab.
2. Select the latest **CHRONOX Android APK** run.
3. Wait until the workflow is green.
4. Open **Artifacts** and download `chronox-release-apk`.
5. Extract the ZIP and install `app-release.apk` on Android.

You can also start a build manually from **Actions → CHRONOX Android APK → Run workflow**.

## Tech
Flutter / Dart · SQLite · flutter_local_notifications · timezone · flutter_secure_storage · SharedPreferences

All task data is stored locally on the device. Android notification permission must be granted for reminders to appear. Android battery settings may affect delivery timing.
