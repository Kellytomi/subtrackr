# SubTrackr

A modern Flutter subscription tracking app that helps you manage and monitor all your subscriptions in one place.

## Features

- 📱 **Cross-platform**: Native iOS and Android apps
- 💰 **Multi-currency support**: Track subscriptions in different currencies
- 🔄 **Auto-sync**: Cloud synchronization with Supabase backend
- 🔔 **Smart notifications**: Local reminders + promotional push notifications via OneSignal
- 📊 **Price tracking**: Monitor subscription price changes over time
- 🎨 **Modern UI**: Beautiful, responsive design with dark/light theme support
- 🔐 **Secure authentication**: Email/password and social login support
- 📈 **Statistics**: Detailed spending analytics and insights
- 🚀 **Auto-updates**: Over-the-air updates via Shorebird

## Prerequisites

- Flutter 3.x
- Dart 3.x
- Android Studio / Xcode for mobile development
- [Shorebird CLI](https://shorebird.dev) for auto-updates
- [Firebase CLI](https://firebase.google.com/docs/cli) for distribution

## Quick Setup

1. **Clone the repository**
   ```bash
   git clone [repository-url]
   cd subtrackr
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment** (optional)
   ```bash
   cp .env.example .env
   # Edit .env with your credentials if needed
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Development Workflow

This project includes automated scripts for streamlined development:

### 🚀 Release Management
```bash
# Create a new release with automatic version bumping
./scripts/release.sh

# Create a patch for existing release
./scripts/patch.sh

# Distribute via Firebase App Distribution
./scripts/distribute.sh
```

### 🧹 Project Maintenance
```bash
# Clean up build artifacts and optimize project
./scripts/cleanup.sh

# Run comprehensive security check
./scripts/security_check.sh
```

## Build & Deployment

### Development Build
```bash
flutter build apk --debug
# or
flutter build ios --debug
```

### Production Release
```bash
# Use the automated release script
./scripts/release.sh

# Or manually with Shorebird
shorebird release android
shorebird release ios
```

### Distribution
```bash
# Distribute to testers via Firebase
./scripts/distribute.sh

# Or manually
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app [APP_ID] --groups "testers"
```

## Architecture

- **State Management**: Provider pattern
- **Backend**: Supabase (PostgreSQL, Auth, Real-time)
- **Local Storage**: SQLite with drift
- **Push Notifications**: OneSignal
- **Auto-updates**: Shorebird
- **Authentication**: Supabase Auth with social providers

## Project Structure

```
lib/
├── core/                 # Core functionality and utilities
│   ├── config/          # App configuration
│   ├── constants/       # App constants
│   ├── theme/           # Theme and styling
│   ├── utils/           # Utility functions
│   └── widgets/         # Reusable core widgets
├── data/                # Data layer
│   ├── models/          # Data models
│   ├── repositories/    # Repository implementations
│   └── services/        # External services
├── domain/              # Domain layer
│   └── entities/        # Business entities
└── presentation/        # UI layer
    ├── pages/           # Screen implementations
    ├── providers/       # State management
    └── widgets/         # UI components
```

## Security

- All sensitive configuration is environment-based
- Credentials are properly gitignored
- Regular security audits via automated scripts
- Supabase RLS (Row Level Security) for data protection

## Contributing

1. Run security check before committing: `./scripts/security_check.sh`
2. Follow Flutter/Dart best practices
3. Ensure tests pass: `flutter test`
4. Use conventional commit messages

## Scripts Reference

| Script | Purpose |
|--------|---------|
| `release.sh` | Auto-bump version and create Shorebird release |
| `patch.sh` | Create patch for existing release |
| `distribute.sh` | Distribute via Firebase App Distribution |
| `cleanup.sh` | Remove build artifacts and optimize project |
| `security_check.sh` | Comprehensive security verification |

## License

This project is licensed under the MIT License - see the LICENSE file for details.
