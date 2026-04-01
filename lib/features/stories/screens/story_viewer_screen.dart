import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
//import '../../../core/theme/theme.dart';
import '../providers/story.provider.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  final String userId;

  const StoryViewerScreen({super.key, required this.userId});

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  int _currentIndex = 0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this);
    Future.microtask(
      () => ref.read(storyViewerProvider.notifier).loadStories(widget.userId),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _startProgress() {
    _progressController.reset();
    _progressController.duration = const Duration(seconds: 5);
    _progressController.forward().then((_) {
      if (mounted && !_isPaused) _nextStory();
    });
  }

  void _nextStory() {
    final state = ref.read(storyViewerProvider);
    if (_currentIndex < state.stories.length - 1) {
      setState(() => _currentIndex++);
      _startProgress();
      _recordView();
    } else {
      context.pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _startProgress();
    } else {
      // No previous story — just restart current
      _startProgress();
    }
  }

  void _pause() {
    _isPaused = true;
    _progressController.stop();
  }

  void _resume() {
    _isPaused = false;
    _progressController.forward();
  }

  void _recordView() {
    final state = ref.read(storyViewerProvider);
    if (state.stories.isNotEmpty && _currentIndex < state.stories.length) {
      ref.read(storyViewerProvider.notifier).viewStory(
            state.stories[_currentIndex].id,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyViewerProvider);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (state.stories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'No stories available',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text(
                  'Go back',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_progressController.status == AnimationStatus.dismissed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startProgress();
        _recordView();
      });
    }

    final story = state.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: _SwipeToDismiss(
        onDismiss: () => context.pop(),
        child: GestureDetector(
        // Long press anywhere to pause
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),

        // Tap left/right to navigate
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
            _previousStory();
          } else if (details.globalPosition.dx > width * 2 / 3) {
            _nextStory();
          }
        },

        child: Stack(
          children: [
            // Story media
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: story.mediaUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[900],
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),

            // Gradient overlay top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
              ),
            ),

            // Progress bars
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(state.stories.length, (index) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: index < _currentIndex
                            ? Container(
                                height: 2.5,
                                color: Colors.white,
                              )
                            : index == _currentIndex
                                ? AnimatedBuilder(
                                    animation: _progressController,
                                    builder: (context, child) {
                                      return LinearProgressIndicator(
                                        value: _progressController.value,
                                        backgroundColor:
                                            Colors.white.withValues(
                                                alpha: 0.4),
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                                Colors.white),
                                        minHeight: 2.5,
                                      );
                                    },
                                  )
                                : Container(
                                    height: 2.5,
                                    color: Colors.white
                                        .withValues(alpha: 0.4),
                                  ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Header
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white24,
                    backgroundImage: story.avatarUrl != null
                        ? CachedNetworkImageProvider(story.avatarUrl!)
                        : null,
                    child: story.avatarUrl == null
                        ? Text(
                            story.authorName.isNotEmpty
                                ? story.authorName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.authorName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _timeAgo(story.createdAt),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),

            // Caption
            if (story.caption != null && story.caption!.isNotEmpty)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    story.caption!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Pause indicator
            if (_isPaused)
              const Center(
                child: Icon(
                  Icons.pause_circle_outline,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
          ],
        ),
      ),
      )
    );
  }

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}

class _SwipeToDismiss extends StatefulWidget {
  final Widget child;
  final VoidCallback onDismiss;

  const _SwipeToDismiss({
    required this.child,
    required this.onDismiss,
  });

  @override
  State<_SwipeToDismiss> createState() => _SwipeToDismissState();
}

class _SwipeToDismissState extends State<_SwipeToDismiss>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> scaleAnimation;
  late Animation<double> opacityAnimation;
  late Animation<BorderRadius?> borderAnimation;
  double dragOffset = 0;
  bool isDismissing = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    scaleAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );

    opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );

    borderAnimation = BorderRadiusTween(
      begin: BorderRadius.zero,
      end: BorderRadius.circular(30),
    ).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void onVerticalDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy > 0) {
      setState(() {
        dragOffset += details.delta.dy;
        controller.value = (dragOffset / 300).clamp(0.0, 1.0);
      });
    }
  }

  void onVerticalDragEnd(DragEndDetails details) {
    if (dragOffset > 100 || (details.primaryVelocity ?? 0) > 500) {
      isDismissing = true;
      controller.forward().then((_) {
        widget.onDismiss();
      });
    } else {
      // Snap back
      setState(() => dragOffset = 0);
      controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, dragOffset * 0.3),
            child: Transform.scale(
              scale: scaleAnimation.value,
              child: Opacity(
                opacity: opacityAnimation.value,
                child: ClipRRect(
                  borderRadius: borderAnimation.value ?? BorderRadius.zero,
                  child: child,
                ),
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}