import 'package:flutter/material.dart';

class PostDetailScreen extends StatelessWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Post Detail Screen')),
    );
  }
}