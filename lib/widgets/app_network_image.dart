import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/image_utils.dart';
import '../theme/app_colors.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveImageUrl(url);
    Widget image;
    if (resolved == null) {
      image = const _Placeholder();
    } else {
      if (kDebugMode) debugPrint('Resolved room image URL: $resolved');
      image = Image.network(
        resolved,
        fit: fit,
        width: width,
        height: height,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const ColoredBox(
                color: AppColors.cream,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.darkGold,
                    ),
                  ),
                ),
              ),
        errorBuilder: (context, error, stack) {
          debugPrint('IMAGE ERROR: $resolved | $error');
          return const _Placeholder();
        },
      );
    }
    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    if (width != null || height != null) {
      image = SizedBox(width: width, height: height, child: image);
    }
    return image;
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AppColors.cream,
    child: Center(
      child: Icon(Icons.bed_outlined, color: AppColors.greyText, size: 48),
    ),
  );
}
