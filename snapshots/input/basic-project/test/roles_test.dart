import 'package:dart_test/other.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  test('anonymous callback', () {
    final Foo foo = buildFoo();
    expect(foo.value, isTrue);
  });

  test('named test function', namedTestFunction);
}

void namedTestFunction() {
  expect(Bar('a'), isA<Bar>());
}
