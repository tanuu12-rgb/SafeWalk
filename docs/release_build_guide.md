# SafeWalk - Android Release APK Build & Signing Guide

This guide details the procedure to generate and sign a production/release APK (`flutter build apk --release`) for Android devices.

---

## 1. Prerequisites
- Flutter SDK (v3.3.0 or higher)
- Android SDK with Platform Tools & Build Tools (API 34)
- Java Development Kit (JDK 17 or JDK 11) with `keytool` utility

---

## 2. Step-by-Step Signing Procedure

### Step 1: Generate an Android Upload Keystore
Run the Java `keytool` command in your terminal (PowerShell / Command Prompt):

```powershell
keytool -genkey -v -keystore android/app/safewalk_keystore.jks `
        -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 `
        -alias safewalk_key
```

When prompted:
1. Enter a secure keystore password (e.g. `SafeWalkPass2026`).
2. Fill in the organizational units (e.g. `College Lab`, `Your Name`).
3. Confirm by typing `yes`.

---

### Step 2: Configure `android/key.properties`
Create a file named `android/key.properties` (**never commit this to public version control**):

```properties
storePassword=SafeWalkPass2026
keyPassword=SafeWalkPass2026
keyAlias=safewalk_key
storeFile=safewalk_keystore.jks
```

---

### Step 3: Link Signing Config in `android/app/build.gradle`
In [`android/app/build.gradle`](file:///c:/Women%20safety%20app/android/app/build.gradle):

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            if (keystorePropertiesFile.exists()) {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
            }
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled false
            shrinkResources false
        }
    }
}
```

---

### Step 4: Build the Release APK
Clean previous build artifacts and trigger the release compilation:

```powershell
# 1. Clean build cache
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Build standalone Android release APK
flutter build apk --release
```

The resulting signed APK will be output at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 3. Installing on an Android Device via ADB
To sideload the APK onto a connected physical Android device:

```powershell
adb install -r build/app/outputs/flutter-apk/app-release.apk
```
