import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// Screen 3: Detail Screen (The 3D Interaction)
/// Renders the 3D .glb avatar using model_viewer_plus.
/// Enables rotation, zoom, camera controls, and Augmented Reality (AR).
class AvatarDetailScreen extends StatelessWidget {
  final String glbUrl;

  const AvatarDetailScreen({
    super.key,
    required this.glbUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Avatar Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Copy GLB URL',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: glbUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('GLB model URL copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 3D Model Renderer via model_viewer_plus
          ModelViewer(
            src: glbUrl,
            alt: 'Ready Player Me 3D Avatar',
            autoRotate: true,
            cameraControls: true,
            ar: true,
            backgroundColor: const Color(0xFF0F172A),
          ),

          // User interaction tips overlay
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InteractionTip(
                    icon: Icons.rotate_right,
                    label: 'Drag to Rotate',
                  ),
                  _InteractionTip(
                    icon: Icons.pinch,
                    label: 'Pinch to Zoom',
                  ),
                  _InteractionTip(
                    icon: Icons.view_in_ar,
                    label: 'Tap AR Icon',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractionTip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InteractionTip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6366F1)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
