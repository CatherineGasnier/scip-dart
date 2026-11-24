  import 'package:dart_test/other.dart';
// definition scip-dart pub dart_test 1.0.0 test/`roles_test.dart`/
//       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ reference scip-dart pub dart_test 1.0.0 lib/`other.dart`/
  import 'package:test/test.dart';
//       ^^^^^^^^^^^^^^^^^^^^^^^^ reference scip-dart pub test 1.24.3 lib/`test.dart`/
  
  import 'helpers.dart';
//       ^^^^^^^^^^^^^^ reference scip-dart pub dart_test 1.0.0 test/`helpers.dart`/
  
  void main() {
//     ^^^^ definition scip-dart pub dart_test 1.0.0 test/`roles_test.dart`/main().
    test('anonymous callback', () {
//  ^^^^ reference scip-dart pub test_core 0.5.3 lib/`scaffolding.dart`/test().
      final Foo foo = buildFoo();
//          ^^^ reference scip-dart pub dart_test 1.0.0 lib/`other.dart`/Foo#
//              ^^^ definition local 0
//                    ^^^^^^^^ reference scip-dart pub dart_test 1.0.0 test/`helpers.dart`/buildFoo().
      expect(foo.value, isTrue);
//    ^^^^^^ reference scip-dart pub matcher 0.12.16 lib/src/expect/`expect.dart`/expect().
//           ^^^ reference local 0
//               ^^^^^ reference scip-dart pub dart_test 1.0.0 lib/`other.dart`/Foo#value.
//                      ^^^^^^ reference scip-dart pub matcher 0.12.16 lib/src/`core_matchers.dart`/isTrue.
    });
  
    test('named test function', namedTestFunction);
//  ^^^^ reference scip-dart pub test_core 0.5.3 lib/`scaffolding.dart`/test().
//                              ^^^^^^^^^^^^^^^^^ reference scip-dart pub dart_test 1.0.0 test/`roles_test.dart`/namedTestFunction().
  }
  
  void namedTestFunction() {
//     ^^^^^^^^^^^^^^^^^ definition scip-dart pub dart_test 1.0.0 test/`roles_test.dart`/namedTestFunction().
    expect(Bar('a'), isA<Bar>());
//  ^^^^^^ reference scip-dart pub matcher 0.12.16 lib/src/expect/`expect.dart`/expect().
//         ^^^ reference scip-dart pub dart_test 1.0.0 lib/`other.dart`/Bar#`<constructor>`().
//                   ^^^ reference scip-dart pub matcher 0.12.16 lib/src/`type_matcher.dart`/isA().
//                       ^^^ reference scip-dart pub dart_test 1.0.0 lib/`other.dart`/Bar#
  }
  
