import 'package:get/get.dart';
import 'package:untitled/core/constants/app_strings.dart';
import 'package:untitled/models/saved_avatar.dart';
import 'package:untitled/services/storage_service.dart';
import 'package:untitled/widgets/custom_dialogs.dart';
import 'package:untitled/widgets/custom_snackbars.dart';

/// GetX controller managing gallery screen state, avatar lists, search, and navigation.
class AvatarGalleryController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();

  final RxList<SavedAvatar> avatars = <SavedAvatar>[].obs;
  final RxList<SavedAvatar> filteredAvatars = <SavedAvatar>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAvatars();
    // Reactive listener for live search filtering
    ever(searchQuery, (_) => _filterAvatars());
  }

  /// Reload avatar list from local storage.
  void loadAvatars() {
    isLoading.value = true;
    final list = _storageService.loadAvatars();
    avatars.assignAll(list);
    _filterAvatars();
    isLoading.value = false;
  }

  void _filterAvatars() {
    if (searchQuery.isEmpty) {
      filteredAvatars.assignAll(avatars);
    } else {
      final query = searchQuery.value.toLowerCase();
      filteredAvatars.assignAll(
        avatars.where((a) => a.name.toLowerCase().contains(query)).toList(),
      );
    }
  }

  /// Navigate to creator screen using GetX router.
  void goToCreator() {
    Get.toNamed('/creator')?.then((_) => loadAvatars());
  }

  /// Navigate to detail screen using GetX router.
  void goToDetail(SavedAvatar avatar) {
    Get.toNamed('/detail', arguments: avatar)?.then((_) => loadAvatars());
  }

  /// Delete avatar with confirmation dialog.
  Future<void> deleteAvatar(SavedAvatar avatar) async {
    final confirmed = await CustomDialogs.showConfirmDelete(
      title: AppStrings.confirmDeleteTitle,
      message: AppStrings.confirmDeleteMessage,
    );

    if (confirmed) {
      await _storageService.deleteAvatar(avatar.id);
      loadAvatars();
      CustomSnackbars.showSuccess(AppStrings.avatarDeletedSuccess);
    }
  }
}
