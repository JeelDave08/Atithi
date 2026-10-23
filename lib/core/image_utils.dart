import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const roomImageBucket = 'room-images';

/// Resolves either a full image URL or an object path in room storage.
String? resolveImageUrl(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return Uri.encodeFull(optimizedImageUrl(value));
  }
  try {
    final path = value.replaceFirst(RegExp(r'^/+'), '');
    final publicUrl = Supabase.instance.client.storage
        .from(roomImageBucket)
        .getPublicUrl(path);
    return Uri.encodeFull(publicUrl);
  } catch (error) {
    if (kDebugMode) debugPrint('Could not resolve room image $value: $error');
    return null;
  }
}

/// Adds image resizing parameters to Unsplash image URLs.
String optimizedImageUrl(String url, {int width = 800}) {
  final uri = Uri.tryParse(url);
  final host = uri?.host.toLowerCase();
  final isUnsplash =
      host == 'unsplash.com' || (host?.endsWith('.unsplash.com') ?? false);
  if (uri == null || !uri.hasScheme || !isUnsplash) {
    return url;
  }

  return uri
      .replace(
        queryParameters: {...uri.queryParameters, 'w': '$width', 'q': '70'},
      )
      .toString();
}
