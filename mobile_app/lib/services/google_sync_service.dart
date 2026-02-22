import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSyncService {
  /// Triggers the Google Sign-In flow and links the account to the current user.
  /// This adheres to the Gatekeeper rule by only allowing linking for
  /// users who are already signed in (manually).
  static Future<void> syncWithGoogle() async {
    try {
      // 1. Trigger Google Sign-In flow
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in flow
        return;
      }

      // 2. Get the AuthCredential
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Link with the currently logged-in Firebase user
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.linkWithCredential(credential);
        debugPrint('Successfully linked Google account.');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        debugPrint(
            'Error: This credential is already associated with a different user account.');
      } else {
        debugPrint('Error linking Google account: ${e.message}');
      }
    } catch (e) {
      debugPrint('Unexpected error during Google sync: $e');
    }
  }
}
