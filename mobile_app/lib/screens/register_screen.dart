import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();

void _loginWithGoogle() async {
    print("Google Sign-in initiated...");
    try {
      final user = await _auth.signInWithGoogle(); 
      if (user != null && mounted) {
        print("Google Login Success! Navigating to home...");
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      print("Google Sign-In Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google Sign-In failed!")),
        );
      }
    }
  }

  void _register() async {
print("Sign up button pressed...");
try{
    final user = await _auth.signUp(
      _emailController.text,
      _passwordController.text,
      _nameController.text,
      _studentIdController.text,
    );
print("Sign up result: $user");
    if (user != null && mounted) {
      print("Success! Navigating to home...");
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      print("User is null - registration failed logic triggered");
      if(mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed!")),
      );
      }
    }
  }catch (e) {
    print ("CRITICAL ERROR during registration: $e");
  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Account")),
      body: SingleChildScrollView( // Prevents keyboard overflow
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: InputDecoration(labelText: "Full Name")),
            TextField(controller: _studentIdController, decoration: InputDecoration(labelText: "Student ID (Matric)")),
            TextField(controller: _emailController, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _register, child: Text("Sign Up")),
            // ... below your ElevatedButton ...
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text("OR"),
              ),
              Expanded(child: Divider()),
            ],
          ),
          SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _loginWithGoogle, // We will define this method next
            icon: Icon(Icons.login), // You can use Image.asset('assets/google.png') for a real logo
            label: Text("Sign up with Google"),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              side: BorderSide(color: Colors.grey),
            ),
          ),
          ],
        ),
      ),
    );
  }
}