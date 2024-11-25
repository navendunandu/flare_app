import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flare_app/main.dart';
import 'package:flare_app/screens/home_screen.dart';
import 'package:flare_app/screens/signup_screen.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscureText = true;

  final TextEditingController _emailEditingController = TextEditingController();
  final TextEditingController _passwordEditingController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    loadConfig(); // Load config.json when the screen initializes
  }

  Future<void> signIn() async {
    final AuthResponse res = await supabase.auth.signInWithPassword(
      email: _emailEditingController.text,
      password: _passwordEditingController.text,
    );
    final User? user = res.user;
    await saveFcmToken(user?.id);
    if (user?.id != "") {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    }
  }

  String? webClientId;

  Future<void> loadConfig() async {
    try {
      final String jsonString =
          await rootBundle.loadString('lib/services/config.json');
      final config = json.decode(jsonString) as Map<String, dynamic>;
      setState(() {
        webClientId = config['googleSignIn']['clientId'];
      });
      print("WebClient: $webClientId");
    } catch (e) {
      print("Error loading config.json: $e");
    }
  }

  Future<void> saveFcmToken(uid) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await supabase
            .from('tbl_user')
            .update({'fcm_token': fcmToken}).eq('id', uid);
      }
    } catch (e) {
      print("FCM Token Error: $e");
    }
  }

  Future<AuthResponse?> _googleSignIn() async {
    print("google sign in");
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );
      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser!.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw 'No Access Token found.';
      }
      if (idToken == null) {
        throw 'No ID Token found.';
      }
      print("Access Token: $accessToken");
      print("ID Token: $idToken");
      return supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      print("Google Sign In Error: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                // Welcome Text
                Text(
                  "Welcome",
                  style: GoogleFonts.poppins(
                    color: const Color.fromARGB(255, 224, 137, 6),
                    fontSize: 44,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.left,
                ),
                Text(
                  "back!",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Sign in to your account",
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),
                // Form Fields
                Column(
                  children: [
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      controller: _emailEditingController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Colors.grey, // Default icon color
                        ),
                        hintText: 'Enter Email',
                        hintStyle: const TextStyle(color: Colors.white38),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Colors.white38,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(
                                255, 224, 137, 6), // Color when focused
                          ),
                        ),
                      ),
                      cursorColor: const Color.fromARGB(
                          255, 224, 137, 6), // Cursor color
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      controller: _passwordEditingController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Colors.white38,
                        ),
                        hintText: 'Enter Password',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Colors.white38,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(
                                255, 224, 137, 6), // Color when focused
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white38,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                      ),
                      cursorColor: const Color.fromARGB(255, 224, 137, 6),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              signIn();
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 224, 137, 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12)),
                            child: const Text(
                              "Sign in",
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    const Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white38,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            "or",
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white38,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    googleSignInButton(context),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Flexible(
                            child: Text("Don't have an account? ",
                                style: TextStyle(color: Colors.white54))),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpScreen(),
                                ));
                          },
                          child: const Text(
                            'Create a new account',
                            style: TextStyle(
                              color: Color.fromARGB(255, 224, 137, 6),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget googleSignInButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        await _googleSignIn();
      },
      icon: Image.asset(
        'assets/google_logo.png',
        height: 24,
      ),
      label: const Text(
        "Continue with Google",
        style: TextStyle(fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 32, 32, 32),
        foregroundColor: Colors.white70,
        minimumSize: const Size(double.infinity, 50),
        // padding: EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
