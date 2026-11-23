import 'dart:io';

import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:scip_dart/scip_dart.dart';
import 'package:scip_dart/src/gen/scip.pb.dart';
import 'package:scip_dart/src/test_paths.dart';
import 'package:test/test.dart';

/// The package indexed by the [SymbolRole.Test] tests.
///
/// Run `dart pub get` in this directory before running these tests. Its
/// `dart_test.yaml` sets `paths: [spec]`.
const _fixtureRoot = 'snapshots/input/basic-project';

final _definition = SymbolRole.Definition.value;
final _testRole = SymbolRole.Test.value;

void main() {
  group('TestPaths', () {
    test('without dart_test.yaml, contains test/ and integration_test/', () {
      final testPaths = _testPathsFor({});

      expect(testPaths.contains(p.join('test', 'foo_test.dart')), isTrue);
      expect(testPaths.contains(p.join('test', 'src', 'helpers.dart')), isTrue);
      expect(
        testPaths.contains(p.join('integration_test', 'app_test.dart')),
        isTrue,
      );
      expect(testPaths.contains(p.join('lib', 'foo.dart')), isFalse);
      expect(testPaths.contains(p.join('lib', 'test', 'fake.dart')), isFalse);
      expect(testPaths.contains(p.join('testing', 'foo_test.dart')), isFalse);
      expect(testPaths.contains('test.dart'), isFalse);
    });

    test('ignores dart_test.yaml without top-level paths', () {
      final testPaths = _testPathsFor({
        'dart_test.yaml': 'concurrency: 1\npresets: {ci: {paths: [ci]}}\n',
      });

      expect(testPaths.contains(p.join('test', 'foo_test.dart')), isTrue);
      expect(testPaths.contains(p.join('ci', 'foo_test.dart')), isFalse);
    });

    test('adds each directory in paths, with everything under it', () {
      final testPaths = _testPathsFor({'dart_test.yaml': 'paths: [spec]\n'});

      expect(testPaths.contains(p.join('spec', 'foo_test.dart')), isTrue);
      expect(testPaths.contains(p.join('spec', 'src', 'helper.dart')), isTrue);
      expect(testPaths.contains(p.join('test', 'foo_test.dart')), isTrue);
      expect(testPaths.contains(p.join('specs', 'foo_test.dart')), isFalse);
      expect(testPaths.contains(p.join('lib', 'foo.dart')), isFalse);
    });

    test('adds each file in paths, without its siblings', () {
      final testPaths = _testPathsFor({
        'dart_test.yaml': 'paths: [tool/smoke_test.dart]\n',
      });

      expect(testPaths.contains(p.join('tool', 'smoke_test.dart')), isTrue);
      expect(testPaths.contains(p.join('tool', 'build.dart')), isFalse);
    });

    test('follows include, relative to the including file', () {
      final testPaths = _testPathsFor({
        'dart_test.yaml': 'include: config/base.yaml\n',
        'config/base.yaml': 'include: shared.yaml\n',
        'config/shared.yaml': 'paths: [spec]\n',
      });

      expect(testPaths.contains(p.join('spec', 'foo_test.dart')), isTrue);
    });

    test('lets paths in dart_test.yaml replace the included paths', () {
      final testPaths = _testPathsFor({
        'dart_test.yaml': 'include: base.yaml\npaths: [local]\n',
        'base.yaml': 'paths: [included]\n',
      });

      expect(testPaths.contains(p.join('local', 'foo_test.dart')), isTrue);
      expect(testPaths.contains(p.join('included', 'foo_test.dart')), isFalse);
    });

    test('fails on a malformed configuration, naming the file', () {
      void expectError(Map<String, String> files, String file, String error) {
        expect(
          () => _testPathsFor(files),
          throwsA(
            isA<FormatException>().having(
              (exception) => exception.toString(),
              'toString()',
              allOf(contains(file), contains(error)),
            ),
          ),
        );
      }

      expectError({'dart_test.yaml': 'paths: [spec'}, 'dart_test.yaml', ']');
      expectError(
        {'dart_test.yaml': '[spec]'},
        'dart_test.yaml',
        'must be a YAML map',
      );
      expectError(
        {'dart_test.yaml': 'paths: spec'},
        'dart_test.yaml',
        'paths must be a list',
      );
      expectError(
        {'dart_test.yaml': 'paths: [1]'},
        'dart_test.yaml',
        'Paths must be strings',
      );
      expectError(
        {'dart_test.yaml': 'paths: [/spec]'},
        'dart_test.yaml',
        'must be relative',
      );
      expectError(
        {'dart_test.yaml': 'paths: [file:spec]'},
        'dart_test.yaml',
        'must be relative',
      );
      expectError(
        {'dart_test.yaml': 'include: missing.yaml'},
        'dart_test.yaml',
        'missing.yaml',
      );
      expectError(
        {'dart_test.yaml': 'include: base.yaml', 'base.yaml': 'paths: spec'},
        'base.yaml',
        'paths must be a list',
      );
    });
  });

  group('SymbolRole.Test', () {
    late Index index;

    setUpAll(() async {
      index = await _indexFixture();
    });

    test('is set on every occurrence in test files', () {
      final occurrences = _occurrencesInFiles(index, _isFixtureTestFile);
      expect(occurrences, isNotEmpty);
      expect(occurrences.where((o) => !_hasTestRole(o)), isEmpty);
    });

    test('is not set on any occurrence outside test files', () {
      final occurrences = _occurrencesInFiles(
        index,
        (path) => !_isFixtureTestFile(path),
      );
      expect(occurrences, isNotEmpty);
      expect(occurrences.where(_hasTestRole), isEmpty);
    });

    test('is set on functions defined in test files', () {
      final rolesTest = p.join('test', 'roles_test.dart');
      final helpers = p.join('test', 'helpers.dart');

      expect(_rolesOf(index, rolesTest, '/main().'), [_definition | _testRole]);
      expect(_rolesOf(index, rolesTest, '/namedTestFunction().'), [
        _testRole,
        _definition | _testRole,
      ]);
      expect(_rolesOf(index, helpers, '/buildFoo().'), [
        _definition | _testRole,
      ]);
    });

    test('is set on references inside a test(...) callback', () {
      final rolesTest = p.join('test', 'roles_test.dart');

      expect(_rolesOf(index, rolesTest, '`scaffolding.dart`/test().'), [
        _testRole,
        _testRole,
      ]);
      expect(_rolesOf(index, rolesTest, '/buildFoo().'), [_testRole]);
    });

    test('is set on references from test code to lib/ code only', () {
      final rolesTest = p.join('test', 'roles_test.dart');
      final other = p.join('lib', 'other.dart');

      expect(_rolesOf(index, rolesTest, 'lib/`other.dart`/Foo#'), [_testRole]);
      expect(_rolesOf(index, other, 'lib/`other.dart`/Foo#'), [_definition]);
    });

    test('is set in the paths of dart_test.yaml', () {
      final specTest = p.join('spec', 'spec_test.dart');

      expect(_rolesOf(index, specTest, '/main().'), [_definition | _testRole]);
      expect(
        _rolesOf(index, specTest, 'lib/`other.dart`/Bar#`<constructor>`().'),
        [_testRole],
      );
    });
  });
}

