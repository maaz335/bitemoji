import 'dart:convert';
import 'package:fluttermoji/fluttermoji.dart';

/// Represents a user-customized avatar saved in storage (supports 2D SVG and 3D GLB models).
class SavedAvatar {
  final String id;
  final String name;
  final String svgData;
  final String? glbPath;
  final DateTime createdAt;

  SavedAvatar({
    required this.id,
    required this.name,
    required this.svgData,
    this.glbPath,
    required this.createdAt,
  });

  /// Automatically resolves raw SVG XML string from either encoded JSON or direct SVG XML.
  String get renderedSvg {
    final trimmed = svgData.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('{"')) {
      try {
        return FluttermojiFunctions().decodeFluttermojifromString(trimmed);
      } catch (_) {
        return svgData;
      }
    }
    return svgData;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'svgData': svgData,
      'glbPath': glbPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavedAvatar.fromMap(Map<String, dynamic> map) {
    return SavedAvatar(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Untitled Avatar',
      svgData: map['svgData'] ?? '',
      glbPath: map['glbPath'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory SavedAvatar.fromJson(String source) =>
      SavedAvatar.fromMap(json.decode(source));

  SavedAvatar copyWith({
    String? id,
    String? name,
    String? svgData,
    String? glbPath,
    DateTime? createdAt,
  }) {
    return SavedAvatar(
      id: id ?? this.id,
      name: name ?? this.name,
      svgData: svgData ?? this.svgData,
      glbPath: glbPath ?? this.glbPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

