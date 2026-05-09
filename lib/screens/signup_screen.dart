import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  // ignore: prefer_final_fields
  bool _isPasswordHidden = true;

  final Color _primaryColor = const Color(0xFF4A6FA5); // calm blue
  final Color _accentColor = const Color(0xFF7B61FF); // soft purple

  final Color _textColor = const Color(0xFF1E2A38); // dark neutral
  final Color _subtitleColor = const Color(0xFF6B7C93); // soft gray-blue

  final Color _inputFillColor = const Color(0xFFF5F7FB); // light blue
  final Color _inputBorderColor = const Color(0xFFD6DEEA);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
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
            colors: [Color(0xFFEAF1FF), Color(0xFFF3EFFF)],
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
                              'Create Account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start your migraine management journey',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: _subtitleColor,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Full Name Field
                            _buildLabel('Full Name'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _nameController,
                              hintText: 'Name',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 20),

                            // Username Field
                            _buildLabel('Username'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _usernameController,
                              hintText: 'username',
                              icon: Icons.alternate_email,
                            ),
                            const SizedBox(height: 20),

                            // Email Field
                            _buildLabel('Email'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _emailController,
                              hintText: 'your@email.com',
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
                              obscureText: _isPasswordHidden, // USE VARIABLE
                              isPassword: true,
                            ),
                            const SizedBox(height: 32),

                            // Sign Up Button
                            ElevatedButton(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(context);

                                // VALIDATION
                                if (_nameController.text.trim().isEmpty ||
                                    _usernameController.text.trim().isEmpty ||
                                    _emailController.text.trim().isEmpty ||
                                    _passwordController.text.trim().isEmpty) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text("Please fill all fields"),
                                    ),
                                  );
                                  return;
                                }

                                if (_usernameController.text.contains(' ')) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Username cannot contain spaces",
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (!_emailController.text.contains('@')) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text("Enter a valid email"),
                                    ),
                                  );
                                  return;
                                }

                                if (_passwordController.text.length < 6) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Password must be at least 6 characters",
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  final auth = FirebaseAuth.instance;
                                  final firestore = FirebaseFirestore.instance;

                                  final usernameDoc = await firestore
                                      .collection('usernames')
                                      .doc(
                                        _usernameController.text
                                            .trim()
                                            .toLowerCase(),
                                      )
                                      .get();

                                  if (usernameDoc.exists) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text("Username already taken"),
                                      ),
                                    );
                                    return;
                                  }

                                  UserCredential userCredential = await auth
                                      .createUserWithEmailAndPassword(
                                        email: _emailController.text.trim(),
                                        password: _passwordController.text
                                            .trim(),
                                      );

                                  await userCredential.user!.updateDisplayName(
                                    _nameController.text.trim(),
                                  );

                                  await userCredential.user!.reload();

                                  if (userCredential.user != null) {
                                    await firestore
                                        .collection('users')
                                        .doc(userCredential.user!.uid)
                                        .set({
                                          'createdAt': Timestamp.now(),
                                          'email': _emailController.text.trim(),
                                          'name': _nameController.text.trim(),
                                          'username': _usernameController.text
                                              .trim(),
                                          'streak': 0,
                                          'notificationsEnabled': true,
                                          'darkModeEnabled': false,
                                        });

                                    await firestore
                                        .collection('usernames')
                                        .doc(
                                          _usernameController.text
                                              .trim()
                                              .toLowerCase(),
                                        )
                                        .set({'uid': userCredential.user!.uid});

                                    navigator.pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => const MainScreen(),
                                      ),
                                    );
                                  }
                                } on FirebaseAuthException catch (e) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.message ?? 'Authentication failed',
                                      ),
                                    ),
                                  );
                                } on FirebaseException catch (e) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Unable to save user data. Please try again.",
                                      ),
                                    ),
                                  );

                                  debugPrint("Firestore error: ${e.message}");
                                } catch (e) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Unexpected error occurred.",
                                      ),
                                    ),
                                  );

                                  debugPrint(e.toString());
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
                                  child: const Text(
                                    'Create Account',
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
                                  "Already have an account? ",
                                  style: TextStyle(color: _subtitleColor),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Sign In',
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
                        'By signing up, you agree to our Terms & Privacy Policy',
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
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: _textColor),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: _subtitleColor.withValues(alpha: 0.8)),
        prefixIcon: Icon(icon, color: _subtitleColor),

        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                  color: _subtitleColor,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordHidden = !_isPasswordHidden;
                  });
                },
              )
            : null,
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
