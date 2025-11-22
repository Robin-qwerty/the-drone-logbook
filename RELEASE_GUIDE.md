# Google Play Test Release Guide

This guide will help you prepare and release your app to Google Play Store for testing.

## Prerequisites

1. **Google Play Console Account**
   - Create an account at https://play.google.com/console
   - Pay the one-time $25 registration fee
   - Complete your developer profile

2. **Java JDK** (for creating keystore)
   - Ensure you have Java installed (comes with Android Studio)

## Step 1: Package Name

The package name has been set to `com.dronelogbook.app`. This is already configured and ready to use.

**Note:** If you want to change it in the future:
1. Update `android/app/build.gradle` - change `applicationId` and `namespace`
2. Update folder structure: `android/app/src/main/kotlin/com/dronelogbook/app/`
3. Update `MainActivity.kt` package declaration

## Step 2: Create a Keystore for Signing

You need a keystore to sign your release builds. **Keep this file safe - you'll need it for all future updates!**

### Create the Keystore

Run this command in your project root (replace with your own values):

```bash
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

You'll be prompted for:
- **Keystore password**: Choose a strong password (remember this!)
- **Key password**: Can be same as keystore password
- **Name, Organization, etc.**: Enter your details
- **Confirm**: Type 'yes'

### Configure Signing

1. Edit `android/key.properties` and replace the placeholders:
   ```
   storePassword=YOUR_KEYSTORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=upload
   storeFile=../upload-keystore.jks
   ```

2. **IMPORTANT:** Add `android/key.properties` to `.gitignore` to keep your passwords safe:
   ```
   android/key.properties
   android/upload-keystore.jks
   ```

## Step 3: Update App Version

Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1
```
- Format: `version: <versionName>+<versionCode>`
- `versionName`: User-visible version (e.g., 1.0.0)
- `versionCode`: Integer that must increase with each release (e.g., 1, 2, 3...)

For your first release, `1.0.0+1` is fine.

## Step 4: Build Release APK

Build the release APK:

```bash
flutter build apk --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

**Note:** For Google Play, you can upload APK files directly. If you prefer AAB format later, use:
```bash
flutter build appbundle --release
```

## Step 5: Prepare for Google Play Console

### Required Assets:

1. **App Icon**: 512x512px PNG (no transparency)
   - Place at: `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

2. **Feature Graphic**: 1024x500px PNG
   - For Google Play Store listing

3. **Screenshots**: 
   - Phone: At least 2, max 8 (16:9 or 9:16, min 320px, max 3840px)
   - Tablet (optional): Same requirements

4. **App Description**: 
   - Short description: 80 characters max
   - Full description: 4000 characters max

### Content Rating Questionnaire

Complete the content rating questionnaire in Google Play Console.

## Step 6: Upload to Google Play Console

1. **Create App**
   - Go to Google Play Console
   - Click "Create app"
   - Fill in app details:
     - App name: "The Drone Logbook"
     - Default language: English
     - App or game: App
     - Free or paid: Free
     - Declarations: Check all that apply

2. **Set Up Store Listing**
   - Add app description
   - Upload screenshots
   - Add feature graphic
   - Set app category

3. **Create Internal Test Track** (for testing)
   - Go to "Testing" → "Internal testing"
   - Click "Create new release"
   - Upload your APK file (`app-release.apk`)
   - Add release notes
   - Save and review

4. **Add Testers**
   - Add email addresses of testers
   - They'll receive an email with a link to install

5. **Review and Rollout**
   - Review all information
   - Click "Start rollout to Internal testing"
   - Testers can now install via the Play Store link

## Step 7: Testing Checklist

Before releasing, test:
- [ ] App installs correctly
- [ ] All features work as expected
- [ ] Database persists data correctly
- [ ] No crashes on different Android versions
- [ ] Permissions work correctly (if using storage)
- [ ] App icon displays correctly
- [ ] App name displays correctly

## Troubleshooting

### Build Errors

If you get signing errors:
- Check that `key.properties` exists and has correct paths
- Verify keystore file exists at the specified location
- Check passwords are correct

### Google Play Console Errors

- **Package name conflict**: Change your package name (see Step 1)
- **Version code conflict**: Increment versionCode in pubspec.yaml
- **Missing assets**: Upload required screenshots and graphics

## Next Steps After Testing

1. **Fix any issues** found during testing
2. **Increment version**: Update `version: 1.0.0+2` in pubspec.yaml
3. **Build new release**: Run `flutter build appbundle --release` again
4. **Create production release** in Google Play Console
5. **Submit for review** when ready

## Important Notes

- **Keep your keystore safe!** You'll need it for every update. If you lose it, you can't update your app.
- **Version code must always increase** - Google Play won't accept a lower version code
- **Test thoroughly** before releasing to production
- **Review Google Play policies** to ensure compliance

## Quick Commands Reference

```bash
# Build release APK
flutter build apk --release

# Build release AAB (for Google Play)
flutter build appbundle --release

# Check app size
flutter build apk --release --analyze-size

# Clean build
flutter clean
flutter pub get
```

Good luck with your release! 🚀

