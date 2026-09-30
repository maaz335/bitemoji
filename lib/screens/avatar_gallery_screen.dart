import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'avatar_creator_screen.dart';
import 'avatar_detail_screen.dart';

/// Screen 2: Home / Gallery Screen (The 2D Optimization)
/// Loads persisted .glb URLs from SharedPreferences and renders 2D PNGs
/// using the Ready Player Me 2D Render API to prevent memory crashes.
class AvatarGalleryScreen extends StatefulWidget {
  const AvatarGalleryScreen({super.key});

  @override
  State<AvatarGalleryScreen> createState() => _AvatarGalleryScreenState();
}

class _AvatarGalleryScreenState extends State<AvatarGalleryScreen> {
  static const String _storageKey = 'saved_rpm_avatars';
  List<String> _avatarGlbUrls = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedAvatars();
  }

  Future<void> _loadSavedAvatars() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList(_storageKey) ?? [];
    if (mounted) {
      setState(() {
        _avatarGlbUrls = savedList;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAvatar(String glbUrl) async {
    if (_avatarGlbUrls.contains(glbUrl)) return;

    final updated = [glbUrl, ..._avatarGlbUrls];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, updated);

    if (mounted) {
      setState(() {
        _avatarGlbUrls = updated;
      });
    }
  }

  Future<void> _deleteAvatar(int index) async {
    final updated = List<String>.from(_avatarGlbUrls)..removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, updated);

    if (mounted) {
      setState(() {
        _avatarGlbUrls = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avatar removed from gallery'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Converts the 3D .glb URL to the RPM 2D Render API format
  /// CRITICAL: Prevents memory exhaustion by avoiding multiple 3D viewports.
  String _to2dRenderUrl(String glbUrl) {
    if (glbUrl.contains('.glb')) {
      return glbUrl.replaceFirst('.glb', '.png?pose=fullbody-portrait-v1');
    }
    return glbUrl;
  }

  Future<void> _openAvatarCreator() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const AvatarCreatorScreen(),
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _saveAvatar(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avatar Gallery'),
        actions: [
          if (_avatarGlbUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  '${_avatarGlbUrls.length} Avatars',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _avatarGlbUrls.isEmpty
              ? _buildEmptyState()
              : _buildGalleryGrid(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAvatarCreator,
        icon: const Icon(Icons.add),
        label: const Text('Create Avatar'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.person_add_alt_1_outlined,
                size: 64,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Avatars Created Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to launch the Ready Player Me creator and build your first 3D character.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openAvatarCreator,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Launch Creator'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _avatarGlbUrls.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final glbUrl = _avatarGlbUrls[index];
        final png2dUrl = _to2dRenderUrl(glbUrl);

        return _buildAvatarCard(glbUrl, png2dUrl, index);
      },
    );
  }

  Widget _buildAvatarCard(String glbUrl, String png2dUrl, int index) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AvatarDetailScreen(glbUrl: glbUrl),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                png2dUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              (loadingProgress.expectedTotalBytes ?? 1)
                          : null,
                      strokeWidth: 2,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 40,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '2D Render Unavailable',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.view_in_ar, size: 12, color: Color(0xFF6366F1)),
                    SizedBox(width: 4),
                    Text(
                      '3D',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.white.withValues(alpha: 0.6),
                tooltip: 'Delete Avatar',
                onPressed: () => _confirmDelete(index),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: const Text(
                  'Tap to inspect in 3D',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Avatar'),
        content: const Text(
          'Are you sure you want to remove this avatar from your gallery?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAvatar(index);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
