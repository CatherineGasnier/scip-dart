import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// The files of a package that are test code.
///
/// A file is test code if it is one of the test paths, or is inside one of
/// them. The test paths are relative to the package root. They are:
///
/// - `test/` and `integration_test/`, the test directories of the pub package
///   layout conventions:
///   https://dart.dev/tools/pub/package-layout#tests-and-benchmarks
/// - the `paths` that the package's `dart_test.yaml` gives `dart test` to run
///   by default:
///   https://github.com/dart-lang/test/blob/master/pkgs/test/doc/configuration.md#paths
class TestPaths {
  final List<String> _paths;

  TestPaths._(this._paths);

  /// Reads the test paths of the package at [packageRoot].
  ///
  /// Throws a [FormatException] that names the file if `dart_test.yaml`, or a
  /// file it includes, is malformed.
  factory TestPaths.forPackage(String packageRoot) {
    final configPath = p.join(packageRoot, 'dart_test.yaml');
    return TestPaths._([
      'test',
      'integration_test',
      if (File(configPath).existsSync()) ..._configuredPaths(configPath),
    ]);
  }

  /// Whether the file at [relativePath], relative to the package root, is
  /// test code.
  bool contains(String relativePath) => _paths.any(
    (path) => p.equals(path, relativePath) || p.isWithin(path, relativePath),
  );
}

/// The top-level `paths` of the test configuration file at [configPath].
///
/// This follows `dart test`: an `include` is resolved relative to the file
/// that includes it, and a non-empty `paths` replaces the included one.
/// `paths` inside `presets` are ignored, because they only apply when the
/// preset is selected.
List<String> _configuredPaths(String configPath) {
  final document = loadYamlNode(
    File(configPath).readAsStringSync(),
    sourceUrl: p.toUri(configPath),
  );
  if (document.value == null) return [];
  if (document is! YamlMap) {
    throw _error(document, 'The configuration must be a YAML map.');
  }

  final includeNode = document.nodes['include'];
  final included = includeNode == null
      ? <String>[]
      : _configuredPaths(_includedPath(configPath, includeNode));

  final pathsNode = document.nodes['paths'];
  final paths = pathsNode == null ? <String>[] : _parsePaths(pathsNode);

  return paths.isNotEmpty ? paths : included;
}

/// The path of the file included by [includeNode], in the file at
/// [configPath].
String _includedPath(String configPath, YamlNode includeNode) {
  final path = p.join(
    p.dirname(configPath),
    _parsePath(includeNode, 'include path must be a string.'),
  );
  if (!File(path).existsSync()) throw _error(includeNode, 'Cannot find $path.');
  return path;
}

List<String> _parsePaths(YamlNode pathsNode) {
  if (pathsNode is! YamlList) throw _error(pathsNode, 'paths must be a list.');
  return [
    for (final node in pathsNode.nodes)
      _parsePath(node, 'Paths must be strings.', relative: true),
  ];
}

/// Converts the URL-format path in [node] to a platform path.
///
/// [notAString] is the error message for a value that is not a string. With
/// [relative], absolute paths and URLs are rejected too, as `dart test` does
/// for `paths`.
String _parsePath(YamlNode node, String notAString, {bool relative = false}) {
  final value = node.value;
  if (value is! String) throw _error(node, notAString);
  if (relative && !p.url.isRelative(value)) {
    throw _error(node, 'Paths must be relative.');
  }
  try {
    return p.fromUri(value);
  } on FormatException catch (error) {
    throw _error(node, 'Invalid path: ${error.message}');
  }
}

/// An error about [node], showing its file, line and column.
FormatException _error(YamlNode node, String message) =>
    FormatException(node.span.message(message));
