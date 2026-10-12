import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Convenience accessor for the finance/subscription tokens (design.md §2).
///
/// Usage: `Theme.of(context).finance.surface`.
extension FinanceTheme on ThemeData {
  AppFinanceColors get finance => extension<AppFinanceColors>() ?? AppFinanceColors.dark;
}

extension FinanceContext on BuildContext {
  AppFinanceColors get finance => Theme.of(this).finance;
}
