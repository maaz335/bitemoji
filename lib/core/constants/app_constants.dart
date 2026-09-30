/// Global app constants for layout metrics, animation durations, and storage keys.
class AppConstants {
  // Storage Keys
  static const String avatarStorageKey = 'saved_avatars_v1';
  static const String themeStorageKey = 'is_dark_mode';
  
  // Layout Padding & Radii
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  
  static const double radiusS = 8.0;
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;
  static const double radiusCircular = 100.0;
  
  // Elevation & Blur
  static const double cardElevation = 4.0;
  
  // Animations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);
}
