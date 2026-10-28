# SafeWalk 🛡️
> **Women Safety Prototype Mobile App with Safe-Walk Dead-Man's Switch Timer**  
> *Developed for College Mobile Application Development Lab Project (Target: Android).*

![SafeWalk Logo](assets/images/logo.png)

---

## 📖 Project Overview
**SafeWalk** is a reliable mobile safety application engineered to protect women walking alone, particularly during night commutes or in deserted areas.

### Core Concept: Dead-Man's Switch Timer
The user defines a destination (e.g. *"Hostel"*, *"Metro Station"*) and a timer duration. If the user does not tap **"I've arrived safely"** before the countdown concludes:
1. **Local Notification Reminder**: An alarm notification fires with a 60-second grace period countdown.
2. **Automated Escalation**: If still unconfirmed after 60 seconds, SafeWalk automatically:
   - Queries the device's foreground GPS coordinates.
   - Logs an alert record into **Firebase Realtime Database** (and saves to local JSON if offline).
   - Launches the device's native messaging application with a pre-filled emergency SMS containing live Google Maps coordinates to registered emergency contacts (the user taps send; no illegal silent auto-SMS).

### Secondary SOS Triggers:
- **Manual SOS Button**: Double-tap or long-press on the pulsating emergency button on the Home Dashboard.
- **Shake Detection**: Rapidly shaking the phone uses the device's accelerometer (`sensors_plus`) to trigger the emergency escalation instantly.

---

## 📱 Screens (6 Core Screens)
1. **Login / Register Screen ([`lib/screens/auth/login_register_screen.dart`](lib/screens/auth/login_register_screen.dart))**: Validated email/password authentication using Firebase Auth, toggle between Sign In/Sign Up, prototype disclaimer checkbox, and a direct Lab Demo Bypass for examiners.
2. **Home Dashboard ([`lib/screens/home/home_screen.dart`](lib/screens/home/home_screen.dart))**: Pulsating emergency SOS button, "Start Safe Walk" navigation card, live emergency contacts summary, safety educational card (`Image.network`), recent activity list, and offline cloud-sync indicator.
3. **Emergency Contacts ([`lib/screens/contacts/emergency_contacts_screen.dart`](lib/screens/contacts/emergency_contacts_screen.dart))**: Add, edit, and delete contacts with validation. Stored on-device in a JSON file via `dart:io` & `path_provider` (read using `FutureBuilder`) and synced to Firebase. Features relationship dropdown and "Primary Contact" designation.
4. **Safe Walk Timer ([`lib/screens/safe_walk/safe_walk_screen.dart`](lib/screens/safe_walk/safe_walk_screen.dart))**: Destination chips & duration picker (includes a 1-minute test chip for lab grading), circular countdown indicator, "I've arrived safely" green confirmation button, 60-second grace period alarm screen, and automatic escalation trigger.
5. **Report Unsafe Area ([`lib/screens/reports/report_unsafe_screen.dart`](lib/screens/reports/report_unsafe_screen.dart))**: Categorized hazard dropdown, description validator, auto-captured device GPS coordinates, and write to Firebase via `push().set()`.
6. **Activity & Stats ([`lib/screens/activity/activity_stats_screen.dart`](lib/screens/activity/activity_stats_screen.dart))**: Real-time **`fl_chart`** bar chart aggregating community unsafe spots by hazard category from live Firebase data (`onValue` stream via `StreamBuilder`), with an empty state when no data exists. Also displays past walks and local JSON alert logs.

---

## ⚠️ KNOWN LIMITATIONS (Mandatory Lab Disclosure)
1. **No Silent Auto-SMS**: By Android security guidelines and Google Play Policy, apps cannot silently transmit SMS in the background without user interaction. SafeWalk opens the default SMS app with the pre-filled coordinates message; **the user must tap send**.
2. **Foreground Location Only**: Location is retrieved only when active or when an alert triggers. Background continuous location tracking is intentionally excluded in this MVP to prevent battery drain and avoid Google Play background location permission restrictions.
3. **Android Target Only**: Engineered and configured specifically for Android devices (SDK 23 to 34).
4. **College Prototype**: SafeWalk is an academic prototype built for laboratory demonstration and evaluation. It is **not** a certified government safety product or a replacement for national emergency services (e.g., 911 / 112).

