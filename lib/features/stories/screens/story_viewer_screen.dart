import 'package:flutter/material.dart';

class StoryViewerScreen extends StatelessWidget {
  final String userId;

  const StoryViewerScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Story Viewer Screen')),
    );
  }
}