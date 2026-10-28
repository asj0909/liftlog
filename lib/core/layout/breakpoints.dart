/// 画面幅の区分（基本設計書 6.3）。
enum WindowSize {
  /// 600px 未満：下部 NavigationBar、1 カラム
  compact,

  /// 600〜1023px：NavigationRail、2 ペイン
  medium,

  /// 1024px 以上：ラベル付き NavigationRail、グラフ 2 列
  expanded;

  static const mediumMinWidth = 600.0;
  static const expandedMinWidth = 1024.0;

  static WindowSize fromWidth(double width) {
    if (width >= expandedMinWidth) return WindowSize.expanded;
    if (width >= mediumMinWidth) return WindowSize.medium;
    return WindowSize.compact;
  }
}
