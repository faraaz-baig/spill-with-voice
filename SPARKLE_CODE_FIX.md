# How to Fix "No such module 'Sparkle'" via Code (Not Xcode GUI)

## The Problem

When you added `import Sparkle` to your Swift code, Xcode showed:
```
No such module 'Sparkle'
```

This happened because Sparkle was added as a Swift Package dependency to your project, but wasn't **linked** to your app target.

## The Solution (Code-Based)

I edited the `project.pbxproj` file directly to add Sparkle to your app target. Here's what was changed:

### 1. Added PBXBuildFile Entry (Line 15)

```
68DE226F2E3B6A0000A93201 /* Sparkle in Frameworks */ = {isa = PBXBuildFile; productRef = 68DE226E2E3B6A0000A93201 /* Sparkle */; };
```

This tells Xcode to build Sparkle as part of your app.

### 2. Added to Frameworks Build Phase (Line 82)

```
68DE226F2E3B6A0000A93201 /* Sparkle in Frameworks */,
```

This links the Sparkle framework to your app's binary.

### 3. Added Package Product Dependency (Lines 731-735)

```
68DE226E2E3B6A0000A93201 /* Sparkle */ = {
    isa = XCSwiftPackageProductDependency;
    package = 68DE257A2E3B695A00A93201 /* XCRemoteSwiftPackageReference "Sparkle" */;
    productName = Sparkle;
};
```

This references the Sparkle package product.

### 4. Added to Target's Package Dependencies (Line 148)

```
packageProductDependencies = (
    68DE22642E38ED1000A93201 /* LiveKit */,
    68DE22682E38ED6700A93201 /* AsyncAlgorithms */,
    68DE226A2E38ED6E00A93201 /* Collections */,
    68DE226D2E38EDC500A93201 /* LiveKitComponents */,
    68DE226E2E3B6A0000A93201 /* Sparkle */,  ← Added this
);
```

This associates Sparkle with the spillitout app target.

## What Changed in project.pbxproj

**File:** `spillitout.xcodeproj/project.pbxproj`

The changes ensure that:
1. Sparkle is compiled as a framework
2. Sparkle is linked to your app binary
3. The Swift compiler knows where to find the Sparkle module

## Why This Approach Works

The `project.pbxproj` file is a plain text file that describes your Xcode project structure. All the GUI operations in Xcode (adding frameworks, linking libraries, etc.) ultimately modify this file.

By editing it directly, you can:
- Version control your changes easily (git diff shows exactly what changed)
- Automate project configuration via scripts
- Understand exactly what Xcode does under the hood
- Fix issues without relying on the GUI

## Verification

After making these changes:

1. **Close Xcode** (if it's open) to avoid conflicts
2. **Reopen the project** in Xcode
3. **Clean build folder**: `Cmd+Shift+K` or Product → Clean Build Folder
4. **Build**: `Cmd+B`

The "No such module 'Sparkle'" error should now be gone!

## Understanding the UUIDs

You might wonder about the random-looking IDs like `68DE226E2E3B6A0000A93201`. These are:

- **Unique identifiers** for each object in the Xcode project
- **Hexadecimal values** that Xcode generates
- **References** used to link different parts of the project together

When adding new entries manually, you can:
1. Generate your own UUID (any unique hex string works)
2. Or follow the pattern: increment the last existing ID

I used `68DE226E2E3B6A0000A93201` and `68DE226F2E3B6A0000A93201` which follow the existing pattern in your project.

## Other Packages You Could Add This Way

The same technique works for any Swift Package:

1. Find the package reference UUID (search for `XCRemoteSwiftPackageReference`)
2. Create a PBXBuildFile entry
3. Add to Frameworks build phase
4. Create XCSwiftPackageProductDependency
5. Add to target's packageProductDependencies

Example for a hypothetical package "Foo":

```
/* PBXBuildFile */
AAAA11112E3B6A0000A93201 /* Foo in Frameworks */ = {isa = PBXBuildFile; productRef = AAAA11102E3B6A0000A93201 /* Foo */; };

/* Frameworks Build Phase */
AAAA11112E3B6A0000A93201 /* Foo in Frameworks */,

/* XCSwiftPackageProductDependency */
AAAA11102E3B6A0000A93201 /* Foo */ = {
    isa = XCSwiftPackageProductDependency;
    package = AAAA10002E3B695A00A93201 /* XCRemoteSwiftPackageReference "Foo" */;
    productName = Foo;
};

/* Target packageProductDependencies */
AAAA11102E3B6A0000A93201 /* Foo */,
```

## Git Diff

If you want to see exactly what changed:

```bash
git diff spillitout.xcodeproj/project.pbxproj
```

You should see:
- `+` lines with Sparkle entries
- In 4 different sections of the file

## Troubleshooting

If you still see the error:

1. **Check Xcode isn't caching**: Close Xcode, delete DerivedData
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/spillitout-*
   ```

2. **Verify package is resolved**: File → Packages → Resolve Package Versions

3. **Check the package reference exists**: Search project.pbxproj for "Sparkle"
   ```bash
   grep "Sparkle" spillitout.xcodeproj/project.pbxproj
   ```

4. **Try updating packages**: File → Packages → Update to Latest Package Versions

## Summary

✅ **Fixed**: Sparkle is now properly linked to your app target
✅ **Method**: Direct edit of project.pbxproj (no GUI needed)
✅ **Result**: `import Sparkle` will now work in your Swift code

The module error should be resolved. Build your project to verify!
