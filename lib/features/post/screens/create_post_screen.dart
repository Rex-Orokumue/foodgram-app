import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../../core/theme/theme.dart';
import '../providers/post.provider.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _captionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  String _postType = 'regular';
  String? _cuisineTag;
  bool _isForSale = false;

  final List<String> _cuisineTags = [
    'Nigerian', 'West African', 'Ghanaian', 'Kenyan',
    'Ethiopian', 'South African', 'Asian', 'Italian',
    'American', 'Mediterranean', 'Mexican', 'Indian',
    'Chinese', 'Japanese', 'Other',
  ];

  final List<String> _postTypes = ['regular', 'recipe', 'menu_item'];

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final success = await ref.read(createPostProvider.notifier).createPost(
          caption: _captionController.text,
          postType: _postType,
          cuisineTag: _cuisineTag,
          locationName: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          isForSale: _isForSale,
          price: _isForSale && _priceController.text.isNotEmpty
              ? double.tryParse(_priceController.text)
              : null,
        );

    if (success && mounted) {
      ref.read(createPostProvider.notifier).reset();
      context.go('/feed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createPostProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () {
            ref.read(createPostProvider.notifier).reset();
            context.go('/feed');
          },
        ),
        title: const Text('New Post'),
        actions: [
          TextButton(
            onPressed: createState.isLoading ? null : _submit,
            child: createState.isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Text(
                    'Share',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media picker
            _buildMediaPicker(createState),

            const SizedBox(height: 16),

            // Caption
            TextField(
              controller: _captionController,
              maxLines: 5,
              minLines: 3,
              maxLength: 2200,
              decoration: const InputDecoration(
                hintText: 'What are you eating, cooking or sharing? 🍽️',
                border: InputBorder.none,
                filled: false,
                counterStyle: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 11,
                ),
              ),
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),

            const Divider(),
            const SizedBox(height: 12),

            // Post type selector
            _buildSectionLabel('Post type'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _postTypes.map((type) {
                  final isSelected = _postType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _postType = type),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        type == 'menu_item' ? 'Menu item' : _capitalize(type),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Cuisine tag
            _buildSectionLabel('Cuisine'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _cuisineTags.map((tag) {
                  final isSelected = _cuisineTag == tag;
                  return GestureDetector(
                    onTap: () => setState(
                      () => _cuisineTag = isSelected ? null : tag,
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Location
            _buildSectionLabel('Location'),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'Add location',
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  color: AppColors.textHint,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // For sale toggle
            Row(
              children: [
                _buildSectionLabel('Available for order'),
                const Spacer(),
                Switch(
                  value: _isForSale,
                  onChanged: (value) => setState(() => _isForSale = value),
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),

            // Price field
            if (_isForSale) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Price (₦)',
                  prefixIcon: Icon(
                    Icons.attach_money,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                ),
              ),
            ],

            // Error message
            if (createState.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  createState.error!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPicker(CreatePostState createState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (createState.selectedMedia.isEmpty)
          Row(
            children: [
              _buildMediaButton(
                icon: Icons.photo_library_outlined,
                label: 'Photo',
                onTap: () =>
                    ref.read(createPostProvider.notifier).pickMedia(),
              ),
              const SizedBox(width: 12),
              _buildMediaButton(
                icon: Icons.videocam_outlined,
                label: 'Video',
                onTap: () =>
                    ref.read(createPostProvider.notifier).pickVideo(),
              ),
            ],
          )
        else
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: createState.selectedMedia.length + 1,
              itemBuilder: (context, index) {
                if (index == createState.selectedMedia.length) {
                  return GestureDetector(
                    onTap: () =>
                        ref.read(createPostProvider.notifier).pickMedia(),
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.textHint,
                      ),
                    ),
                  );
                }

                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(
                            File(createState.selectedMedia[index].path),
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => ref
                            .read(createPostProvider.notifier)
                            .removeMedia(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}