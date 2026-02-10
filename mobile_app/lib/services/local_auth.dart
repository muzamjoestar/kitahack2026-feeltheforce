import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAuth {
  static const _kUsers = "users_db";
  static const _kSession = "session_user";

  // ------- DB helpers -------
  static Future<Map<String, dynamic>> _readDb() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kUsers);
    if (raw == null || raw.trim().isEmpty) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> _writeDb(Map<String, dynamic> db) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kUsers, jsonEncode(db));
  }

  // ------- Session -------
  static Future<Map<String, dynamic>?> currentUser() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kSession);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kSession);
  }

  // ------- Signup/Login -------
  static Future<String?> signUp({
    required String matric,
    required String password,
    required Map<String, dynamic> profile,
  }) async {
    final m = matric.trim();
    if (m.isEmpty) return "No Matrik kosong.";
    if (password.trim().length < 6) return "Password minimum 6 karakter.";

    final db = await _readDb();
    if (db.containsKey(m)) return "No Matrik dah wujud. Try login.";

    // store user record
    db[m] = {
      "matric": m,
      "password": password, // ⚠️ local only. For real app, hash in backend.
      "profile": {
        "name": profile["name"] ?? "",
        "email": profile["email"] ?? "",
        "phone": profile["phone"] ?? "",
        "kulliyyah": profile["kulliyyah"] ?? "",
        "mahallah": profile["mahallah"] ?? "",
        "year": profile["year"] ?? "",
      },
      "createdAt": DateTime.now().toIso8601String(),
    };

    await _writeDb(db);

    // auto login after signup
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kSession, jsonEncode(db[m]));
    return null; // success
  }

  static Future<String?> login({
    required String matric,
    required String password,
  }) async {
    final m = matric.trim();
    final db = await _readDb();
    if (!db.containsKey(m)) return "Account tak wujud. Sila signup dulu.";

    final user = db[m] as Map<String, dynamic>;
    if ((user["password"] ?? "") != password) return "Password salah.";

    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kSession, jsonEncode(user));
    return null;
  }

  static Future<void> updateProfile({
    required String matric,
    required Map<String, dynamic> newProfile,
  }) async {
    final db = await _readDb();
    if (!db.containsKey(matric)) return;

    final user = db[matric] as Map<String, dynamic>;
    final prof = (user["profile"] as Map?)?.cast<String, dynamic>() ?? {};

    prof.addAll({
      "name": newProfile["name"] ?? prof["name"] ?? "",
      "email": newProfile["email"] ?? prof["email"] ?? "",
      "phone": newProfile["phone"] ?? prof["phone"] ?? "",
      "kulliyyah": newProfile["kulliyyah"] ?? prof["kulliyyah"] ?? "",
      "mahallah": newProfile["mahallah"] ?? prof["mahallah"] ?? "",
      "year": newProfile["year"] ?? prof["year"] ?? "",
    });

    user["profile"] = prof;
    db[matric] = user;

    await _writeDb(db);

    // update session too
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kSession, jsonEncode(user));
  }
}
