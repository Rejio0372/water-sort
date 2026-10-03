import 'dart:math';

import 'package:flutter/material.dart';
import 'package:watersort/domain/models/tube.dart';

enum LevelSolveStatus { found, limitReached, noSolution }

class LevelSolveResult {
  const LevelSolveResult({
    required this.status,
    required this.moves,
    required this.visited,
    required this.maxVisited,
    required this.maxDepth,
    required this.maxDuration,
  });

  final LevelSolveStatus status;
  final List<WaterSortMove> moves;
  final int visited;
  final int maxVisited;
  final int maxDepth;
  final Duration maxDuration;

  bool get found => status == LevelSolveStatus.found;
  bool get limitReached => status == LevelSolveStatus.limitReached;
  int get visitedCount => visited;
  List<WaterSortMove> get solution => moves;
  bool get isFound => found;

  factory LevelSolveResult.fromMap(Map<dynamic, dynamic> map) {
    final statusName = map['status'] as String? ?? 'noSolution';
    final status = LevelSolveStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => LevelSolveStatus.noSolution,
    );
    final moves = (map['moves'] as List<dynamic>? ?? const [])
        .map((move) {
          final pair = move as List;
          return WaterSortMove(
            fromIndex: pair[0] as int,
            toIndex: pair[1] as int,
          );
        })
        .toList();
    return LevelSolveResult(
      status: status,
      moves: moves,
      visited: map['visited'] as int? ?? 0,
      maxVisited: map['maxVisited'] as int? ?? 150000,
      maxDepth: map['maxDepth'] as int? ?? 384,
      maxDuration: Duration(milliseconds: map['maxDurationMs'] as int? ?? 4000),
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'moves': moves.map((move) => [move.fromIndex, move.toIndex]).toList(),
        'visited': visited,
        'maxVisited': maxVisited,
        'maxDepth': maxDepth,
        'maxDurationMs': maxDuration.inMilliseconds,
      };
}

class WaterSortMove {
  final int fromIndex;
  final int toIndex;
  WaterSortMove({required this.fromIndex, required this.toIndex});
}

class LevelSolver {
  static const int defaultMaxVisited = 150000;
  static const int defaultMaxDepth = 384;
  static const Duration defaultMaxDuration = Duration(seconds: 4);

  List<WaterSortMove>? solve(
    List<Tube> initialTubes, {
    int maxVisited = defaultMaxVisited,
    int maxDepth = defaultMaxDepth,
    Duration maxDuration = defaultMaxDuration,
  }) {
    final result = solveDetailed(
      initialTubes,
      maxVisited: maxVisited,
      maxDepth: maxDepth,
      maxDuration: maxDuration,
    );
    return result.found ? result.moves : null;
  }

  LevelSolveResult solveDetailed(
    List<Tube> initialTubes, {
    int maxVisited = defaultMaxVisited,
    int maxDepth = defaultMaxDepth,
    Duration maxDuration = defaultMaxDuration,
  }) {
    final visited = <String>{};
    final stopwatch = Stopwatch()..start();
    var hitLimit = false;
    List<WaterSortMove>? result;

    String serializeState(List<Tube> tubes) {
      final keys = tubes.map((t) {
        final colors = t.colors.map((c) => c.toARGB32().toRadixString(16)).join(',');
        return '$colors:${t.capacity}';
      }).toList()..sort();
      return keys.join('|');
    }

    bool isComplete(List<Tube> tubes) {
      return tubes.every((t) => t.isEmpty || t.isSolved);
    }

    bool budgetExceeded() {
      if (visited.length >= maxVisited || stopwatch.elapsed >= maxDuration) {
        hitLimit = true;
        return true;
      }
      return false;
    }

    bool dfs(List<Tube> currentTubes, List<WaterSortMove> path) {
      if (isComplete(currentTubes)) {
        result = List<WaterSortMove>.from(path);
        return true;
      }
      if (budgetExceeded() || path.length >= maxDepth) {
        if (path.length >= maxDepth) hitLimit = true;
        return false;
      }

      final stateKey = serializeState(currentTubes);
      if (!visited.add(stateKey)) return false;

      final moves = _getValidMoves(currentTubes);
      for (final move in moves) {
        if (budgetExceeded()) return false;
        if (path.isNotEmpty) {
          final lastMove = path.last;
          if (lastMove.fromIndex == move.toIndex && lastMove.toIndex == move.fromIndex) {
            continue;
          }
        }

        final nextTubes = _performPour(currentTubes, move.fromIndex, move.toIndex);
        if (nextTubes != null) {
          path.add(move);
          if (dfs(nextTubes, path)) return true;
          path.removeLast();
        }
      }
      return false;
    }

    dfs(initialTubes, []);
    stopwatch.stop();
    final status = result != null
        ? LevelSolveStatus.found
        : hitLimit
            ? LevelSolveStatus.limitReached
            : LevelSolveStatus.noSolution;
    return LevelSolveResult(
      status: status,
      moves: result ?? const [],
      visited: visited.length,
      maxVisited: maxVisited,
      maxDepth: maxDepth,
      maxDuration: maxDuration,
    );
  }

