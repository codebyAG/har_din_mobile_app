import 'package:flutter/services.dart';

/// Cleans a typed or pasted phone number down to the ten digits the API
/// wants: `+91 98765-43210`, `09876543210` and `919876543210` all become
/// `9876543210`. The server applies +91 itself.
String normalizeIndianPhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length > 10 && digits.startsWith('91')) {
    digits = digits.substring(2);
  } else if (digits.length > 10 && digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  return digits.length > 10 ? digits.substring(0, 10) : digits;
}

/// Input formatter that applies [normalizeIndianPhone] — so a paste from
/// the contacts app isn't blocked or truncated to the wrong ten digits.
class IndianPhoneFormatter extends TextInputFormatter {
  const IndianPhoneFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = normalizeIndianPhone(newValue.text);
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  }
}
