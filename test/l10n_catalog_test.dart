import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English and Malay catalogs contain the same nonempty messages', () {
    Map<String, dynamic> catalog(String code) =>
        jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
            as Map<String, dynamic>;
    final en = catalog('en')..removeWhere((key, value) => key.startsWith('@'));
    final ms = catalog('ms')..removeWhere((key, value) => key.startsWith('@'));
    expect(ms.keys.toSet(), en.keys.toSet());
    for (final value in [...en.values, ...ms.values]) {
      expect(value, isA<String>());
      expect((value as String).trim(), isNotEmpty);
    }
  });
}
