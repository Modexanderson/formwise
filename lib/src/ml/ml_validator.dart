import 'dart:async';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'model_loader.dart';
import 'text_preprocessor.dart';

/// Base class for ML-powered validators that run on-device TFLite models.
///
/// Subclasses implement [preprocess] and [postprocess] to define how
/// input text becomes model input and how model output becomes a
/// validation result.
///
/// ```dart
/// class MyMLValidator extends MlValidator {
///   MyMLValidator() : super(
///     modelAsset: 'packages/formwise/models/my_model.tflite',
///     maxLength: 64,
///   );
///
///   @override
///   List<List<double>> preprocess(String input) { ... }
///
///   @override
///   MlValidationResult postprocess(List<dynamic> output, String input) { ... }
/// }
/// ```
abstract class MlValidator {
  final String modelAsset;
  final TextPreprocessor preprocessor;
  final ModelLoader _loader;

  Interpreter? _interpreter;
  bool _isReady = false;

  MlValidator({
    required this.modelAsset,
    int maxLength = 64,
    String vocab = TextPreprocessor.defaultVocab,
    ModelLoader? loader,
  })  : preprocessor = TextPreprocessor(vocab: vocab, maxLength: maxLength),
        _loader = loader ?? ModelLoader();

  /// Whether the model has been loaded and is ready for inference.
  bool get isReady => _isReady;

  /// Loads the model. Must be called before [validate].
  ///
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_isReady) return;

    try {
      _interpreter = await _loader.loadFromAsset(modelAsset);
      _isReady = true;
    } catch (e) {
      _isReady = false;
      rethrow;
    }
  }

  /// Converts input text into the model's expected input tensor format.
  ///
  /// Default implementation uses char-level encoding via [preprocessor].
  /// Override for custom preprocessing (tokenization, normalization, etc.).
  List<List<double>> preprocess(String input) {
    return preprocessor.encodeAsTensor(input);
  }

  /// Interprets model output into a validation result.
  ///
  /// [rawOutput] is the raw tensor output from the model.
  /// [input] is the original text for reference.
  MlValidationResult postprocess(List<dynamic> rawOutput, String input);

  /// Runs the model on [input] and returns a validation result.
  ///
  /// Returns [MlValidationResult.unavailable] if the model isn't loaded.
  Future<MlValidationResult> validate(String input) async {
    if (!_isReady || _interpreter == null) {
      return MlValidationResult.unavailable();
    }

    final inputTensor = preprocess(input);

    // Allocate output buffer matching the model's output shape
    final outputShapes = _interpreter!.getOutputTensors()
        .map((t) => t.shape)
        .toList();

    final outputs = <int, Object>{};
    for (int i = 0; i < outputShapes.length; i++) {
      outputs[i] = _allocateOutput(outputShapes[i]);
    }

    _interpreter!.runForMultipleInputs([inputTensor], outputs);

    return postprocess(
      outputs.values.toList(),
      input,
    );
  }

  /// Creates a validator function compatible with [SmartTextFormField].
  ///
  /// Falls back to [fallbackValidator] when the model isn't loaded.
  Future<String?> Function(String?) asAsyncValidator({
    String? Function(String?)? fallbackValidator,
  }) {
    return (String? value) async {
      if (value == null || value.isEmpty) return null;

      if (!_isReady) {
        // Try to initialize on first use
        try {
          await initialize();
        } catch (_) {
          return fallbackValidator?.call(value);
        }
      }

      final result = await validate(value);

      if (!result.isAvailable) {
        return fallbackValidator?.call(value);
      }

      return result.isValid ? null : result.errorMessage;
    };
  }

  /// Allocates an output buffer matching the given tensor shape.
  Object _allocateOutput(List<int> shape) {
    if (shape.length == 1) {
      return List<double>.filled(shape[0], 0.0);
    }
    if (shape.length == 2) {
      return List.generate(
        shape[0],
        (_) => List<double>.filled(shape[1], 0.0),
      );
    }
    // For higher dimensions, flatten to 2D
    return List.generate(
      shape[0],
      (_) => List<double>.filled(
        shape.sublist(1).reduce((a, b) => a * b),
        0.0,
      ),
    );
  }

  /// Releases the model resources.
  void dispose() {
    _loader.unload(modelAsset);
    _interpreter = null;
    _isReady = false;
  }
}

/// The result of an ML-powered validation.
class MlValidationResult {
  /// Whether the input passed validation.
  final bool isValid;

  /// Error message if invalid, null if valid.
  final String? errorMessage;

  /// Suggested correction, if the model detected a fixable issue.
  final String? suggestion;

  /// Model confidence score (0.0–1.0).
  final double confidence;

  /// Whether the ML model was available to run.
  final bool isAvailable;

  const MlValidationResult({
    required this.isValid,
    this.errorMessage,
    this.suggestion,
    this.confidence = 1.0,
    this.isAvailable = true,
  });

  /// Creates a result indicating the model wasn't available.
  const MlValidationResult.unavailable()
      : isValid = true,
        errorMessage = null,
        suggestion = null,
        confidence = 0.0,
        isAvailable = false;

  @override
  String toString() {
    if (!isAvailable) return 'MlValidationResult(unavailable)';
    return 'MlValidationResult(valid: $isValid, confidence: $confidence'
        '${suggestion != null ? ', suggestion: $suggestion' : ''})';
  }
}
