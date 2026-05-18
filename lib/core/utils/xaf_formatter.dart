import 'package:intl/intl.dart';

class XafFormatter {
  static final _fmt = NumberFormat('#,##0', 'fr_FR');

  static String format(double amount) => '${_fmt.format(amount.round())} FCFA';

  static String formatInt(int amount) => '${_fmt.format(amount)} FCFA';

  /// Returns amount without currency label (for receipt line items)
  static String amount(double value) => _fmt.format(value.round());
}
