import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watersort/domain/models/tube.dart';
import 'package:watersort/domain/use_cases/level_solver.dart';

List<Tube> _board(int capacity) => [
      Tube(
        capacity: capacity,
        colors: List.generate(capacity, (index) => index.isEven ? Colors.red : Colors.blue),
      ),
      Tube(
        capacity: capacity,
        colors: List.generate(capacity, (index) => index.isEven ? Colors.blue : Colors.red),
      ),
      Tube(colors: const [], capacity: capacity),
    ];

List<Tube> _applyMove(List<Tube> tubes, WaterSortMove move) {
  final from = tubes[move.fromIndex];
  final to = tubes[move.toIndex];
  expect(from.isEmpty, isFalse);
  expect(to.isFull, isFalse);
  expect(to.canReceive(from.topColor!), isTrue);
  final color = from.topColor!;
  var count = 0;
  for (var i = from.colors.length - 1; i >= 0 && from.colors[i] == color; i--) {
    count++;
  }
  final amount = count.clamp(0, to.capacity - to.colors.length);
  expect(amount, greaterThan(0));
  final next = List<Tube>.from(tubes);
  next[move.fromIndex] = from.copyWith(
    colors: List<Color>.from(from.colors)..removeRange(from.colors.length - amount, from.colors.length),
  );
  next[move.toIndex] = to.copyWith(
    colors: List<Color>.from(to.colors)..addAll(List.filled(amount, color)),
  );
  return next;
}

void _expectSolved(List<Tube> tubes) {
  expect(tubes.every((tube) => tube.isEmpty || tube.isSolved), isTrue);
}

void main() {
  test('solves mixed boards and every returned move is legal', () {
    for (final capacity in [4, 5, 6]) {
      final initial = _board(capacity);
      final result = LevelSolver().solveDetailed(initial);
      expect(result.status, LevelSolveStatus.found);
      var current = initial;
      for (final move in result.moves) {
        current = _applyMove(current, move);
      }
      _expectSolved(current);
    }
  });

  test('already solved state succeeds with an empty solution', () {
    final result = LevelSolver().solveDetailed([
      Tube(colors: [Colors.red, Colors.red, Colors.red, Colors.red]),
      Tube(colors: [Colors.blue, Colors.blue, Colors.blue, Colors.blue]),
      const Tube(colors: []),
    ]);
    expect(result.status, LevelSolveStatus.found);
    expect(result.moves, isEmpty);
  });

  test('full mixed board with no spare tube is reported as no solution', () {
    final result = LevelSolver().solveDetailed([
      Tube(colors: [Colors.red, Colors.blue, Colors.red, Colors.blue]),
      Tube(colors: [Colors.blue, Colors.red, Colors.blue, Colors.red]),
    ]);
    expect(result.status, LevelSolveStatus.noSolution);
    expect(result.moves, isEmpty);
  });

  test('visited budget is reported as limitReached rather than noSolution', () {
    final result = LevelSolver().solveDetailed(_board(4), maxVisited: 1);
    expect(result.status, LevelSolveStatus.limitReached);
    expect(result.maxVisited, 1);
    expect(result.visited, lessThanOrEqualTo(1));
  });

  test('depth budget is reported as limitReached', () {
    final result = LevelSolver().solveDetailed(_board(4), maxDepth: 0);
    expect(result.status, LevelSolveStatus.limitReached);
    expect(result.maxDepth, 0);
  });

  test('elapsed time budget is reported as limitReached', () {
    final result = LevelSolver().solveDetailed(_board(4), maxDuration: Duration.zero);
    expect(result.status, LevelSolveStatus.limitReached);
  });
}
