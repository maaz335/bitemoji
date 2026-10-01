import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Service to merge modular GLB body parts (Head, Body, Legs, Feet)
/// into a single, unified, fully-assembled 3D avatar GLB file.
class GlbMergerService {
  // In-memory cache for raw asset bytes to achieve sub-10ms part swapping
  static final Map<String, Uint8List> _assetCache = {};

  /// Loads bytes for a given asset path, caching in memory
  static Future<Uint8List> loadAssetBytes(String assetPath) async {
    if (_assetCache.containsKey(assetPath)) {
      return _assetCache[assetPath]!;
    }
    final byteData = await rootBundle.load(assetPath);
    final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    _assetCache[assetPath] = bytes;
    return bytes;
  }

  /// Merges 4 modular part asset paths into a single assembled GLB file
  static Future<File> assembleModularAvatar({
    required List<String> partAssetPaths,
    String? outputFileName,
  }) async {
    final List<Uint8List> glbDataList = [];
    for (final path in partAssetPaths) {
      final bytes = await loadAssetBytes(path);
      glbDataList.add(bytes);
    }

    final mergedBytes = mergeGlbBytes(glbDataList);

    final dir = await getTemporaryDirectory();
    final fileName = outputFileName ?? 'assembled_avatar_${DateTime.now().millisecondsSinceEpoch}.glb';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(mergedBytes, flush: true);
    return file;
  }

