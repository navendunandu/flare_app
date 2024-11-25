import 'package:flutter/material.dart';
import 'package:flare_app/main.dart';
import 'package:flare_app/screens/profile_screen.dart';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

class MainAppBar extends StatelessWidget {
  MainAppBar({super.key});

  // Method to get greeting based on the time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;

    // Return greeting based on the current time
    if (hour < 12) {
      return "Good Morning!";
    } else if (hour < 17) {
      return "Good Afternoon!";
    } else {
      return "Good Evening!";
    }
  }

  final Session? session = supabase.auth.currentSession;

  // Method to get a random motivational quote
  String _getRandomQuote() {
    final quotes = [
      "Believe you can and you're halfway there.",
      "Every day is a new beginning.",
      "The best time for new beginnings is now.",
      "Stay positive, work hard, and make it happen.",
      "You are capable of amazing things.",
      "Good things take time. Keep pushing forward.",
    ];

    // Return a random quote from the list
    return quotes[Random().nextInt(quotes.length)];
  }

  @override
  Widget build(BuildContext context) {
    // Get greeting and random quote
    final greeting = _getGreeting();
    final quote = _getRandomQuote();
    String name = session?.user.userMetadata!['display_name'];
    return Container(
      // Padding for the app bar content
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.0),
          bottomRight: Radius.circular(20.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting and quote text display
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display greeting message
                  Text(
                    greeting,
                    style: const TextStyle(
                      color: Color.fromARGB(
                          255, 224, 137, 6), // White color for greeting
                      fontSize: 22,
                      fontWeight: FontWeight.bold, // Bold for greeting
                    ),
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold, // Bold for greeting
                    ),
                  ),
                  // Display random quote with ellipsis if it overflows
                  const SizedBox(height: 5),
                  Text(
                    quote,
                    style: const TextStyle(
                      color: Color.fromARGB(
                          255, 224, 137, 6), // Orange color for quote
                      fontSize: 14,
                      fontStyle: FontStyle.italic, // Italic for quote
                    ),
                    maxLines: 2, // Limit to 2 lines for the quote
                    overflow: TextOverflow
                        .ellipsis, // Show ellipsis if text overflows
                  ),
                ],
              ),
            ),
            // Icon for visual appeal
            IconButton(
              icon: const Icon(
                Icons.account_circle_outlined,
                color: Color.fromARGB(
                    255, 224, 137, 6), // Matching the orange theme
                size: 28,
              ), // Icon representing night-time or relaxation
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(),
                    ));
              },
              // Icon size
            ),
          ],
        ),
      ),
    );
  }
}
