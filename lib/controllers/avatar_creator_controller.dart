import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttermoji/fluttermoji.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled/models/saved_avatar.dart';
import 'package:untitled/services/glb_merger_service.dart';
import 'package:untitled/services/storage_service.dart';
import 'package:untitled/widgets/custom_dialogs.dart';
import 'package:untitled/widgets/custom_snackbars.dart';

/// Model representing a selectable 3D character.
class Character3D {
  final String id;
  final String name;
  final String glbPath;
  final IconData icon;

  const Character3D({
    required this.id,
    required this.name,
    required this.glbPath,
    required this.icon,
  });
}

/// Model for a modular body part option.
class BodyPart3D {
  final String id;
  final String label;
  final String glbPath;
  final IconData icon;

  const BodyPart3D({
    required this.id,
    required this.label,
    required this.glbPath,
    required this.icon,
  });
}

/// Body part category (Head, Body, Legs, Feet).
class PartCategory {
  final String id;
  final String title;
  final IconData icon;
  final List<BodyPart3D> parts;

  const PartCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.parts,
  });
}

/// GetX Controller managing 3D avatar customization with two modes:
/// 1. Full Character selection (21 pre-made characters)
/// 2. Modular Mix & Match (swap Head/Body/Legs/Feet independently)
class AvatarCreatorController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final RxBool isSaving = false.obs;

  // Active 3D model path displayed in the viewer
  final RxString current3dGlbPath = ''.obs;

  // ══════════════════════════════════════════════
  // MODE TOGGLE: 0 = Full Characters, 1 = Mix & Match
  // ══════════════════════════════════════════════
  final RxInt viewMode = 0.obs;

  // ══════════════════════════════════════════════
  // FULL CHARACTER MODE
  // ══════════════════════════════════════════════
  final RxInt selectedGender = 0.obs; // 0 = Men, 1 = Women
  final RxInt selectedCharacterIndex = 0.obs;

  static const String _menBase = 'assets/models/characters/men';
  final List<Character3D> menCharacters = const [
    Character3D(id: 'men_adventurer', name: 'Adventurer', glbPath: '$_menBase/Adventurer.gltf', icon: Icons.hiking_rounded),
    Character3D(id: 'men_beach', name: 'Beach', glbPath: '$_menBase/Beach.gltf', icon: Icons.beach_access_rounded),
    Character3D(id: 'men_casual', name: 'Casual', glbPath: '$_menBase/Casual_2.gltf', icon: Icons.weekend_rounded),
    Character3D(id: 'men_hoodie', name: 'Hoodie', glbPath: '$_menBase/Casual_Hoodie.gltf', icon: Icons.dry_cleaning_rounded),
    Character3D(id: 'men_farmer', name: 'Farmer', glbPath: '$_menBase/Farmer.gltf', icon: Icons.agriculture_rounded),
    Character3D(id: 'men_king', name: 'King', glbPath: '$_menBase/King.gltf', icon: Icons.shield_rounded),
    Character3D(id: 'men_punk', name: 'Punk', glbPath: '$_menBase/Punk.gltf', icon: Icons.music_note_rounded),
    Character3D(id: 'men_spacesuit', name: 'Spacesuit', glbPath: '$_menBase/Spacesuit.gltf', icon: Icons.rocket_launch_rounded),
    Character3D(id: 'men_suit', name: 'Suit', glbPath: '$_menBase/Suit.gltf', icon: Icons.work_rounded),
    Character3D(id: 'men_swat', name: 'SWAT', glbPath: '$_menBase/Swat.gltf', icon: Icons.local_police_rounded),
    Character3D(id: 'men_worker', name: 'Worker', glbPath: '$_menBase/Worker.gltf', icon: Icons.construction_rounded),
  ];

  static const String _womenBase = 'assets/models/characters/women';
  final List<Character3D> womenCharacters = const [
    Character3D(id: 'women_adventurer', name: 'Adventurer', glbPath: '$_womenBase/Adventurer.gltf', icon: Icons.hiking_rounded),
    Character3D(id: 'women_casual', name: 'Casual', glbPath: '$_womenBase/Casual.gltf', icon: Icons.weekend_rounded),
    Character3D(id: 'women_formal', name: 'Formal', glbPath: '$_womenBase/Formal.gltf', icon: Icons.checkroom_rounded),
    Character3D(id: 'women_medieval', name: 'Medieval', glbPath: '$_womenBase/Medieval.gltf', icon: Icons.shield_rounded),
    Character3D(id: 'women_punk', name: 'Punk', glbPath: '$_womenBase/Punk.gltf', icon: Icons.music_note_rounded),
    Character3D(id: 'women_scifi', name: 'Sci-Fi', glbPath: '$_womenBase/SciFi.gltf', icon: Icons.rocket_launch_rounded),
    Character3D(id: 'women_soldier', name: 'Soldier', glbPath: '$_womenBase/Soldier.gltf', icon: Icons.local_police_rounded),
    Character3D(id: 'women_suit', name: 'Suit', glbPath: '$_womenBase/Suit.gltf', icon: Icons.work_rounded),
    Character3D(id: 'women_witch', name: 'Witch', glbPath: '$_womenBase/Witch.gltf', icon: Icons.auto_fix_high_rounded),
    Character3D(id: 'women_worker', name: 'Worker', glbPath: '$_womenBase/Worker.gltf', icon: Icons.construction_rounded),
  ];

  List<Character3D> get activeCharacters =>
      selectedGender.value == 0 ? menCharacters : womenCharacters;

  Character3D get selectedCharacter =>
      activeCharacters[selectedCharacterIndex.value];

  // ══════════════════════════════════════════════
  // MIX & MATCH MODE (Modular Body Parts)
  // ══════════════════════════════════════════════
  final RxInt mixGender = 0.obs; // 0 = Men parts, 1 = Women parts
  final RxInt selectedPartCategoryIndex = 0.obs;

  // Currently selected part per category (index in each category's parts list)
  final RxMap<String, int> selectedParts = <String, int>{}.obs;

  // ── Men modular part categories ──
  static const String _menParts = 'assets/models/modular_parts/men';
  final List<PartCategory> menPartCategories = const [
    PartCategory(id: 'head', title: 'Head', icon: Icons.face_rounded, parts: [
      BodyPart3D(id: 'adventurer_head', label: 'Adventurer', glbPath: '$_menParts/adventurer_head.glb', icon: Icons.hiking_rounded),
      BodyPart3D(id: 'beach_head', label: 'Beach', glbPath: '$_menParts/beach_head.glb', icon: Icons.beach_access_rounded),
      BodyPart3D(id: 'casual2_head', label: 'Casual', glbPath: '$_menParts/casual2_head.glb', icon: Icons.weekend_rounded),
      BodyPart3D(id: 'casual_head', label: 'Hoodie', glbPath: '$_menParts/casual_head.glb', icon: Icons.dry_cleaning_rounded),
      BodyPart3D(id: 'farmer_head', label: 'Farmer', glbPath: '$_menParts/farmer_head.glb', icon: Icons.agriculture_rounded),
      BodyPart3D(id: 'king_head', label: 'King', glbPath: '$_menParts/king_head.glb', icon: Icons.shield_rounded),
      BodyPart3D(id: 'punk_head', label: 'Punk', glbPath: '$_menParts/punk_head.glb', icon: Icons.music_note_rounded),
      BodyPart3D(id: 'spacesuit_head', label: 'Spacesuit', glbPath: '$_menParts/spacesuit_head.glb', icon: Icons.rocket_launch_rounded),
      BodyPart3D(id: 'suit_head', label: 'Suit', glbPath: '$_menParts/suit_head.glb', icon: Icons.work_rounded),
      BodyPart3D(id: 'swat_head', label: 'SWAT', glbPath: '$_menParts/swat_head.glb', icon: Icons.local_police_rounded),
      BodyPart3D(id: 'worker_head', label: 'Worker', glbPath: '$_menParts/worker_head.glb', icon: Icons.construction_rounded),
    ]),
    PartCategory(id: 'body', title: 'Body', icon: Icons.accessibility_new_rounded, parts: [
      BodyPart3D(id: 'adventurer_body', label: 'Adventurer', glbPath: '$_menParts/adventurer_body.glb', icon: Icons.hiking_rounded),
      BodyPart3D(id: 'beach_body', label: 'Beach', glbPath: '$_menParts/beach_body.glb', icon: Icons.beach_access_rounded),
      BodyPart3D(id: 'casual2_body', label: 'Casual', glbPath: '$_menParts/casual2_body.glb', icon: Icons.weekend_rounded),
      BodyPart3D(id: 'casual_body', label: 'Hoodie', glbPath: '$_menParts/casual_body.glb', icon: Icons.dry_cleaning_rounded),
      BodyPart3D(id: 'farmer_body', label: 'Farmer', glbPath: '$_menParts/farmer_body.glb', icon: Icons.agriculture_rounded),
      BodyPart3D(id: 'king_body', label: 'King', glbPath: '$_menParts/king_body.glb', icon: Icons.shield_rounded),
      BodyPart3D(id: 'punk_body', label: 'Punk', glbPath: '$_menParts/punk_body.glb', icon: Icons.music_note_rounded),
      BodyPart3D(id: 'spacesuit_body', label: 'Spacesuit', glbPath: '$_menParts/spacesuit_body.glb', icon: Icons.rocket_launch_rounded),
      BodyPart3D(id: 'suit_body', label: 'Suit', glbPath: '$_menParts/suit_body.glb', icon: Icons.work_rounded),
      BodyPart3D(id: 'swat_body', label: 'SWAT', glbPath: '$_menParts/swat_body.glb', icon: Icons.local_police_rounded),
      BodyPart3D(id: 'worker_body', label: 'Worker', glbPath: '$_menParts/worker_body.glb', icon: Icons.construction_rounded),
    ]),
    PartCategory(id: 'legs', title: 'Legs', icon: Icons.straighten_rounded, parts: [
      BodyPart3D(id: 'adventurer_legs', label: 'Adventurer', glbPath: '$_menParts/adventurer_legs.glb', icon: Icons.hiking_rounded),
      BodyPart3D(id: 'beach_legs', label: 'Beach', glbPath: '$_menParts/beach_legs.glb', icon: Icons.beach_access_rounded),
      BodyPart3D(id: 'casual2_legs', label: 'Casual', glbPath: '$_menParts/casual2_legs.glb', icon: Icons.weekend_rounded),
      BodyPart3D(id: 'casual_legs', label: 'Hoodie', glbPath: '$_menParts/casual_legs.glb', icon: Icons.dry_cleaning_rounded),
      BodyPart3D(id: 'farmer_legs', label: 'Farmer', glbPath: '$_menParts/farmer_legs.glb', icon: Icons.agriculture_rounded),
      BodyPart3D(id: 'king_legs', label: 'King', glbPath: '$_menParts/king_legs.glb', icon: Icons.shield_rounded),
      BodyPart3D(id: 'punk_legs', label: 'Punk', glbPath: '$_menParts/punk_legs.glb', icon: Icons.music_note_rounded),
      BodyPart3D(id: 'spacesuit_legs', label: 'Spacesuit', glbPath: '$_menParts/spacesuit_legs.glb', icon: Icons.rocket_launch_rounded),
      BodyPart3D(id: 'suit_legs', label: 'Suit', glbPath: '$_menParts/suit_legs.glb', icon: Icons.work_rounded),
      BodyPart3D(id: 'swat_legs', label: 'SWAT', glbPath: '$_menParts/swat_legs.glb', icon: Icons.local_police_rounded),
      BodyPart3D(id: 'worker_legs', label: 'Worker', glbPath: '$_menParts/worker_legs.glb', icon: Icons.construction_rounded),
    ]),
    PartCategory(id: 'feet', title: 'Feet', icon: Icons.do_not_step_rounded, parts: [
      BodyPart3D(id: 'adventurer_feet', label: 'Adventurer', glbPath: '$_menParts/adventurer_feet.glb', icon: Icons.hiking_rounded),
      BodyPart3D(id: 'beach_feet', label: 'Beach', glbPath: '$_menParts/beach_feet.glb', icon: Icons.beach_access_rounded),
      BodyPart3D(id: 'casual2_feet', label: 'Casual', glbPath: '$_menParts/casual2_feet.glb', icon: Icons.weekend_rounded),
      BodyPart3D(id: 'casual_feet', label: 'Hoodie', glbPath: '$_menParts/casual_feet.glb', icon: Icons.dry_cleaning_rounded),
      BodyPart3D(id: 'farmer_feet', label: 'Farmer', glbPath: '$_menParts/farmer_feet.glb', icon: Icons.agriculture_rounded),
      BodyPart3D(id: 'king_feet', label: 'King', glbPath: '$_menParts/king_feet.glb', icon: Icons.shield_rounded),
      BodyPart3D(id: 'punk_feet', label: 'Punk', glbPath: '$_menParts/punk_feet.glb', icon: Icons.music_note_rounded),
      BodyPart3D(id: 'spacesuit_feet', label: 'Spacesuit', glbPath: '$_menParts/spacesuit_feet.glb', icon: Icons.rocket_launch_rounded),
      BodyPart3D(id: 'suit_feet', label: 'Suit', glbPath: '$_menParts/suit_feet.glb', icon: Icons.work_rounded),
      BodyPart3D(id: 'swat_feet', label: 'SWAT', glbPath: '$_menParts/swat_feet.glb', icon: Icons.local_police_rounded),
      BodyPart3D(id: 'worker_feet', label: 'Worker', glbPath: '$_menParts/worker_feet.glb', icon: Icons.construction_rounded),
    ]),
  ];

  // ── Women modular part categories ──
  static const String _womenParts = 'assets/models/modular_parts/women';
  final List<PartCategory> womenPartCategories = const [
    PartCategory(id: 'head', title: 'Head', icon: Icons.face_rounded, parts: [
      BodyPart3D(id: 'adventurer_head', label: 'Adventurer', glbPath: '$_womenParts/adventurer_head.glb', icon: Icons.hiking_rounded),
      BodyPart3D(id: 'casual_head', label: 'Casual', glbPath: '$_womenParts/casual_head.glb', icon: Icons.weekend_rounded),
      BodyPart3D(id: 'formal_head', label: 'Formal', glbPath: '$_womenParts/formal_head.glb', icon: Icons.checkroom_rounded),
      BodyPart3D(id: 'medieval_head', label: 'Medieval', glbPath: '$_womenParts/medieval_head.glb', icon: Icons.shield_rounded),
      BodyPart3D(id: 'punk_head', label: 'Punk', glbPath: '$_womenParts/punk_head.glb', icon: Icons.music_note_rounded),
      BodyPart3D(id: 'scifi_head', label: 'Sci-Fi', glbPath: '$_womenParts/scifi_head.glb', icon: Icons.rocket_launch_rounded),
      BodyPart3D(id: 'soldier_head', label: 'Soldier', glbPath: '$_womenParts/soldier_head.glb', icon: Icons.local_police_rounded),
      BodyPart3D(id: 'suit_head', label: 'Suit', glbPath: '$_womenParts/suit_head.glb', icon: Icons.work_rounded),
      BodyPart3D(id: 'witch_head', label: 'Witch', glbPath: '$_womenParts/witch_head.glb', icon: Icons.auto_fix_high_rounded),
      BodyPart3D(id: 'worker_head', label: 'Worker', glbPath: '$_womenParts/worker_head.glb', icon: Icons.construction_rounded),
    ]),
    PartCategory(id: 'body', title: 'Body', icon: Icons.accessibility_new_rounded, parts: [
      BodyPart3D(id: 'adventurer_body', label: 'Adventurer', glbPath: '$_womenParts/adventurer_body.glb', icon: Icons.hiking_rounded),
      BodyPart3D(id: 'casual_body', label: 'Casual', glbPath: '$_womenParts/casual_body.glb', icon: Icons.weekend_rounded),
      BodyPart3D(id: 'formal_body', label: 'Formal', glbPath: '$_womenParts/formal_body.glb', icon: Icons.checkroom_rounded),
      BodyPart3D(id: 'medieval_body', label: 'Medieval', glbPath: '$_womenParts/medieval_body.glb', icon: Icons.shield_rounded),
      BodyPart3D(id: 'punk_body', label: 'Punk', glbPath: '$_womenParts/punk_body.glb', icon: Icons.music_note_rounded),
      BodyPart3D(id: 'scifi_body', label: 'Sci-Fi', glbPath: '$_womenParts/scifi_body.glb', icon: Icons.rocket_launch_rounded),
      BodyPart3D(id: 'soldier_body', label: 'Soldier', glbPath: '$_womenParts/soldier_body.glb', icon: Icons.local_police_rounded),
      BodyPart3D(id: 'suit_body', label: 'Suit', glbPath: '$_womenParts/suit_body.glb', icon: Icons.work_rounded),
      BodyPart3D(id: 'witch_body', label: 'Witch', glbPath: '$_womenParts/witch_body.glb', icon: Icons.auto_fix_high_rounded),
      BodyPart3D(id: 'worker_body', label: 'Worker', glbPath: '$_womenParts/worker_body.glb', icon: Icons.construction_rounded),
    ]),
    PartCategory(id: 'legs', title: 'Legs', icon: Icons.straighten_rounded, parts: [
      BodyPart3D(id: 'adventurer_legs', label: 'Adventurer', glbPath: '$_womenParts/adventurer_legs.glb', icon: Icons.hiking_rounded),
      BodyPart3D(id: 'casual_legs', label: 'Casual', glbPath: '$_womenParts/casual_legs.glb', icon: Icons.weekend_rounded),
      BodyPart3D(id: 'formal_legs', label: 'Formal', glbPath: '$_womenParts/formal_legs.glb', icon: Icons.checkroom_rounded),
      BodyPart3D(id: 'medieval_legs', label: 'Medieval', glbPath: '$_womenParts/medieval_legs.glb', icon: Icons.shield_rounded),
      BodyPart3D(id: 'punk_legs', label: 'Punk', glbPath: '$_womenParts/punk_legs.glb', icon: Icons.music_note_rounded),
      BodyPart3D(id: 'scifi_legs', label: 'Sci-Fi', glbPath: '$_womenParts/scifi_legs.glb', icon: Icons.rocket_launch_rounded),
      BodyPart3D(id: 'soldier_legs', label: 'Soldier', glbPath: '$_womenParts/soldier_legs.glb', icon: Icons.local_police_rounded),
      BodyPart3D(id: 'suit_legs', label: 'Suit', glbPath: '$_womenParts/suit_legs.glb', icon: Icons.work_rounded),
      BodyPart3D(id: 'witch_legs', label: 'Witch', glbPath: '$_womenParts/witch_legs.glb', icon: Icons.auto_fix_high_rounded),
      BodyPart3D(id: 'worker_legs', label: 'Worker', glbPath: '$_womenParts/worker_legs.glb', icon: Icons.construction_rounded),
    ]),
    PartCategory(id: 'feet', title: 'Feet', icon: Icons.do_not_step_rounded, parts: [
      BodyPart3D(id: 'adventurer_feet', label: 'Adventurer', glbPath: '$_womenParts/adventurer_feet.glb', icon: Icons.hiking_rounded),
      BodyPart3D(id: 'casual_feet', label: 'Casual', glbPath: '$_womenParts/casual_feet.glb', icon: Icons.weekend_rounded),
      BodyPart3D(id: 'formal_feet', label: 'Formal', glbPath: '$_womenParts/formal_feet.glb', icon: Icons.checkroom_rounded),
      BodyPart3D(id: 'medieval_feet', label: 'Medieval', glbPath: '$_womenParts/medieval_feet.glb', icon: Icons.shield_rounded),
      BodyPart3D(id: 'punk_feet', label: 'Punk', glbPath: '$_womenParts/punk_feet.glb', icon: Icons.music_note_rounded),
      BodyPart3D(id: 'scifi_feet', label: 'Sci-Fi', glbPath: '$_womenParts/scifi_feet.glb', icon: Icons.rocket_launch_rounded),
      BodyPart3D(id: 'soldier_feet', label: 'Soldier', glbPath: '$_womenParts/soldier_feet.glb', icon: Icons.local_police_rounded),
      BodyPart3D(id: 'suit_feet', label: 'Suit', glbPath: '$_womenParts/suit_feet.glb', icon: Icons.work_rounded),
      BodyPart3D(id: 'witch_feet', label: 'Witch', glbPath: '$_womenParts/witch_feet.glb', icon: Icons.auto_fix_high_rounded),
      BodyPart3D(id: 'worker_feet', label: 'Worker', glbPath: '$_womenParts/worker_feet.glb', icon: Icons.construction_rounded),
    ]),
  ];

  /// Active part categories based on mix gender
  List<PartCategory> get activePartCategories =>
      mixGender.value == 0 ? menPartCategories : womenPartCategories;

  /// Current selected part category
  PartCategory get currentPartCategory =>
      activePartCategories[selectedPartCategoryIndex.value];

  /// Get selected part for a specific category, returns the GLB path
  String getSelectedPartPath(String categoryId) {
    final cats = activePartCategories;
    final cat = cats.firstWhere((c) => c.id == categoryId);
    final idx = selectedParts[categoryId] ?? 0;
    return cat.parts[idx].glbPath;
  }

  @override
  void onInit() {
    super.onInit();
    current3dGlbPath.value = menCharacters[0].glbPath;
    // Initialize default selections for mix mode
    _initDefaultParts();
  }

  void _initDefaultParts() {
    selectedParts.value = {
      'head': 0,
      'body': 0,
      'legs': 0,
      'feet': 0,
    };
  }

  // ── Mode Toggle ──
  void switchViewMode(int mode) {
    viewMode.value = mode;
    if (mode == 0) {
      // Full character mode
      current3dGlbPath.value = selectedCharacter.glbPath;
    } else {
      // Mix & match mode — show the currently selected part
      _updateMixPreview();
    }
  }

  // ── Full Character Mode Actions ──
  void switchGender(int genderIndex) {
    selectedGender.value = genderIndex;
    selectedCharacterIndex.value = 0;
    current3dGlbPath.value = activeCharacters[0].glbPath;
  }

  void selectCharacter(int index) {
    selectedCharacterIndex.value = index;
    current3dGlbPath.value = activeCharacters[index].glbPath;
  }

  // ── Mix & Match Mode Actions ──
  void switchMixGender(int genderIndex) {
    mixGender.value = genderIndex;
    _initDefaultParts();
    selectedPartCategoryIndex.value = 0;
    _updateMixPreview();
  }

  void selectPartCategory(int index) {
    selectedPartCategoryIndex.value = index;
  }

  void selectPart(int partIndex) {
    final catId = currentPartCategory.id;
    selectedParts[catId] = partIndex;
    selectedParts.refresh();
    _updateMixPreview();
  }

  /// Update 3D preview to show the fully assembled composite avatar
  Future<void> _updateMixPreview() async {
    try {
      final head = getSelectedPartPath('head');
      final body = getSelectedPartPath('body');
      final legs = getSelectedPartPath('legs');
      final feet = getSelectedPartPath('feet');

      final assembledFile = await GlbMergerService.assembleModularAvatar(
        partAssetPaths: [head, body, legs, feet],
        outputFileName: 'preview_composite_${mixGender.value}.glb',
      );
      current3dGlbPath.value = assembledFile.uri.toString();
    } catch (e) {
      debugPrint('Error assembling avatar preview: $e');
    }
  }

  /// Save customized 3D avatar with its model path to local storage
  Future<void> saveAvatar() async {
    final String? avatarName = await CustomDialogs.showSaveNameDialog();

    if (avatarName == null || avatarName.trim().isEmpty) {
      return;
    }

    try {
      isSaving.value = true;
      String actualSvgXml = '';
      try {
        final String encodedOptions = await FluttermojiFunctions().encodeMySVGtoString();
        actualSvgXml = FluttermojiFunctions().decodeFluttermojifromString(encodedOptions);
      } catch (_) {
        actualSvgXml = '<svg></svg>';
      }

      String finalGlbPath = current3dGlbPath.value;
      final avatarId = DateTime.now().millisecondsSinceEpoch.toString();

      if (viewMode.value == 1) {
        // In Mix & Match mode, assemble and save the permanent composite GLB
        final head = getSelectedPartPath('head');
        final body = getSelectedPartPath('body');
        final legs = getSelectedPartPath('legs');
        final feet = getSelectedPartPath('feet');

        final docsDir = await getApplicationDocumentsDirectory();
        final persistentFile = File('${docsDir.path}/custom_avatar_$avatarId.glb');
        final assembled = await GlbMergerService.assembleModularAvatar(
          partAssetPaths: [head, body, legs, feet],
          outputFileName: 'temp_save_$avatarId.glb',
        );
        await assembled.copy(persistentFile.path);
        finalGlbPath = persistentFile.uri.toString();
      }

      final newAvatar = SavedAvatar(
        id: avatarId,
        name: avatarName.trim(),
        svgData: actualSvgXml,
        glbPath: finalGlbPath,
        createdAt: DateTime.now(),
      );

      await _storageService.saveAvatar(newAvatar);
      Get.back(result: true);
      CustomSnackbars.showSuccess('3D Avatar "${avatarName.trim()}" saved successfully!');
    } catch (e) {
      CustomSnackbars.showError('Failed to save 3D avatar: $e');
    } finally {
      isSaving.value = false;
    }
  }

  void goBack() {
    Get.back();
  }
}
