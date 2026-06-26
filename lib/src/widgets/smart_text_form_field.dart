import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../smart_form_controller.dart';
import '../validators/smart_validators.dart';
import '../formatters/smart_formatters.dart';

/// A smart text form field with built-in validation feedback,
/// debounced validation, and shake-on-error animation.
///
/// ```dart
/// SmartTextFormField(
///   name: 'email',
///   labelText: 'Email',
///   validator: SmartValidators.email(
///     suggestCorrection: (suggestion) {
///       // Show suggestion to user
///     },
///   ),
///   inputFormatters: [SmartFormatters.lowercase()],
///   validationDebounce: Duration(milliseconds: 500),
///   shakeOnError: true,
/// )
/// ```
class SmartTextFormField extends StatefulWidget {
  /// A unique name identifying this field within a [SmartFormController].
  final String name;

  /// The controller for the form this field belongs to.
  final SmartFormController? formController;

  /// Optional text editing controller. One will be created if not provided.
  final TextEditingController? controller;

  /// Synchronous validator function.
  final String? Function(String?)? validator;

  /// Async validator for server-side validation or expensive checks.
  /// Runs after the sync validator passes.
  final Future<String?> Function(String?)? asyncValidator;

  /// Debounce duration for validation. Prevents excessive validation
  /// calls while the user is still typing.
  final Duration validationDebounce;

  /// Whether to play a shake animation when validation fails.
  final bool shakeOnError;

  /// Whether to validate on every change (true) or only on form submit (false).
  final bool autoValidate;

  /// Input formatters to apply to the field.
  final List<TextInputFormatter>? inputFormatters;

  /// Initial value for the field.
  final String? initialValue;

  // Pass-through TextFormField properties
  final InputDecoration? decoration;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool readOnly;

  const SmartTextFormField({
    super.key,
    required this.name,
    this.formController,
    this.controller,
    this.validator,
    this.asyncValidator,
    this.validationDebounce = const Duration(milliseconds: 300),
    this.shakeOnError = true,
    this.autoValidate = true,
    this.inputFormatters,
    this.initialValue,
    this.decoration,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.focusNode,
    this.onChanged,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.readOnly = false,
  });

  /// Creates an email field with typo detection, lowercase formatting,
  /// and email keyboard type pre-configured.
  ///
  /// ```dart
  /// SmartTextFormField.email(
  ///   name: 'email',
  ///   onTypoDetected: (suggestion) => print('Did you mean $suggestion?'),
  /// )
  /// ```
  SmartTextFormField.email({
    super.key,
    required this.name,
    this.formController,
    this.controller,
    this.asyncValidator,
    this.validationDebounce = const Duration(milliseconds: 300),
    this.shakeOnError = true,
    this.autoValidate = true,
    this.initialValue,
    this.decoration,
    String? labelText,
    String? hintText,
    this.prefixIcon = const Icon(Icons.email_outlined),
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.focusNode,
    this.onChanged,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.textInputAction,
    this.readOnly = false,
    void Function(String suggestion)? onTypoDetected,
    String? errorMessage,
  })  : labelText = labelText ?? 'Email',
        hintText = hintText ?? 'you@example.com',
        keyboardType = TextInputType.emailAddress,
        textCapitalization = TextCapitalization.none,
        validator = SmartValidators.email(
          errorMessage: errorMessage ?? 'Please enter a valid email address',
          suggestCorrection: onTypoDetected,
        ),
        inputFormatters = [SmartFormatters.lowercase()];

  /// Creates a phone number field with mask formatting, digit keyboard,
  /// and phone validation pre-configured.
  ///
  /// ```dart
  /// SmartTextFormField.phone(
  ///   name: 'phone',
  ///   mask: '+## (###) ###-####',
  ///   minDigits: 10,
  /// )
  /// ```
  SmartTextFormField.phone({
    super.key,
    required this.name,
    this.formController,
    this.controller,
    this.asyncValidator,
    this.validationDebounce = const Duration(milliseconds: 300),
    this.shakeOnError = true,
    this.autoValidate = true,
    this.initialValue,
    this.decoration,
    String? labelText,
    String? hintText,
    this.prefixIcon = const Icon(Icons.phone_outlined),
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.focusNode,
    this.onChanged,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.textInputAction,
    this.readOnly = false,
    String mask = '(###) ###-####',
    int minDigits = 7,
    int maxDigits = 15,
    String? errorMessage,
  })  : labelText = labelText ?? 'Phone',
        hintText = hintText ?? '(123) 456-7890',
        keyboardType = TextInputType.phone,
        textCapitalization = TextCapitalization.none,
        validator = SmartValidators.phone(
          errorMessage: errorMessage ?? 'Please enter a valid phone number',
          minDigits: minDigits,
          maxDigits: maxDigits,
        ),
        inputFormatters = [SmartFormatters.phone(mask: mask)];

