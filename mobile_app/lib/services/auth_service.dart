import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      return result.user;
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  // 1. SIGN UP (Email & Password)
  Future<User?> signUp(String email, String password, String name, String studentId) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      // Store extra data in Firestore
      await _db.collection('users').doc(user!.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'studentId': studentId,
        'createdAt': DateTime.now(),
      });
      return user;
    } catch (e) {
      print("Sign Up Error: $e");
      return null;
    }
  }

  // 2. SIGN IN (Google)
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      // --- BACKEND LEAD ADDITION: Sync with Firestore ---
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': user.displayName ?? "No Name",
          'email': user.email,
          'studentId': '', // Google doesn't provide this, so we leave it empty
          'lastLogin': DateTime.now(),
        }, SetOptions(merge: true)); // 'merge: true' prevents overwriting existing data
      }
      
      return user;
    } catch (e) {
      print("Google Sign In Error: $e");
      return null;
    }
  }
}