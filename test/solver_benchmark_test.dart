@Tags(['benchmark'])
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watersort/domain/models/tube.dart';
import 'package:watersort/domain/use_cases/level_generator.dart';
import 'package:watersort/domain/use_cases/level_solver.dart';

void main() {
  test('time fixed-seed gameplay boards and replay every returned solution', () {
    final times = <double>[];
    var total = 0;
    var limited = 0;
    final generator = LevelGenerator();
    final solver = LevelSolver();

    for (final shape in [(3, 4), (6, 4), (9, 5), (12, 5), (16, 6)]) {
      for (final seed in [1, 7, 42]) {
        total++;
        print('GENERATE colors=${shape.$1} capacity=${shape.$2} seed=$seed');
        final generationClock = Stopwatch()..start();
        final level = generator.generateRandom(
          colorCount: shape.$1,
          capacity: shape.$2,
          seed: seed,
        );
        generationClock.stop();
        final clock = Stopwatch()..start();
        final result = solver.solveDetailed(level.tubes);
        clock.stop();
        final milliseconds = clock.elapsedMicroseconds / 1000;
        print('SOLVER colors=${shape.$1} capacity=${shape.$2} seed=$seed '
            'status=${result.status.name} ms=${milliseconds.toStringAsFixed(3)} '
            'visited=${result.visited} moves=${result.moves.length} '
            'generationMs=${generationClock.elapsedMilliseconds}');
        if (!result.found) {
          limited++;
          continue;
        }
        times.add(milliseconds);
        var tubes = level.tubes;
        for (final move in result.moves) {
          final source = tubes[move.fromIndex];
          final target = tubes[move.toIndex];
          expect(move.fromIndex, isNot(move.toIndex));
          expect(source.isEmpty, isFalse);
          expect(target.canReceive(source.topColor!), isTrue);
          final color = source.topColor!;
          final run = source.colors.reversed.takeWhile((c) => c == color).length;
          final count = math.min(run, target.capacity - target.colors.length);
          final next = List<Tube>.from(tubes);
          next[move.fromIndex] = source.copyWith(
            colors: source.colors.sublist(0, source.colors.length - count),
          );
          next[move.toIndex] = target.copyWith(
            colors: [...target.colors, ...List<Color>.filled(count, color)],
          );
          tubes = next;
        }
        expect(tubes.every((tube) => tube.isEmpty || tube.isSolved), isTrue);
      }
    }
    expect(times, isNotEmpty);
    times.sort();
    final median = times[times.length ~/ 2];
    print('SUMMARY solved=${times.length}/$total incomplete=$limited '
        'medianMs=${median.toStringAsFixed(3)} '
        'minMs=${times.first.toStringAsFixed(3)} '
        'maxMs=${times.last.toStringAsFixed(3)} '
        'under500ms=${times.where((ms) => ms < 500).length}/${times.length}');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
