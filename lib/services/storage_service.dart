import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:untitled/core/constants/app_constants.dart';
import 'package:untitled/models/saved_avatar.dart';

/// High-performance local persistence service using GetStorage key-value store.
class StorageService extends GetxService {
  late final GetStorage _box;

  Future<StorageService> init() async {
    await GetStorage.init();
    _box = GetStorage();
    return this;
  }

  /// Retrieve all saved avatars from disk.
  List<SavedAvatar> loadAvatars() {
    try {
      final List<dynamic>? rawList = _box.read<List<dynamic>>(AppConstants.avatarStorageKey);
      if (rawList == null) return [];
      return rawList.map((e) => SavedAvatar.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      Get.log('Error loading avatars from storage: $e');
      return [];
    }
  }

  /// Save or update an avatar in local storage.
  Future<void> saveAvatar(SavedAvatar avatar) async {
    final List<SavedAvatar> currentList = loadAvatars();
    final index = currentList.indexWhere((element) => element.id == avatar.id);

    if (index >= 0) {
      currentList[index] = avatar;
    } else {
      currentList.insert(0, avatar);
    }

    final rawList = currentList.map((a) => a.toMap()).toList();
    await _box.write(AppConstants.avatarStorageKey, rawList);
  }

  /// Delete an avatar by ID from storage.
  Future<void> deleteAvatar(String id) async {
    final List<SavedAvatar> currentList = loadAvatars();
    currentList.removeWhere((element) => element.id == id);
    final rawList = currentList.map((a) => a.toMap()).toList();
    await _box.write(AppConstants.avatarStorageKey, rawList);
  }

  /// Clear all saved avatar records.
  Future<void> clearAll() async {
    await _box.remove(AppConstants.avatarStorageKey);
  }
}