  /// Creates a credit card number field with Luhn validation, card formatting,
  /// and number keyboard pre-configured.
  ///
  /// Use [SmartValidators.detectCardBrand] in your [onChanged] callback
  /// to detect the card brand as the user types.
  ///
  /// ```dart
  /// SmartTextFormField.creditCard(
  ///   name: 'card_number',
  ///   onChanged: (value) {
  ///     final brand = SmartValidators.detectCardBrand(value);
  ///     setState(() => _brand = brand);
  ///   },
  /// )
  /// ```
  SmartTextFormField.creditCard({
    super.key,
    required this.name,
    this.formController,
    this.controller,
    this.asyncValidator,
    this.validationDebounce = const Duration(milliseconds: 300),
    this.shakeOnError = true,
    this.autoValidate = true,
    this.initialValue,
    this.decoration,
    String? labelText,
    String? hintText,
    this.prefixIcon = const Icon(Icons.credit_card_outlined),
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.focusNode,
    this.onChanged,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.textInputAction,
    this.readOnly = false,
    bool amexFormat = false,
    String? errorMessage,
  })  : labelText = labelText ?? 'Card Number',
        hintText = hintText ?? '1234 5678 9012 3456',
        keyboardType = TextInputType.number,
        textCapitalization = TextCapitalization.none,
        validator = SmartValidators.creditCard(
          errorMessage: errorMessage ?? 'Please enter a valid card number',
        ),
        inputFormatters = [SmartFormatters.creditCard(amexFormat: amexFormat)];

  /// Creates a URL field with URL validation, URL keyboard type,
  /// and optional HTTPS enforcement.
  ///
  /// ```dart
  /// SmartTextFormField.url(
  ///   name: 'website',
  ///   requireHttps: true,
  /// )
  /// ```
  SmartTextFormField.url({
    super.key,
    required this.name,
    this.formController,
    this.controller,
    this.asyncValidator,
    this.validationDebounce = const Duration(milliseconds: 300),
    this.shakeOnError = true,
    this.autoValidate = true,
    this.initialValue,
    this.decoration,
    String? labelText,
    String? hintText,
    this.prefixIcon = const Icon(Icons.link_outlined),
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.focusNode,
    this.onChanged,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.textInputAction,
    this.readOnly = false,
    bool requireHttps = false,
    List<String>? allowedSchemes,
    String? errorMessage,
  })  : labelText = labelText ?? 'URL',
        hintText = hintText ?? 'https://example.com',
        keyboardType = TextInputType.url,
        textCapitalization = TextCapitalization.none,
        validator = SmartValidators.url(
          errorMessage: errorMessage ?? 'Please enter a valid URL',
          requireHttps: requireHttps,
          allowedSchemes: allowedSchemes,
        ),
        inputFormatters = [SmartFormatters.lowercase()];

  /// Creates a numeric field with range validation and number keyboard.
  ///
  /// ```dart
  /// SmartTextFormField.numeric(
  ///   name: 'age',
  ///   min: 0,
  ///   max: 150,
  ///   allowDecimals: false,
  /// )
  /// ```
  SmartTextFormField.numeric({
    super.key,
    required this.name,
    this.formController,
    this.controller,
    this.asyncValidator,
    this.validationDebounce = const Duration(milliseconds: 300),
    this.shakeOnError = true,
    this.autoValidate = true,
    this.initialValue,
    this.decoration,
    String? labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.focusNode,
    this.onChanged,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.textInputAction,
    this.readOnly = false,
    double? min,
    double? max,
    bool allowDecimals = true,
    String? errorMessage,
  })  : labelText = labelText ?? 'Number',
        keyboardType = TextInputType.numberWithOptions(
          decimal: allowDecimals,
          signed: min != null && min < 0,
        ),
        textCapitalization = TextCapitalization.none,
        validator = SmartValidators.numericRange(
          errorMessage: errorMessage ?? 'Please enter a valid number',
          min: min,
          max: max,
          allowDecimals: allowDecimals,
        ),
        inputFormatters = allowDecimals
            ? null
            : [FilteringTextInputFormatter.digitsOnly];

