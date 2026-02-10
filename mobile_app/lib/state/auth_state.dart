import 'package:flutter/foundation.dart';

class AuthState extends ChangeNotifier {
  bool loggedIn = false;
  bool verified = false;

  // basic profile
  String name = "";
  String matric = "";

  void login({required String name, required String matric}) {
    loggedIn = true;
    this.name = name;
    this.matric = matric;
    notifyListeners();
  }

  void logout() {
    loggedIn = false;
    verified = false;
    name = "";
    matric = "";
    notifyListeners();
  }

  void markVerified() {
    verified = true;
    notifyListeners();
  }
}
