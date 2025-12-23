import 'package:intl/intl.dart';

/// Format a numeric value into a currency string.
///
/// The [value] must represent the amount of money; an optional
/// [currency] can be provided to switch between currencies. The
/// default currency is Peruvian sol (PEN) and falls back to dollar
/// formatting otherwise. The returned string includes the currency
/// symbol and localized number formatting.
String formatMoney(double value, {String currency = 'PEN'}) {
  final formatter = NumberFormat.currency(
    symbol: currency == 'PEN' ? 'S/\u00a0' : '\$',
    decimalDigits: 2,
    locale: 'es_PE',
  );
  return formatter.format(value);
}