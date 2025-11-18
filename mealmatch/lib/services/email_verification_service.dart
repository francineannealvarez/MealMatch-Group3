// 📁 lib/services/email_verification_handler.dart
// Updated version with custom action code settings

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailVerificationHandler {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Request email change with custom action code settings
  /// This allows you to customize the redirect URL
  static Future<Map<String, dynamic>> requestEmailChange({
    required String currentPassword,
    required String newEmail,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No user is currently logged in'};
      }

      final currentEmail = user.email;
      if (currentEmail == null) {
        return {'success': false, 'message': 'Current email not found'};
      }

      // Validate email format
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(newEmail)) {
        return {'success': false, 'message': 'Invalid email format'};
      }

      // Check if new email is same as current
      if (newEmail.toLowerCase() == currentEmail.toLowerCase()) {
        return {
          'success': false,
          'message': 'New email is the same as current email',
        };
      }

      // Step 1: Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: currentEmail,
        password: currentPassword,
      );

      try {
        await user.reauthenticateWithCredential(credential);
      } catch (e) {
        return {
          'success': false,
          'message': 'Incorrect password. Please try again.',
        };
      }

      // Step 2: Store pending email in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'pendingEmailChange': newEmail,
        'pendingEmailChangeRequestedAt': FieldValue.serverTimestamp(),
        'originalEmailBeforeChange': currentEmail,
      }, SetOptions(merge: true));

      // Step 3: Configure action code settings (optional customization)
      // This doesn't change the email template, but customizes the redirect URL
      ///final actionCodeSettings = ActionCodeSettings(
      // Where to redirect after email verification
      ///url: 'https://mealmatch-ec825.firebaseapp.com/?email=$newEmail',
      // For mobile apps - this enables deep linking
      ///handleCodeInApp: false,
      // iOS bundle ID
      ///iOSBundleId: 'com.mealmatch.app',
      // Android package name
      ///androidPackageName: 'com.mealmatch.app',
      // Whether to install the app if not installed
      ///androidInstallApp: true,
      // Minimum version
      ///androidMinimumVersion: '12',
      // Dynamic link domain (if you have one)
      // dynamicLinkDomain: 'mealmatch.page.link',
      ///);

      // Step 4: Send verification email with custom settings
      try {
        await user.verifyBeforeUpdateEmail(newEmail);
        print('✅ Verification email sent to $newEmail');
      } catch (e) {
        // If custom settings fail, try without them
        print('⚠️ Custom action code failed, trying default...');
        await user.verifyBeforeUpdateEmail(newEmail);
      }

      return {
        'success': true,
        'message':
            'Verification email sent to $newEmail. Please check your inbox.',
        'pendingEmail': newEmail,
      };
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');

      // Clean up on failure
      try {
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'pendingEmailChange': FieldValue.delete(),
            'pendingEmailChangeRequestedAt': FieldValue.delete(),
            'originalEmailBeforeChange': FieldValue.delete(),
          });
        }
      } catch (_) {}

      switch (e.code) {
        case 'email-already-in-use':
          return {
            'success': false,
            'message': 'This email is already registered with another account',
          };
        case 'invalid-email':
          return {'success': false, 'message': 'Invalid email address'};
        case 'requires-recent-login':
          return {
            'success': false,
            'message':
                'For security, please log out and log back in before changing your email',
            'requiresRelogin': true,
          };
        case 'wrong-password':
          return {'success': false, 'message': 'Incorrect password'};
        default:
          return {
            'success': false,
            'message': e.message ?? 'Failed to send verification email',
          };
      }
    } catch (e) {
      print('Error requesting email change: $e');

      // Clean up on error
      try {
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'pendingEmailChange': FieldValue.delete(),
            'pendingEmailChangeRequestedAt': FieldValue.delete(),
            'originalEmailBeforeChange': FieldValue.delete(),
          });
        }
      } catch (_) {}

      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  /// Check if email has been verified and update Firestore
  static Future<Map<String, dynamic>> checkAndCompleteEmailChange() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final pendingEmail = userDoc.data()?['pendingEmailChange'] as String?;

      if (pendingEmail == null) {
        return {
          'success': false,
          'message': 'No pending email change request',
          'emailChanged': false,
        };
      }

      // Reload user to get latest email
      await user.reload();
      final refreshedUser = _auth.currentUser;

      if (refreshedUser == null) {
        return {'success': false, 'message': 'User session expired'};
      }

      print('🔍 Checking email verification:');
      print('   Current Auth email: ${refreshedUser.email}');
      print('   Pending email: $pendingEmail');

      // Check if email matches
      if (refreshedUser.email?.toLowerCase() == pendingEmail.toLowerCase()) {
        print('✅ Email verified! Updating Firestore...');

        await _firestore.collection('users').doc(user.uid).update({
          'email': pendingEmail,
          'pendingEmailChange': FieldValue.delete(),
          'pendingEmailChangeRequestedAt': FieldValue.delete(),
          'originalEmailBeforeChange': FieldValue.delete(),
          'emailUpdatedAt': FieldValue.serverTimestamp(),
        });

        return {
          'success': true,
          'message': 'Email successfully updated to $pendingEmail! 🎉',
          'emailChanged': true,
          'newEmail': pendingEmail,
        };
      } else {
        print('⏳ Email not verified yet.');

        return {
          'success': false,
          'message':
              'Email not verified yet. Please check your inbox and click the verification link.',
          'emailChanged': false,
        };
      }
    } catch (e) {
      print('❌ Error checking email verification: $e');
      return {
        'success': false,
        'message': 'Error checking verification status',
        'emailChanged': false,
      };
    }
  }

  /// Cancel pending email change
  static Future<bool> cancelPendingEmailChange() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      print('🚫 Canceling pending email change...');

      await _firestore.collection('users').doc(user.uid).update({
        'pendingEmailChange': FieldValue.delete(),
        'pendingEmailChangeRequestedAt': FieldValue.delete(),
        'originalEmailBeforeChange': FieldValue.delete(),
      });

      print('✅ Pending email change canceled');
      return true;
    } catch (e) {
      print('❌ Error canceling email change: $e');
      return false;
    }
  }

  /// Check if there's a pending email change
  static Future<String?> getPendingEmailChange() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data()?['pendingEmailChange'] as String?;
    } catch (e) {
      print('Error getting pending email: $e');
      return null;
    }
  }
}
