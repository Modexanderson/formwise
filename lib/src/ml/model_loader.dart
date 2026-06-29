import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Manages loading and caching of TFLite models for on-device inference.
///
/// Models can be loaded from Flutter assets or from raw bytes.
/// Once loaded, interpreters are cached for reuse across validations.
///
/// ```dart
/// final loader = ModelLoader();
/// final interpreter = await loader.load('assets/models/typo_detector.tflite');
/// ```
class ModelLoader {
  final Map<String, Interpreter> _cache = {};

  /// Loads a TFLite model from a Flutter asset path.
  ///
  /// Returns a cached [Interpreter] if the model was previously loaded.
  /// The [numThreads] parameter controls inference parallelism (default: 2).
  Future<Interpreter> loadFromAsset(
    String assetPath, {
    int numThreads = 2,
    bool useGpuDelegate = false,
  }) async {
    if (_cache.containsKey(assetPath)) {
      return _cache[assetPath]!;
    }

    final options = InterpreterOptions()..threads = numThreads;

    if (useGpuDelegate) {
      try {
        options.addDelegate(GpuDelegateV2());
      } catch (_) {
        // GPU delegate not available on this platform — fall back to CPU
      }
    }

    final interpreter = await Interpreter.fromAsset(
      assetPath,
      options: options,
    );

    _cache[assetPath] = interpreter;
    return interpreter;
  }

  /// Loads a TFLite model from raw bytes.
  ///
  /// Useful for models downloaded at runtime or bundled differently.
  Interpreter loadFromBytes(
    Uint8List modelBytes, {
    String? cacheKey,
    int numThreads = 2,
  }) {
    if (cacheKey != null && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final options = InterpreterOptions()..threads = numThreads;

    final interpreter = Interpreter.fromBuffer(
      modelBytes,
      options: options,
    );

    if (cacheKey != null) {
      _cache[cacheKey] = interpreter;
    }

    return interpreter;
  }

  /// Returns info about a loaded model's input/output tensors.
  ModelInfo getModelInfo(Interpreter interpreter) {
    final inputTensors = interpreter.getInputTensors();
    final outputTensors = interpreter.getOutputTensors();

    return ModelInfo(
      inputShapes: inputTensors.map((t) => t.shape).toList(),
      outputShapes: outputTensors.map((t) => t.shape).toList(),
      inputTypes: inputTensors.map((t) => t.type).toList(),
      outputTypes: outputTensors.map((t) => t.type).toList(),
    );
  }

  /// Whether a model is currently cached.
  bool isLoaded(String key) => _cache.containsKey(key);

  /// Closes a specific cached interpreter and removes it from cache.
  void unload(String key) {
    _cache[key]?.close();
    _cache.remove(key);
  }

  /// Closes all cached interpreters and clears the cache.
  void dispose() {
    for (final interpreter in _cache.values) {
      interpreter.close();
    }
    _cache.clear();
  }
}

/// Describes the input/output tensor shapes and types of a loaded model.
class ModelInfo {
  final List<List<int>> inputShapes;
  final List<List<int>> outputShapes;
  final List<TensorType> inputTypes;
  final List<TensorType> outputTypes;

  const ModelInfo({
    required this.inputShapes,
    required this.outputShapes,
    required this.inputTypes,
    required this.outputTypes,
  });

  @override
  String toString() {
    return 'ModelInfo(inputs: $inputShapes $inputTypes, outputs: $outputShapes $outputTypes)';
  }
}
