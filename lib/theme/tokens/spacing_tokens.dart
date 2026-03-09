import '../app_scale.dart';

class AppSpacing {
  const AppSpacing._();

  static double get xs => AppScale.s(4);
  static double get sm => AppScale.s(8);
  static double get md => AppScale.s(12);
  static double get base => AppScale.s(16);
  static double get lg => AppScale.s(24);
  static double get xl => AppScale.s(32);
  static double get xxl => AppScale.s(48);

  static double get spacingXS => xs;
  static double get spacingS => sm;
  static double get spacingM => base;
  static double get spacingL => lg;
  static double get spacingXL => xl;

  static double get screenHPadding => base;
  static double get screenVPadding => base;
  static double get cardPadding => md;
  static double get sectionSpacing => lg;
  static double get itemSpacing => sm;
}
