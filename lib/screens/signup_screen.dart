import 'package:flutter/material.dart';
import 'package:flare_app/main.dart';
import 'package:flare_app/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _obscureText = true;
  bool _obscureText2 = true;
  bool _acceptTerms = false;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameEditingController = TextEditingController();
  final TextEditingController _emailEditingController = TextEditingController();
  final TextEditingController _passwordEditingController =
      TextEditingController();

  // Function to pick an image
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _signUp() async {
    try {
      print("Hai");
      // Step 1: Sign up with Supabase Authentication
      final AuthResponse response = await supabase.auth.signUp(
        email: _emailEditingController.text,
        password: _passwordEditingController.text,
      );

      if (response.user != null) {
        String fullName = _nameEditingController.text;
        String firstName = fullName.split(' ').first;
        await supabase.auth.updateUser(UserAttributes(
          data: {'display_name': firstName},
        ));
      }

      final User? user = response.user;

      if (user == null) {
        print('Sign up error: $user');
      } else {
        final String userId = user.id;

        // Step 2: Upload profile photo (if selected)
        String? photoUrl;
        if (_image != null) {
          photoUrl = await _uploadImage(_image!, userId);
        }

        // Step 3: Insert user details into `tbl_user`
        await supabase.from('tbl_user').insert({
          'id': userId,
          'user_name': _nameEditingController.text,
          'user_email': _emailEditingController.text,
          'user_photo': photoUrl,
          'user_password': _passwordEditingController.text,
          'created_at': DateTime.now().toIso8601String(),
        });
        print('User created successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account Created successfully')),
        );
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoginScreen(),
            ));
      }
    } catch (e) {
      print('Sign up failed: $e');
    }
  }

  Future<String?> _uploadImage(File image, String userId) async {
    try {
      final fileName = 'user_$userId';

      await supabase.storage.from('profile_images').upload(fileName, image);

      // Get public URL of the uploaded image
      final imageUrl =
          supabase.storage.from('profile_images').getPublicUrl(fileName);
      return imageUrl;
    } catch (e) {
      print('Image upload failed: $e');
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
                  "Create Account",
                  style: GoogleFonts.poppins(
                    color: const Color.fromARGB(255, 224, 137, 6),
                    fontSize: 44,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 5),
                Text(
                  "Join us and get started!",
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),
                // Profile Photo Upload
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white38,
                      backgroundImage:
                          _image != null ? FileImage(_image!) : null,
                      child: _image == null
                          ? const Icon(Icons.camera_alt,
                              color: Colors.white38, size: 30)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Form Fields
                Column(
                  children: [
                    // Username Field
                    TextField(
                      controller: _nameEditingController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Colors.grey,
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
                            color: Color.fromARGB(255, 224, 137, 6),
                          ),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      cursorColor: const Color.fromARGB(255, 224, 137, 6),
                    ),
                    const SizedBox(height: 20),
                    // Email Field
                    TextField(
                      controller: _emailEditingController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.email,
                          color: Colors.grey,
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
                            color: Color.fromARGB(255, 224, 137, 6),
                          ),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      cursorColor: const Color.fromARGB(255, 224, 137, 6),
                    ),
                    const SizedBox(height: 20),
                    // Password Field
                    TextField(
                      controller: _passwordEditingController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Colors.white38,
                        ),
                        hintText: 'Enter Password',
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
                            color: Color.fromARGB(255, 224, 137, 6),
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
                      style: const TextStyle(color: Colors.white),
                      cursorColor: const Color.fromARGB(255, 224, 137, 6),
                    ),
                    const SizedBox(height: 20),
                    // Password Field
                    TextField(
                      obscureText: _obscureText2,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Colors.white38,
                        ),
                        hintText: 'Enter Password',
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
                            color: Color.fromARGB(255, 224, 137, 6),
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText2
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white38,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText2 = !_obscureText2;
                            });
                          },
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      cursorColor: const Color.fromARGB(255, 224, 137, 6),
                    ),
                    const SizedBox(height: 20),
                    // Terms and Conditions Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          activeColor: const Color.fromARGB(255, 224, 137, 6),
                          onChanged: (value) {
                            setState(() {
                              _acceptTerms = value!;
                            });
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              _showTermsDialog(context);
                            },
                            child: const Text(
                              "I accept the Terms and Conditions",
                              style: TextStyle(
                                color: Color.fromARGB(255, 224, 137, 6),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Sign Up Button
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _signUp();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 224, 137, 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Function to show Terms and Conditions dialog
  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 20, 20, 20),
          title: const Text(
            "Terms and Conditions",
            style: TextStyle(color: Colors.white),
          ),
          content: const SingleChildScrollView(
            child: Text(
              "Here are the Terms and Conditions:\n\n"
              "1. You must agree to the terms to create an account.\n"
              "2. The data provided will be used as per our privacy policy.\n"
              "3. Unauthorized use of the app is prohibited.\n"
              "4. We reserve the right to update these terms at any time.\n"
              "Please read the full terms on our website for more details.",
              style: TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Close",
                style: TextStyle(color: Color.fromARGB(255, 224, 137, 6)),
              ),
            ),
          ],
        );
      },
    );
  }
}
