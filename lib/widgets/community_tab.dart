import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});

  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab> {
  static const Color accentColor = Colors.purpleAccent;
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  bool _isUploading = false;
  Set<String> _myRatedPostIds = {};

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('community_posts')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      final userId = Supabase.instance.client.auth.currentUser?.id;
      Set<String> ratedIds = {};
      if (userId != null) {
        final ratings = await Supabase.instance.client
            .from('community_ratings')
            .select('post_id')
            .eq('rater_user_id', userId);
        ratedIds = (ratings as List)
            .map((r) => r['post_id'] as String)
            .toSet();
      }

      if (!mounted) return;
      setState(() {
        _posts = List<Map<String, dynamic>>.from(data);
        _myRatedPostIds = ratedIds;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load community feed: $e')),
      );
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
              leading: const Icon(Icons.camera_alt_outlined, color: accentColor),
              title: const Text('Take photo', style: TextStyle(color: Colors.white)),
              onTap: () async {
                final img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 75);
                if (ctx.mounted) Navigator.of(ctx).pop(img);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined, color: accentColor),
              title: const Text('Choose from gallery', style: TextStyle(color: Colors.white)),
              onTap: () async {
                final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
                if (ctx.mounted) Navigator.of(ctx).pop(img);
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
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to post')),
      );
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
        'media_type': 'image',
        'caption': caption.isEmpty ? null : caption,
      });

      if (!mounted) return;
      setState(() => _isUploading = false);
      _loadPosts();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
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
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121F),
        elevation: 0,
        title: const Text(
          'Community',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : _posts.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No posts yet. Be the first to share your AI creation!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPosts,
                  color: accentColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      final ratingCount = post['rating_count'] as int? ?? 0;
                      final ratingSum = post['rating_sum'] as int? ?? 0;
                      final avgRating = ratingCount > 0 ? ratingSum / ratingCount : 0.0;
                      final alreadyRated = _myRatedPostIds.contains(post['id']);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12121F),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                              child: Image.network(
                                post['media_url'],
                                width: double.infinity,
                                height: 240,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 240,
                                  color: Colors.white10,
                                  child: const Icon(Icons.broken_image_outlined, color: Colors.white38),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (post['caption'] != null)
                                    Text(
                                      post['caption'],
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                    ),
                                  const SizedBox(height: 8),
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
                                              starValue <= avgRating.round()
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: accentColor,
                                              size: 20,
                                            ),
                                          );
                                        }),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        ratingCount > 0
                                            ? '${avgRating.toStringAsFixed(1)} ($ratingCount)'
                                            : 'No ratings yet',
                                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                                      ),
                                      const Spacer(),
                                      if (alreadyRated)
                                        const Text(
                                          'Rated',
                                          style: TextStyle(color: accentColor, fontSize: 11.5),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
