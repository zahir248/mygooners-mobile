# Google Sign-In Setup Instructions

## Error Code 10 (DEVELOPER_ERROR) Fix

This error occurs when Google Sign-In is not properly configured. Follow these steps:

## Step 1: Get Your SHA-1 Fingerprint

### For Debug Build:
```bash
# Windows (PowerShell)
cd android
.\gradlew signingReport

# Or using keytool directly
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

### For Release Build:
```bash
keytool -list -v -keystore YOUR_KEYSTORE_PATH -alias YOUR_KEY_ALIAS
```

Copy the SHA-1 fingerprint (it looks like: `AA:BB:CC:DD:EE:FF:...`)

## Step 2: Configure Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select or create a project
3. Enable **Google Sign-In API**:
   - Go to "APIs & Services" > "Library"
   - Search for "Google Sign-In API" and enable it
4. Go to "APIs & Services" > "Credentials"
5. Click "Create Credentials" > "OAuth client ID"
6. If prompted, configure the OAuth consent screen first
7. Create OAuth client ID for **Android**:
   - **Application type**: Android
   - **Name**: MyGooners Android (or any name)
   - **Package name**: `com.example.mygooners` (from android/app/build.gradle.kts)
   - **SHA-1 certificate fingerprint**: Paste the SHA-1 from Step 1
   - Click "Create"
   - **Your Android Client ID**: `945050509185-e64tsa4gqjc6tctiaa07tqm5j8qj0pn9.apps.googleusercontent.com` ✅
8. Verify you have a **Web application** OAuth client ID:
   - **Your Web Client ID**: `945050509185-cptos9ssc86tm0a0e28ko7la6je9uakc.apps.googleusercontent.com` ✅
   - (This is already configured in the code)

## Step 3: Verify Flutter Code

The Flutter code is already configured! ✅

- **Web Client ID** is set in `lib/config/api_config.dart` and used as `serverClientId`
- **Android Client ID** is automatically used by Flutter (configured in Google Cloud Console)
- Both login and register pages are configured correctly

No code changes needed - just make sure the SHA-1 fingerprint is added in Google Cloud Console!

## Step 4: Rebuild the App

```bash
flutter clean
flutter pub get
flutter run
```

## Alternative: Quick Test (Without Web Client ID)

If you just want to test without full configuration, you can try:

1. Make sure you've added the SHA-1 fingerprint in Google Cloud Console
2. The app should work with just the Android OAuth client ID configured
3. The `serverClientId` is optional but recommended for production

## Troubleshooting

- **Still getting error 10**: Make sure SHA-1 is correctly added in Google Cloud Console
- **Error persists**: Wait a few minutes after adding SHA-1 (Google needs time to propagate)
- **Different error**: Check Google Cloud Console for API quotas and restrictions

## Notes

- The package name must match exactly: `com.example.mygooners`
- You need separate OAuth clients for Android and Web
- For production, use release keystore SHA-1, not debug keystore

