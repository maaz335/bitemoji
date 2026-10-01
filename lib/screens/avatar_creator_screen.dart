import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:get/get.dart';
import 'package:untitled/controllers/avatar_creator_controller.dart';
import 'package:untitled/core/theme/app_theme.dart';
import 'package:untitled/widgets/custom_button.dart';

/// Screen with two modes:
/// 1. Full Character — select from 21 pre-made 3D characters
/// 2. Mix & Match — swap Head/Body/Legs/Feet parts independently
class AvatarCreatorScreen extends GetView<AvatarCreatorController> {
  const AvatarCreatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top Navigation Bar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
                      onPressed: controller.goBack,
                    ),
                    const Expanded(
                      child: Text(
                        '3D Avatar Creator',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // ── Mode Toggle: Full Character / Mix & Match ──
              Container(
                    margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.secondaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        _buildModeTab(0, 'Characters', Icons.person_rounded),
                        _buildModeTab(1, 'Mix & Match', Icons.dashboard_customize_rounded),
                      ],
                    ),
                  ),

              const SizedBox(height: 6),

              // ── 3D Viewport ──
              Container(
                    height: 230,
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.35),
                          blurRadius: 24,
                          spreadRadius: 3,
                        ),
                      ],
                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.5), width: 2.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          Obx(() {
                            final rawPath = controller.current3dGlbPath.value;
                            if (rawPath.isEmpty) {
                              return const Center(
                                child: CircularProgressIndicator(color: AppTheme.secondaryColor),
                              );
                            }
                            final src = (rawPath.startsWith('assets/') ||
                                    rawPath.startsWith('http') ||
                                    rawPath.startsWith('file:'))
                                ? rawPath
                                : Uri.file(rawPath).toString();
                            return Stack(
                              children: [
                                Flutter3DViewer(
                                  key: ValueKey(src),
                                  src: src,
                                ),
                                if (controller.isAssemblingPreview.value)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black.withValues(alpha: 0.35),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 32,
                                          height: 32,
                                          child: CircularProgressIndicator(
                                            color: AppTheme.secondaryColor,
                                            strokeWidth: 2.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }),
                          // Badge
                          Positioned(
                            left: 12,
                            top: 12,
                            child: Obx(() => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                controller.viewMode.value == 0
                                    ? controller.selectedCharacter.name
                                    : 'Custom Avatar (${controller.currentPartCategory.title})',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            )),
                          ),
                          // Hint
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.touch_app_rounded, size: 14, color: AppTheme.secondaryColor),
                                  SizedBox(width: 4),
                                  Text('360° Rotate & Zoom',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

              const SizedBox(height: 6),

              // ── Bottom Panel (switches between modes) ──
              Expanded(
                child: Obx(() => controller.viewMode.value == 0
                    ? _buildFullCharacterPanel()
                    : _buildMixMatchPanel()),
              ),

              // ── Save Button ──
              Container(
                color: AppTheme.cardColor,
                padding: const EdgeInsets.all(16),
                child: Obx(() => CustomButton(
                      label: 'Save 3D Avatar',
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

  // ════════════════════════════════════════════════
  // FULL CHARACTER PANEL
  // ════════════════════════════════════════════════
  Widget _buildFullCharacterPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Gender toggle
          Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildGenderTab(0, 'Men', Icons.male_rounded, isFullMode: true),
                      _buildGenderTab(1, 'Women', Icons.female_rounded, isFullMode: true),
                    ],
                  ),
                ),
              ),
          // Grid
          Expanded(
            child: Obx(() {
              final characters = controller.activeCharacters;
              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.0,
                ),
                itemCount: characters.length,
                itemBuilder: (context, index) {
                  final char = characters[index];
                  final isSelected = controller.selectedCharacterIndex.value == index;
                  return _buildGridTile(
                    label: char.name,
                    icon: char.icon,
                    isSelected: isSelected,
                    onTap: () => controller.selectCharacter(index),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════
  // MIX & MATCH PANEL
  // ════════════════════════════════════════════════
  Widget _buildMixMatchPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Gender toggle for parts
          Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildGenderTab(0, 'Men Parts', Icons.male_rounded, isFullMode: false),
                      _buildGenderTab(1, 'Women Parts', Icons.female_rounded, isFullMode: false),
                    ],
                  ),
                ),
              ),

          // Part category tabs (Head / Body / Legs / Feet)
          Obx(() {
            final cats = controller.activePartCategories;
            return Container(
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(cats.length, (index) {
                  final cat = cats[index];
                  final isActive = controller.selectedPartCategoryIndex.value == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => controller.selectPartCategory(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.secondaryColor : AppTheme.surfaceColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(cat.icon, size: 18, color: isActive ? Colors.black : AppTheme.textSecondary),
                            Text(cat.title,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                    color: isActive ? Colors.black : AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),

          // Parts grid for selected category
          Expanded(
            child: Obx(() {
              final parts = controller.currentPartCategory.parts;
              final catId = controller.currentPartCategory.id;
              final selectedIdx = controller.selectedParts[catId] ?? 0;

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.0,
                ),
                itemCount: parts.length,
                itemBuilder: (context, index) {
                  final part = parts[index];
                  final isSelected = selectedIdx == index;
                  return _buildGridTile(
                    label: part.label,
                    icon: part.icon,
                    isSelected: isSelected,
                    onTap: () => controller.selectPart(index),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════
  // SHARED WIDGETS
  // ════════════════════════════════════════════════

  Widget _buildModeTab(int index, String label, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.switchViewMode(index),
        child: Obx(() {
          final isActive = controller.viewMode.value == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.secondaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: isActive ? Colors.black : AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? Colors.black : AppTheme.textSecondary)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGenderTab(int index, String label, IconData icon, {required bool isFullMode}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => isFullMode ? controller.switchGender(index) : controller.switchMixGender(index),
        child: Obx(() {
          final currentVal = isFullMode ? controller.selectedGender.value : controller.mixGender.value;
          final isActive = currentVal == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: isActive ? Colors.white : AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? Colors.white : AppTheme.textSecondary)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGridTile({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : AppTheme.surfaceColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: isSelected ? AppTheme.secondaryColor : AppTheme.textSecondary),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
