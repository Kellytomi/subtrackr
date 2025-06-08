import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/email_scanner_service.dart';

class EmailDetectionPage extends StatefulWidget {
  const EmailDetectionPage({super.key});

  @override
  State<EmailDetectionPage> createState() => _EmailDetectionPageState();
}

class _EmailDetectionPageState extends State<EmailDetectionPage> {
  final AuthService _authService = AuthService();
  final EmailScannerService _emailService = EmailScannerService();
  
  bool _isLoading = false;
  bool _isScanning = false;
  GoogleSignInAccount? _currentUser;
  List<DetectedSubscription> _detectedSubscriptions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    setState(() => _isLoading = true);
    
    try {
      await _authService.initialize();
      setState(() {
        _currentUser = _authService.currentUser;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to initialize authentication: $error';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    
    try {
      final account = await _authService.signIn();
      setState(() {
        _currentUser = account;
        _errorMessage = null;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Sign in failed: $error';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    
    try {
      await _authService.signOut();
      setState(() {
        _currentUser = null;
        _detectedSubscriptions = [];
        _errorMessage = null;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Sign out failed: $error';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _scanEmails() async {
    if (_currentUser == null) return;
    
    setState(() => _isScanning = true);
    
    try {
      // Check if we have Gmail permissions
      final hasPermissions = await _authService.hasGmailPermissions();
      if (!hasPermissions) {
        final granted = await _authService.requestGmailPermissions();
        if (!granted) {
          setState(() {
            _errorMessage = 'Gmail permissions are required to scan emails';
          });
          return;
        }
      }
      
      // Scan emails for subscriptions
      final subscriptions = await _emailService.scanForSubscriptions(
        maxResults: 50,
        daysBack: 90,
      );
      
      setState(() {
        _detectedSubscriptions = subscriptions;
        _errorMessage = null;
      });
      
      if (subscriptions.isEmpty) {
        _showSnackBar('No subscriptions found in your recent emails', isError: false);
      } else {
        _showSnackBar('Found ${subscriptions.length} potential subscriptions!', isError: false);
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Error scanning emails: $error';
      });
    } finally {
      setState(() => _isScanning = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Subscription Detection'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildIntroSection(),
            const SizedBox(height: 24),
            _buildAuthSection(),
            if (_currentUser != null) ...[
              const SizedBox(height: 24),
              _buildScanSection(),
              const SizedBox(height: 24),
              _buildResultsSection(),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIntroSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Smart Email Detection',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Automatically detect subscriptions from your email receipts and billing statements. '
              'This feature scans your Gmail for subscription-related emails and extracts '
              'subscription details to save you time.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              '🔒 Your privacy is important: We only read subscription-related emails and never store your email content.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Google Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_currentUser == null)
              _buildSignInButton()
            else
              _buildUserInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _signIn,
        icon: _isLoading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.login),
        label: Text(_isLoading ? 'Signing in...' : 'Sign in with Google'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage: _currentUser!.photoUrl != null
                ? NetworkImage(_currentUser!.photoUrl!)
                : null,
            child: _currentUser!.photoUrl == null
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(_currentUser!.displayName ?? 'Unknown'),
          subtitle: Text(_currentUser!.email),
          trailing: IconButton(
            onPressed: _isLoading ? null : _signOut,
            icon: const Icon(Icons.logout),
          ),
        ),
      ],
    );
  }

  Widget _buildScanSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Email Scanning',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scan your recent emails (last 90 days) for subscription receipts and billing statements.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? null : _scanEmails,
                icon: _isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.email_outlined),
                label: Text(_isScanning ? 'Scanning emails...' : 'Scan My Emails'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_detectedSubscriptions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detected Subscriptions (${_detectedSubscriptions.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _detectedSubscriptions.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final subscription = _detectedSubscriptions[index];
                return _buildSubscriptionTile(subscription);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to add subscriptions page with detected data
                  _showSnackBar('Feature coming soon: Add selected subscriptions', isError: false);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Selected Subscriptions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionTile(DetectedSubscription subscription) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Icon(
          Icons.subscriptions,
          color: Theme.of(context).primaryColor,
        ),
      ),
      title: Text(
        subscription.serviceName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${subscription.currency} ${subscription.amount.toStringAsFixed(2)} / ${subscription.billingCycle.name}'),
          Text(
            'From: ${subscription.detectedFrom}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (subscription.emailDate != null)
            Text(
              'Date: ${subscription.emailDate!.toLocal().toString().split(' ')[0]}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
      trailing: Checkbox(
        value: true, // TODO: Implement selection state
        onChanged: (value) {
          // TODO: Implement selection logic
        },
      ),
    );
  }

  Widget _buildErrorSection() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 