import 'package:flutter/foundation.dart';

class AuthStore extends ChangeNotifier {
  bool loggedIn = false;
  bool verified = false;

  String? name;
  String? matric;

  void login({required String name, required String matric, bool verified = false}) {
    loggedIn = true;
    this.name = name;
    this.matric = matric;
    this.verified = verified;
    notifyListeners();
  }

  void logout() {
    loggedIn = false;
    verified = false;
    name = null;
    matric = null;
    notifyListeners();
  }

  void markVerified() {
    verified = true;
    notifyListeners();
  }
}

final auth = AuthStore();
