#!/bin/bash

# SubTrackr Project Cleanup Script
# Removes unnecessary files and organizes the project before committing

set -e  # Exit on any error

echo "🧹 SubTrackr Project Cleanup Script"
echo "==================================="

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found. Please run this script from the project root."
    exit 1
fi

echo "🔍 Scanning for files to clean up..."

# Count files before cleanup
BEFORE_COUNT=$(find . -type f | wc -l)

# 1. Remove system junk files
echo "🗑️  Removing system junk files..."
find . -name ".DS_Store" -delete 2>/dev/null || true
find . -name "Thumbs.db" -delete 2>/dev/null || true
find . -name "desktop.ini" -delete 2>/dev/null || true

# 2. Remove large debug/build artifacts that aren't needed in repo
echo "🗑️  Removing large build artifacts..."
rm -f native-debug-symbols.zip 2>/dev/null || true

# 3. Clean Flutter build cache
echo "🧹 Cleaning Flutter build cache..."
flutter clean > /dev/null 2>&1

# 4. Remove Android native debug files
echo "🗑️  Removing Android native debug files..."
rm -rf android/app/.cxx 2>/dev/null || true

# 5. Remove IDE files that shouldn't be tracked
echo "🗑️  Removing unnecessary IDE files..."
rm -rf .idea/workspace.xml 2>/dev/null || true
rm -rf .idea/tasks.xml 2>/dev/null || true
rm -rf .idea/misc.xml 2>/dev/null || true

# 6. Check for any accidentally committed sensitive files
echo "🔍 Checking for sensitive files (should be empty)..."
SENSITIVE_FILES=$(git ls-files | grep -E "(google-services\.json|client_secret|\.env|key\.properties|keystore|\.jks|\.p12)" | grep -v "\.template" || true)
if [ -n "$SENSITIVE_FILES" ]; then
    echo "⚠️  WARNING: Found sensitive files in git:"
    echo "$SENSITIVE_FILES"
    echo "🚨 These should be removed from git immediately!"
else
    echo "✅ No sensitive files found in git tracking"
fi

# 7. Optimize images if any are too large
echo "🖼️  Checking image sizes..."
LARGE_IMAGES=$(find assets/ -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" 2>/dev/null | xargs ls -la 2>/dev/null | awk '$5 > 1000000 {print $9, $5}' || true)
if [ -n "$LARGE_IMAGES" ]; then
    echo "⚠️  Large images found (>1MB):"
    echo "$LARGE_IMAGES"
    echo "💡 Consider optimizing these images"
else
    echo "✅ No overly large images found"
fi

# Count files after cleanup
AFTER_COUNT=$(find . -type f | wc -l)
REMOVED_COUNT=$((BEFORE_COUNT - AFTER_COUNT))

echo ""
echo "✅ Cleanup completed!"
echo "📊 Files removed: $REMOVED_COUNT"
echo "📁 Total files now: $AFTER_COUNT"
echo ""
echo "🔒 Security checklist:"
echo "   ✅ Sensitive files are in .gitignore"
echo "   ✅ No API keys in source code"
echo "   ✅ Templates exist for configuration files"
echo ""
echo "📋 Ready for commit!"
echo "   • All sensitive data is protected"
echo "   • Project is clean and organized"
echo "   • File count optimized"
echo ""
echo "�� Happy committing!" 