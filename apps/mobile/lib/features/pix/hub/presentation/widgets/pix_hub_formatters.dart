import 'package:intl/intl.dart';

/// Formats [amountInCents] as Brazilian currency.
String formatBrlCents(int amountInCents) {
  return NumberFormat.currency(
    locale: 'pt_BR',
    symbol: r'R$',
    decimalDigits: 2,
  ).format(amountInCents / 100);
}

/// Formats DePix base units (8 decimals) as `1.234,56 DEPIX`.
///
/// The value uses integer math, so no amount passes through a double. The
/// fraction keeps 2 digits, or all 8 when the extra digits are not zero.
String formatDepixUnits(int units) {
  const unitsPerDepix = 100000000;
  final whole = units ~/ unitsPerDepix;
  final fraction = (units % unitsPerDepix).toString().padLeft(8, '0');
  final digits = fraction.substring(2) == '000000'
      ? fraction.substring(0, 2)
      : fraction;
  final grouped = NumberFormat.decimalPattern('pt_BR').format(whole);
  return '$grouped,$digits DEPIX';
}

/// Formats an integer with the Brazilian thousands separator.
String formatPixInteger(int value) =>
    NumberFormat.decimalPattern('pt_BR').format(value);

/// Formats a date as `dd/MM/yyyy`.
String formatPixDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

/// Formats a date as `dd/MM/yyyy HH:mm`.
String formatPixDateTime(DateTime date) =>
    DateFormat('dd/MM/yyyy HH:mm').format(date);

/// Formats a date as `dd MMM` for compact lists.
String formatPixShortDate(DateTime date, String localeName) =>
    DateFormat('dd MMM', localeName).format(date);
