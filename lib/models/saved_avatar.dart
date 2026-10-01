import 'dart:convert';
import 'package:fluttermoji/fluttermoji.dart';

/// Represents a user-customized avatar saved in storage (supports 2D SVG and 3D GLB models).
class SavedAvatar {
  final String id;
  final String name;
  final String svgData;
  final String? glbPath;
  final String? thumbnailPath;
  final DateTime createdAt;

  SavedAvatar({
    required this.id,
    required this.name,
    required this.svgData,
    this.glbPath,
    this.thumbnailPath,
    required this.createdAt,
  });

  bool get is3D => glbPath != null && glbPath!.isNotEmpty;

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
      'thumbnailPath': thumbnailPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavedAvatar.fromMap(Map<String, dynamic> map) {
    final glb = map['glbPath'] as String?;
    String? thumb = map['thumbnailPath'] as String?;
    if (thumb == null && glb != null && glb.isNotEmpty) {
      final lower = glb.toLowerCase();
      if (lower.contains('adventurer')) {
        thumb = 'assets/thumbnails/adventurer_head.png';
      } else if (lower.contains('farmer')) {
        thumb = 'assets/thumbnails/farmer_head.png';
      } else if (lower.contains('worker')) {
        thumb = 'assets/thumbnails/worker_head.png';
      } else if (lower.contains('king')) {
        thumb = 'assets/thumbnails/king_head.png';
      } else if (lower.contains('suit')) {
        thumb = 'assets/thumbnails/suit_head.png';
      } else if (lower.contains('spacesuit')) {
        thumb = 'assets/thumbnails/spacesuit_head.png';
      } else if (lower.contains('swat')) {
        thumb = 'assets/thumbnails/swat_head.png';
      } else if (lower.contains('beach')) {
        thumb = 'assets/thumbnails/beach_head.png';
      } else if (lower.contains('punk')) {
        thumb = 'assets/thumbnails/punk_head.png';
      } else if (lower.contains('witch')) {
        thumb = 'assets/thumbnails/witch_head.png';
      } else if (lower.contains('soldier')) {
        thumb = 'assets/thumbnails/soldier_head.png';
      } else if (lower.contains('formal')) {
        thumb = 'assets/thumbnails/formal_head.png';
      } else if (lower.contains('scifi')) {
        thumb = 'assets/thumbnails/scifi_head.png';
      } else if (lower.contains('medieval')) {
        thumb = 'assets/thumbnails/medieval_head.png';
      } else if (lower.contains('hoodie') || lower.contains('casual')) {
        thumb = 'assets/thumbnails/casual_head.png';
      } else {
        thumb = 'assets/thumbnails/default_3d.png';
      }
    }
    return SavedAvatar(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Untitled Avatar',
      svgData: map['svgData'] ?? '',
      glbPath: glb,
      thumbnailPath: thumb,
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
    String? thumbnailPath,
    DateTime? createdAt,
  }) {
    return SavedAvatar(
      id: id ?? this.id,
      name: name ?? this.name,
      svgData: svgData ?? this.svgData,
      glbPath: glbPath ?? this.glbPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

