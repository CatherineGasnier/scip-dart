import 'package:dart_test/other.dart';
import 'package:test/test.dart';

void main() {
  test('in a directory listed in dart_test.yaml', () {
    expect(Bar('b'), isNotNull);
  });
}
