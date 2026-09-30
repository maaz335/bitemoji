import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:untitled/core/constants/app_strings.dart';
import 'package:untitled/models/saved_avatar.dart';
import 'package:untitled/services/storage_service.dart';
import 'package:untitled/widgets/custom_dialogs.dart';
import 'package:untitled/widgets/custom_snackbars.dart';

/// GetX controller managing full-screen avatar view, PNG sticker export, download, and social sharing.
class AvatarDetailController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  late final SavedAvatar avatar;
  final RxBool isProcessing = false.obs;

  /// RepaintBoundary key used to capture the avatar widget as a high-res PNG sticker.
  final GlobalKey repaintBoundaryKey = GlobalKey();

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is SavedAvatar) {
      avatar = Get.arguments as SavedAvatar;
    } else {
      Get.back();
    }
  }

  /// Capture the visible avatar widget as high-resolution transparent PNG bytes.
  Future<Uint8List?> _capturePngBytes() async {
    try {
      final boundary = repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 4.0); // 4x resolution for crisp transparent sticker PNG
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      Get.log('Error capturing avatar PNG: $e');
      return null;
    }
  }

  /// Download PNG sticker image file to local storage.
  Future<void> downloadAvatar() async {
    try {
      isProcessing.value = true;
      final directory = await getApplicationDocumentsDirectory();
      final sanitizedName = avatar.name.replaceAll(RegExp(r'[^\w\s]+'), '_').replaceAll(' ', '_');
      final pngBytes = await _capturePngBytes();

      if (pngBytes != null) {
        final fileName = '${sanitizedName}_sticker.png';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pngBytes);

        CustomSnackbars.showSuccess(
          'Saved PNG Sticker to documents:\n$fileName',
          title: AppStrings.success,
        );
      } else {
        // Fallback to SVG format
        final fileName = '${sanitizedName}_avatar.svg';
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(avatar.renderedSvg);

        CustomSnackbars.showSuccess(
          'Saved SVG Vector to documents:\n$fileName',
          title: AppStrings.success,
        );
      }
    } catch (e) {
      CustomSnackbars.showError('Failed to download avatar: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  /// Share avatar PNG sticker image directly to social media apps.
  Future<void> shareAvatar() async {
    try {
      isProcessing.value = true;
      final directory = await getTemporaryDirectory();
      final sanitizedName = avatar.name.replaceAll(RegExp(r'[^\w\s]+'), '_').replaceAll(' ', '_');
      final pngBytes = await _capturePngBytes();

      if (pngBytes != null) {
        final fileName = '${sanitizedName}_sticker.png';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pngBytes);

        final xFile = XFile(file.path, mimeType: 'image/png', name: fileName);
        await Share.shareXFiles(
          [xFile],
          text: 'My custom Bitmoji avatar "${avatar.name}" sticker!',
        );
      } else {
        // Fallback to SVG format
        final fileName = '${sanitizedName}_avatar.svg';
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(avatar.renderedSvg);

        final xFile = XFile(file.path, mimeType: 'image/svg+xml', name: fileName);
        await Share.shareXFiles(
          [xFile],
          text: 'My custom Bitmoji avatar "${avatar.name}"!',
        );
      }
    } catch (e) {
      CustomSnackbars.showError('Failed to share avatar: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  /// Copy raw SVG string to clipboard.
  Future<void> copySvg() async {
    await Clipboard.setData(ClipboardData(text: avatar.renderedSvg));
    CustomSnackbars.showSuccess(AppStrings.svgCopiedSuccess);
  }

  /// Delete avatar and return to gallery.
  Future<void> deleteAvatar() async {
    final confirmed = await CustomDialogs.showConfirmDelete(
      title: AppStrings.confirmDeleteTitle,
      message: AppStrings.confirmDeleteMessage,
    );

    if (confirmed) {
      await _storageService.deleteAvatar(avatar.id);
      CustomSnackbars.showSuccess(AppStrings.avatarDeletedSuccess);
      Get.back(result: true);
    }
  }

  /// Go back cleanly.
  void goBack() {
    Get.back();
  }
}
