import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Formats a double [amount] as a currency string.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final _formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
  );

  static String format(double amount) => _formatter.format(amount);

  static String formatCompact(double amount) {
    if (amount >= 100000) {
      return '${AppConstants.currencySymbol}${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${AppConstants.currencySymbol}${(amount / 1000).toStringAsFixed(1)}K';
    }
    return format(amount);
  }
}
