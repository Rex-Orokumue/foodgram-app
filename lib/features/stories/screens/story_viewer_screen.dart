import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/story.provider.dart';
import '../../../shared/models/story.model.dart';
import '../../feed/providers/story_feed.provider.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  final String userId;
  const StoryViewerScreen({super.key, required this.userId});

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  int _storyIndex = 0;
  bool _isPaused = false;
  bool _started = false;

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

  void _startProgress(int durationSecs) {
    _progressController.reset();
    _progressController.duration = Duration(seconds: durationSecs);
    _progressController.forward().then((_) {
      if (mounted && !_isPaused) _nextStory();
    });
  }

  void _nextStory() {
    final state = ref.read(storyViewerProvider);
    final stories = state.currentStories;

    if (_storyIndex < stories.length - 1) {
      setState(() => _storyIndex++);
      _recordView();
    } else if (state.hasNextGroup) {
      // Mark current group as viewed before moving
      _markCurrentGroupViewed();
      ref.read(storyViewerProvider.notifier).goToNextGroup();
      setState(() {
        _storyIndex = 0;
        _started = false;
      });
    } else {
      _markCurrentGroupViewed();
      context.pop();
    }
  }

  void _markCurrentGroupViewed() {
    final currentGroup = ref.read(storyViewerProvider).currentGroup;
    if (currentGroup != null) {
      ref.read(storyFeedProvider.notifier).markGroupAsViewed(currentGroup.userId);
    }
  }

  void _previousStory() {
    final state = ref.read(storyViewerProvider);

    if (_storyIndex > 0) {
      setState(() => _storyIndex--);
      _startProgress(5);
    } else if (state.hasPreviousGroup) {
      ref.read(storyViewerProvider.notifier).goToPreviousGroup();
      setState(() => _storyIndex = 0);
      _started = false;
    } else {
      _startProgress(5);
    }
  }

  void _recordView() {
    final stories = ref.read(storyViewerProvider).currentStories;
    if (stories.isNotEmpty && _storyIndex < stories.length) {
      ref.read(storyViewerProvider.notifier).viewStory(stories[_storyIndex].id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyViewerProvider);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (state.currentGroup == null || state.currentStories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No stories available',
                  style: TextStyle(color: Colors.white)),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Go back',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    // Clamp story index when group changes
    final stories = state.currentStories;
    if (_storyIndex >= stories.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _storyIndex = 0);
      });
      return const Scaffold(backgroundColor: Colors.black);
    }

    final story = stories[_storyIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: _SwipeToDismiss(
        onDismiss: () => context.pop(),
        child: GestureDetector(
          onLongPressStart: (_) {
            _isPaused = true;
            _progressController.stop();
          },
          onLongPressEnd: (_) {
            _isPaused = false;
            _progressController.forward();
          },
          onTapUp: (details) {
            final width = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx < width / 3) {
              _progressController.stop();
              _previousStory();
            } else if (details.globalPosition.dx > width * 2 / 3) {
              _progressController.stop();
              _nextStory();
            }
          },
          child: Stack(
            children: [
              // Media
              Positioned.fill(
                child: _StoryImage(
                  key: ValueKey('${state.currentGroupIndex}_$_storyIndex'),
                  story: story,
                  onLoaded: () {
                    if (!_started || !_progressController.isAnimating) {
                      _started = true;
                      _startProgress(5);
                      _recordView();
                    }
                  },
                ),
              ),

              // Top gradient
              Positioned(
                top: 0, left: 0, right: 0, height: 120,
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
                left: 8, right: 8,
                child: Row(
                  children: List.generate(stories.length, (index) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: index < _storyIndex
                              ? Container(height: 2.5, color: Colors.white)
                              : index == _storyIndex
                                  ? AnimatedBuilder(
                                      animation: _progressController,
                                      builder: (_, _) => LinearProgressIndicator(
                                        value: _progressController.value,
                                        backgroundColor: Colors.white.withValues(alpha: 0.4),
                                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                                        minHeight: 2.5,
                                      ),
                                    )
                                  : Container(
                                      height: 2.5,
                                      color: Colors.white.withValues(alpha: 0.4),
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
                left: 12, right: 12,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white24,
                      backgroundImage: story.avatarUrl != null
                          ? NetworkImage(story.avatarUrl!)
                          : null,
                      child: story.avatarUrl == null
                          ? Text(
                              story.authorName.isNotEmpty
                                  ? story.authorName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(story.authorName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          Text(_timeAgo(story.createdAt),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        _markCurrentGroupViewed();
                        context.pop();
                      },
                    ),
                  ],
                ),
              ),

              // Caption
              if (story.caption != null && story.caption!.isNotEmpty)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                  left: 16, right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      story.caption!,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              if (_isPaused)
                const Center(
                  child: Icon(Icons.pause_circle_outline,
                      color: Colors.white54, size: 64),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

// Separate widget that notifies when image is loaded
class _StoryImage extends StatefulWidget {
  final StoryModel story;
  final VoidCallback onLoaded;

  const _StoryImage({super.key, required this.story, required this.onLoaded});

  @override
  State<_StoryImage> createState() => _StoryImageState();
}

class _StoryImageState extends State<_StoryImage> {
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: widget.story.mediaUrl,
      fit: BoxFit.contain,
      imageBuilder: (context, imageProvider) {
        if (!_loaded) {
          _loaded = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onLoaded();
          });
        }
        return Image(image: imageProvider, fit: BoxFit.contain);
      },
      placeholder: (context, url) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[900],
        child: const Icon(Icons.broken_image_outlined,
            color: Colors.white54, size: 48),
      ),
    );
  }
}

class _SwipeToDismiss extends StatefulWidget {
  final Widget child;
  final VoidCallback onDismiss;

  const _SwipeToDismiss({required this.child, required this.onDismiss});

  @override
  State<_SwipeToDismiss> createState() => _SwipeToDismissState();
}

class _SwipeToDismissState extends State<_SwipeToDismiss>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<BorderRadius?> _radius;
  double _drag = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scale = Tween(begin: 1.0, end: 0.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _radius = BorderRadiusTween(
            begin: BorderRadius.zero, end: BorderRadius.circular(30))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (d) {
        if (d.delta.dy > 0) {
          setState(() {
            _drag += d.delta.dy;
            _ctrl.value = (_drag / 300).clamp(0.0, 1.0);
          });
        }
      },
      onVerticalDragEnd: (d) {
        if (_drag > 100 || (d.primaryVelocity ?? 0) > 500) {
          _ctrl.forward().then((_) => widget.onDismiss());
        } else {
          setState(() => _drag = 0);
          _ctrl.reverse();
        }
      },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, _drag * 0.3),
          child: Transform.scale(
            scale: _scale.value,
            child: Opacity(
              opacity: _opacity.value,
              child: ClipRRect(
                borderRadius: _radius.value ?? BorderRadius.zero,
                child: child,
              ),
            ),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}