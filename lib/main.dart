import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/controllers/avatar_creator_controller.dart';
import 'package:untitled/controllers/avatar_detail_controller.dart';
import 'package:untitled/controllers/avatar_gallery_controller.dart';
import 'package:untitled/core/constants/app_strings.dart';
import 'package:untitled/core/theme/app_theme.dart';
import 'package:untitled/screens/avatar_creator_screen.dart';
import 'package:untitled/screens/avatar_detail_screen.dart';
import 'package:untitled/screens/avatar_gallery_screen.dart';
import 'package:untitled/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize GetStorage high-performance local persistence service
  final storageService = StorageService();
  await storageService.init();
  Get.put<StorageService>(storageService, permanent: true);

  runApp(const BitmojiAvatarApp());
}

class BitmojiAvatarApp extends StatelessWidget {
  const BitmojiAvatarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      getPages: [
        GetPage(
          name: '/',
          page: () => const AvatarGalleryScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut<AvatarGalleryController>(() => AvatarGalleryController());
          }),
        ),
        GetPage(
          name: '/creator',
          page: () => const AvatarCreatorScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut<AvatarCreatorController>(() => AvatarCreatorController());
          }),
          transition: Transition.rightToLeftWithFade,
        ),
        GetPage(
          name: '/detail',
          page: () => const AvatarDetailScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut<AvatarDetailController>(() => AvatarDetailController());
          }),
          transition: Transition.fadeIn,
        ),
      ],
    );
  }
}
