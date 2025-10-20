# Configuration Setup

This directory contains environment-specific configuration files for the app.

## Files

- `Config.swift` - Swift code that reads configuration values
- `Debug.xcconfig` - Development configuration (local server)
- `Release.xcconfig` - Production configuration (production server)
- `Config.example.xcconfig` - Example template for new configurations

## Setup in Xcode

### Step 1: Add Configuration Files to Xcode Project

1. Open Xcode
2. Right-click on the `spillitout` folder in the Project Navigator
3. Select "Add Files to 'spillitout'..."
4. Navigate to the `Config` folder
5. Select all `.xcconfig` files and `Config.swift`
6. Make sure "Copy items if needed" is **unchecked** (they're already in the right place)
7. Click "Add"

### Step 2: Configure Build Settings

1. In Xcode, click on the project name at the top of the Project Navigator
2. Select the **spillitout** target (not the project)
3. Go to the **Info** tab
4. Under **Configurations**, expand **Debug** and **Release**:
   - For **Debug**: Set configuration file to `Debug`
   - For **Release**: Set configuration file to `Release`

### Step 3: Add to Info.plist

1. Open `Info.plist` in Xcode
2. Add a new row with key: `API_BASE_URL`
3. Set the value to: `$(API_BASE_URL)`

This allows the app to read the value from the xcconfig file.

### Step 4: Verify Setup

1. Build and run the app (⌘+R)
2. Check the console for any configuration errors
3. The app should automatically use `http://localhost:3000/api` in Debug mode

## How It Works

### Development (Debug Build)
- When you run the app from Xcode (⌘+R), it uses `Debug.xcconfig`
- API calls go to: `http://localhost:3000/api`
- Perfect for local testing with your backend running

### Production (Release Build)
- When you archive for App Store (⌘+B → Archive), it uses `Release.xcconfig`
- API calls go to: `https://api.yourapp.com/api` (or whatever you configure)
- Ensures production builds never accidentally hit localhost

## Updating Configuration

### Change Local Development URL
Edit `Debug.xcconfig`:
```
API_BASE_URL = http:/$()/192.168.1.100:3000/api
```

### Change Production URL
Edit `Release.xcconfig`:
```
API_BASE_URL = https:/$()/your-production-domain.com/api
```

**Note:** The `$(/)` syntax is required to prevent Xcode from treating `://` as a URL scheme separator.

## Security

- `.xcconfig` files are added to `.gitignore`
- They won't be committed to version control
- Each team member can have their own local configuration
- Production secrets stay secure

## Troubleshooting

### "API_BASE_URL not set" Error
1. Make sure xcconfig files are added to the Xcode project
2. Verify Info.plist contains `API_BASE_URL` = `$(API_BASE_URL)`
3. Clean build folder (⌘+Shift+K) and rebuild

### Still Using localhost in Production
1. Check you're building a Release build, not Debug
2. Verify `Release.xcconfig` has the correct URL
3. Clean and rebuild

### Configuration Not Updating
1. Clean build folder (⌘+Shift+K)
2. Quit Xcode completely
3. Delete `DerivedData` folder
4. Restart Xcode and rebuild

## Example: Adding New Environment Variables

To add more configuration values (like API keys):

1. Add to `Debug.xcconfig`:
```
API_BASE_URL = http:/$()/localhost:3000/api
ANALYTICS_KEY = debug_key_here
```

2. Add to `Release.xcconfig`:
```
API_BASE_URL = https:/$()/api.yourapp.com/api
ANALYTICS_KEY = production_key_here
```

3. Add to `Info.plist`:
```xml
<key>ANALYTICS_KEY</key>
<string>$(ANALYTICS_KEY)</string>
```

4. Access in Swift:
```swift
static var analyticsKey: String {
    return Bundle.main.object(forInfoDictionaryKey: "ANALYTICS_KEY") as? String ?? ""
}
```

## Current Configuration

### Debug (Development)
- API Base URL: `http://localhost:3000/api`
- Environment: Development

### Release (Production)
- API Base URL: `https://api.yourapp.com/api` (Update this before deploying!)
- Environment: Production

**Remember to update the production URL in `Release.xcconfig` before submitting to the App Store!**
