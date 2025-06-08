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
    } catch (error) {
      print('Error initializing Gmail API: $error');
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