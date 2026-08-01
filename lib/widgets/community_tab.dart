import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});

  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab> {
  static const Color accentColor = Colors.purpleAccent;
  final ImagePicker _picker = ImagePicker();
  final PageController _pageController = PageController();

  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  bool _isUploading = false;
  Set<String> _myRatedPostIds = {};

  final Map<int, VideoPlayerController> _controllers = {};
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('community_posts')
          .select()
          .eq('media_type', 'video')
          .order('created_at', ascending: false)
          .limit(50);

      final userId = Supabase.instance.client.auth.currentUser?.id;
      Set<String> ratedIds = {};
      if (userId != null) {
        final ratings = await Supabase.instance.client
            .from('community_ratings')
            .select('post_id')
            .eq('rater_user_id', userId);
        ratedIds = (ratings as List).map((r) => r['post_id'] as String).toSet();
      }

      if (!mounted) return;
      setState(() {
        _posts = List<Map<String, dynamic>>.from(data);
        _myRatedPostIds = ratedIds;
        _isLoading = false;
      });

      if (_posts.isNotEmpty) _initController(0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load community feed: $e')),
      );
    }
  }

  void _initController(int index) {
    if (index < 0 || index >= _posts.length) return;
    if (_controllers.containsKey(index)) return;

    final url = _posts[index]['media_url'] as String;
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controllers[index] = controller;
    controller.initialize().then((_) {
      if (!mounted) return;
      controller.setLooping(true);
      if (index == _currentIndex) {
        controller.play();
      }
      setState(() {});
    });
  }

  void _onPageChanged(int index) {
    // Pause old, play new
    _controllers[_currentIndex]?.pause();
    _currentIndex = index;
    _initController(index);
    _controllers[index]?.play();

    // Preload next
    _initController(index + 1);

    // Dispose far-away controllers to save memory
    final keep = {index - 1, index, index + 1};
    final toRemove = _controllers.keys.where((k) => !keep.contains(k)).toList();
    for (final k in toRemove) {
      _controllers[k]?.dispose();
      _controllers.remove(k);
    }
  }

  Future<void> _uploadPost() async {
    final XFile? picked = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: const Color(0xFF12121F),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.videocam_outlined, color: accentColor),
              title: const Text('Record video', style: TextStyle(color: Colors.white)),
              onTap: () async {
                final vid = await _picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 90));
                if (ctx.mounted) Navigator.of(ctx).pop(vid);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined, color: accentColor),
              title: const Text('Choose from gallery', style: TextStyle(color: Colors.white)),
              onTap: () async {
                final vid = await _picker.pickVideo(source: ImageSource.gallery);
                if (ctx.mounted) Navigator.of(ctx).pop(vid);
              },
            ),
          ],
        ),
      ),
    );

    if (picked == null) return;

    final captionController = TextEditingController();
    final caption = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF12121F),
        title: const Text('Add a caption', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: captionController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'What did you create?',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(captionController.text.trim()),
            child: const Text('Post', style: TextStyle(color: accentColor)),
          ),
        ],
      ),
    );

    if (caption == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to post')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.path.split('.').last;
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await Supabase.instance.client.storage
          .from('community-media')
          .uploadBinary(fileName, bytes);

      final publicUrl = Supabase.instance.client.storage
          .from('community-media')
          .getPublicUrl(fileName);

      await Supabase.instance.client.from('community_posts').insert({
        'user_id': userId,
        'media_url': publicUrl,
        'media_type': 'video',
        'caption': caption.isEmpty ? null : caption,
      });

      if (!mounted) return;
      setState(() => _isUploading = false);
      _loadPosts();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  Future<void> _ratePost(String postId, int rating) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client.from('community_ratings').insert({
        'post_id': postId,
        'rater_user_id': userId,
        'rating': rating,
      });

      if (!mounted) return;
      setState(() => _myRatedPostIds.add(postId));
      _loadPosts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You may have already rated this post')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : _posts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'No videos yet. Be the first to share!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        IconButton(
                          icon: const Icon(Icons.add_a_photo_outlined, color: accentColor, size: 32),
                          onPressed: _isUploading ? null : _uploadPost,
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: _posts.length,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        final controller = _controllers[index];
                        final ratingCount = post['rating_count'] as int? ?? 0;
                        final ratingSum = post['rating_sum'] as int? ?? 0;
                        final avgRating = ratingCount > 0 ? ratingSum / ratingCount : 0.0;
                        final alreadyRated = _myRatedPostIds.contains(post['id']);

                        return GestureDetector(
                          onTap: () {
                            if (controller == null || !controller.value.isInitialized) return;
                            setState(() {
                              controller.value.isPlaying ? controller.pause() : controller.play();
                            });
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (controller != null && controller.value.isInitialized)
                                FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: controller.value.size.width,
                                    height: controller.value.size.height,
                                    child: VideoPlayer(controller),
                                  ),
                                )
                              else
                                const Center(child: CircularProgressIndicator(color: accentColor)),

                              // Bottom gradient + caption + rating
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.transparent, Colors.black87],
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (post['caption'] != null)
                                        Text(
                                          post['caption'],
                                          style: const TextStyle(color: Colors.white, fontSize: 15),
                                        ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Row(
                                            children: List.generate(5, (i) {
                                              final starValue = i + 1;
                                              return GestureDetector(
                                                onTap: alreadyRated
                                                    ? null
                                                    : () => _ratePost(post['id'], starValue),
                                                child: Icon(
                                                  starValue <= avgRating.round() ? Icons.star : Icons.star_border,
                                                  color: accentColor,
                                                  size: 22,
                                                ),
                                              );
                                            }),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            ratingCount > 0
                                                ? '${avgRating.toStringAsFixed(1)} ($ratingCount)'
                                                : 'No ratings yet',
                                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                                          ),
                                          const Spacer(),
                                          if (alreadyRated)
                                            const Text('Rated', style: TextStyle(color: accentColor, fontSize: 11.5)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Top bar
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Community',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              IconButton(
                                icon: _isUploading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: accentColor),
                                      )
                                    : const Icon(Icons.add_a_photo_outlined, color: accentColor),
                                onPressed: _isUploading ? null : _uploadPost,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
