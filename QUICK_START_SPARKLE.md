# Quick Start: Sparkle Integration

## Status: ✅ Code Integration Complete

The Sparkle auto-update framework has been integrated into your app. Here's what's done and what's left:

## ✅ Completed

- [x] Sparkle 2.7.1+ added via Swift Package Manager
- [x] Info.plist configured with feed URL and public key placeholder
- [x] Sparkle initialized in app startup code
- [x] "Check for Updates…" menu item added to app menu
- [x] Update checking logic implemented

## ⏳ Next Steps (For Your Release Manager)

### 1. Generate EdDSA Keys (One-Time Setup)

Your friend needs to run this once:

```bash
# Download Sparkle tools from:
# https://github.com/sparkle-project/Sparkle/releases
# Get "Sparkle-for-Swift-Package-Manager.zip"

# Extract and run:
./bin/generate_keys

# Output will look like:
# Private key: (save this secretly!)
# Public key: ABC123... (put this in Info.plist)
```

### 2. Update Info.plist

Replace `YOUR_PUBLIC_EDDSA_KEY_GOES_HERE` in `spillitout/Info.plist` with the public key from step 1.

**File:** `spillitout/Info.plist` (lines 33-34)

### 3. Set Up Server Hosting

Host these two files at `https://ghq.rathoreactual.com/`:

1. `appcast.xml` - Update feed (use `appcast.xml.template` as starting point)
2. `updates/Spill-X.X.X.zip` - Your app releases (signed and notarized)

### 4. Release Process

For each new version:

```bash
# 1. Build & notarize in Xcode (Developer ID distribution)

# 2. Create ZIP
ditto -c -k --sequesterRsrc --keepParent "Spill.app" "Spill-1.0.1.zip"

# 3. Sign ZIP
./bin/sign_update "Spill-1.0.1.zip" -f /path/to/private_key
# (Save the signature output!)

# 4. Upload ZIP to server

# 5. Update appcast.xml with:
#    - New version number
#    - Download URL
#    - EdDSA signature
#    - File size
#    - Release notes

# 6. Upload appcast.xml to server

# 7. Test!
```

## 📚 Documentation

Three documents have been created for you:

1. **SPARKLE_INTEGRATION.md** (This file) - Overview and how it works
2. **SPARKLE_RELEASE_GUIDE.md** - Detailed step-by-step release process for your friend
3. **appcast.xml.template** - Template for the update feed XML file

## 🧪 Testing Before Production

1. Generate test keys
2. Build app at version 1.0.0
3. Build app at version 1.0.1
4. Sign v1.0.1 with test key
5. Create test appcast.xml
6. Host appcast locally or on test server
7. Run v1.0.0 and click "Check for Updates…"
8. Verify update downloads and installs correctly

## 🔒 Security Checklist

- [ ] Private EdDSA key is kept secure (not in git!)
- [ ] Public key is in Info.plist
- [ ] App is notarized before distribution
- [ ] Updates are hosted over HTTPS (not HTTP)
- [ ] Each release ZIP is signed with `sign_update`

## 🎯 User Experience

When users run your app:

1. **First launch**: Sparkle initializes (no visible change)
2. **Background**: App checks for updates every 24 hours
3. **Update available**: User gets a notification with release notes
4. **Manual check**: User can click "Spill > Check for Updates…" anytime
5. **Installation**: One-click download, verify, install, relaunch

## 🔍 How to Verify Integration

Build and run the app now to verify:

1. Open Xcode
2. Build and run (Cmd+R)
3. In the app menu bar, click **Spill**
4. You should see **"Check for Updates…"** in the menu

If you see it: ✅ Integration successful!

The button will be disabled until you:
- Add the public key to Info.plist
- Host a valid appcast.xml at the configured URL

## 🚀 Ready to Ship?

Before your first production release with Sparkle:

- [ ] Public key added to Info.plist
- [ ] appcast.xml hosted at `https://ghq.rathoreactual.com/appcast.xml`
- [ ] Server can host update ZIPs
- [ ] Release process tested with beta build
- [ ] Release manager has read `SPARKLE_RELEASE_GUIDE.md`

## 📞 Need Help?

- Sparkle Docs: https://sparkle-project.org/documentation/
- Sparkle GitHub: https://github.com/sparkle-project/Sparkle
- Check Console.app for Sparkle debug logs

---

**Give `SPARKLE_RELEASE_GUIDE.md` to your friend who handles releases!**
