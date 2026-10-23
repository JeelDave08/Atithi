import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'breakpoints.dart';

class AppContainer extends StatelessWidget {
  const AppContainer({
    required this.child,
    this.padding,
    this.backgroundColor = AppColors.cream,
    this.maxWidthOverride,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color backgroundColor;
  final double? maxWidthOverride;

  @override
  Widget build(BuildContext context) {
    final maxWidth =
        maxWidthOverride ??
        context.responsive<double>(
          mobile: double.infinity,
          tablet: 840.0,
          desktop: 1200.0,
        );
    final horizontalPadding = context.responsive(
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );
    return ColoredBox(
      color: backgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding:
                padding ?? EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: child,
          ),
        ),
      ),
    );
  }
}
