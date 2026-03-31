import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String? username;

  const ProfileScreen({super.key, this.username});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Profile Screen')),
    );
  }
}