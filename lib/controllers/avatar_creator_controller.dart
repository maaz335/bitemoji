import 'package:fluttermoji/fluttermoji.dart';
import 'package:get/get.dart';
import 'package:untitled/core/constants/app_strings.dart';
import 'package:untitled/models/saved_avatar.dart';
import 'package:untitled/services/storage_service.dart';
import 'package:untitled/widgets/custom_dialogs.dart';
import 'package:untitled/widgets/custom_snackbars.dart';

/// GetX Controller managing avatar creation, customization, and saving.
class AvatarCreatorController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final RxBool isSaving = false.obs;

  /// Encode current fluttermoji state to SVG string and save to storage.
  Future<void> saveAvatar() async {
    final String? avatarName = await CustomDialogs.showSaveNameDialog();

    if (avatarName == null || avatarName.trim().isEmpty) {
      return;
    }

    try {
      isSaving.value = true;
      // Get options JSON string from fluttermoji
      final String encodedOptions = await FluttermojiFunctions().encodeMySVGtoString();
      
      // Convert to actual rendered <svg> XML payload
      final String actualSvgXml = FluttermojiFunctions().decodeFluttermojifromString(encodedOptions);

      final newAvatar = SavedAvatar(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: avatarName.trim(),
        svgData: actualSvgXml,
        createdAt: DateTime.now(),
      );

      await _storageService.saveAvatar(newAvatar);
      
      // Pop CreatorScreen back to GalleryScreen immediately!
      Get.back(result: true);
      
      // Show success feedback toast on the gallery screen
      CustomSnackbars.showSuccess(AppStrings.avatarSavedSuccess);
    } catch (e) {
      CustomSnackbars.showError('Failed to save avatar: $e');
    } finally {
      isSaving.value = false;
    }
  }

  /// Go back to previous screen maintaining clean navigation stack.
  void goBack() {
    Get.back();
  }
}
