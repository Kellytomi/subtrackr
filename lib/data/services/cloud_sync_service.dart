import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/subscription.dart';
import 'auth_service.dart';
import 'settings_service.dart';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final SettingsService _settingsService = SettingsService();
  
  bool _isInitialized = false;
  StreamSubscription<QuerySnapshot>? _syncSubscription;
  
  // Callback for when subscriptions are updated from cloud
  Function(List<Subscription>)? onSubscriptionsUpdated;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Check if Firebase is available
      if (_auth.app.isAutomaticDataCollectionEnabled != null) {
        _isInitialized = true;
        print('CloudSyncService initialized');
      }
    } catch (e) {
      print('CloudSyncService initialization failed (Firebase not available): $e');
      _isInitialized = false;
      // Don't rethrow - allow app to continue without cloud sync
    }
  }

  bool get isUserSignedIn {
    final googleSignedIn = _authService.isSignedIn;
    final firebaseSignedIn = _auth.currentUser != null;
    
    // If Firebase user exists, we consider the user signed in
    // This handles cases where Google Sign-In has type cast errors but Firebase auth succeeded
    final result = firebaseSignedIn && (googleSignedIn || _auth.currentUser != null);
    
    print('🔍 CloudSyncService.isUserSignedIn debug:');
    print('   Google signed in: $googleSignedIn');
    print('   Firebase user: ${_auth.currentUser?.uid}');
    print('   Firebase email: ${_auth.currentUser?.email}');
    print('   Overall result: $result (prioritizing Firebase auth)');
    
    return result;
  }

  String? get userId => _auth.currentUser?.uid;
  
  /// Get the current Firebase user
  User? get currentFirebaseUser => _auth.currentUser;

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      print('🔄 Starting email/password sign-in for: $email');
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Email/password sign-in successful: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('❌ Email/password sign-in failed: ${e.code} - ${e.message}');
      throw e;
    } catch (e) {
      print('❌ Unexpected error during email/password sign-in: $e');
      throw e;
    }
  }

  /// Create account with email and password
  Future<UserCredential?> createAccountWithEmailAndPassword(String email, String password) async {
    try {
      print('🔄 Creating account for: $email');
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Account creation successful: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('❌ Account creation failed: ${e.code} - ${e.message}');
      throw e;
    } catch (e) {
      print('❌ Unexpected error during account creation: $e');
      throw e;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      print('🔄 Sending password reset email to: $email');
      
      await _auth.sendPasswordResetEmail(email: email);
      
      print('✅ Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      print('❌ Failed to send password reset email: ${e.code} - ${e.message}');
      throw e;
    } catch (e) {
      print('❌ Unexpected error sending password reset email: $e');
      throw e;
    }
  }

  /// Sign in to Firebase using Google Sign-In
  Future<bool> signInWithGoogle() async {
    try {
      print('🔄 Starting Google Sign-In process...');
      
      // Check if already signed in to Google
      if (_authService.isSignedIn && _authService.currentUser != null) {
        print('🔍 Already signed in to Google, using existing account');
        final googleUser = _authService.currentUser!;
        
        try {
          // Get Google Auth credentials
          final googleAuth = await googleUser.authentication;

          // Sign in to Firebase with Google credentials
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          final userCredential = await _auth.signInWithCredential(credential);
          print('✅ Signed in to Firebase using existing Google account: ${userCredential.user?.email}');
          
          return userCredential.user != null;
        } catch (e) {
          print('❌ Error using existing Google account for Firebase: $e');
          // Fall through to try fresh sign-in
        }
      }
      
      // Try fresh Google Sign-In
      print('🔄 Attempting fresh Google Sign-In...');
      GoogleSignInAccount? googleUser;
      bool hadTypecastError = false;
      
      try {
        googleUser = await _authService.signIn();
        print('✅ Google Sign-In completed successfully');
      } catch (e) {
        print('❌ Google Sign-In failed with error: $e');
        
        // If it's the known type cast error, try alternative approach
        if (e.toString().contains('PigeonUserDetails') || e.toString().contains('type cast') || e.toString().contains('List<Object?>')) {
          print('🔄 Detected type cast error, implementing workaround...');
          hadTypecastError = true;
          
          // Wait a bit for the sign-in to complete internally
          await Future.delayed(const Duration(milliseconds: 1000));
          
          // Check if sign-in actually succeeded despite the error
          googleUser = _authService.currentUser;
          
          if (googleUser != null) {
            print('✅ Workaround successful! Found user: ${googleUser.email}');
          } else {
            print('❌ Workaround failed, no user found after delay');
          }
        } else {
          // Different error, rethrow
          rethrow;
        }
      }
      
      // If we still don't have a user, but Firebase shows we're authenticated, 
      // it means the sign-in worked but we can't access the Google user object
      if (googleUser == null) {
        print('🔍 No Google user object, but checking if Firebase auth succeeded...');
        
        // Wait a bit more and check Firebase auth status
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (_auth.currentUser != null) {
          print('✅ Firebase auth succeeded despite Google Sign-In error! User: ${_auth.currentUser!.uid}');
          return true; // Success! Firebase auth worked
        }
        
        print('❌ No Google user and no Firebase user - sign-in truly failed');
        return false;
      }

      // We have a Google user, now sign in to Firebase
      try {
        // Get Google Auth credentials
        final googleAuth = await googleUser.authentication;

        // Sign in to Firebase with Google credentials
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        print('✅ Signed in to Firebase: ${userCredential.user?.email}');
        
        return userCredential.user != null;
      } catch (firebaseError) {
        print('❌ Firebase sign-in failed: $firebaseError');
        
        // Even if Firebase credential sign-in fails, check if we're already authenticated
        if (_auth.currentUser != null) {
          print('✅ Already authenticated to Firebase! User: ${_auth.currentUser!.uid}');
          return true;
        }
        
        return false;
      }
    } catch (e) {
      print('❌ Error signing in to Firebase: $e');
      return false;
    }
  }

  /// Sign out from both Firebase and Google
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _authService.signOut();
      stopSync();
      print('✅ Signed out from Firebase and Google');
    } catch (e) {
      print('❌ Error signing out: $e');
    }
  }

  CollectionReference get _userSubscriptionsCollection {
    if (userId == null) {
      throw Exception('User not signed in');
    }
    return _firestore.collection('users').doc(userId).collection('subscriptions');
  }

  /// Start listening to cloud changes
  Future<void> startSync() async {
    if (!isUserSignedIn) {
      print('Cannot start sync: user not signed in');
      return;
    }

    try {
      _syncSubscription?.cancel();
      
      _syncSubscription = _userSubscriptionsCollection.snapshots().listen(
        (snapshot) {
          final subscriptions = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id; // Ensure Firestore document ID is used
            return Subscription.fromMap(data);
          }).toList();
          
          print('Received ${subscriptions.length} subscriptions from cloud');
          onSubscriptionsUpdated?.call(subscriptions);
        },
        onError: (error) {
          print('Error in cloud sync stream: $error');
        },
      );
      
      print('Cloud sync started');
    } catch (e) {
      print('Error starting cloud sync: $e');
    }
  }

  /// Stop listening to cloud changes
  void stopSync() {
    _syncSubscription?.cancel();
    _syncSubscription = null;
    print('Cloud sync stopped');
  }

  /// Upload a subscription to cloud
  Future<void> uploadSubscription(Subscription subscription) async {
    if (!isUserSignedIn) {
      print('Cannot upload subscription: user not signed in');
      return;
    }

    try {
      final data = subscription.toMap();
      data['lastModified'] = FieldValue.serverTimestamp();
      
      await _userSubscriptionsCollection.doc(subscription.id).set(data);
      print('Uploaded subscription: ${subscription.name}');
    } catch (e) {
      print('Error uploading subscription: $e');
      rethrow;
    }
  }

  /// Upload multiple subscriptions to cloud
  Future<void> uploadSubscriptions(List<Subscription> subscriptions) async {
    if (!isUserSignedIn) {
      print('Cannot upload subscriptions: user not signed in');
      return;
    }

    try {
      final batch = _firestore.batch();
      
      for (final subscription in subscriptions) {
        final data = subscription.toMap();
        data['lastModified'] = FieldValue.serverTimestamp();
        
        final docRef = _userSubscriptionsCollection.doc(subscription.id);
        batch.set(docRef, data);
      }
      
      await batch.commit();
      print('Uploaded ${subscriptions.length} subscriptions to cloud');
    } catch (e) {
      print('Error uploading subscriptions: $e');
      rethrow;
    }
  }

  /// Download all subscriptions from cloud
  Future<List<Subscription>> downloadSubscriptions() async {
    if (!isUserSignedIn) {
      print('Cannot download subscriptions: user not signed in');
      return [];
    }

    try {
      final snapshot = await _userSubscriptionsCollection.get();
      
      final subscriptions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure Firestore document ID is used
        return Subscription.fromMap(data);
      }).toList();
      
      print('Downloaded ${subscriptions.length} subscriptions from cloud');
      return subscriptions;
    } catch (e) {
      print('Error downloading subscriptions: $e');
      rethrow;
    }
  }

  /// Delete a subscription from cloud
  Future<void> deleteSubscription(String subscriptionId) async {
    if (!isUserSignedIn) {
      print('Cannot delete subscription: user not signed in');
      return;
    }

    try {
      await _userSubscriptionsCollection.doc(subscriptionId).delete();
      print('Deleted subscription from cloud: $subscriptionId');
    } catch (e) {
      print('Error deleting subscription from cloud: $e');
      rethrow;
    }
  }

  /// Sync local subscriptions with cloud (merge strategy)
  Future<List<Subscription>> syncSubscriptions(List<Subscription> localSubscriptions) async {
    if (!isUserSignedIn) {
      print('Cannot sync subscriptions: user not signed in');
      return localSubscriptions;
    }

    try {
      // Download cloud subscriptions
      final cloudSubscriptions = await downloadSubscriptions();
      
      // Create maps for easier lookup
      final localMap = {for (var sub in localSubscriptions) sub.id: sub};
      final cloudMap = {for (var sub in cloudSubscriptions) sub.id: sub};
      
      final toUpload = <Subscription>[];
      final merged = <Subscription>[];
      
      // Process local subscriptions
      for (final localSub in localSubscriptions) {
        final cloudSub = cloudMap[localSub.id];
        
        if (cloudSub == null) {
          // Local subscription doesn't exist in cloud - upload it
          toUpload.add(localSub);
          merged.add(localSub);
        } else {
          // Both exist - use the more recently modified one
          // For simplicity, we'll prefer cloud version in conflicts
          merged.add(cloudSub);
        }
      }
      
      // Add cloud-only subscriptions
      for (final cloudSub in cloudSubscriptions) {
        if (!localMap.containsKey(cloudSub.id)) {
          merged.add(cloudSub);
        }
      }
      
      // Upload new local subscriptions
      if (toUpload.isNotEmpty) {
        await uploadSubscriptions(toUpload);
      }
      
      print('Sync completed: ${merged.length} total subscriptions');
      return merged;
    } catch (e) {
      print('Error syncing subscriptions: $e');
      // Return local subscriptions if sync fails
      return localSubscriptions;
    }
  }

  /// Clear all cloud data for current user
  Future<void> clearCloudData() async {
    if (!isUserSignedIn) {
      print('Cannot clear cloud data: user not signed in');
      return;
    }

    try {
      final snapshot = await _userSubscriptionsCollection.get();
      final batch = _firestore.batch();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('Cleared all cloud data for user');
    } catch (e) {
      print('Error clearing cloud data: $e');
      rethrow;
    }
  }

  /// Check if auto sync is enabled
  bool get isAutoSyncEnabled {
    return _settingsService.isAutoSyncEnabled();
  }

  /// Auto sync a subscription if auto sync is enabled
  Future<void> autoSyncSubscription(Subscription subscription) async {
    if (!isAutoSyncEnabled) {
      print('Auto sync disabled, skipping');
      return;
    }
    
    if (!isUserSignedIn) {
      print('Cannot auto sync: user not signed in');
      return;
    }
    
    try {
      await uploadSubscription(subscription);
      print('Auto sync completed for: ${subscription.name}');
    } catch (e) {
      print('Auto sync failed for ${subscription.name}: $e');
      // Don't rethrow for auto sync - it should be silent
    }
  }

  /// Auto sync subscription deletion if auto sync is enabled
  Future<void> autoSyncDeleteSubscription(String subscriptionId) async {
    if (!isAutoSyncEnabled) {
      print('Auto sync disabled, skipping deletion');
      return;
    }
    
    if (!isUserSignedIn) {
      print('Cannot auto sync deletion: user not signed in');
      return;
    }
    
    try {
      await deleteSubscription(subscriptionId);
      print('Auto sync deletion completed for: $subscriptionId');
    } catch (e) {
      print('Auto sync deletion failed for $subscriptionId: $e');
      // Don't rethrow for auto sync - it should be silent
    }
  }

  void dispose() {
    stopSync();
  }
} 