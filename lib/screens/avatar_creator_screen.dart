import 'package:flutter/material.dart';
import 'package:fluttermoji/fluttermoji.dart';
import 'package:get/get.dart';
import 'package:untitled/controllers/avatar_creator_controller.dart';
import 'package:untitled/core/constants/app_strings.dart';
import 'package:untitled/core/theme/app_theme.dart';
import 'package:untitled/widgets/custom_button.dart';

/// Creator Screen displaying live Fluttermoji preview and feature customization grid.
class AvatarCreatorScreen extends GetView<AvatarCreatorController> {
  const AvatarCreatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    const Expanded(
                      child: Text(
                        AppStrings.creatorTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance title layout
                  ],
                ),
              ),

              // Live SVG Avatar Preview Circle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: ClipOval(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4), width: 3),
                      ),
                      child: ClipOval(
                        child: FluttermojiCircleAvatar(
                          radius: 85,
                          backgroundColor: AppTheme.surfaceColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Custom Dark-Themed Fluttermoji Grid
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    child: FluttermojiCustomizer(
                      scaffoldWidth: MediaQuery.of(context).size.width,
                      theme: FluttermojiThemeData(
                        primaryBgColor: AppTheme.cardColor,
                        secondaryBgColor: AppTheme.surfaceColor,
                        labelTextStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                        ),
                        selectedIconColor: AppTheme.secondaryColor,
                        unselectedIconColor: AppTheme.textSecondary.withValues(alpha: 0.6),
                        iconColor: AppTheme.secondaryColor,
                        selectedTileDecoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primaryColor,
                            width: 2.5,
                          ),
                          color: AppTheme.primaryColor.withValues(alpha: 0.25),
                        ),
                        unselectedTileDecoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppTheme.cardColor.withValues(alpha: 0.6),
                        ),
                        boxDecoration: const BoxDecoration(color: Colors.transparent),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Save Action Button Container
              Container(
                color: AppTheme.cardColor,
                padding: const EdgeInsets.all(20),
                child: Obx(() => CustomButton(
                      label: AppStrings.saveAvatar,
                      icon: Icons.check_circle_rounded,
                      isLoading: controller.isSaving.value,
                      onPressed: controller.saveAvatar,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
