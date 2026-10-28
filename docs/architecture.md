# SafeWalk - System Architecture & Engineering Design

## 1. System Overview
**SafeWalk** is an Android-targeted Flutter prototype designed to safeguard individuals walking alone through an automated **Dead-Man's Switch Timer**, an immediate **Manual SOS trigger** (via long-press, double-tap, or accelerometer shake), local **JSON persistence**, and real-time **Firebase Cloud synchronization**.

```
+------------------------------------------------------------------------+
|                            PRESENTATION LAYER                          |
|  - Login/Register Screen       - Home Dashboard Screen                 |
|  - Emergency Contacts Screen   - Safe Walk Timer Screen                |
|  - Report Unsafe Area Screen   - Activity & Real-Time Stats Screen     |
+------------------------------------------------------------------------+
                                    |
+------------------------------------------------------------------------+
|                            SERVICE LAYER                               |
|  - AuthService (Firebase Auth)                                         |
|  - LocationService (Geolocator & PermissionHandler)                    |
|  - NotificationService (FlutterLocalNotificationsPlugin)               |
|  - ShakeDetectorService (sensors_plus UserAccelerometer)               |
|  - EscalationService (Coordinates SMS launch & Alert Dispatch)         |
+------------------------------------------------------------------------+
                  /                                      \
+-------------------------------+      +---------------------------------+
|      LOCAL PERSISTENCE        |      |       CLOUD BACKEND             |
|  - LocalStorageService        |      |  - Firebase Realtime Database   |
|  - dart:io & path_provider    | <--> |  - push().set() / onValue       |
|  - JSON files:                |      |  - Per-user Security Rules      |
|    * contacts.json            |      |  - Automated Retry Sync Engine  |
|    * offline_alerts.json      |      |                                 |
+-------------------------------+      +---------------------------------+
```

---

## 2. Layered Architecture Breakdown

### A. Presentation Layer (`lib/screens` & `lib/widgets`)
- **Responsive Layouts**: Constructed using flexible responsive widgets (`Column`, `Row`, `Expanded`, `Flexible`, `SingleChildScrollView`, `ConstrainedBox`).
- **Material 3 Design System**: Custom safety dark palette defined in `AppTheme` with custom `BoxDecoration` glassmorphism and glowing SOS button styles.
- **Form Validation**: Reactive input validation with `GlobalKey<FormState>`, regex email/phone checking, and required field validators.

### B. Sensor & Device Hardware Layer (`lib/services`)
- **GPS Location Engine (`LocationService`)**: Queries foreground GPS coordinates via `geolocator`. Enforces user permission checks via `permission_handler`, routing to a user-friendly `PermissionScreen` when denied.
- **Motion Sensor Engine (`ShakeDetectorService`)**: Streams 3D user acceleration from `sensors_plus`. Calculates magnitude $\sqrt{x^2 + y^2 + z^2}$, debouncing false shakes to trigger SOS escalation when a rapid movement spike occurs.
- **Notification Engine (`NotificationService`)**: Manages high-priority local notifications with sound and vibration to prompt users during the 60-second grace window.
- **Emergency Telephony Dispatch (`EscalationService`)**: Uses `url_launcher` to generate pre-filled SMS messages with clickable Google Maps coordinates links (`https://maps.google.com/?q=lat,lng`).

### C. Data Persistence & Synchronization Layer
- **Local File System**: Direct file I/O using `dart:io` and `path_provider` saves contacts and alerts to JSON on device storage.
- **Offline Reliability**: If network fails or Firebase credentials are offline, alerts are stored locally with `isSynced: false`. Once connectivity resumes, `retrySyncOfflineAlerts()` automatically syncs them.
- **Firebase Realtime Database**: Stores user-scoped contacts, walks, alerts, and community-shared unsafe area reports with database security rules (`database.rules.json`).
