import 'package:flutter/material.dart';

/// Padding inferior consistente para scrolls — evita botões cortados pela barra do sistema.
class ScrollBottomPadding {
  ScrollBottomPadding._();

  static double bottom(BuildContext context, {double extra = 16, bool includeNavBar = false}) {
    var pad = MediaQuery.paddingOf(context).bottom + extra;
    if (includeNavBar) pad += kBottomNavigationBarHeight;
    return pad;
  }

  static EdgeInsets all(BuildContext context, {double extra = 16, bool includeNavBar = false}) {
    return EdgeInsets.fromLTRB(16, 16, 16, bottom(context, extra: extra, includeNavBar: includeNavBar));
  }

  static EdgeInsets onlyBottom(BuildContext context, {double extra = 16, bool includeNavBar = false}) {
    return EdgeInsets.only(bottom: bottom(context, extra: extra, includeNavBar: includeNavBar));
  }
}
