import 'package:flare_app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flare_app/components/main_appbar.dart';
import 'package:flare_app/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart' as auth;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // List to store all users fetched from the database
  List<Map<String, dynamic>> users = [];

  final Session? session = supabase.auth.currentSession;

  String uid = "";

  Stream<List<Map<String, dynamic>>>? _usersStream;

  Future<Map<String, dynamic>> loadConfig() async {
    try {
      final String jsonString = await rootBundle
          .loadString('lib/services/firebase_service_account.json');
      print("DATA: $jsonString");
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print("Error loading config.json: $e");
      return {}; // Return an empty map or handle appropriately
    }
  }

  Future<String> getAccessToken() async {
    // Your client ID and client secret obtained from Google Cloud Console
    final serviceAccountJson = await loadConfig();

    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging"
    ];

    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

    // Obtain the access token
    auth.AccessCredentials credentials =
        await auth.obtainAccessCredentialsViaServiceAccount(
            auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
            scopes,
            client);

    // Close the HTTP client
    client.close();

    // Return the access token
    return credentials.accessToken.data;
  }

  void sendPushNotification(String userToken, String msg) async {
    try {
      final String serverKey = await getAccessToken(); // Your FCM server key
      const String fcmEndpoint =
          'https://fcm.googleapis.com/v1/projects/flare-app-18697/messages:send';
      final Map<String, dynamic> message = {
        'message': {
          'token':
              userToken, // Token of the device you want to send the message to
          'notification': {
            "title": "Flare Notification",
            "body": msg,
          },
          'data': {
            'current_user_fcm_token':
                userToken, // Include the current user's FCM token in data payload
          },
        }
      };

      final http.Response response = await http.post(
        Uri.parse(fcmEndpoint),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverKey',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print('FCM message sent successfully');
      } else {
        print('Failed to send FCM message: ${response.statusCode}');
      }
    } catch (e) {
      print("Failed Notification: $e");
    }
  }

  @override
  void initState() {
    super.initState();

    supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;

      if (event == AuthChangeEvent.signedOut) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
    uid = session!.user.id;

    // Initialize the stream to fetch users
    _usersStream = supabase
        .from('tbl_user')
        .stream(primaryKey: ['id']).neq('id', uid); // Exclude the current user
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with custom height
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: MainAppBar(),
      ),
      backgroundColor: Colors.black,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Listen for updates from the 'tbl_user' table
        stream: _usersStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            ); // Loading state
          }

          final newUsers = snapshot.data ?? [];
          users = newUsers; // Update the users list with the latest data

          if (users.isEmpty) {
            return const Center(
              child: Text(
                "No users found",
                style: TextStyle(color: Colors.white),
              ),
            ); // Display message if no users
          }

          // Display the users in a ListView
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Slidable(
                key: ValueKey(user['id']), // Unique key for the widget
                endActionPane: ActionPane(
                  motion: const DrawerMotion(), // Motion effect
                  children: [
                    SlidableAction(
                      onPressed: (context) {
                        String name =
                            session?.user.userMetadata!['display_name'];
                        String message =
                            "Hello ${user['user_name']}, $name sends you a flare";
                        sendPushNotification(user['fcm_token'], message);
                      },
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      icon: Icons.notifications,
                      label: 'Notify',
                    ),
                  ],
                ),
                child: Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // User photo
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: user['user_photo'] != null
                              ? NetworkImage(user['user_photo'])
                              : null,
                          backgroundColor: Colors.grey[700],
                          child: user['user_photo'] == null
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 30,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        // User details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['user_name'] ?? 'Unknown',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                user['user_email'] ?? 'No contact info',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            String name =
                                session?.user.userMetadata!['display_name'];
                            String message =
                                "Hello ${user['user_name']}, $name sends you a flare";
                            sendPushNotification(user['fcm_token'], message);
                          },
                          icon: const Icon(Icons.call),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
