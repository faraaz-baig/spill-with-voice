# Sparkle Update Workflow

## The Complete Update Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    RELEASE MANAGER'S WORK                       │
│                    (Your Friend's Job)                          │
└─────────────────────────────────────────────────────────────────┘

    1. Build App in Xcode (with new version number)
              ↓
    2. Archive & Notarize (Developer ID)
              ↓
    3. Export Notarized App
              ↓
    4. Create ZIP with ditto
         $ ditto -c -k --sequesterRsrc --keepParent Spill.app Spill-1.0.1.zip
              ↓
    5. Sign ZIP with EdDSA Private Key
         $ sign_update Spill-1.0.1.zip -f private_key
         Output: sparkle:edSignature="..." length="12345"
              ↓
    6. Upload ZIP to Server
         → https://ghq.rathoreactual.com/updates/Spill-1.0.1.zip
              ↓
    7. Update appcast.xml
         - Add new <item> with version, signature, download URL
         - Include release notes
              ↓
    8. Upload appcast.xml
         → https://ghq.rathoreactual.com/appcast.xml

┌─────────────────────────────────────────────────────────────────┐
│                       END USER'S EXPERIENCE                      │
│                     (What Happens on User's Mac)                │
└─────────────────────────────────────────────────────────────────┘

    User launches Spill v1.0.0
              ↓
    Sparkle checks appcast.xml (every 24 hours or manual)
              ↓
         ┌─────────────────┐
         │  Is new version │  NO → User continues using app
         │   available?    │──────────────────────────────┐
         └─────────────────┘                              │
                ↓ YES                                     │
         ┌─────────────────┐                              │
         │ Show update     │                              │
         │ notification    │                              │
         │ with release    │                              │
         │ notes           │                              │
         └─────────────────┘                              │
                ↓                                          │
         User clicks "Install"                            │
                ↓                                          │
         Download Spill-1.0.1.zip                         │
                ↓                                          │
         Verify EdDSA signature                           │
         (using public key in Info.plist)                 │
                ↓                                          │
         ┌─────────────────┐                              │
         │  Signature OK?  │  NO → Show error, abort     │
         └─────────────────┘                              │
                ↓ YES                                     │
         Extract and replace app                          │
                ↓                                          │
         Relaunch Spill v1.0.1                            │
                ↓                                          │
         User now has latest version ←────────────────────┘
```

## Key Components Explained

### 1. appcast.xml (The Update Feed)
**What it is:** An XML file that lists all available versions
**Where it lives:** `https://ghq.rathoreactual.com/appcast.xml`
**What it contains:**
- Version numbers
- Download URLs
- EdDSA signatures
- Release notes
- Minimum system requirements

**Your app checks this file to see if updates exist.**

### 2. EdDSA Keys (Security)
**Private Key:**
- Used to sign each update ZIP
- Kept secret by release manager
- NEVER committed to git or shared

**Public Key:**
- Embedded in your app's Info.plist
- Used to verify updates haven't been tampered with
- Safe to share publicly

**Why this matters:** Without the private key, nobody can create fake updates for your app.

### 3. Update ZIP Files
**What they are:** Compressed, signed, notarized versions of your app
**Where they live:** `https://ghq.rathoreactual.com/updates/`
**Naming:** `Spill-1.0.0.zip`, `Spill-1.0.1.zip`, etc.

**Must be created with `ditto`** (not Finder's compress) to preserve code signatures!

## Division of Responsibilities

### Your Job (Developer) ✅ DONE
- [x] Integrate Sparkle into the codebase
- [x] Configure Info.plist with feed URL
- [x] Add "Check for Updates" menu item
- [x] Test that update checking works
- [x] Document the process

### Your Friend's Job (Release Manager)
- [ ] Generate EdDSA key pair (one-time)
- [ ] Add public key to Info.plist
- [ ] Set up server hosting for appcast.xml and ZIPs
- [ ] Build, sign, notarize each release
- [ ] Create and sign update ZIPs
- [ ] Maintain appcast.xml with version history
- [ ] Test updates before releasing

## Timeline for Your First Update

### Before First Release (v1.0.0)
1. Generate EdDSA keys
2. Add public key to Info.plist
3. Set up server hosting
4. Create initial (empty) appcast.xml
5. Release v1.0.0 to users

### When Releasing Update (v1.0.1)
1. Build and notarize v1.0.1
2. Create signed ZIP
3. Upload ZIP to server
4. Update appcast.xml
5. Within 24 hours, users will see update notification

## Security Features

```
┌──────────────────┐
│   Update ZIP     │
│  on your server  │
└────────┬─────────┘
         │
         │ EdDSA signature prevents tampering
         ↓
┌──────────────────┐         Public key verifies
│   User's Mac     │ ←───────── it came from you
│  (Spill v1.0.0)  │
└──────────────────┘
```

**Protection against:**
- ❌ Man-in-the-middle attacks (HTTPS + signature)
- ❌ Tampered updates (EdDSA verification)
- ❌ Fake update servers (public key pinning)
- ❌ Unsigned code execution (macOS notarization)

## Rollback Strategy

Keep old versions in appcast.xml for 90 days:

```xml
<item>Version 1.0.2</item>  ← Latest
<item>Version 1.0.1</item>  ← Previous
<item>Version 1.0.0</item>  ← Keep for rollback
```

If v1.0.2 has a critical bug:
1. Remove v1.0.2 from appcast.xml
2. Users checking for updates will get v1.0.1
3. Fix bug and release v1.0.3

## Bandwidth Considerations

**Hosting costs depend on:**
- App size (e.g., 50MB app)
- Number of users (e.g., 1000 users)
- Update frequency (e.g., monthly)

**Example:** 1000 users × 50MB = 50GB per update

**Options:**
- Self-host on your server
- Use CDN (Cloudflare, AWS CloudFront)
- Use GitHub Releases (free for open source)

## Monitoring

**What to watch:**
- Server bandwidth usage
- Download success rate
- Number of users on each version
- Update errors (check crash reports)

**Sparkle provides anonymized stats** if you enable `SUSendProfileInfo` in Info.plist.

## Common Scenarios

### Scenario 1: User has auto-updates disabled
- They can still manually check via menu
- "Check for Updates…" always works

### Scenario 2: User is offline when update releases
- Next time online, they'll get the notification
- Sparkle doesn't spam; shows once per version

### Scenario 3: Major version upgrade (1.x → 2.x)
- Same process as minor updates
- Can add `<sparkle:minimumSystemVersion>` if new macOS required
- Use release notes to explain breaking changes

### Scenario 4: Hotfix needed urgently
- Build and release immediately
- Use higher version number (e.g., 1.0.1.1)
- Update appcast.xml
- Users will see update within 24 hours (or when they manually check)

## Testing Checklist

Before releasing to production:

- [ ] Generate test EdDSA keys
- [ ] Build app v1.0.0 with test public key
- [ ] Build app v1.0.1
- [ ] Sign v1.0.1 with test private key
- [ ] Create test appcast.xml with test signature
- [ ] Host appcast on local server (http://localhost:8000)
- [ ] Update SUFeedURL in Info.plist to local URL
- [ ] Run v1.0.0
- [ ] Click "Check for Updates…"
- [ ] Verify update notification appears
- [ ] Install update
- [ ] Verify v1.0.1 launches successfully
- [ ] Reset SUFeedURL to production URL
- [ ] Replace test public key with production public key

---

**Next Step:** Share `SPARKLE_RELEASE_GUIDE.md` with your friend!