/// The [TestPaths] of a new package made of [files], keyed by their
/// URL-format relative paths.
TestPaths _testPathsFor(Map<String, String> files) {
  final root = Directory.systemTemp.createTempSync('scip_dart_test_paths');
  addTearDown(() => root.deleteSync(recursive: true));
  for (final MapEntry(key: path, value: content) in files.entries) {
    File(p.join(root.path, p.fromUri(path)))
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }
  return TestPaths.forPackage(root.path);
}

/// Whether [relativePath] is test code in [_fixtureRoot]: it is in `test/`
/// by convention, or in `spec/` because of its `dart_test.yaml`.
bool _isFixtureTestFile(String relativePath) =>
    const {'test', 'spec'}.contains(p.split(relativePath).first);

/// Indexes [_fixtureRoot] the same way `bin/scip_dart.dart` does, without
/// indexing its pubspec.
Future<Index> _indexFixture() async {
  final packageConfig = await findPackageConfig(
    Directory(_fixtureRoot),
    recurse: false,
  );
  if (packageConfig == null) {
    throw StateError('Run `dart pub get` in $_fixtureRoot first');
  }
  final pubspec = Pubspec.parse(
    File(p.join(_fixtureRoot, 'pubspec.yaml')).readAsStringSync(),
  );
  return indexPackage(_fixtureRoot, packageConfig, pubspec);
}

/// All the occurrences in the documents whose relative path matches
/// [includePath].
List<Occurrence> _occurrencesInFiles(
  Index index,
  bool Function(String relativePath) includePath,
) => [
  for (final document in index.documents)
    if (includePath(document.relativePath)) ...document.occurrences,
];

/// The roles of each occurrence in [relativePath] whose symbol ends with
/// [symbolSuffix], in source order.
List<int> _rolesOf(Index index, String relativePath, String symbolSuffix) =>
    index.documents
        .singleWhere((document) => document.relativePath == relativePath)
        .occurrences
        .where((occurrence) => occurrence.symbol.endsWith(symbolSuffix))
        .map((occurrence) => occurrence.symbolRoles)
        .toList();

bool _hasTestRole(Occurrence occurrence) =>
    occurrence.symbolRoles & _testRole != 0;
