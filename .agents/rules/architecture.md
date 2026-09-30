# Bitmoji Avatar Studio — Project Architecture & Rules

## 1. Architecture Overview (GetX State Management & Service Pattern)
This project follows a strict **Clean Architecture / GetX Pattern**:
- **`lib/main.dart`**: App entry point initializing `GetStorage`, `StorageService`, global GetX dependencies, and GetPage routing table.
- **`lib/core/`**:
  - `constants/app_strings.dart`: Centralized string repository. **No hardcoded text strings in UI components!**
  - `constants/app_constants.dart`: Layout spacing, radii, storage keys, animation durations.
  - `theme/app_theme.dart`: Design system, custom dark palette, linear gradients, Material 3 ThemeData.
- **`lib/controllers/`**: Reactive `GetxController` state managers (`AvatarGalleryController`, `AvatarCreatorController`, `AvatarDetailController`).
- **`lib/services/`**: High-performance persistence layer (`StorageService`) powered by `GetStorage`.
- **`lib/models/`**: Data models (`SavedAvatar`) with serialization (`toMap`, `fromMap`).
- **`lib/screens/`**: UI Views (`AvatarGalleryScreen`, `AvatarCreatorScreen`, `AvatarDetailScreen`) implementing `StatelessWidget` with `GetView<Controller>`.
- **`lib/widgets/`**: Reusable custom UI components (`CustomButton`, `AvatarCardWidget`, `CustomDialogs`, `CustomSnackbars`).

## 2. Mandatory Rules for Developers & AI Agents
1. **Zero Standard Navigator**:
   - Never use `Navigator.push`, `Navigator.pop`, `Navigator.pushReplacement`.
   - Always use GetX routing: `Get.toNamed()`, `Get.back()`, `Get.offNamed()`.
2. **Stateless UI with GetView**:
   - All screens must extend `StatelessWidget` and bind via `GetView<T>` or `Obx()`.
   - Never use `StatefulWidget` for business logic or state mutation.
3. **No Hardcoded Strings**:
   - Add all UI text to `AppStrings` in `lib/core/constants/app_strings.dart`.
4. **Local Persistence**:
   - All disk operations must route through `StorageService` (`GetStorage`).
5. **Custom Dialogs & Snackbars**:
   - Use `CustomDialogs.showConfirmDelete()` and `CustomSnackbars.showSuccess()` for user interaction feedback.
