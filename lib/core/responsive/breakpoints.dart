import 'package:flutter/widgets.dart';

enum DeviceType { mobile, tablet, desktop }

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  DeviceType get deviceType {
    if (screenWidth < 600) return DeviceType.mobile;
    if (screenWidth < 1024) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;
  bool get isLarge => screenWidth >= 1440;

  T responsive<T>({required T mobile, required T tablet, required T desktop}) =>
      switch (deviceType) {
        DeviceType.mobile => mobile,
        DeviceType.tablet => tablet,
        DeviceType.desktop => desktop,
      };
}
