part of '../main.dart';

enum ScreenClass { compact, medium, wide }

abstract final class AppBreakpoints {
  static const double compact = 700;
  static const double wide = 1100;
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

abstract final class AppSizes {
  static const double minTouchTarget = 48;
  static const double contentMaxWidth = 1320;
}

ScreenClass screenClassForWidth(double width) {
  if (width < AppBreakpoints.compact) return ScreenClass.compact;
  if (width < AppBreakpoints.wide) return ScreenClass.medium;
  return ScreenClass.wide;
}

ScreenClass screenClassOf(BuildContext context) =>
    screenClassForWidth(MediaQuery.sizeOf(context).width);
