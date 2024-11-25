import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flare_app/screens/home_screen.dart';
import 'package:flare_app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  ///await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
}

void main() async {
  // Ensures that the app is fully initialized before anything is executed
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp();
  final config = await loadConfig();
  requestNotificationPermission();
  await FirebaseMessaging.instance.setAutoInitEnabled(true);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.notification?.title}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });
  // Initialize the Supabase instance with your project URL and anon key
  await Supabase.initialize(
    url: config['supabase']['url'],
    anonKey: config['supabase']['anonKey'],
  );
  final session = supabase.auth.currentSession;
  Widget startWidget =
      session == null ? const LoginScreen() : const HomeScreen();
  // Run the app after Supabase initialization is complete
  runApp(MainApp(
    startWidget: startWidget,
  ));
}

Future<Map<String, dynamic>> loadConfig() async {
  try {
    final String jsonString =
        await rootBundle.loadString('lib/services/config.json');
    print("DATA: $jsonString");
    return json.decode(jsonString) as Map<String, dynamic>;
  } catch (e) {
    print("Error loading config.json: $e");
    return {}; // Return an empty map or handle appropriately
  }
}

Future<void> requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission');
  } else {
    print('User denied permission');
  }
}

// Initialize the Supabase client for later use across the app
final supabase = Supabase.instance.client;

class MainApp extends StatelessWidget {
  final Widget startWidget;
  // Constructor for MainApp widget
  const MainApp({super.key, required this.startWidget});

  @override
  Widget build(BuildContext context) {
    // The main widget for the app, which is a MaterialApp
    // `home` points to the MainScreen widget, where the app's UI will be built
    return MaterialApp(
        debugShowCheckedModeBanner: false, // Disables the debug banner
        home:
            startWidget); // Main screen of the app, where the notes will be shown
  }
}
