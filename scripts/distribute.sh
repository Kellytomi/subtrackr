#!/bin/bash

# SubTrackr Automated Distribution Script
# This script distributes the AAB file via Firebase App Distribution CLI

set -e  # Exit on any error

echo "📤 SubTrackr Automated Distribution Script"
echo "=========================================="

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found. Please run this script from the project root."
    exit 1
fi

# Check if APK file exists
APK_FILE="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$APK_FILE" ]; then
    echo "❌ Error: APK file not found at $APK_FILE"
    echo "💡 Run './scripts/release.sh' first to create a release."
    exit 1
fi

# Read current version from pubspec.yaml
CURRENT_VERSION=$(grep "^version:" pubspec.yaml | cut -d' ' -f2)
echo "📋 Version: $CURRENT_VERSION"

# Firebase App ID for SubTrackr Android
APP_ID="1:466119548770:android:a8ee91aa495d31a41cd63b"

# Release notes
RELEASE_NOTES="Version $CURRENT_VERSION - Shorebird auto-updates enabled, OneSignal notifications ready"

echo "📦 APK File: $APK_FILE"
echo "📝 Release Notes: $RELEASE_NOTES"
echo ""

# Ask for confirmation
read -p "🤔 Do you want to distribute this version to the Testers group? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Distribution cancelled."
    exit 1
fi

echo "📤 Distributing to Firebase App Distribution..."

# Try to distribute via Firebase CLI
if firebase appdistribution:distribute "$APK_FILE" \
    --app "$APP_ID" \
    --groups "Testers" \
    --release-notes "$RELEASE_NOTES"; then
    
    echo ""
    echo "✅ Distribution completed successfully!"
    echo "📧 Testers will receive email notifications"
    echo "📱 They can download from the Firebase App Distribution dashboard"
    echo ""
    echo "🎉 Happy distributing!"
else
    echo ""
    echo "❌ CLI distribution failed. Use the web console instead:"
    echo ""
    echo "🌐 Web Console Steps:"
    echo "   1. Go to: https://console.firebase.google.com"
    echo "   2. Select: subtrackr-fresh"
    echo "   3. Navigate: App Distribution → New Release"
    echo "   4. Upload: $APK_FILE"
    echo "   5. Release Notes: $RELEASE_NOTES"
    echo "   6. Groups: Testers"
    echo "   7. Distribute!"
    echo ""
fi 