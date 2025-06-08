import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/theme_provider.dart';
import '../../../data/services/cloud_sync_service.dart';
import '../../../data/services/settings_service.dart';
import '../../../core/constants/app_constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _isSignUp = false;
  bool _showEmailAuth = false;
  bool _obscurePassword = true;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    
    try {
      final cloudSyncService = Provider.of<CloudSyncService>(context, listen: false);
      final settingsService = Provider.of<SettingsService>(context, listen: false);
      final success = await cloudSyncService.signInWithGoogle();
      
      if (success && mounted) {
        // Mark auth flow as complete
        await settingsService.setAuthFlowComplete(true);
        // Navigate to next step (currency selection or home)
        _navigateToNextStep();
      } else if (mounted) {
        _showErrorSnackBar('Sign in was cancelled or failed');
      }
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Error signing in: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _continueAsGuest() async {
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    // Mark auth flow as complete (user chose guest mode)
    await settingsService.setAuthFlowComplete(true);
    // Navigate to next step
    _navigateToNextStep();
  }

  void _navigateToNextStep() {
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    final currencyCode = settingsService.getCurrencyCode();
    
    if (currencyCode == null || currencyCode.isEmpty) {
      // Currency not set, go to currency selection
      Navigator.pushReplacementNamed(context, AppConstants.CURRENCY_SELECTION_ROUTE);
    } else {
      // Everything complete, go to main app
      Navigator.pushReplacementNamed(context, AppConstants.HOME_ROUTE);
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final cloudSyncService = Provider.of<CloudSyncService>(context, listen: false);
      
      if (_isSignUp) {
        await cloudSyncService.createAccountWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        _showSuccessSnackBar('Account created successfully!');
      } else {
        await cloudSyncService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        _showSuccessSnackBar('Signed in successfully!');
      }
      
      if (mounted) {
        // Mark auth flow as complete
        final settingsService = Provider.of<SettingsService>(context, listen: false);
        await settingsService.setAuthFlowComplete(true);
        // Navigate to next step
        _navigateToNextStep();
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Authentication failed';
      
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'email-already-in-use':
          message = 'Email is already registered';
          break;
        case 'weak-password':
          message = 'Password should be at least 6 characters';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address';
          break;
        case 'too-many-requests':
          message = 'Too many failed attempts. Try again later';
          break;
        default:
          message = e.message ?? 'Authentication failed';
      }
      
      if (mounted) {
        _showErrorSnackBar(message);
      }
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Error: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your email address first');
      return;
    }
    
    try {
      final cloudSyncService = Provider.of<CloudSyncService>(context, listen: false);
      await cloudSyncService.sendPasswordResetEmail(_emailController.text.trim());
      
      if (mounted) {
        _showSuccessSnackBar('Password reset email sent!');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to send reset email';
      
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address';
          break;
        default:
          message = e.message ?? 'Failed to send reset email';
      }
      
      if (mounted) {
        _showErrorSnackBar(message);
      }
    }
  }

  void _toggleAuthMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _passwordController.clear();
    });
  }

  void _toggleEmailAuth() {
    setState(() {
      _showEmailAuth = !_showEmailAuth;
      if (!_showEmailAuth) {
        _emailController.clear();
        _passwordController.clear();
        _isSignUp = false;
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    // Set system UI overlay style to match the page
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: colorScheme.surface,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.secondary.withOpacity(0.05),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Header
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Icon
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colorScheme.primary, colorScheme.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.subscriptions_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // App Name
                        Text(
                          AppConstants.APP_NAME,
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            letterSpacing: -1,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Subtitle
                        Text(
                          'Track and manage your subscriptions\nwith ease',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurface.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Auth Buttons
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Features List
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colorScheme.outline.withOpacity(0.1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildFeatureItem(
                                  Icons.auto_awesome,
                                  'Smart Email Detection',
                                  'Automatically find subscriptions in your Gmail',
                                  Colors.orange,
                                ),
                                const SizedBox(height: 12),
                                _buildFeatureItem(
                                  Icons.cloud_sync_rounded,
                                  'Cloud Sync',
                                  'Sync your data across all devices',
                                  Colors.blue,
                                ),
                                const SizedBox(height: 12),
                                _buildFeatureItem(
                                  Icons.analytics_rounded,
                                  'Smart Analytics',
                                  'Get insights into your spending patterns',
                                  Colors.green,
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Email/Password Form (if enabled)
                          if (_showEmailAuth) ...[
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Email Field
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.email_outlined, color: colorScheme.primary),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Password Field
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: Icon(Icons.lock_outlined, color: colorScheme.primary),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                          color: colorScheme.primary,
                                        ),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      if (_isSignUp && value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Forgot Password (only for sign in)
                                  if (!_isSignUp)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _sendPasswordReset,
                                        child: Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: colorScheme.primary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Email Auth Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _signInWithEmail,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 3,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : Text(
                                              _isSignUp ? 'Create Account' : 'Sign In',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Toggle Sign Up/In
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _isSignUp ? "Already have an account? " : "Don't have an account? ",
                                        style: TextStyle(
                                          color: colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _toggleAuthMode,
                                        child: Text(
                                          _isSignUp ? 'Sign In' : 'Sign Up',
                                          style: TextStyle(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Back to Social Auth
                                  TextButton.icon(
                                    onPressed: _toggleEmailAuth,
                                    icon: Icon(Icons.arrow_back, color: colorScheme.primary),
                                    label: Text(
                                      'Back to other options',
                                      style: TextStyle(color: colorScheme.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Google Sign In Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _signInWithGoogle,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.login, color: Colors.white),
                                label: Text(
                                  _isLoading ? 'Signing in...' : 'Sign in with Google',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 3,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Email/Password Sign In Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _toggleEmailAuth,
                                icon: Icon(Icons.email_outlined, color: colorScheme.primary),
                                label: const Text(
                                  'Sign in with Email',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.primary,
                                  side: BorderSide(color: colorScheme.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // OR Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: colorScheme.outline.withOpacity(0.3))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withOpacity(0.6),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: colorScheme.outline.withOpacity(0.3))),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Continue as Guest
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _continueAsGuest,
                                icon: Icon(
                                  Icons.person_outline,
                                  color: colorScheme.primary,
                                ),
                                label: const Text(
                                  'Continue as Guest',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.primary,
                                  side: BorderSide(color: colorScheme.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 20),
                          
                          // Guest Mode Note
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.amber.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.amber.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Guest mode: Data saved locally only. Sign in to sync across devices.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.amber.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 