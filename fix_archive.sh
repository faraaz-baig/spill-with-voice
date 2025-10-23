#!/bin/bash

# Script to fix archive bundle structure for App Store validation
# This removes nested Contents directories that cause shared bundle path errors

ARCHIVE_PATH="build/spill.xcarchive"
APP_PATH="$ARCHIVE_PATH/Products/Applications/spill.app"

echo "Fixing archive bundle structure..."

# Remove nested Contents directories from LiveKit bundle
if [ -d "$APP_PATH/Contents/Resources/LiveKit_LiveKit.bundle/Contents" ]; then
    echo "Removing nested Contents from LiveKit_LiveKit.bundle"
    rm -rf "$APP_PATH/Contents/Resources/LiveKit_LiveKit.bundle/Contents"
fi

# Remove nested Contents directories from SwiftProtobuf bundle
if [ -d "$APP_PATH/Contents/Resources/SwiftProtobuf_SwiftProtobuf.bundle/Contents" ]; then
    echo "Removing nested Contents from SwiftProtobuf_SwiftProtobuf.bundle"
    rm -rf "$APP_PATH/Contents/Resources/SwiftProtobuf_SwiftProtobuf.bundle/Contents"
fi

# Remove duplicate Info.plist from Resources directory
if [ -f "$APP_PATH/Contents/Resources/Info.plist" ]; then
    echo "Removing duplicate Info.plist from Resources directory"
    rm "$APP_PATH/Contents/Resources/Info.plist"
fi

# Verify the fix
echo "Checking remaining Contents directories:"
find "$ARCHIVE_PATH" -name "Contents" -type d

echo "Archive structure fixed. You can now proceed with App Store validation."