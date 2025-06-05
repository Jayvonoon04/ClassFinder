import 'package:classfinder_f/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:classfinder_f/screens/create_profile.dart';
import 'package:classfinder_f/screens/bottom_navigation_bar.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _loginFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();

  final signUpEmailController = TextEditingController();
  final signUpPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    signUpEmailController.dispose();
    signUpPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      hintText: hint,
      border: const OutlineInputBorder(),
      errorStyle: const TextStyle(color: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05),
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                const Text('Login', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600)),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                const Text(
                  'Welcome back, Please sign in and continue your journey with us.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                TabBar(
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.black,
                  tabs: const [
                    Tab(child: Text('Login', style: TextStyle(fontSize: 20))),
                    Tab(child: Text('Sign Up', style: TextStyle(fontSize: 20))),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: TabBarView(
                    children: [loginWidget(), signUpWidget()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget loginWidget() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: loginEmailController,
            decoration: inputDecoration('Enter your email', Icons.email),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email is required';
              if (!value.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: loginPasswordController,
            obscureText: true,
            decoration: inputDecoration('Enter your password', Icons.lock),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                if (!loginEmailController.text.contains('@')) {
                  showError('Enter a valid email address');
                  return;
                }
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: loginEmailController.text.trim(),
                  );
                  showError('Password reset email sent.');
                } on FirebaseAuthException catch (e) {
                  showError(e.message ?? 'Failed to send reset email.');
                }
              },
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (!_loginFormKey.currentState!.validate()) return;
              try {
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: loginEmailController.text.trim(),
                  password: loginPasswordController.text.trim(),
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const BottomBarView()),
                );
              } on FirebaseAuthException catch (e) {
                showError(e.message ?? 'Login failed.');
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget signUpWidget() {
    return Form(
      key: _signUpFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: signUpEmailController,
            decoration: inputDecoration('Enter your email', Icons.email),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email is required';
              if (!value.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: signUpPasswordController,
            obscureText: true,
            decoration: inputDecoration('Enter your password', Icons.lock),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: confirmPasswordController,
            obscureText: true,
            decoration: inputDecoration('Confirm your password', Icons.lock_outline),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Confirm password is required';
              if (value != signUpPasswordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (!_signUpFormKey.currentState!.validate()) return;

              try {
                await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: signUpEmailController.text.trim(),
                  password: signUpPasswordController.text.trim(),
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              } on FirebaseAuthException catch (e) {
                showError(e.message ?? 'Sign up failed.');
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: const Text('Sign Up'),
          ),
          const SizedBox(height: 20),
          const Text(
            'By signing up, you agree to our terms, data policy and cookies policy.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
