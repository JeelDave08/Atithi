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
