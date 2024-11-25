import 'package:flutter/material.dart';
import 'package:flare_app/components/screen_appbar.dart';
import 'package:flare_app/main.dart';
import 'package:flare_app/screens/login_screen.dart';
import 'package:flare_app/screens/profileedit_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  int totalNotes = 0;
  int completedNotes = 0;
  int incompleteNotes = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchNoteStats();
  }

  Future<void> _fetchUserData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final response =
            await supabase.from('tbl_user').select().eq('id', userId).single();
        setState(() {
          userData = response;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _fetchNoteStats() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        // Fetch total notes count
        final totalResponse =
            await supabase.from('notes').select().eq('user_id', userId);
        totalNotes = totalResponse.length;

        // Fetch completed notes count
        final completedResponse = await supabase
            .from('notes')
            .select()
            .eq('user_id', userId)
            .eq('status', 'completed');
        completedNotes = completedResponse.length;

        // Fetch incomplete notes count
        final incompleteResponse = await supabase
            .from('notes')
            .select()
            .eq('user_id', userId)
            .eq('status', 'incomplete');
        incompleteNotes = incompleteResponse.length;

        setState(() {});
      }
    } catch (e) {
      print('Error fetching note stats: $e');
    }
  }

  // Logout functionality
  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
      // Navigate to login screen after logout (assuming you have a login screen)
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ));
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const PreferredSize(
          preferredSize: Size.fromHeight(80),
          child: SAppBar(title: 'My Profile')),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Photo
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: userData!['user_photo'] != null
                        ? NetworkImage(userData!['user_photo'])
                        : null,
                    backgroundColor: Colors.white38,
                    child: userData!['user_photo'] == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 20),
                  // User Details
                  Text(
                    userData!['user_name'] ?? 'Username',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userData!['user_email'] ?? 'Email',
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Note Statistics
                  Card(
                    color: Colors.white12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'Notes Statistics',
                            style: GoogleFonts.poppins(
                              color: const Color.fromARGB(255, 224, 137, 6),
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildStatItem('Total Notes', totalNotes),
                          _buildStatItem('Completed Notes', completedNotes),
                          _buildStatItem('Incomplete Notes', incompleteNotes),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Edit Profile and Logout Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfilePage(),
                              ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 224, 137, 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.all(12),
                        ),
                        label: const Text(
                          "Edit Profile",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                        ),
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 224, 137, 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.all(12),
                        ),
                        label: const Text(
                          "Log out",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  // Helper widget for displaying statistics
  Widget _buildStatItem(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          Text(
            count.toString(),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
