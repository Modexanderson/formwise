import 'package:flutter_test/flutter_test.dart';
import 'package:formwise/formwise.dart';

void main() {
  group('EmailTypoDetector', () {
    const detector = EmailTypoDetector();

    group('detectTypo', () {
      test('returns null for valid domains', () {
        expect(detector.detectTypo('gmail.com'), isNull);
        expect(detector.detectTypo('yahoo.com'), isNull);
        expect(detector.detectTypo('outlook.com'), isNull);
        expect(detector.detectTypo('hotmail.com'), isNull);
        expect(detector.detectTypo('icloud.com'), isNull);
      });

      test('detects single-char transposition', () {
        final match = detector.detectTypo('gmial.com');
        expect(match, isNotNull);
        expect(match!.suggested, 'gmail.com');
        expect(match.distance, lessThanOrEqualTo(2));
      });

      test('detects missing character', () {
        final match = detector.detectTypo('gmal.com');
        expect(match, isNotNull);
        expect(match!.suggested, 'gmail.com');
      });

      test('detects extra character', () {
        final match = detector.detectTypo('gmaill.com');
        expect(match, isNotNull);
        expect(match!.suggested, 'gmail.com');
      });

      test('detects wrong TLD', () {
        final match = detector.detectTypo('gmail.con');
        expect(match, isNotNull);
        expect(match!.suggested, 'gmail.com');
      });

      test('detects yahoo typos', () {
        final match = detector.detectTypo('yhaoo.com');
        expect(match, isNotNull);
        expect(match!.suggested, 'yahoo.com');
      });

      test('detects hotmail typos', () {
        final match = detector.detectTypo('hotmial.com');
        expect(match, isNotNull);
        expect(match!.suggested, 'hotmail.com');
      });

      test('detects outlook typos', () {
        final match = detector.detectTypo('outlok.com');
        expect(match, isNotNull);
        expect(match!.suggested, 'outlook.com');
      });

      test('detects icloud typos', () {
        final match = detector.detectTypo('iclod.com');
        expect(match, isNotNull);
        expect(match!.suggested, 'icloud.com');
      });

      test('detects protonmail typos', () {
        final match = detector.detectTypo('protonmal.com');
        expect(match, isNotNull);
        expect(match!.suggested, 'protonmail.com');
      });

      test('returns null for completely unknown domains', () {
        expect(detector.detectTypo('mycompany.com'), isNull);
        expect(detector.detectTypo('randomdomain.org'), isNull);
      });

      test('returns null for domains too different from any known', () {
        expect(detector.detectTypo('zzzzz.com'), isNull);
      });

      test('is case insensitive', () {
        final match = detector.detectTypo('GMIAL.COM');
        expect(match, isNotNull);
        expect(match!.suggested, 'gmail.com');
      });
    });

    group('suggestCorrection', () {
      test('returns corrected full email', () {
        final result = detector.suggestCorrection('user@gmial.com');
        expect(result, 'user@gmail.com');
      });

      test('preserves local part exactly', () {
        final result = detector.suggestCorrection('John.Doe+tag@yhaoo.com');
        expect(result, 'John.Doe+tag@yahoo.com');
      });

      test('returns null for valid emails', () {
        expect(detector.suggestCorrection('user@gmail.com'), isNull);
      });

      test('returns null for unknown domains', () {
        expect(detector.suggestCorrection('user@mycompany.com'), isNull);
      });

      test('returns null for invalid input without @', () {
        expect(detector.suggestCorrection('notanemail'), isNull);
      });
    });

    group('custom domains', () {
      test('can add custom domains', () {
        final custom = EmailTypoDetector(
          domains: [...EmailTypoDetector.defaultDomains, 'mycompany.com'],
        );

        // mycompany.com is now valid
        expect(custom.detectTypo('mycompany.com'), isNull);

        // typo of custom domain is detected
        final match = custom.detectTypo('mycompny.com');
        expect(match, isNotNull);
        expect(match!.suggested, 'mycompany.com');
      });

      test('respects custom max distance', () {
        const strict = EmailTypoDetector(maxDistance: 1);

        // 1 edit away — detected
        expect(strict.detectTypo('gmail.con'), isNotNull);

        // 2 edits away — not detected with strict threshold
        expect(strict.detectTypo('gmial.con'), isNull);
      });
    });
  });

  group('Levenshtein distance', () {
    test('identical strings have distance 0', () {
      expect(EmailTypoDetector.levenshtein('abc', 'abc'), 0);
    });

    test('empty to non-empty is length', () {
      expect(EmailTypoDetector.levenshtein('', 'abc'), 3);
      expect(EmailTypoDetector.levenshtein('abc', ''), 3);
    });

    test('single substitution is distance 1', () {
      expect(EmailTypoDetector.levenshtein('cat', 'car'), 1);
    });

    test('single insertion is distance 1', () {
      expect(EmailTypoDetector.levenshtein('cat', 'cart'), 1);
    });

    test('single deletion is distance 1', () {
      expect(EmailTypoDetector.levenshtein('cart', 'cat'), 1);
    });

    test('transposition is distance 2', () {
      expect(EmailTypoDetector.levenshtein('ab', 'ba'), 2);
    });

    test('completely different strings', () {
      expect(EmailTypoDetector.levenshtein('abc', 'xyz'), 3);
    });
  });

  group('SmartValidators.email integration', () {
    test('detects typos via edit distance (not just static list)', () {
      String? suggestion;
      final validate = SmartValidators.email(
        suggestCorrection: (s) => suggestion = s,
      );

      // This typo wasn't in the old static dictionary
      final result = validate('user@gamil.com');
      expect(result, isNotNull);
      expect(suggestion, 'user@gmail.com');
    });

    test('supports custom domains parameter', () {
      String? suggestion;
      final validate = SmartValidators.email(
        customDomains: ['mycompany.com'],
        suggestCorrection: (s) => suggestion = s,
      );

      // Custom domain is valid
      expect(validate('user@mycompany.com'), isNull);

      // Typo of custom domain is detected
      final result = validate('user@mycompny.com');
      expect(result, isNotNull);
      expect(suggestion, 'user@mycompany.com');
    });

    test('supports maxTypoDistance parameter', () {
      final strict = SmartValidators.email(maxTypoDistance: 1);

      // 1 edit — detected
      expect(strict('user@gmail.con'), isNotNull);

      // Valid — passes
      expect(strict('user@gmail.com'), isNull);
    });
  });
}
