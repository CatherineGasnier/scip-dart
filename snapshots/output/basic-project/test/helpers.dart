  import 'package:dart_test/other.dart';
// definition scip-dart pub dart_test 1.0.0 test/`helpers.dart`/
//       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ reference scip-dart pub dart_test 1.0.0 lib/`other.dart`/
  
  /// Not a test suite: a helper shared by test files.
  Foo buildFoo() => Foo(1, value: true, value2: 'helper');
//^^^ reference scip-dart pub dart_test 1.0.0 lib/`other.dart`/Foo#
//    ^^^^^^^^ definition scip-dart pub dart_test 1.0.0 test/`helpers.dart`/buildFoo().
//    documentation
//    > Not a test suite: a helper shared by test files.
//                  ^^^ reference scip-dart pub dart_test 1.0.0 lib/`other.dart`/Foo#`<constructor>`().
//                         ^^^^^ reference scip-dart pub dart_test 1.0.0 lib/`other.dart`/Foo#`<constructor>`().(value)
//                                      ^^^^^^ reference scip-dart pub dart_test 1.0.0 lib/`other.dart`/Foo#`<constructor>`().(value2)
  
