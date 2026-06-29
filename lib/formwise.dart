/// ML-powered smart form fields for Flutter with auto-validation,
/// auto-formatting, and typo detection.
///
/// Provides [SmartTextFormField] widgets with built-in validators,
/// formatters, and a [SmartFormController] for programmatic control.
///
/// ```dart
/// import 'package:formwise/formwise.dart';
///
/// SmartTextFormField(
///   name: 'email',
///   labelText: 'Email Address',
///   validator: SmartValidators.email(),
///   inputFormatters: [SmartFormatters.lowercase()],
/// )
/// ```
library;

export 'src/validators/smart_validators.dart';
export 'src/validators/email_typo_detector.dart';
export 'src/formatters/smart_formatters.dart';
export 'src/widgets/smart_text_form_field.dart';
export 'src/smart_form_controller.dart';