  /// Creates a password field with obscured text, configurable strength
  /// validation, and a visibility toggle.
  ///
  /// ```dart
  /// SmartTextFormField.password(
  ///   name: 'password',
  ///   minLength: 8,
  ///   requireUppercase: true,
  ///   requireDigit: true,
  /// )
  /// ```
  SmartTextFormField.password({
    super.key,
    required this.name,
    this.formController,
    this.controller,
    this.asyncValidator,
    this.validationDebounce = const Duration(milliseconds: 300),
    this.shakeOnError = true,
    this.autoValidate = true,
    this.initialValue,
    this.decoration,
    String? labelText,
    String? hintText,
    this.prefixIcon = const Icon(Icons.lock_outline),
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.focusNode,
    this.onChanged,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.textInputAction,
    this.readOnly = false,
    int minLength = 8,
    bool requireUppercase = false,
    bool requireLowercase = false,
    bool requireDigit = false,
    bool requireSpecialChar = false,
  })  : labelText = labelText ?? 'Password',
        hintText = hintText ?? 'Enter your password',
        keyboardType = TextInputType.visiblePassword,
        textCapitalization = TextCapitalization.none,
        obscureText = true,
        inputFormatters = null,
        validator = SmartValidators.compose([
          SmartValidators.required(errorMessage: 'Password is required'),
          SmartValidators.minLength(
            length: minLength,
            errorMessage: 'Must be at least $minLength characters',
          ),
          if (requireUppercase)
            SmartValidators.pattern(
              regex: RegExp(r'[A-Z]'),
              errorMessage: 'Must contain an uppercase letter',
            ),
          if (requireLowercase)
            SmartValidators.pattern(
              regex: RegExp(r'[a-z]'),
              errorMessage: 'Must contain a lowercase letter',
            ),
          if (requireDigit)
            SmartValidators.pattern(
              regex: RegExp(r'\d'),
              errorMessage: 'Must contain a digit',
            ),
          if (requireSpecialChar)
            SmartValidators.pattern(
              regex: RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
              errorMessage: 'Must contain a special character',
            ),
        ]);

  @override
  State<SmartTextFormField> createState() => _SmartTextFormFieldState();
}

class _SmartTextFormFieldState extends State<SmartTextFormField>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  Timer? _debounceTimer;
  String? _errorText;
  bool _isValidating = false;
  bool _hasInteracted = false;
  SmartFieldState? _fieldState;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();

    // Shake animation
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: -3), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -3, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    // Register with form controller
    _fieldState = SmartFieldState(
      textController: _controller,
      validator: _syncValidate,
      initialValue: widget.initialValue,
    );
    widget.formController?.registerField(widget.name, _fieldState!);

    // Listen for changes
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.formController?.unregisterField(widget.name);
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _shakeController.dispose();
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!widget.autoValidate || !_hasInteracted) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.validationDebounce, () {
      _validate();
    });

    widget.onChanged?.call(_controller.text);
    widget.formController?.fieldDidChange();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && !_hasInteracted) {
      _hasInteracted = true;
      _validate();
    }
  }

  String? _syncValidate(String? value) {
    return widget.validator?.call(value);
  }

  Future<void> _validate() async {
    final value = _controller.text;

    // Sync validation first
    final syncError = _syncValidate(value);
    if (syncError != null) {
      _setError(syncError);
      return;
    }

    // Async validation
    if (widget.asyncValidator != null) {
      setState(() => _isValidating = true);

      final asyncError = await widget.asyncValidator!(value);

      // Check if value hasn't changed during async validation
      if (_controller.text == value) {
        if (asyncError != null) {
          _setError(asyncError);
        } else {
          _clearError();
        }
        setState(() => _isValidating = false);
      }
    } else {
      _clearError();
    }
  }

  void _setError(String error) {
    setState(() {
      _errorText = error;
      _fieldState?.error = error;
    });

    if (widget.shakeOnError) {
      _shakeController.forward(from: 0);
    }
  }

  void _clearError() {
    setState(() {
      _errorText = null;
      _fieldState?.error = null;
    });
  }

  InputDecoration _buildDecoration() {
    if (widget.decoration != null) {
      return widget.decoration!.copyWith(
        errorText: _errorText,
        suffixIcon: _buildSuffixIcon(),
      );
    }

    return InputDecoration(
      labelText: widget.labelText,
      hintText: widget.hintText,
      prefixIcon: widget.prefixIcon,
      suffixIcon: _buildSuffixIcon(),
      errorText: _errorText,
      border: const OutlineInputBorder(),
    );
  }

  Widget? _buildSuffixIcon() {
    if (_isValidating) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (widget.suffixIcon != null) return widget.suffixIcon;

    if (_hasInteracted && _errorText == null && _controller.text.isNotEmpty) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    Widget field = TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: _buildDecoration(),
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      onEditingComplete: widget.onEditingComplete,
      onFieldSubmitted: widget.onFieldSubmitted,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      readOnly: widget.readOnly,
      validator: (value) {
        _hasInteracted = true;
        final error = _syncValidate(value);
        if (error != null && widget.shakeOnError) {
          _shakeController.forward(from: 0);
        }
        return error;
      },
    );

    if (widget.shakeOnError) {
      field = AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          );
        },
        child: field,
      );
    }

    return field;
  }
}
