
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

class GeocodingLoader {
  // --- Private members ---

  // A cache for the manifest file itself.
  static Map<String, List<String>>? _manifest;

  // A cache for the loaded geocoding data to avoid re-reading from assets.
  // The key is a compound key, e.g., "en_86".
  static final Map<String, Map<int, String>> _dataCache = {};

  static const _assetPath = 'packages/dlibphonenumber/assets/geocoding';

  // --- Public API ---

  /// This is the main public method.
  /// It ensures the data for a given country code and language is loaded.
  /// It implements a lazy-loading strategy using a manifest file.
  ///
  /// Returns the geocoding data map for the requested language and country.
  /// Returns null if no data is available.
  static Future<Map<int, String>?>getDataFor(int countryCode, String language) async {
    final cacheKey = '${language}_$countryCode';
    if (_dataCache.containsKey(cacheKey)) {
      return _dataCache[cacheKey];
    }

    final manifest = await _getManifest();
    final countryCodeStr = countryCode.toString();

    if (!manifest.containsKey(countryCodeStr)) {
      return null; // No data for this country code.
    }

    // Filter the file list from the manifest by the requested language.
    final languageSuffix = '_$language.json';
    final filesToLoad = manifest[countryCodeStr]!
        .where((filename) => filename.endsWith(languageSuffix))
        .toList();

    if (filesToLoad.isEmpty) {
      return null; // No files for this specific language.
    }

    // Load and merge all required files.
    final Map<int, String> mergedData = {};
    for (final filename in filesToLoad) {
      try {
        final assetKey = '$_assetPath/$filename';
        final jsonString = await rootBundle.loadString(assetKey);
        final Map<String, dynamic> json = jsonDecode(jsonString);
        json.forEach((key, value) {
          mergedData[int.parse(key)] = value as String;
        });
      } catch (e) {
        print('Error loading geocoding asset: $filename. Error: $e');
        // Depending on strictness, you might want to fail here.
        // For now, we continue, allowing partial data.
      }
    }

    // Cache the merged data for future requests.
    _dataCache[cacheKey] = mergedData;
    return mergedData;
  }

  // --- Internal helper methods ---

  /// Loads the manifest.json file from assets.
  /// Caches the manifest in memory after the first load.
  static Future<Map<String, List<String>>> _getManifest() async {
    if (_manifest != null) {
      return _manifest!;
    }
    try {
      final jsonString = await rootBundle.loadString('$_assetPath/manifest.json');
      final Map<String, dynamic> json = jsonDecode(jsonString);
      _manifest = json.map((key, value) {
        return MapEntry(key, List<String>.from(value));
      });
      return _manifest!;
    } catch (e) {
      print('CRITICAL: Could not load or parse geocoding manifest.json. Error: $e');
      // If the manifest is missing, geocoding will not work.
      return {};
    }
  }
}
