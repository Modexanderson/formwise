import 'package:flutter/services.dart';

/// Country codes supported by postal code validation.
enum PostalCountry {
  /// United States: 5 digits or ZIP+4 (12345 or 12345-6789)
  us('US', r'^\d{5}(-\d{4})?$', '12345'),

  /// United Kingdom: A9 9AA, A99 9AA, A9A 9AA, AA9 9AA, AA99 9AA, AA9A 9AA
  uk('UK', r'^[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2}$', 'SW1A 1AA'),

  /// Canada: A1A 1A1
  canada('CA', r'^[A-Z]\d[A-Z]\s?\d[A-Z]\d$', 'K1A 0B1'),

  /// Japan: 3 digits, hyphen, 4 digits (123-4567)
  japan('JP', r'^\d{3}-?\d{4}$', '123-4567'),

  /// Germany: 5 digits
  germany('DE', r'^\d{5}$', '10115'),

  /// France: 5 digits
  france('FR', r'^\d{5}$', '75001'),

  /// Australia: 4 digits
  australia('AU', r'^\d{4}$', '2000'),

  /// India: 6 digits
  india('IN', r'^\d{6}$', '110001'),

  /// Brazil: 5 digits, hyphen, 3 digits (12345-678)
  brazil('BR', r'^\d{5}-?\d{3}$', '01001-000'),

  /// Nigeria: 6 digits
  nigeria('NG', r'^\d{6}$', '100001'),

  /// Netherlands: 4 digits + 2 letters (1234 AB)
  netherlands('NL', r'^\d{4}\s?[A-Z]{2}$', '1234 AB'),

  /// Italy: 5 digits
  italy('IT', r'^\d{5}$', '00100'),

  /// Spain: 5 digits (01000-52999)
  spain('ES', r'^\d{5}$', '28001'),

  /// South Korea: 5 digits
  southKorea('KR', r'^\d{5}$', '03141'),

  /// China: 6 digits
  china('CN', r'^\d{6}$', '100000'),

  /// Russia: 6 digits
  russia('RU', r'^\d{6}$', '101000'),

  /// Mexico: 5 digits
  mexico('MX', r'^\d{5}$', '06600'),

  /// Switzerland: 4 digits
  switzerland('CH', r'^\d{4}$', '3000'),

  /// Poland: 2 digits, hyphen, 3 digits (12-345)
  poland('PL', r'^\d{2}-?\d{3}$', '00-001'),

  /// Sweden: 3 digits + 2 digits (123 45)
  sweden('SE', r'^\d{3}\s?\d{2}$', '111 22');

  final String code;
  final String _pattern;
  final String example;

  const PostalCountry(this.code, this._pattern, this.example);

  RegExp get regex => RegExp(_pattern, caseSensitive: false);
}

/// Validates postal/zip codes by country format.
class PostalCodeValidator {
  PostalCodeValidator._();

  /// Validates a postal code against a specific country's format.
  static String? Function(String?) forCountry(
    PostalCountry country, {
    String? errorMessage,
  }) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return errorMessage ?? 'Please enter a postal code';
      }

      final trimmed = value.trim().toUpperCase();

      if (!country.regex.hasMatch(trimmed)) {
        return errorMessage ??
            'Invalid postal code for ${country.code} (e.g. ${country.example})';
      }

      return null;
    };
  }

  /// Auto-detects the country format and validates.
  ///
  /// Tries each country's pattern and returns valid if any match.
  /// Use [preferredCountries] to prioritize certain formats when
  /// multiple could match (e.g., "12345" matches US, DE, FR, etc.).
  static String? Function(String?) autoDetect({
    String errorMessage = 'Invalid postal code format',
    List<PostalCountry>? preferredCountries,
  }) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) return errorMessage;

      final trimmed = value.trim().toUpperCase();
      final countries = preferredCountries ?? PostalCountry.values;

      for (final country in countries) {
        if (country.regex.hasMatch(trimmed)) return null;
      }

      // If preferred didn't match, try all
      if (preferredCountries != null) {
        for (final country in PostalCountry.values) {
          if (country.regex.hasMatch(trimmed)) return null;
        }
      }

      return errorMessage;
    };
  }

  /// Detects which country a postal code likely belongs to.
  ///
  /// Returns all matching countries, most specific first.
  static List<PostalCountry> detectCountry(String postalCode) {
    final trimmed = postalCode.trim().toUpperCase();
    final matches = <PostalCountry>[];

    for (final country in PostalCountry.values) {
      if (country.regex.hasMatch(trimmed)) {
        matches.add(country);
      }
    }

    return matches;
  }
}

/// Input formatter for postal codes that auto-formats as you type.
class PostalCodeFormatter extends TextInputFormatter {
  final PostalCountry country;

  const PostalCodeFormatter(this.country);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    switch (country) {
      case PostalCountry.us:
        return _formatUs(newValue);
      case PostalCountry.japan:
        return _formatWithSeparator(newValue, 3, '-');
      case PostalCountry.brazil:
        return _formatWithSeparator(newValue, 5, '-');
      case PostalCountry.poland:
        return _formatWithSeparator(newValue, 2, '-');
      case PostalCountry.uk:
        return _formatUk(newValue);
      case PostalCountry.canada:
        return _formatCanada(newValue);
      case PostalCountry.netherlands:
        return _formatNetherlands(newValue);
      case PostalCountry.sweden:
        return _formatWithSeparator(newValue, 3, ' ', maxLen: 5);
      default:
        return newValue;
    }
  }

  TextEditingValue _formatUs(TextEditingValue value) {
    final digits = value.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length <= 5) return value.copyWith(text: digits);

    final formatted = '${digits.substring(0, 5)}-${digits.substring(5, digits.length.clamp(0, 9))}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  TextEditingValue _formatWithSeparator(
    TextEditingValue value,
    int splitAt,
    String separator, {
    int? maxLen,
  }) {
    final digits = value.text.replaceAll(RegExp(r'[^\d]'), '');
    final capped = maxLen != null && digits.length > maxLen
        ? digits.substring(0, maxLen)
        : digits;

    if (capped.length <= splitAt) return value.copyWith(text: capped);

    final formatted = '${capped.substring(0, splitAt)}$separator${capped.substring(splitAt)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  TextEditingValue _formatUk(TextEditingValue value) {
    final cleaned = value.text.replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (cleaned.length <= 3) return value.copyWith(text: cleaned);

    // UK postcodes: outward (2-4 chars) + space + inward (3 chars)
    final inwardStart = cleaned.length - 3;
    if (inwardStart < 2) return value.copyWith(text: cleaned);

    final formatted = '${cleaned.substring(0, inwardStart)} ${cleaned.substring(inwardStart)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  TextEditingValue _formatCanada(TextEditingValue value) {
    final cleaned = value.text.replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (cleaned.length <= 3) return value.copyWith(text: cleaned);

    final capped = cleaned.length > 6 ? cleaned.substring(0, 6) : cleaned;
    final formatted = '${capped.substring(0, 3)} ${capped.substring(3)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  TextEditingValue _formatNetherlands(TextEditingValue value) {
    final cleaned = value.text.replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (cleaned.length <= 4) return value.copyWith(text: cleaned);

    final capped = cleaned.length > 6 ? cleaned.substring(0, 6) : cleaned;
    final formatted = '${capped.substring(0, 4)} ${capped.substring(4)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
