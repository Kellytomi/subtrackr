#!/bin/bash

# SubTrackr Automated Release Script
# This script automatically bumps the version and creates a Shorebird release

set -e  # Exit on any error

echo "🚀 SubTrackr Automated Release Script"
echo "====================================="

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found. Please run this script from the project root."
    exit 1
fi

# Read current version from pubspec.yaml
CURRENT_VERSION=$(grep "^version:" pubspec.yaml | cut -d' ' -f2)
echo "📋 Current version: $CURRENT_VERSION"

# Split version into parts (e.g., 1.0.6+1 -> 1.0.6 and 1)
VERSION_NAME=$(echo $CURRENT_VERSION | cut -d'+' -f1)
BUILD_NUMBER=$(echo $CURRENT_VERSION | cut -d'+' -f2)

# Increment build number
NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
NEW_VERSION="${VERSION_NAME}+${NEW_BUILD_NUMBER}"

echo "🔢 New version: $NEW_VERSION"

# Ask for confirmation
read -p "🤔 Do you want to bump to version $NEW_VERSION and create a Shorebird release? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Release cancelled."
    exit 1
fi

# Update version in pubspec.yaml
echo "📝 Updating pubspec.yaml..."
sed -i.bak "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml
rm pubspec.yaml.bak

echo "✅ Version updated to $NEW_VERSION"

# Clean Flutter build cache
echo "🧹 Cleaning Flutter build cache..."
flutter clean > /dev/null 2>&1

# Run Shorebird release (APK for Firebase App Distribution)
echo "🐦 Creating Shorebird release..."
shorebird release android --artifact apk

echo ""
echo "✅ Release completed successfully!"
echo "📦 APK file location: build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "📋 Next steps:"
echo "   1. Run './scripts/distribute.sh' to distribute via Firebase App Distribution"
echo "   2. Later, use 'shorebird patch android --release-version=$NEW_VERSION' for updates"
echo ""
echo "🎉 Happy releasing!" 