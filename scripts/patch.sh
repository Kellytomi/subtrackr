#!/bin/bash

# SubTrackr Automated Patch Script
# This script creates a Shorebird patch for the current release

set -e  # Exit on any error

echo "🔧 SubTrackr Automated Patch Script"
echo "==================================="

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found. Please run this script from the project root."
    exit 1
fi

# Read current version from pubspec.yaml
CURRENT_VERSION=$(grep "^version:" pubspec.yaml | cut -d' ' -f2)
echo "📋 Current version: $CURRENT_VERSION"

# Ask for confirmation
read -p "🤔 Do you want to create a patch for version $CURRENT_VERSION? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Patch cancelled."
    exit 1
fi

echo "🔨 Creating Shorebird patch..."
shorebird patch android --release-version=$CURRENT_VERSION

echo ""
echo "✅ Patch created successfully!"
echo "🎯 Patch for version: $CURRENT_VERSION"
echo ""
echo "📱 Users with this version will automatically receive the patch!"
echo "�� Happy patching!" 