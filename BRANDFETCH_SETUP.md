# Brandfetch Logo Service Setup

SubTrackr uses Brandfetch to automatically display high-quality logos for your subscriptions. To get the best experience, you'll need a free Brandfetch client ID.

## Why Brandfetch?

- ✅ **Free**: 1,000,000 requests per month at no cost
- ✅ **High Quality**: Better logos than other services  
- ✅ **Automatic Updates**: Logos update when companies change them
- ✅ **Comprehensive**: Covers most subscription services
- ✅ **Fast**: CDN-delivered for quick loading

## Setup Instructions

### 1. Get Your Free Client ID

1. Go to: https://developers.brandfetch.com/register
2. Create a free developer account (takes 30 seconds)
3. Access your dashboard to get your client ID

### 2. Configure SubTrackr

1. Open `lib/core/config/brandfetch_config.dart`
2. Replace `'YOUR_CLIENT_ID'` with your actual client ID:

```dart
class BrandfetchConfig {
  // Replace with your actual client ID from Brandfetch dashboard
  static const String clientId = 'your-actual-client-id-here';
  
  // ... rest of the file
}
```

### 3. Rebuild the App

After updating the client ID, rebuild your app:

```bash
flutter clean
flutter pub get
flutter run
```

## Without Client ID

The app will still work without a client ID, but:
- Some logos may not load
- You'll see debug messages in the console
- Overall logo quality may be reduced

## Benefits After Setup

Once configured, you'll get:
- 🎯 Perfect logos for Apple Music, Netflix, Spotify, Disney+, etc.
- 🚀 Automatic logo suggestions when adding subscriptions
- 📱 Consistent high-quality branding throughout the app
- 🔄 Logos that stay up-to-date automatically

## Support

If you have issues:
1. Check that your client ID is correct
2. Make sure you've rebuilt the app after configuration
3. Verify your internet connection
4. Check Brandfetch status: https://status.brandfetch.com

For Brandfetch-specific issues, contact: https://docs.brandfetch.com/docs/getting-help 