  List<WaterSortMove> _getValidMoves(List<Tube> tubes) {
    final moves = <_ScoredMove>[];
    int firstEmptyIndex = -1;
    for (int i = 0; i < tubes.length; i++) {
      if (tubes[i].isEmpty) {
        firstEmptyIndex = i;
        break;
      }
    }

    for (int i = 0; i < tubes.length; i++) {
      final fromTube = tubes[i];
      if (fromTube.isEmpty || fromTube.isSolved) continue;
      final colorToMove = fromTube.topColor!;
      int countToMove = 0;
      for (int k = fromTube.colors.length - 1; k >= 0; k--) {
        if (fromTube.colors[k] == colorToMove) {
          countToMove++;
        } else {
          break;
        }
      }
      final fromIsMono = fromTube.colors.every((c) => c == colorToMove);

      for (int j = 0; j < tubes.length; j++) {
        if (i == j) continue;
        final toTube = tubes[j];
        if (toTube.isFull) continue;
        if (toTube.isEmpty) {
          if (fromIsMono || j != firstEmptyIndex) continue;
        } else if (toTube.topColor != colorToMove) {
          continue;
        }
        final space = toTube.capacity - toTube.colors.length;
        final pourCount = min(countToMove, space);
        if (pourCount == 0) continue;

        int score = 0;
        final willSolveTarget = (toTube.colors.length + pourCount == toTube.capacity) &&
            (toTube.isEmpty || toTube.colors.every((c) => c == colorToMove));
        final willEmptySource = fromTube.colors.length == pourCount;
        final willRevealNewColor = !willEmptySource && countToMove == pourCount;
        if (willSolveTarget) {
          score += 150;
        } else if (willEmptySource) {
          score += 80;
        } else if (willRevealNewColor) {
          score += 50;
        } else if (!toTube.isEmpty) {
          score += pourCount == countToMove ? 35 : 10;
        } else {
          score += fromTube.colors.length - pourCount > 0 ? 25 : 5;
        }
        moves.add(_ScoredMove(move: WaterSortMove(fromIndex: i, toIndex: j), score: score));
      }
    }
    moves.sort((a, b) => b.score.compareTo(a.score));
    return moves.map((m) => m.move).toList();
  }

  List<Tube>? _performPour(List<Tube> tubes, int fromIndex, int toIndex) {
    final fromTube = tubes[fromIndex];
    final toTube = tubes[toIndex];
    if (fromTube.isEmpty || toTube.isFull) return null;
    final colorToMove = fromTube.topColor!;
    if (!toTube.canReceive(colorToMove)) return null;
    int countToMove = 0;
    for (int i = fromTube.colors.length - 1; i >= 0; i--) {
      if (fromTube.colors[i] == colorToMove) {
        countToMove++;
      } else {
        break;
      }
    }
    final pourCount = min(countToMove, toTube.capacity - toTube.colors.length);
    if (pourCount == 0) return null;
    final newFromColors = List<Color>.from(fromTube.colors)
      ..removeRange(fromTube.colors.length - pourCount, fromTube.colors.length);
    final newToColors = List<Color>.from(toTube.colors)
      ..addAll(List.filled(pourCount, colorToMove));
    final newTubes = List<Tube>.from(tubes);
    newTubes[fromIndex] = fromTube.copyWith(colors: newFromColors);
    newTubes[toIndex] = toTube.copyWith(colors: newToColors);
    return newTubes;
  }
}

class _ScoredMove {
  final WaterSortMove move;
  final int score;
  _ScoredMove({required this.move, required this.score});
}
