/// Brandfetch Configuration
/// 
/// To get high-quality logos from Brandfetch, you need a free client ID.
/// 
/// Steps to set up:
/// 1. Go to: https://developers.brandfetch.com/register
/// 2. Create a free developer account
/// 3. Get your client ID from the dashboard
/// 4. Replace 'YOUR_CLIENT_ID' below with your actual client ID
/// 
/// Note: The app will work without a client ID but logos may not load optimally.

class BrandfetchConfig {
  // Replace 'YOUR_CLIENT_ID' with your actual Brandfetch client ID
  static const String clientId = '1idW26h6Or0WfUZJfLU';
  
  // Check if client ID is configured
  static bool get isConfigured => clientId != 'YOUR_CLIENT_ID';
  
  // Get the registration URL
  static const String registrationUrl = 'https://developers.brandfetch.com/register';
} 