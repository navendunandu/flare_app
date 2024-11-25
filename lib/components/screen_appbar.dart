import 'package:flutter/material.dart';

class SAppBar extends StatelessWidget {
  const SAppBar({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(color: Color.fromARGB(255, 224, 137, 6)),
      ),
      backgroundColor: Colors.black,
      leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          )),
    );
  }
}
