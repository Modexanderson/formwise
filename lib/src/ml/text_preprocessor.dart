import 'dart:typed_data';

/// Converts text to numeric tensors for TFLite model input.
///
/// Supports character-level encoding (each character → integer index)
/// which is used by typo detection and text classification models.
class TextPreprocessor {
  /// Default character vocabulary: ASCII printable characters.
  static const String defaultVocab =
      ' !"#\$%&\'()*+,-./0123456789:;<=>?@'
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`'
      'abcdefghijklmnopqrstuvwxyz{|}~';

  final Map<String, int> _charToIndex;
  final int _maxLength;
  final int _padIndex;
  final int _unknownIndex;

  /// Creates a preprocessor with the given vocabulary and max sequence length.
  ///
  /// [vocab] is a string where each character gets an index (starting at 1).
  /// Index 0 is reserved for padding, and [vocab.length + 1] for unknown chars.
  TextPreprocessor({
    String vocab = defaultVocab,
    int maxLength = 64,
  })  : _maxLength = maxLength,
        _padIndex = 0,
        _unknownIndex = vocab.length + 1,
        _charToIndex = {
          for (int i = 0; i < vocab.length; i++) vocab[i]: i + 1,
        };

  /// Encodes a string into a fixed-length integer sequence.
  ///
  /// Characters not in the vocabulary map to [unknownIndex].
  /// Sequences shorter than [maxLength] are right-padded with 0.
  /// Sequences longer than [maxLength] are truncated.
  List<int> encode(String text) {
    final encoded = <int>[];

    for (int i = 0; i < text.length && i < _maxLength; i++) {
      encoded.add(_charToIndex[text[i]] ?? _unknownIndex);
    }

    // Pad to maxLength
    while (encoded.length < _maxLength) {
      encoded.add(_padIndex);
    }

    return encoded;
  }

  /// Encodes text and returns it as a Float32List suitable for TFLite input.
  Float32List encodeAsFloat32(String text) {
    final encoded = encode(text);
    return Float32List.fromList(encoded.map((e) => e.toDouble()).toList());
  }

  /// Encodes text into a shaped tensor: [1, maxLength] for single inference.
  List<List<double>> encodeAsTensor(String text) {
    final encoded = encode(text);
    return [encoded.map((e) => e.toDouble()).toList()];
  }

  /// Batch-encodes multiple texts into a [batchSize, maxLength] tensor.
  List<List<double>> encodeBatch(List<String> texts) {
    return texts.map((t) => encodeAsTensor(t)[0]).toList();
  }

  /// The size of the vocabulary (including padding and unknown tokens).
  int get vocabSize => _charToIndex.length + 2;

  /// The maximum sequence length.
  int get maxLength => _maxLength;
}

/// Decodes model output probabilities into predictions.
class OutputDecoder {
  /// Returns the index of the highest value in a list (argmax).
  static int argmax(List<double> values) {
    int maxIndex = 0;
    double maxValue = values[0];

    for (int i = 1; i < values.length; i++) {
      if (values[i] > maxValue) {
        maxValue = values[i];
        maxIndex = i;
      }
    }

    return maxIndex;
  }

  /// Applies softmax to raw logits.
  static List<double> softmax(List<double> logits) {
    final maxLogit = logits.reduce((a, b) => a > b ? a : b);
    final exps = logits.map((l) => _exp(l - maxLogit)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  /// Returns the top-k indices sorted by descending probability.
  static List<int> topK(List<double> values, int k) {
    final indexed = List.generate(values.length, (i) => MapEntry(i, values[i]));
    indexed.sort((a, b) => b.value.compareTo(a.value));
    return indexed.take(k).map((e) => e.key).toList();
  }

  /// Whether the top prediction exceeds a confidence threshold.
  static bool isConfident(List<double> probabilities, double threshold) {
    final maxProb = probabilities.reduce((a, b) => a > b ? a : b);
    return maxProb >= threshold;
  }

  static double _exp(double x) {
    // Clamp to avoid overflow
    final clamped = x.clamp(-50.0, 50.0);
    return _pow(2.718281828459045, clamped);
  }

  static double _pow(double base, double exponent) {
    // Use Dart's built-in
    return base == 0 ? 0 : _dartPow(base, exponent);
  }

  static double _dartPow(double base, double exp) {
    // Dart's core doesn't import dart:math by default in all contexts,
    // so we use a simple iterative approach for integer exponents
    // and fall back for fractional ones
    if (exp == exp.roundToDouble() && exp >= 0 && exp < 100) {
      double result = 1;
      for (int i = 0; i < exp.round(); i++) {
        result *= base;
      }
      return result;
    }
    // For fractional exponents, use the identity: b^e = e^(e * ln(b))
    // We'll import dart:math indirectly via the exp/log functions
    return _expApprox(exp * _lnApprox(base));
  }

  static double _expApprox(double x) {
    // Taylor series approximation for e^x
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 20; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }

  static double _lnApprox(double x) {
    if (x <= 0) return double.negativeInfinity;
    // Use the identity: ln(x) = 2 * atanh((x-1)/(x+1))
    final y = (x - 1) / (x + 1);
    double result = 0;
    double term = y;
    for (int i = 0; i < 20; i++) {
      result += term / (2 * i + 1);
      term *= y * y;
    }
    return 2 * result;
  }
}
