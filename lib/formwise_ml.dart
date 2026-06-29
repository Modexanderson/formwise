/// Optional ML-powered validation module for formwise.
///
/// Provides on-device TFLite model loading, text preprocessing,
/// and a base class for building ML-backed validators.
///
/// Requires the `tflite_flutter` package and platform-specific setup.
/// See https://pub.dev/packages/tflite_flutter for native library setup.
///
/// ```dart
/// import 'package:formwise/formwise_ml.dart';
///
/// class MyValidator extends MlValidator {
///   MyValidator() : super(modelAsset: 'models/my_model.tflite');
///   // ...
/// }
/// ```
library;

export 'src/ml/model_loader.dart';
export 'src/ml/text_preprocessor.dart';
export 'src/ml/ml_validator.dart';