  /// Binary merger for multiple GLB (glTF 2.0 Binary) files
  static Uint8List mergeGlbBytes(List<Uint8List> glbDataList) {
    final Map<String, dynamic> mergedJson = {
      'asset': {'version': '2.0', 'generator': 'BitemojiGlbMerger'},
      'scene': 0,
      'scenes': [
        {'nodes': <int>[]}
      ],
      'nodes': <Map<String, dynamic>>[],
      'materials': <Map<String, dynamic>>[],
      'meshes': <Map<String, dynamic>>[],
      'accessors': <Map<String, dynamic>>[],
      'bufferViews': <Map<String, dynamic>>[],
      'buffers': [
        {'byteLength': 0}
      ]
    };

    final BytesBuilder mergedBin = BytesBuilder();
    int currentBinOffset = 0;

    for (final glbBytes in glbDataList) {
      final byteData = ByteData.sublistView(glbBytes);
      final magic = byteData.getUint32(0, Endian.little);
      if (magic != 0x46546C67) {
        throw Exception('Invalid GLB magic header');
      }

      // Chunk 0: JSON
      final chunk0Len = byteData.getUint32(12, Endian.little);
      final chunk0Type = byteData.getUint32(16, Endian.little);
      if (chunk0Type != 0x4E4F534A) {
        throw Exception('Chunk 0 is not JSON');
      }
      final jsonBytes = glbBytes.sublist(20, 20 + chunk0Len);
      final Map<String, dynamic> gltf = json.decode(utf8.decode(jsonBytes)) as Map<String, dynamic>;

      // Chunk 1: BIN
      final chunk1HeaderOffset = 20 + chunk0Len;
      final chunk1Len = byteData.getUint32(chunk1HeaderOffset, Endian.little);
      final binBytes = glbBytes.sublist(chunk1HeaderOffset + 8, chunk1HeaderOffset + 8 + chunk1Len);

      final binOffset = currentBinOffset;
      mergedBin.add(binBytes);
      currentBinOffset += binBytes.length;

      // Align BIN to 4 bytes boundary
      final pad = (4 - (binBytes.length % 4)) % 4;
      for (int p = 0; p < pad; p++) {
        mergedBin.addByte(0);
        currentBinOffset++;
      }

      final bvOffset = (mergedJson['bufferViews'] as List).length;
      final accOffset = (mergedJson['accessors'] as List).length;
      final matOffset = (mergedJson['materials'] as List).length;

      // 1. Remap and copy BufferViews
      for (final bv in (gltf['bufferViews'] as List? ?? [])) {
        final newBv = Map<String, dynamic>.from(bv as Map);
        newBv['buffer'] = 0;
        newBv['byteOffset'] = ((newBv['byteOffset'] as num?)?.toInt() ?? 0) + binOffset;
        (mergedJson['bufferViews'] as List).add(newBv);
      }

      // 2. Remap and copy Accessors
      for (final acc in (gltf['accessors'] as List? ?? [])) {
        final newAcc = Map<String, dynamic>.from(acc as Map);
        if (newAcc.containsKey('bufferView')) {
          newAcc['bufferView'] = (newAcc['bufferView'] as num).toInt() + bvOffset;
        }
        (mergedJson['accessors'] as List).add(newAcc);
      }

      // 3. Copy Materials
      for (final mat in (gltf['materials'] as List? ?? [])) {
        (mergedJson['materials'] as List).add(Map<String, dynamic>.from(mat as Map));
      }

      // 4. Remap and copy Meshes & Nodes
      for (final mesh in (gltf['meshes'] as List? ?? [])) {
        final newMesh = <String, dynamic>{
          'name': (mesh as Map)['name'] ?? 'mesh',
          'primitives': <Map<String, dynamic>>[]
        };

        for (final prim in (mesh['primitives'] as List? ?? [])) {
          final primMap = prim as Map;
          final newAttributes = <String, dynamic>{};
          final attrs = primMap['attributes'] as Map? ?? {};
          for (final entry in attrs.entries) {
            newAttributes[entry.key as String] = (entry.value as num).toInt() + accOffset;
          }

          final newPrim = <String, dynamic>{
            'attributes': newAttributes,
          };

          if (primMap.containsKey('indices')) {
            newPrim['indices'] = (primMap['indices'] as num).toInt() + accOffset;
          }
          if (primMap.containsKey('material')) {
            newPrim['material'] = (primMap['material'] as num).toInt() + matOffset;
          }

          (newMesh['primitives'] as List).add(newPrim);
        }

        final meshIdx = (mergedJson['meshes'] as List).length;
        (mergedJson['meshes'] as List).add(newMesh);

        final nodeIdx = (mergedJson['nodes'] as List).length;
        (mergedJson['nodes'] as List).add({
          'name': 'Node_$meshIdx',
          'mesh': meshIdx,
        });

        ((mergedJson['scenes'] as List)[0]['nodes'] as List).add(nodeIdx);
      }
    }

    final binPayload = mergedBin.toBytes();
    (mergedJson['buffers'] as List)[0]['byteLength'] = binPayload.length;

    // Encode JSON and pad to 4 bytes with spaces (0x20)
    final jsonStr = json.encode(mergedJson);
    final jsonBytesBuilder = BytesBuilder();
    jsonBytesBuilder.add(utf8.encode(jsonStr));
    final jsonPad = (4 - (jsonBytesBuilder.length % 4)) % 4;
    for (int p = 0; p < jsonPad; p++) {
      jsonBytesBuilder.addByte(0x20);
    }
    final finalJsonBytes = jsonBytesBuilder.toBytes();

    // Assemble final GLB
    final totalLength = 12 + 8 + finalJsonBytes.length + 8 + binPayload.length;
    final outBuilder = BytesBuilder();

    // 12-byte Header
    final header = ByteData(12);
    header.setUint32(0, 0x46546C67, Endian.little); // 'glTF'
    header.setUint32(4, 2, Endian.little); // version 2
    header.setUint32(8, totalLength, Endian.little);
    outBuilder.add(header.buffer.asUint8List());

    // Chunk 0 Header + JSON
    final chunk0Header = ByteData(8);
    chunk0Header.setUint32(0, finalJsonBytes.length, Endian.little);
    chunk0Header.setUint32(4, 0x4E4F534A, Endian.little); // 'JSON'
    outBuilder.add(chunk0Header.buffer.asUint8List());
    outBuilder.add(finalJsonBytes);

    // Chunk 1 Header + BIN
    final chunk1Header = ByteData(8);
    chunk1Header.setUint32(0, binPayload.length, Endian.little);
    chunk1Header.setUint32(4, 0x004E4942, Endian.little); // 'BIN\0'
    outBuilder.add(chunk1Header.buffer.asUint8List());
    outBuilder.add(binPayload);

    return outBuilder.toBytes();
  }
}
