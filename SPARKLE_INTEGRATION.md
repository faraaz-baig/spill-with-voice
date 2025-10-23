# Sparkle Auto-Update Integration

## What Was Done

Sparkle 2.7.1+ has been fully integrated into the Spill app to enable automatic updates.

### Code Changes

1. **Info.plist** (`spillitout/Info.plist`)
   - Added `SUFeedURL`: Points to your appcast.xml at `https://ghq.rathoreactual.com/appcast.xml`
   - Added `SUPublicEDKey`: Placeholder for EdDSA public key (needs to be filled by your release manager)

2. **spillitoutApp.swift**
   - Imported Sparkle framework
   - Initialized `SPUStandardUpdaterController` on app launch
   - Added "Check for Updates…" menu item in the app menu

3. **CheckForUpdatesView.swift** (new file)
   - SwiftUI view that provides the "Check for Updates" button
   - Automatically disables when checking for updates
   - Follows Sparkle 2.x best practices

### How It Works

```
┌─────────────┐      Checks for      ┌──────────────┐
│  Spill App  │ ──────updates───────> │ appcast.xml  │
│   (User's   │                       │ (Your Server)│
│  Computer)  │                       └──────────────┘
└─────────────┘                              │
      │                                      │
      │         If new version exists        │
      │ <────────────────────────────────────┘
      │
      ▼
┌─────────────┐
│  Downloads  │      Verifies signature with
│   Update    │ ────> public key in Info.plist
│   (.zip)    │
└─────────────┘
      │
      ▼
   Installs & Relaunches
```

## What Your Friend Needs to Do

Your friend (who handles releases) needs to:

1. **One-time setup:**
   - Generate EdDSA keys using Sparkle's `generate_keys` tool
   - Put the public key in `Info.plist` (replace `YOUR_PUBLIC_EDDSA_KEY_GOES_HERE`)
   - Keep the private key secure (never commit it!)

2. **For each release:**
   - Build and notarize the app in Xcode
   - Create a ZIP using `ditto` command
   - Sign the ZIP with the private key using `sign_update`
   - Upload the ZIP to your server
   - Update `appcast.xml` with version info and signature
   - Upload `appcast.xml` to your server

See **SPARKLE_RELEASE_GUIDE.md** for detailed step-by-step instructions.

## What Happens for End Users

### Automatic Updates (Default)
- App checks for updates automatically (configurable interval)
- User sees a notification when an update is available
- User can install with one click
- App downloads, verifies, installs, and relaunches automatically

### Manual Updates
- User can click **Spill > Check for Updates…** in the menu bar
- Follows the same download/install process

## Testing the Integration

Before going to production:

1. **Generate test keys:**
   ```bash
   /path/to/sparkle/bin/generate_keys
   ```

2. **Update Info.plist with test public key**

3. **Build the app** (version 1.0.0)

4. **Create a test update:**
   - Change version to 1.0.1 in Xcode
   - Build again
   - Create ZIP with `ditto`
   - Sign with test private key

5. **Host test appcast.xml** (can use local server for testing)

6. **Run version 1.0.0 and check for updates**

## Files to Share with Your Release Manager

- `SPARKLE_RELEASE_GUIDE.md` - Complete release process documentation
- `appcast.xml.template` - Template for the update feed

## Security Notes

- Updates are cryptographically signed with EdDSA
- Sparkle verifies signatures before installation (prevents tampering)
- App must be notarized for macOS Gatekeeper compliance
- HTTPS is required for hosting updates (already configured)

## Customization Options

You can customize Sparkle's behavior in Info.plist:

```xml
<!-- Check for updates at launch (default: true) -->
<key>SUEnableAutomaticChecks</key>
<true/>

<!-- How often to check (in seconds, default: 86400 = 24 hours) -->
<key>SUScheduledCheckInterval</key>
<integer>86400</integer>

<!-- Send system profile (helps understand user base) -->
<key>SUSendProfileInfo</key>
<false/>
```

Add these keys if you want to change defaults.

## Troubleshooting

### "Check for Updates" is Disabled
- App is currently checking for updates
- Network error occurred
- Check Console.app for Sparkle logs

### Updates Not Found
- Verify `appcast.xml` is accessible at the URL in Info.plist
- Check that version in appcast is higher than installed version
- Validate XML syntax

### Signature Verification Failed
- Public key in Info.plist doesn't match private key used for signing
- ZIP file was modified after signing
- Wrong signing tool version used

## Resources

- **Sparkle Project:** https://sparkle-project.org
- **Documentation:** https://sparkle-project.org/documentation/
- **GitHub:** https://github.com/sparkle-project/Sparkle

## Next Steps

1. Share `SPARKLE_RELEASE_GUIDE.md` with your release manager
2. Have them generate the EdDSA keys
3. Update Info.plist with the public key
4. Test with a beta build
5. Set up hosting for appcast.xml and update ZIPs
6. Release your first update!
