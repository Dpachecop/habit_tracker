import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the dependency rule from `ARCHITECTURE.md` §2 mechanically.
///
/// "The domain imports no Flutter and no I/O" is the invariant the whole layer
/// split rests on, and it is exactly the kind of rule that erodes one
/// convenient import at a time. A grep-shaped test costs nothing and turns the
/// erosion into a red suite instead of a code review someone has to remember to
/// do.
void main() {
  /// Packages the domain may never reach for, with why each one is banned.
  const Map<String, String> forbidden = <String, String>{
    'package:flutter/': 'the domain must build without a UI toolkit',
    'package:firebase': 'persistence is an infrastructure detail',
    'package:cloud_firestore': 'persistence is an infrastructure detail',
    'dart:ui':
        'Color and friends belong to presentation — the domain '
        'stores a HabitColorSlot',
    'dart:io': 'no file or socket access below the infrastructure layer',
    'dart:html': 'no browser APIs anywhere in this app',
  };

  test('lib/domain imports nothing outside pure Dart', () {
    final Directory domain = Directory('lib/domain');
    expect(
      domain.existsSync(),
      isTrue,
      reason: 'run this from the Flutter project root',
    );

    final List<String> violations = <String>[];
    final Iterable<File> sources = domain
        .listSync(recursive: true)
        .whereType<File>()
        .where((File file) => file.path.endsWith('.dart'));

    for (final File source in sources) {
      for (final String line in source.readAsLinesSync()) {
        if (!line.startsWith('import ') && !line.startsWith('export ')) {
          continue;
        }
        for (final MapEntry<String, String> ban in forbidden.entries) {
          if (line.contains(ban.key)) {
            violations.add('${source.path}: $line — ${ban.value}');
          }
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('the domain layer actually has files to check', () {
    // Without this, deleting the layer would make the test above pass.
    final int count =
        Directory('lib/domain')
            .listSync(recursive: true)
            .whereType<File>()
            .where((File file) => file.path.endsWith('.dart'))
            .length;

    expect(count, greaterThan(5));
  });
}
