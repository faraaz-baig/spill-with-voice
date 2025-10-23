# Sparkle Release & Update Distribution Guide

This guide is for the person responsible for code signing, notarizing, and releasing updates for the Spill app.

## One-Time Setup

### 1. Generate EdDSA Keys for Sparkle

Sparkle uses EdDSA signing to ensure updates are authentic and haven't been tampered with.

```bash
# Run this in your Terminal (needs Sparkle's generate_keys tool)
# If you have Sparkle installed via Homebrew:
/opt/homebrew/bin/generate_keys

# Or if you cloned Sparkle:
./bin/generate_keys
```

This generates two keys:
- **Private key** (keep secret! needed for signing updates)
- **Public key** (put in Info.plist - already has placeholder)

**Action Required:**
1. Save the private key in a secure location (password manager, keychain)
2. Replace `YOUR_PUBLIC_EDDSA_KEY_GOES_HERE` in `spillitout/Info.plist` with the public key
3. **NEVER commit the private key to git!**

### 2. Set Up Server Hosting

You need to host two things:
1. **appcast.xml** - The update feed (tells Sparkle about new versions)
2. **Spill-X.X.X.zip** - The actual app updates (zipped, signed, notarized)

**Recommended hosting location:** `https://ghq.rathoreactual.com/`
- Appcast URL: `https://ghq.rathoreactual.com/appcast.xml` (already configured in Info.plist)
- App downloads: `https://ghq.rathoreactual.com/updates/Spill-X.X.X.zip`

## Release Process (For Each Update)

### Step 1: Build & Archive in Xcode

1. Open the project in Xcode
2. Select **Product > Archive**
3. Wait for build to complete
4. In Organizer, select your archive and click **Distribute App**
5. Choose **Developer ID** (NOT App Store)
6. Make sure **"Notarize"** is checked
7. Export and wait for notarization to complete

### Step 2: Prepare the Update Package

```bash
# Navigate to your exported app
cd ~/Desktop/Spill-Export  # (or wherever Xcode exported it)

# Create a ZIP file of the app
ditto -c -k --sequesterRsrc --keepParent "Spill.app" "Spill-1.0.1.zip"
```

**Important:** The ZIP must be created with `ditto` (not Finder's compress) to preserve code signatures!

### Step 3: Sign the Update with Sparkle

```bash
# Sign the ZIP file with your EdDSA private key
./path/to/sign_update "Spill-1.0.1.zip" -f /path/to/your/private_key

# This will output something like:
# sparkle:edSignature="..." length="12345678"
```

**Save this output!** You'll need it for the appcast.

### Step 4: Upload the ZIP to Your Server

```bash
# Upload to your server (adjust path/method as needed)
scp Spill-1.0.1.zip user@ghq.rathoreactual.com:/path/to/updates/

# Or use your web hosting control panel
```

### Step 5: Update the Appcast XML

Create or update `appcast.xml` on your server:

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>Spill Updates</title>
        <link>https://ghq.rathoreactual.com/appcast.xml</link>
        <description>Most recent updates for Spill</description>
        <language>en</language>

        <item>
            <title>Version 1.0.1</title>
            <link>https://ghq.rathoreactual.com/updates/Spill-1.0.1.zip</link>
            <sparkle:version>1.0.1</sparkle:version>
            <sparkle:shortVersionString>1.0.1</sparkle:shortVersionString>
            <sparkle:edSignature>PASTE_SIGNATURE_FROM_SIGN_UPDATE_HERE</sparkle:edSignature>
            <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
            <pubDate>Wed, 23 Oct 2025 12:00:00 +0000</pubDate>
            <enclosure
                url="https://ghq.rathoreactual.com/updates/Spill-1.0.1.zip"
                length="12345678"
                type="application/octet-stream"
                sparkle:edSignature="PASTE_SIGNATURE_FROM_SIGN_UPDATE_HERE" />
            <description><![CDATA[
                <h2>What's New</h2>
                <ul>
                    <li>Bug fixes and improvements</li>
                    <li>Performance enhancements</li>
                </ul>
            ]]></description>
        </item>

        <!-- Keep previous releases here for rollback capability -->

    </channel>
</rss>
```

**Replace:**
- `1.0.1` with your version number
- `PASTE_SIGNATURE_FROM_SIGN_UPDATE_HERE` with the EdDSA signature from Step 3
- `12345678` with the actual file size in bytes
- Update the `pubDate` to current date/time
- Add meaningful release notes in the description

### Step 6: Upload appcast.xml

```bash
scp appcast.xml user@ghq.rathoreactual.com:/path/to/appcast.xml
```

Make sure it's accessible at: `https://ghq.rathoreactual.com/appcast.xml`

### Step 7: Test the Update

1. Install the previous version of Spill on a test Mac
2. Launch the app
3. Go to **Spill > Check for Updates…** in the menu
4. Verify that:
   - Update is detected
   - Download works
   - Installation completes successfully
   - App relaunches with new version

## Version Numbering

The app uses two version identifiers (configure in Xcode build settings):

- **MARKETING_VERSION** (`CFBundleShortVersionString`): User-facing version like `1.0.1`
- **CURRENT_PROJECT_VERSION** (`CFBundleVersion`): Build number like `123`

**Best Practice:**
- Increment MARKETING_VERSION for each release: `1.0.0` → `1.0.1` → `1.1.0` → `2.0.0`
- Increment CURRENT_PROJECT_VERSION for each build: `1` → `2` → `3` → `4`

Update these in Xcode before archiving:
1. Select project in navigator
2. Select "spillitout" target
3. Go to "General" tab
4. Update Version (MARKETING_VERSION) and Build (CURRENT_PROJECT_VERSION)

## Troubleshooting

### Update Not Detected
- Verify appcast.xml is accessible at the URL in Info.plist
- Check XML is valid (use an XML validator)
- Ensure version numbers are higher than currently installed version

### "Update is Damaged" Error
- ZIP must be created with `ditto`, not Finder
- App must be properly notarized before zipping
- EdDSA signature must match the ZIP contents

### Signature Verification Failed
- Public key in Info.plist must match the private key used for signing
- Make sure you're using `sign_update` from Sparkle 2.x (not old DSA keys)

## Security Notes

- **Never** share or commit your private EdDSA key
- **Always** notarize the app before distributing
- **Always** use HTTPS for hosting updates (not HTTP)
- Keep old versions in appcast for 90 days (allows downgrades if needed)

## Tools You'll Need

1. **Xcode** (for building and notarizing)
2. **Sparkle's command-line tools:**
   - `generate_keys` (one-time setup)
   - `sign_update` (every release)

   Get these from: https://github.com/sparkle-project/Sparkle/releases
   Download "Sparkle-for-Swift-Package-Manager.zip" and find tools in `bin/` folder

3. **Server access** (for uploading appcast.xml and ZIP files)

## Quick Checklist for Each Release

- [ ] Update version numbers in Xcode
- [ ] Archive and notarize the app
- [ ] Create ZIP with `ditto`
- [ ] Sign ZIP with `sign_update`
- [ ] Upload ZIP to server
- [ ] Update appcast.xml with new version info
- [ ] Upload appcast.xml to server
- [ ] Test update on a clean Mac
- [ ] Announce the update to users

## Resources

- Sparkle Documentation: https://sparkle-project.org/documentation/
- Publishing Updates: https://sparkle-project.org/documentation/publishing/
- Code Signing: https://sparkle-project.org/documentation/signing/