---

## 🛠️ Technology Stack & Dependencies

| Category | Package | Version | Purpose |
|---|---|---|---|
| **Core Framework** | `flutter` | `>=3.3.0` | Mobile application SDK |
| **Cloud Authentication** | `firebase_auth` | `^5.3.1` | User login & registration |
| **Realtime Database** | `firebase_database` | `^11.1.4` | Live sync, reports, and alerts |
| **Location** | `geolocator` | `^13.0.1` | High-accuracy foreground GPS coordinates |
| **Permissions** | `permission_handler`| `^11.3.1` | Runtime Android permission checks |
| **Local File Storage**| `path_provider` | `^2.1.4` | App internal documents directory for JSON files |
| **Telephony / SMS** | `url_launcher` | `^6.3.0` | Launching SMS client and phone dialer |
| **Notifications** | `flutter_local_notifications` | `^18.0.1` | Grace period timer expiry notification |
| **Motion Sensors** | `sensors_plus` | `^6.1.0` | 3D accelerometer shake detection |
| **Data Visualization**| `fl_chart` | `^0.69.0` | Responsive bar chart for incident analytics |

---

## 🗄️ Database Structure (Firebase Realtime Database)

```json
{
  "users": {
    "<user_uid>": {
      "contacts": {
        "<contact_id>": {
          "id": "c1",
          "name": "Mom",
          "phoneNumber": "+919876543210",
          "relationship": "Parent",
          "isPrimary": true,
          "createdAt": "2026-10-21T14:30:00Z"
        }
      },
      "alerts": {
        "<alert_push_id>": {
          "id": "alert_101",
          "alertType": "SAFE_WALK_TIMEOUT",
          "destination": "Hostel B",
          "latitude": 28.5355,
          "longitude": 77.3910,
          "timestamp": "2026-10-21T15:00:00Z",
          "isSynced": true
        }
      },
      "safewalks": {
        "<walk_push_id>": {
          "destination": "Campus Library",
          "durationMinutes": 15,
          "status": "ARRIVED_SAFELY",
          "startTime": "2026-10-21T18:00:00Z"
        }
      }
    }
  },
  "unsafe_reports": {
    "<report_push_id>": {
      "userId": "<user_uid>",
      "category": "Poor Lighting / Dark Street",
      "description": "Street lights completely out for 200 meters near gate 4.",
      "latitude": 28.5360,
      "longitude": 77.3925,
      "timestamp": "2026-10-21T19:30:00Z"
    }
  }
}
```

---

## 🔒 Security Rules (`database.rules.json`)
The application includes production-ready database security rules:
- Users can only read and write their own data under `users/$uid`.
- Authenticated users can write new reports to `unsafe_reports` (with validation for required fields) and read community reports for the analytics chart.

---

## 🚀 Setup & Execution Instructions

### 1. Clone & Install Dependencies
```powershell
cd "c:\Women safety app"
flutter pub get
```

### 2. Configure Firebase (Google Services)
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Create a project and add an Android app with package name: **`com.safewalk.app`**.
3. Enable **Email/Password** in Firebase Authentication.
4. Enable **Firebase Realtime Database** in test/production mode and paste the contents of [`database.rules.json`](database.rules.json).
5. Download your **`google-services.json`** and place it into:
   ```
   android/app/google-services.json
   ```
*(Note: A template placeholder is already present in `android/app/google-services.json`.)*

### 3. Run the App
```powershell
flutter run
```

### 4. Run Automated Tests
```powershell
flutter test
```

---

## 📦 Building Signed Release APK
Refer to the complete walkthrough in [`docs/release_build_guide.md`](docs/release_build_guide.md):
```powershell
flutter clean
flutter pub get
flutter build apk --release
```
The output APK is generated at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 📚 Documentation Directory (`docs/`)
- **[`docs/architecture.md`](docs/architecture.md)**: Architectural design, layers, and service orchestration.
- **[`docs/screen_flow.md`](docs/screen_flow.md)**: Mermaid screen flow & state machine diagram.
- **[`docs/lab_mapping.md`](docs/lab_mapping.md)**: Direct mapping table of syllabus Practicals (1 to 10) to code.
- **[`docs/release_build_guide.md`](docs/release_build_guide.md)**: Android signing and APK generation instructions.
