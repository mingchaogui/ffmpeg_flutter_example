import 'package:ffmpeg_example/tool/transcoding_args_generator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS Device RegExp', () {
    const List<String> names = <String>[
      'iPhone2,1.',
      'iPhone3,1',
      'iPhone4',
      'iPad2,1.',
      'iPad3,1',
      'iPad4',
      'iPad',
      'iPad Simulator',
    ];
    for (final String name in names) {
      final IosMachine model = IosMachine.fromName(name);
      debugPrint('name: $name, model: $model');
    }
  });
}
