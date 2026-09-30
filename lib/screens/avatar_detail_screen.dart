import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:untitled/controllers/avatar_detail_controller.dart';
import 'package:untitled/core/constants/app_strings.dart';
import 'package:untitled/core/theme/app_theme.dart';
import 'package:untitled/widgets/custom_button.dart';

/// Detail view screen displaying full-size rendering of saved Bitmoji avatar, PNG sticker capture, download, and share actions.
class AvatarDetailScreen extends GetView<AvatarDetailController> {
  const AvatarDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final avatar = controller.avatar;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top Navigation Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
                      onPressed: controller.goBack,
                    ),
                    Expanded(
                      child: Text(
                        avatar.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                      onPressed: controller.deleteAvatar,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Full Size Render Box wrapped in RepaintBoundary for PNG sticker rendering
              Center(
                child: RepaintBoundary(
                  key: controller.repaintBoundaryKey,
                  child: ClipOval(
                    child: Container(
                      width: 280,
                      height: 280,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4), width: 3),
                      ),
                      child: ClipOval(
                        child: SvgPicture.string(
                          avatar.renderedSvg,
                          fit: BoxFit.contain,
                          placeholderBuilder: (_) => const Center(
                            child: CircularProgressIndicator(color: AppTheme.primaryColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Date Metadata
              Text(
                '${AppStrings.createdOn}: ${_formatDate(avatar.createdAt)}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),

              const Spacer(),

              // Download and Social Share Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Obx(() => Row(
                      children: [
                        // Download Avatar PNG Sticker Button
                        Expanded(
                          child: CustomButton(
                            label: AppStrings.downloadAvatar,
                            icon: Icons.file_download_rounded,
                            gradient: AppTheme.primaryGradient,
                            isLoading: controller.isProcessing.value,
                            onPressed: controller.downloadAvatar,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Share to Social Media PNG Sticker Button
                        Expanded(
                          child: CustomButton(
                            label: AppStrings.shareAvatar,
                            icon: Icons.share_rounded,
                            gradient: AppTheme.accentGradient,
                            isLoading: controller.isProcessing.value,
                            onPressed: controller.shareAvatar,
                          ),
                        ),
                      ],
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
