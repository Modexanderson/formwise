/// Smart email domain typo detection using Levenshtein edit distance.
///
/// Goes beyond a static dictionary — dynamically compares any typed domain
/// against a list of known valid domains and suggests the closest match
/// when the edit distance is small enough to be a likely typo.
class EmailTypoDetector {
  /// Popular email domains sorted by global usage.
  static const List<String> defaultDomains = [
    'gmail.com',
    'yahoo.com',
    'outlook.com',
    'hotmail.com',
    'icloud.com',
    'mail.com',
    'protonmail.com',
    'proton.me',
    'aol.com',
    'zoho.com',
    'yandex.com',
    'gmx.com',
    'gmx.de',
    'live.com',
    'msn.com',
    'me.com',
    'mac.com',
    'yahoo.co.uk',
    'yahoo.co.jp',
    'yahoo.fr',
    'yahoo.de',
    'yahoo.ca',
    'yahoo.com.br',
    'yahoo.com.au',
    'hotmail.co.uk',
    'hotmail.fr',
    'hotmail.de',
    'outlook.fr',
    'outlook.de',
    'outlook.co.uk',
    'mail.ru',
    'inbox.com',
    'fastmail.com',
    'tutanota.com',
    'hey.com',
    'pm.me',
    'att.net',
    'comcast.net',
    'verizon.net',
    'sbcglobal.net',
    'cox.net',
    'charter.net',
    'earthlink.net',
    'optonline.net',
    'web.de',
    'libero.it',
    'virgilio.it',
    'laposte.net',
    'orange.fr',
    'wanadoo.fr',
    'rediffmail.com',
    'naver.com',
    'daum.net',
    'qq.com',
    '163.com',
    '126.com',
    'sina.com',
  ];

  final List<String> _domains;
  final int _maxDistance;

  /// Creates a detector with the given known domains and max edit distance.
  ///
  /// [maxDistance] controls how different a domain can be and still be
  /// considered a typo. Default is 2 — catches most fat-finger errors
  /// without false positives.
  const EmailTypoDetector({
    List<String>? domains,
    int maxDistance = 2,
  })  : _domains = domains ?? defaultDomains,
        _maxDistance = maxDistance;

  /// Checks if [domain] is likely a typo of a known domain.
  ///
  /// Returns a [TypoMatch] with the suggested correction, or null if
  /// the domain is either valid or too different from any known domain.
  TypoMatch? detectTypo(String domain) {
    final lowerDomain = domain.toLowerCase();

    // Exact match — no typo
    if (_domains.contains(lowerDomain)) return null;

    TypoMatch? bestMatch;

    for (final knownDomain in _domains) {
      final distance = levenshtein(lowerDomain, knownDomain);

      if (distance > 0 && distance <= _maxDistance) {
        if (bestMatch == null || distance < bestMatch.distance) {
          bestMatch = TypoMatch(
            typed: lowerDomain,
            suggested: knownDomain,
            distance: distance,
          );
        }
      }
    }

    return bestMatch;
  }

  /// Checks a full email address and returns the corrected version if
  /// the domain part is a likely typo.
  ///
  /// Returns null if no typo is detected.
  String? suggestCorrection(String email) {
    final atIndex = email.lastIndexOf('@');
    if (atIndex == -1) return null;

    final localPart = email.substring(0, atIndex);
    final domain = email.substring(atIndex + 1);

    final match = detectTypo(domain);
    if (match == null) return null;

    return '$localPart@${match.suggested}';
  }

  /// Computes the Levenshtein edit distance between two strings.
  ///
  /// The edit distance is the minimum number of single-character
  /// insertions, deletions, or substitutions needed to transform
  /// [source] into [target].
  static int levenshtein(String source, String target) {
    if (source == target) return 0;
    if (source.isEmpty) return target.length;
    if (target.isEmpty) return source.length;

    final sLen = source.length;
    final tLen = target.length;

    // Use two rows instead of full matrix for O(min(m,n)) space
    var prevRow = List<int>.generate(tLen + 1, (i) => i);
    var currRow = List<int>.filled(tLen + 1, 0);

    for (int i = 1; i <= sLen; i++) {
      currRow[0] = i;

      for (int j = 1; j <= tLen; j++) {
        final cost = source[i - 1] == target[j - 1] ? 0 : 1;
        currRow[j] = _min3(
          currRow[j - 1] + 1, // insertion
          prevRow[j] + 1, // deletion
          prevRow[j - 1] + cost, // substitution
        );
      }

      // Swap rows
      final temp = prevRow;
      prevRow = currRow;
      currRow = temp;
    }

    return prevRow[tLen];
  }

  static int _min3(int a, int b, int c) {
    if (a <= b && a <= c) return a;
    if (b <= c) return b;
    return c;
  }
}

/// A detected typo match with the suggested correction.
class TypoMatch {
  /// The domain as typed by the user.
  final String typed;

  /// The suggested correct domain.
  final String suggested;

  /// The edit distance between typed and suggested.
  final int distance;

  const TypoMatch({
    required this.typed,
    required this.suggested,
    required this.distance,
  });

  @override
  String toString() => 'TypoMatch($typed → $suggested, distance: $distance)';
}
