import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:formwise/formwise_ml.dart';

void main() {
  group('TextPreprocessor', () {
    late TextPreprocessor preprocessor;

    setUp(() {
      preprocessor = TextPreprocessor(maxLength: 10);
    });

    test('encodes characters to indices', () {
      final encoded = preprocessor.encode('abc');
      // 'a' is at position 65 in the default vocab (after space and symbols)
      expect(encoded.length, 10);
      expect(encoded[0], greaterThan(0)); // 'a' maps to a positive index
      expect(encoded[1], greaterThan(0)); // 'b'
      expect(encoded[2], greaterThan(0)); // 'c'
    });

    test('pads short sequences to maxLength', () {
      final encoded = preprocessor.encode('hi');
      expect(encoded.length, 10);
      // Last 8 positions should be padding (0)
      for (int i = 2; i < 10; i++) {
        expect(encoded[i], 0);
      }
    });

    test('truncates long sequences to maxLength', () {
      final encoded = preprocessor.encode('this is a very long string');
      expect(encoded.length, 10);
    });

    test('maps unknown characters to unknown index', () {
      // Emoji is not in default ASCII vocab
      final encoded = preprocessor.encode('\u{1F600}pad');
      expect(encoded[0], preprocessor.vocabSize - 1);
    });

    test('encodeAsFloat32 returns Float32List', () {
      final result = preprocessor.encodeAsFloat32('test');
      expect(result, isA<Float32List>());
      expect(result.length, 10);
    });

    test('encodeAsTensor returns 2D list [1, maxLength]', () {
      final tensor = preprocessor.encodeAsTensor('test');
      expect(tensor.length, 1);
      expect(tensor[0].length, 10);
    });

    test('encodeBatch returns [batchSize, maxLength]', () {
      final batch = preprocessor.encodeBatch(['hello', 'world', 'test']);
      expect(batch.length, 3);
      expect(batch[0].length, 10);
      expect(batch[1].length, 10);
      expect(batch[2].length, 10);
    });

    test('same character always maps to same index', () {
      final encoded1 = preprocessor.encode('aaa');
      expect(encoded1[0], encoded1[1]);
      expect(encoded1[1], encoded1[2]);
    });

    test('different characters map to different indices', () {
      final encoded = preprocessor.encode('abc');
      expect(encoded[0], isNot(encoded[1]));
      expect(encoded[1], isNot(encoded[2]));
    });

    test('vocabSize includes padding and unknown', () {
      expect(preprocessor.vocabSize, greaterThan(90)); // ASCII printable + 2
    });
  });

  group('OutputDecoder', () {
    test('argmax returns index of highest value', () {
      expect(OutputDecoder.argmax([0.1, 0.8, 0.1]), 1);
      expect(OutputDecoder.argmax([0.9, 0.05, 0.05]), 0);
      expect(OutputDecoder.argmax([0.1, 0.1, 0.8]), 2);
    });

    test('softmax output sums to ~1.0', () {
      final result = OutputDecoder.softmax([1.0, 2.0, 3.0]);
      final sum = result.reduce((a, b) => a + b);
      expect(sum, closeTo(1.0, 0.001));
    });

    test('softmax preserves relative ordering', () {
      final result = OutputDecoder.softmax([1.0, 2.0, 3.0]);
      expect(result[2], greaterThan(result[1]));
      expect(result[1], greaterThan(result[0]));
    });

    test('softmax handles equal values', () {
      final result = OutputDecoder.softmax([1.0, 1.0, 1.0]);
      expect(result[0], closeTo(1.0 / 3.0, 0.001));
      expect(result[1], closeTo(1.0 / 3.0, 0.001));
      expect(result[2], closeTo(1.0 / 3.0, 0.001));
    });

    test('topK returns correct indices', () {
      final result = OutputDecoder.topK([0.1, 0.5, 0.3, 0.9, 0.2], 3);
      expect(result, [3, 1, 2]); // indices sorted by descending value
    });

    test('topK with k=1 returns argmax', () {
      final values = [0.1, 0.5, 0.3, 0.9, 0.2];
      final top1 = OutputDecoder.topK(values, 1);
      expect(top1[0], OutputDecoder.argmax(values));
    });

    test('isConfident returns true above threshold', () {
      expect(OutputDecoder.isConfident([0.1, 0.9], 0.8), isTrue);
      expect(OutputDecoder.isConfident([0.5, 0.5], 0.8), isFalse);
    });
  });

  group('MlValidationResult', () {
    test('valid result', () {
      const result = MlValidationResult(isValid: true, confidence: 0.95);
      expect(result.isValid, isTrue);
      expect(result.isAvailable, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('invalid result with suggestion', () {
      const result = MlValidationResult(
        isValid: false,
        errorMessage: 'Did you mean gmail.com?',
        suggestion: 'user@gmail.com',
        confidence: 0.87,
      );
      expect(result.isValid, isFalse);
      expect(result.suggestion, 'user@gmail.com');
    });

    test('unavailable result', () {
      const result = MlValidationResult.unavailable();
      expect(result.isAvailable, isFalse);
      expect(result.isValid, isTrue); // passes validation when unavailable
      expect(result.confidence, 0.0);
    });
  });
}
