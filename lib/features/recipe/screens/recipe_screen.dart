import 'package:flutter/material.dart';

class RecipeScreen extends StatelessWidget {
  final String postId;

  const RecipeScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Recipe Screen')),
    );
  }
}