import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  final Color _primaryColor = const Color(0xFF4A6FA5); // calm blue 
  final Color _accentColor = const Color(0xFF7B61FF); // soft purple 

  final Color _textColor = const Color(0xFF1E2A38); // dark neutral
  final Color _subtitleColor = const Color(0xFF6B7C93); // soft gray-blue

  final Color _inputFillColor = const Color(0xFFF5F7FB); // very light blue
  final Color _inputBorderColor = const Color(0xFFD6DEEA); // light gray-blue

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEAF1FF), // light blue
              Color(0xFFF3EFFF), // light purple
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 40.0,
                  ),
                  child: Column(
                    children: [
                      // White Card
                      Container(
                        padding: const EdgeInsets.all(32.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo Image
                            Center(
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: 120, // adjust if needed
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Headings
                            Text(
                              'Welcome',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Manage your migraine journey',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: _subtitleColor,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Email Field
                            _buildLabel('Username or Email'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _loginController,
                              hintText: 'username or email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 20),

                            // Password Field
                            _buildLabel('Password'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _passwordController,
                              hintText: '••••••••',
                              icon: Icons.lock_outline,
                              obscureText: true,
                            ),
                            const SizedBox(height: 32),

                            // Sign In Button
                            ElevatedButton(
                              onPressed: () async {
                                if (_loginController.text.isEmpty ||
                                    _passwordController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Please fill all fields"),
                                    ),
                                  );
                                  return; // stop execution
                                }

                                setState(() => _isLoading = true);

                                try {
                                  final input = _loginController.text.trim();
                                  String email = input;

                                  final firestore = FirebaseFirestore.instance;

                                  //  If input is NOT email → treat as username
                                  if (!input.contains('@')) {
                                    final usernameDoc = await firestore
                                        .collection('usernames')
                                        .doc(input.toLowerCase())
                                        .get();

                                    if (!usernameDoc.exists) {
                                      throw FirebaseAuthException(
                                        code: 'user-not-found',
                                      );
                                    }

                                    final uid = usernameDoc['uid'];

                                    final userDoc = await firestore
                                        .collection('users')
                                        .doc(uid)
                                        .get();

                                    email = userDoc['email'];
                                  }

                                  // login with email (original or fetched)
                                  await FirebaseAuth.instance
                                      .signInWithEmailAndPassword(
                                        email: email,
                                        password: _passwordController.text
                                            .trim(),
                                      );

                                  if (!context.mounted) return;
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const MainScreen(),
                                    ),
                                  );
                                } on FirebaseAuthException catch (e) {
                                  String message;

                                  if (e.code == 'invalid-credential' ||
                                      e.code == 'user-not-found' ||
                                      e.code == 'wrong-password') {
                                    message = "Incorrect email or password";
                                  } else if (e.code == 'invalid-email') {
                                    message = "Invalid email format";
                                  } else {
                                    message = "Login failed. Please try again";
                                  }

                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(message),
                                      backgroundColor:
                                          Colors.redAccent, // optional 🔥
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(
                                      () => _isLoading = false,
                                    ); //  STOP LOADING
                                  }
                                }
                              },
                              style:
                                  ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ).copyWith(
                                    backgroundColor: WidgetStateProperty.all(
                                      Colors.transparent,
                                    ),
                                    elevation: WidgetStateProperty.all(0),
                                  ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_primaryColor, _accentColor],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  height: 50,
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Bottom Text
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(color: _subtitleColor),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SignupScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: _accentColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Footer Text
                      Text(
                        'Your health data is secure and private',
                        style: TextStyle(color: _subtitleColor, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _textColor,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: _textColor),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: _subtitleColor.withValues(alpha: 0.7)),
        prefixIcon: Icon(icon, color: _subtitleColor),
        filled: true,
        fillColor: _inputFillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _inputBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _inputBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor),
        ),
      ),
    );
  }
}
