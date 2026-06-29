import '../validators/email_typo_detector.dart';
import 'ml_validator.dart';

/// ML-powered email typo detector using an on-device TFLite model.
///
/// Runs a char-level classification model that predicts whether an email
/// domain is valid or a typo, and suggests the most likely correction.
///
/// Falls back to edit-distance detection when the model isn't available.
///
/// To use this, you need to:
/// 1. Train a char-level model (see the example training script)
/// 2. Export it as a TFLite model
/// 3. Bundle it in your app's assets
///
/// ```dart
/// final validator = EmailMlValidator(
///   modelAsset: 'assets/models/email_typo.tflite',
///   labels: ['gmail.com', 'yahoo.com', 'outlook.com', ...],
/// );
/// await validator.initialize();
///
/// SmartTextFormField(
///   name: 'email',
///   asyncValidator: validator.asAsyncValidator(
///     fallbackValidator: SmartValidators.email(),
///   ),
/// )
/// ```
class EmailMlValidator extends MlValidator {
  /// The ordered list of domain labels the model was trained on.
  /// Index 0 = "valid/unknown", remaining indices map to known domains.
  final List<String> labels;

  /// Minimum confidence to consider a prediction valid.
  final double confidenceThreshold;

  /// Pure-Dart fallback detector for when the model is unavailable.
  final EmailTypoDetector _fallbackDetector;

  EmailMlValidator({
    required super.modelAsset,
    required this.labels,
    this.confidenceThreshold = 0.7,
    super.maxLength = 64,
    EmailTypoDetector? fallbackDetector,
    super.loader,
  }) : _fallbackDetector = fallbackDetector ?? const EmailTypoDetector();

  @override
  List<List<double>> preprocess(String input) {
    // Extract domain part from email
    final atIndex = input.lastIndexOf('@');
    final domain = atIndex >= 0 ? input.substring(atIndex + 1) : input;
    return preprocessor.encodeAsTensor(domain.toLowerCase());
  }

  @override
  MlValidationResult postprocess(List<dynamic> rawOutput, String input) {
    final output = rawOutput[0];
    List<double> probabilities;

    if (output is List<List<double>>) {
      probabilities = output[0];
    } else if (output is List<double>) {
      probabilities = output;
    } else {
      return MlValidationResult.unavailable();
    }

    final predictedIndex = _argmax(probabilities);
    final confidence = probabilities[predictedIndex];

    // Index 0 means "valid/no correction needed"
    if (predictedIndex == 0 || confidence < confidenceThreshold) {
      return const MlValidationResult(isValid: true);
    }

    if (predictedIndex < labels.length) {
      final suggestedDomain = labels[predictedIndex];
      final atIndex = input.lastIndexOf('@');
      final localPart = atIndex >= 0 ? input.substring(0, atIndex) : input;
      final suggestion = '$localPart@$suggestedDomain';

      return MlValidationResult(
        isValid: false,
        errorMessage: 'Did you mean $suggestion?',
        suggestion: suggestion,
        confidence: confidence,
      );
    }

    return const MlValidationResult(isValid: true);
  }

  /// Validates an email using the ML model, with edit-distance fallback.
  ///
  /// If the model isn't loaded or fails, uses [EmailTypoDetector] instead.
  Future<MlValidationResult> validateEmail(String email) async {
    if (!isReady) {
      return _fallbackValidation(email);
    }

    try {
      return await validate(email);
    } catch (_) {
      return _fallbackValidation(email);
    }
  }

  MlValidationResult _fallbackValidation(String email) {
    final suggestion = _fallbackDetector.suggestCorrection(email);

    if (suggestion == null) {
      return const MlValidationResult(isValid: true);
    }

    return MlValidationResult(
      isValid: false,
      errorMessage: 'Did you mean $suggestion?',
      suggestion: suggestion,
      confidence: 0.8,
    );
  }

  int _argmax(List<double> values) {
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
}
