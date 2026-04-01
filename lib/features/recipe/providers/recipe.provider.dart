import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

class RecipeIngredient {
  final String id;
  final String name;
  final String? quantity;
  final String? unit;
  final int displayOrder;

  const RecipeIngredient({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
    required this.displayOrder,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as String?,
      unit: json['unit'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  String get formatted {
    if (quantity != null && unit != null) return '$quantity $unit $name';
    if (quantity != null) return '$quantity $name';
    return name;
  }
}

class RecipeStep {
  final String id;
  final int stepNumber;
  final String instruction;
  final String? imageUrl;

  const RecipeStep({
    required this.id,
    required this.stepNumber,
    required this.instruction,
    this.imageUrl,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      id: json['id'] as String,
      stepNumber: json['step_number'] as int,
      instruction: json['instruction'] as String,
      imageUrl: json['image_url'] as String?,
    );
  }
}

class RecipeModel {
  final String id;
  final String postId;
  final String userId;
  final String title;
  final String? description;
  final int? prepTimeMins;
  final int? cookTimeMins;
  final int? servings;
  final String difficulty;
  final bool isPaid;
  final double? price;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;

  const RecipeModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.title,
    this.description,
    this.prepTimeMins,
    this.cookTimeMins,
    this.servings,
    required this.difficulty,
    required this.isPaid,
    this.price,
    this.username,
    this.displayName,
    this.avatarUrl,
    required this.ingredients,
    required this.steps,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    final ingredientsList = (json['ingredients'] as List<dynamic>? ?? [])
        .map((i) => RecipeIngredient.fromJson(i as Map<String, dynamic>))
        .toList();

    final stepsList = (json['steps'] as List<dynamic>? ?? [])
        .map((s) => RecipeStep.fromJson(s as Map<String, dynamic>))
        .toList();

    return RecipeModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      prepTimeMins: json['prep_time_mins'] as int?,
      cookTimeMins: json['cook_time_mins'] as int?,
      servings: json['servings'] as int?,
      difficulty: json['difficulty'] as String? ?? 'easy',
      isPaid: json['is_paid'] as bool? ?? false,
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      ingredients: ingredientsList,
      steps: stepsList,
    );
  }

  String get authorName => displayName ?? username ?? 'Unknown';

  int get totalTimeMins => (prepTimeMins ?? 0) + (cookTimeMins ?? 0);

  String get formattedPrice => '₦${price?.toStringAsFixed(0) ?? '0'}';
}

class RecipeState {
  final RecipeModel? recipe;
  final bool isLoading;
  final String? error;

  const RecipeState({
    this.recipe,
    this.isLoading = false,
    this.error,
  });

  RecipeState copyWith({
    RecipeModel? recipe,
    bool? isLoading,
    String? error,
  }) {
    return RecipeState(
      recipe: recipe ?? this.recipe,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class RecipeNotifier extends Notifier<RecipeState> {
  @override
  RecipeState build() {
    return const RecipeState();
  }

  Future<void> loadRecipe(String postId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final dio = ApiClient.instance;
      final response = await dio.get('/recipes/post/$postId');
      final recipe = RecipeModel.fromJson(response.data['data']['recipe']);

      state = state.copyWith(
        recipe: recipe,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load recipe',
      );
    }
  }
}

final recipeProvider = NotifierProvider<RecipeNotifier, RecipeState>(() {
  return RecipeNotifier();
});