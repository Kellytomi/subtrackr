#!/bin/bash

# SubTrackr Security Check Script
# Verifies no sensitive data will be committed

set -e  # Exit on any error

echo "🔒 SubTrackr Security Check"
echo "=========================="

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found. Please run this script from the project root."
    exit 1
fi

ISSUES_FOUND=0

echo "🔍 Scanning staged files for security issues..."

# 1. Check for sensitive files in staged changes
echo "1️⃣  Checking staged files for sensitive content..."
STAGED_SENSITIVE=$(git diff --cached --name-only | grep -E "(google-services\.json|client_secret|key\.properties|keystore|\.jks|\.p12)" | grep -v "\.template\|\.example" || true)
# Allow .env.example but not .env files
STAGED_ENV=$(git diff --cached --name-only | grep "\.env" | grep -v "\.env\.example" || true)
if [ -n "$STAGED_SENSITIVE" ] || [ -n "$STAGED_ENV" ]; then
    echo "🚨 CRITICAL: Sensitive files staged for commit:"
    [ -n "$STAGED_SENSITIVE" ] && echo "$STAGED_SENSITIVE"
    [ -n "$STAGED_ENV" ] && echo "$STAGED_ENV"
    echo "   Run: git reset HEAD <file> to unstage"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo "   ✅ No sensitive files in staging area"
fi

# 2. Check for hardcoded secrets in staged code
echo "2️⃣  Checking staged code for hardcoded secrets..."
STAGED_SECRETS=$(git diff --cached | grep -i -E "(api[_-]?key|secret|password|token)[\"']?\s*[:=]\s*[\"'][^\"']{8,}" || true)
if [ -n "$STAGED_SECRETS" ]; then
    echo "🚨 CRITICAL: Potential hardcoded secrets found:"
    echo "$STAGED_SECRETS"
    echo "   Review and remove hardcoded secrets"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo "   ✅ No hardcoded secrets detected"
fi

# 3. Check that sensitive files exist but are ignored
echo "3️⃣  Verifying sensitive files are properly ignored..."
MISSING_GITIGNORE=""

# Check key files exist but are ignored
if [ -f "android/app/google-services.json" ]; then
    if git check-ignore android/app/google-services.json >/dev/null 2>&1; then
        echo "   ✅ google-services.json exists and is ignored"
    else
        echo "   ⚠️  google-services.json exists but not ignored!"
        MISSING_GITIGNORE="$MISSING_GITIGNORE android/app/google-services.json"
    fi
fi

if find . -name "client_secret*.json" -type f | head -1 | read; then
    CLIENT_SECRET_FILE=$(find . -name "client_secret*.json" -type f | head -1)
    if git check-ignore "$CLIENT_SECRET_FILE" >/dev/null 2>&1; then
        echo "   ✅ client_secret file exists and is ignored"
    else
        echo "   ⚠️  client_secret file exists but not ignored!"
        MISSING_GITIGNORE="$MISSING_GITIGNORE $CLIENT_SECRET_FILE"
    fi
fi

if [ -n "$MISSING_GITIGNORE" ]; then
    echo "🚨 Files need to be added to .gitignore:$MISSING_GITIGNORE"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# 4. Check .gitignore has proper patterns
echo "4️⃣  Verifying .gitignore patterns..."
REQUIRED_PATTERNS=("google-services.json" "client_secret" "*.env" "**/*secret*" "key.properties")
MISSING_PATTERNS=""

for pattern in "${REQUIRED_PATTERNS[@]}"; do
    if ! grep -q "$pattern" .gitignore; then
        MISSING_PATTERNS="$MISSING_PATTERNS $pattern"
    fi
done

if [ -n "$MISSING_PATTERNS" ]; then
    echo "   ⚠️  Missing .gitignore patterns:$MISSING_PATTERNS"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
else
    echo "   ✅ All required .gitignore patterns present"
fi

# 5. Check for exposed Supabase anon keys (should use environment variables)
echo "5️⃣  Checking for exposed configuration..."
EXPOSED_CONFIG=$(git diff --cached | grep -i "supabase.*key\|anonkey" | grep -v "fromEnvironment\|getenv\|# Check for exposed\|Consider using environment\|your_supabase\|defaultValue\|SUPABASE_ANON_KEY.*=" || true)
if [ -n "$EXPOSED_CONFIG" ]; then
    echo "   ⚠️  Potentially exposed configuration:"
    echo "$EXPOSED_CONFIG"
    echo "   Consider using environment variables"
    # Not critical for Supabase anon keys, but good practice
else
    echo "   ✅ No exposed configuration detected"
fi

# 6. Final file count check
echo "6️⃣  Verifying commit size..."
STAGED_COUNT=$(git diff --cached --name-only | wc -l)
if [ "$STAGED_COUNT" -gt 50 ]; then
    echo "   ⚠️  Large commit: $STAGED_COUNT files staged"
    echo "   Consider breaking into smaller commits"
else
    echo "   ✅ Reasonable commit size: $STAGED_COUNT files"
fi

echo ""
echo "=================================="
if [ "$ISSUES_FOUND" -eq 0 ]; then
    echo "🎉 SECURITY CHECK PASSED!"
    echo "✅ Safe to commit - no security issues found"
    echo ""
    echo "📋 Summary:"
    echo "   • No sensitive files staged"
    echo "   • No hardcoded secrets detected"
    echo "   • Proper .gitignore configuration"
    echo "   • Good commit practices followed"
    exit 0
else
    echo "🚨 SECURITY CHECK FAILED!"
    echo "❌ Found $ISSUES_FOUND security issue(s)"
    echo ""
    echo "🛠️  Fix the issues above before committing!"
    echo "   Then run this script again to verify"
    exit 1
fi 