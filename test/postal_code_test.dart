import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formwise/formwise.dart';

void main() {
  group('PostalCodeValidator', () {
    group('US postal codes', () {
      final validate = PostalCodeValidator.forCountry(PostalCountry.us);

      test('accepts valid 5-digit ZIP', () {
        expect(validate('12345'), isNull);
        expect(validate('00000'), isNull);
        expect(validate('99999'), isNull);
      });

      test('accepts valid ZIP+4', () {
        expect(validate('12345-6789'), isNull);
      });

      test('rejects invalid formats', () {
        expect(validate('1234'), isNotNull);
        expect(validate('123456'), isNotNull);
        expect(validate('ABCDE'), isNotNull);
        expect(validate('12345-'), isNotNull);
        expect(validate('12345-67'), isNotNull);
      });

      test('rejects empty', () {
        expect(validate(''), isNotNull);
        expect(validate(null), isNotNull);
      });
    });

    group('UK postal codes', () {
      final validate = PostalCodeValidator.forCountry(PostalCountry.uk);

      test('accepts valid formats', () {
        expect(validate('SW1A 1AA'), isNull);
        expect(validate('EC1A 1BB'), isNull);
        expect(validate('W1A 0AX'), isNull);
        expect(validate('M1 1AE'), isNull);
        expect(validate('B33 8TH'), isNull);
      });

      test('accepts without space', () {
        expect(validate('SW1A1AA'), isNull);
      });

      test('is case insensitive', () {
        expect(validate('sw1a 1aa'), isNull);
      });

      test('rejects invalid', () {
        expect(validate('12345'), isNotNull);
        expect(validate('AAAA AAA'), isNotNull);
      });
    });

    group('Canada postal codes', () {
      final validate = PostalCodeValidator.forCountry(PostalCountry.canada);

      test('accepts valid formats', () {
        expect(validate('K1A 0B1'), isNull);
        expect(validate('V6B 3K9'), isNull);
      });

      test('accepts without space', () {
        expect(validate('K1A0B1'), isNull);
      });

      test('rejects invalid', () {
        expect(validate('12345'), isNotNull);
        expect(validate('K1A 0B'), isNotNull);
      });
    });

    group('Japan postal codes', () {
      final validate = PostalCodeValidator.forCountry(PostalCountry.japan);

      test('accepts with hyphen', () {
        expect(validate('123-4567'), isNull);
      });

      test('accepts without hyphen', () {
        expect(validate('1234567'), isNull);
      });

      test('rejects invalid', () {
        expect(validate('12345'), isNotNull);
        expect(validate('12345678'), isNotNull);
      });
    });

    group('Germany postal codes', () {
      final validate = PostalCodeValidator.forCountry(PostalCountry.germany);

      test('accepts 5-digit codes', () {
        expect(validate('10115'), isNull);
        expect(validate('80331'), isNull);
      });

      test('rejects invalid', () {
        expect(validate('1234'), isNotNull);
        expect(validate('123456'), isNotNull);
      });
    });

    group('Brazil postal codes', () {
      final validate = PostalCodeValidator.forCountry(PostalCountry.brazil);

      test('accepts with hyphen', () {
        expect(validate('01001-000'), isNull);
      });

      test('accepts without hyphen', () {
        expect(validate('01001000'), isNull);
      });

      test('rejects invalid', () {
        expect(validate('12345'), isNotNull);
      });
    });

    group('Netherlands postal codes', () {
      final validate =
          PostalCodeValidator.forCountry(PostalCountry.netherlands);

      test('accepts valid formats', () {
        expect(validate('1234 AB'), isNull);
        expect(validate('1234AB'), isNull);
      });

      test('rejects invalid', () {
        expect(validate('12345'), isNotNull);
        expect(validate('1234 A'), isNotNull);
      });
    });

    group('India postal codes', () {
      final validate = PostalCodeValidator.forCountry(PostalCountry.india);

      test('accepts 6-digit codes', () {
        expect(validate('110001'), isNull);
      });

      test('rejects invalid', () {
        expect(validate('12345'), isNotNull);
      });
    });

    group('custom error message', () {
      test('uses custom message', () {
        final validate = PostalCodeValidator.forCountry(
          PostalCountry.us,
          errorMessage: 'Bad ZIP',
        );
        expect(validate('abc'), 'Bad ZIP');
      });
    });
  });

  group('PostalCodeValidator.autoDetect', () {
    final validate = PostalCodeValidator.autoDetect();

    test('accepts US ZIP', () {
      expect(validate('12345'), isNull);
    });

    test('accepts UK postcode', () {
      expect(validate('SW1A 1AA'), isNull);
    });

    test('accepts Canada postcode', () {
      expect(validate('K1A 0B1'), isNull);
    });

    test('rejects garbage', () {
      expect(validate('!!!'), isNotNull);
    });

    test('accepts with preferred countries', () {
      final preferred = PostalCodeValidator.autoDetect(
        preferredCountries: [PostalCountry.us],
      );
      expect(preferred('12345'), isNull);
    });
  });

  group('PostalCodeValidator.detectCountry', () {
    test('detects US format', () {
      final countries = PostalCodeValidator.detectCountry('12345');
      expect(countries, contains(PostalCountry.us));
    });

    test('detects UK format', () {
      final countries = PostalCodeValidator.detectCountry('SW1A 1AA');
      expect(countries, contains(PostalCountry.uk));
    });

    test('returns multiple matches for ambiguous codes', () {
      // 5-digit codes match US, Germany, France, Italy, Spain, etc.
      final countries = PostalCodeValidator.detectCountry('12345');
      expect(countries.length, greaterThan(1));
    });

    test('returns empty for unrecognized format', () {
      final countries = PostalCodeValidator.detectCountry('!!!');
      expect(countries, isEmpty);
    });
  });

  group('PostalCodeFormatter', () {
    TextEditingValue format(PostalCodeFormatter formatter, String text) {
      return formatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        ),
      );
    }

    test('US: auto-inserts hyphen for ZIP+4', () {
      final f = const PostalCodeFormatter(PostalCountry.us);
      expect(format(f, '123456789').text, '12345-6789');
    });

    test('US: leaves 5-digit ZIP alone', () {
      final f = const PostalCodeFormatter(PostalCountry.us);
      expect(format(f, '12345').text, '12345');
    });

    test('Japan: auto-inserts hyphen', () {
      final f = const PostalCodeFormatter(PostalCountry.japan);
      expect(format(f, '1234567').text, '123-4567');
    });

    test('Brazil: auto-inserts hyphen', () {
      final f = const PostalCodeFormatter(PostalCountry.brazil);
      expect(format(f, '01001000').text, '01001-000');
    });

    test('UK: auto-inserts space', () {
      final f = const PostalCodeFormatter(PostalCountry.uk);
      expect(format(f, 'SW1A1AA').text, 'SW1A 1AA');
    });

    test('Canada: auto-inserts space', () {
      final f = const PostalCodeFormatter(PostalCountry.canada);
      expect(format(f, 'K1A0B1').text, 'K1A 0B1');
    });

    test('Netherlands: auto-inserts space', () {
      final f = const PostalCodeFormatter(PostalCountry.netherlands);
      expect(format(f, '1234AB').text, '1234 AB');
    });

    test('Poland: auto-inserts hyphen', () {
      final f = const PostalCodeFormatter(PostalCountry.poland);
      expect(format(f, '00001').text, '00-001');
    });

    test('default countries pass through unchanged', () {
      final f = const PostalCodeFormatter(PostalCountry.india);
      expect(format(f, '110001').text, '110001');
    });
  });

  group('PostalCountry', () {
    test('all countries have non-empty code', () {
      for (final country in PostalCountry.values) {
        expect(country.code.isNotEmpty, isTrue);
      }
    });

    test('all countries have a valid example', () {
      for (final country in PostalCountry.values) {
        final validate = PostalCodeValidator.forCountry(country);
        expect(
          validate(country.example),
          isNull,
          reason: '${country.code} example "${country.example}" should be valid',
        );
      }
    });
  });
}
