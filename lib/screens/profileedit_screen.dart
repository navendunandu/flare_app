import 'package:flutter/material.dart';
import 'package:flare_app/components/screen_appbar.dart';
import 'package:flare_app/main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  File? _profileImage;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetch user data from Supabase and pre-fill the fields
  Future<void> _fetchUserData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final response =
            await supabase.from('tbl_user').select().eq('id', userId).single();
        _nameController.text = response['user_name'];
        _emailController.text = response['user_email'];
        setState(() {
          _profileImageUrl = response['user_photo'];
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  // Pick an image for the profile
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      try {
        String? imageUrl;

        if (_profileImage != null) {
          final fileName = 'user_$userId';
          final filePath = 'profile_images/$fileName';

          // Upload the profile image to Supabase Storage
          await supabase.storage
              .from('profile')
              .upload(filePath, _profileImage!);

          imageUrl = supabase.storage.from('profile').getPublicUrl(filePath);
        }

        // Update user data in tbl_user
        await supabase.from('tbl_user').update({
          'user_name': _nameController.text,
          'user_email': _emailController.text,
          'user_photo': imageUrl ??
              _profileImageUrl, // Use the new image URL if available
        }).eq('id', userId);

        // Update the display_name in Supabase Auth
        String fullName = _nameController.text;
        String firstName = fullName.split(' ').first;

        await supabase.auth.updateUser(UserAttributes(
          data: {
            'display_name': firstName
          }, // Set display_name in Supabase Auth
        ));

        // If everything is successful, pop the current screen
        Navigator.pop(context);
      } catch (e) {
        print('Error saving profile: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const PreferredSize(
          preferredSize: Size.fromHeight(80),
          child: SAppBar(title: 'My Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Image
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : (_profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : null),
                backgroundColor: Colors.white38,
                child: _profileImage == null && _profileImageUrl == null
                    ? const Icon(Icons.person, size: 50, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // Name Field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.person,
                  color: Colors.grey,
                ),
                hintText: 'Enter Username',
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
              controller: _emailController,
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
            const SizedBox(height: 30),

            // Save Button
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 224, 137, 6),
                padding: const EdgeInsets.all(15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Save Changes',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
