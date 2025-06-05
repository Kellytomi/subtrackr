# Security Setup Guide

## 🔒 **IMPORTANT: Protect Your API Keys!**

This project uses Firebase/Google Services that require API keys. **NEVER commit these keys to git!**

## Setup Instructions

### 1. Google Services Configuration

1. Copy the template file:
   ```bash
   cp android/app/google-services.json.template android/app/google-services.json
   ```

2. Replace the placeholder values with your actual Firebase project configuration:
   - Get your config from: https://console.firebase.google.com/
   - Project Settings → General → Your apps → google-services.json

3. **VERIFY** the file is in `.gitignore` before committing anything!

### 2. Environment Variables

For any other API keys or secrets, use environment variables:

1. Create a `.env` file (already in `.gitignore`):
   ```
   GOOGLE_API_KEY=your_api_key_here
   ANOTHER_SECRET=your_secret_here
   ```

2. Load in your Flutter app using `flutter_dotenv` package.

## 🚨 If You Accidentally Commit Secrets

1. **IMMEDIATELY** revoke/regenerate the exposed keys at:
   - Google Cloud Console: https://console.cloud.google.com/apis/credentials
   - Firebase Console: https://console.firebase.google.com/

2. Remove from git history:
   ```bash
   git rm --cached path/to/secret/file
   git commit -m "Remove accidentally committed secrets"
   git push --force-with-lease
   ```

3. Update `.gitignore` to prevent future accidents.

## Best Practices

- ✅ Use `.gitignore` for all secret files
- ✅ Use environment variables for runtime secrets  
- ✅ Use template files to show structure
- ✅ Regularly audit your repository for accidentally committed secrets
- ❌ Never commit `google-services.json`, `.env`, or any file with API keys
- ❌ Never hardcode secrets in source code

## Verification

Before each commit, run:
```bash
git diff --cached | grep -i -E "(api[_-]?key|secret|password|token)"
```

If this returns anything, **DO NOT COMMIT!** 