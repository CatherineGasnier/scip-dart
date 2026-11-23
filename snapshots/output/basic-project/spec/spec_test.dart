  import 'package:dart_test/other.dart';
// definition scip-dart pub dart_test 1.0.0 spec/`spec_test.dart`/
//       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ reference scip-dart pub dart_test 1.0.0 lib/`other.dart`/
  import 'package:test/test.dart';
//       ^^^^^^^^^^^^^^^^^^^^^^^^ reference scip-dart pub test 1.24.3 lib/`test.dart`/
  
  void main() {
//     ^^^^ definition scip-dart pub dart_test 1.0.0 spec/`spec_test.dart`/main().
    test('in a directory listed in dart_test.yaml', () {
//  ^^^^ reference scip-dart pub test_core 0.5.3 lib/`scaffolding.dart`/test().
      expect(Bar('b'), isNotNull);
//    ^^^^^^ reference scip-dart pub matcher 0.12.16 lib/src/expect/`expect.dart`/expect().
//           ^^^ reference scip-dart pub dart_test 1.0.0 lib/`other.dart`/Bar#`<constructor>`().
//                     ^^^^^^^^^ reference scip-dart pub matcher 0.12.16 lib/src/`core_matchers.dart`/isNotNull.
    });
  }
  
