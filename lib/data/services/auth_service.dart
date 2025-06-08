import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:http/http.dart' as http;

/// Service for handling Google authentication and Gmail API access
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      gmail.GmailApi.gmailReadonlyScope,
    ],
  );

  GoogleSignInAccount? _currentUser;
  gmail.GmailApi? _gmailApi;

  /// Current signed-in user
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Gmail API instance
  gmail.GmailApi? get gmailApi => _gmailApi;

  /// Check if user is currently signed in
  bool get isSignedIn => _currentUser != null;

  /// Initialize the auth service
  Future<void> initialize() async {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      _currentUser = account;
      if (account != null) {
        _initializeGmailApi(account);
      } else {
        _gmailApi = null;
      }
    });

    // Try to sign in silently
    await _googleSignIn.signInSilently();
  }

  /// Sign in with Google
  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        await _initializeGmailApi(account);
      }
      return account;
    } catch (error) {
      print('Error signing in: $error');
      
      // Handle the known type cast error - check if sign-in actually succeeded
      if (error.toString().contains('PigeonUserDetails') || 
          error.toString().contains('type cast') || 
          error.toString().contains('List<Object?>')) {
        print('🔄 Detected type cast error, checking if sign-in actually succeeded...');
        
        // Wait a moment for the sign-in to complete internally
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Try to get the current user from Google Sign-In
        try {
          final currentUser = _googleSignIn.currentUser;
          if (currentUser != null) {
            print('✅ Sign-in succeeded despite error! User: ${currentUser.email}');
            _currentUser = currentUser;
            await _initializeGmailApi(currentUser);
            return currentUser;
          }
        } catch (e) {
          print('❌ Failed to get current user after workaround: $e');
        }
      }
      
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _gmailApi = null;
  }

  /// Initialize Gmail API with authenticated user
  Future<void> _initializeGmailApi(GoogleSignInAccount account) async {
    try {
      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      _gmailApi = gmail.GmailApi(authenticateClient);
      print('✅ Gmail API initialized successfully');
    } catch (error) {
      print('❌ Error initializing Gmail API: $error');
      _gmailApi = null;
    }
  }

  /// Check if user has granted Gmail permissions
  Future<bool> hasGmailPermissions() async {
    if (_currentUser == null) return false;
    
    try {
      final scopes = await _googleSignIn.requestScopes([
        gmail.GmailApi.gmailReadonlyScope,
      ]);
      return scopes;
    } catch (error) {
      print('Error checking Gmail permissions: $error');
      return false;
    }
  }

  /// Request Gmail permissions
  Future<bool> requestGmailPermissions() async {
    if (_currentUser == null) return false;
    
    try {
      final scopes = await _googleSignIn.requestScopes([
        gmail.GmailApi.gmailReadonlyScope,
      ]);
      
      if (scopes && _currentUser != null) {
        await _initializeGmailApi(_currentUser!);
      }
      
      return scopes;
    } catch (error) {
      print('Error requesting Gmail permissions: $error');
      return false;
    }
  }

  /// Refresh authentication and reinitialize Gmail API
  Future<bool> refreshAuthentication() async {
    if (_currentUser == null) return false;
    
    try {
      print('🔄 Refreshing authentication...');
      
      // Clear current API instance
      _gmailApi = null;
      
      // Re-authenticate
      await _currentUser!.clearAuthCache();
      await _initializeGmailApi(_currentUser!);
      
      // Test the API with a simple call
      if (_gmailApi != null) {
        await _gmailApi!.users.getProfile('me');
        print('✅ Authentication refresh successful');
        return true;
      }
      
      return false;
    } catch (error) {
      print('❌ Error refreshing authentication: $error');
      return false;
    }
  }
}

/// HTTP client with Google authentication headers
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
} 