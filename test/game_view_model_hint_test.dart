import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watersort/data/repositories/progress_repository.dart';
import 'package:watersort/domain/models/game_level.dart';
import 'package:watersort/domain/models/tube.dart';
import 'package:watersort/domain/use_cases/level_generator.dart';
import 'package:watersort/domain/use_cases/level_solver.dart';
import 'package:watersort/ui/features/game/view_models/game_view_model.dart';

class _FakeProgressRepository implements ProgressRepository {
  bool instantPouring = false;

  @override
  bool isTimerEnabled() => false;

  @override
  bool isSuperHardModeEnabled() => false;

  @override
  bool isBlurSolvedTubesEnabled() => false;

  @override
  bool isInstantPouringEnabled() => instantPouring;

  @override
  bool isHintHelperEnabled() => false;

  @override
  bool isUndoDecrementsMovesEnabled() => false;

  @override
  bool isSoundEffectsEnabled() => false;

  @override
  String getTubeSize() => 'medium';

  @override
  String? getCustomBackgroundImagePath() => null;

  @override
  Map<dynamic, dynamic>? getSavedLevelState() => null;

  @override
  Future<void> clearActiveLevelState() async {}

  @override
  Future<void> saveActiveLevelState(Map<dynamic, dynamic> state) async {}

  @override
  Future<void> saveLevelStars(int levelNumber, int stars) async {}

  @override
  Future<void> addRandomLevelMoves(int moves) async {}

  @override
  Future<void> completeLevel(int levelNumber, int moves) async {}

  @override
  noSuchMethod(Invocation invocation) => null;
}

class _FakeLevelGenerator extends LevelGenerator {
  GameLevel _make(int levelNumber) => GameLevel(
        levelNumber: levelNumber,
        optimalMoves: 20,
        tubes: [
          Tube(colors: [Colors.red, Colors.blue, Colors.red, Colors.blue]),
          Tube(colors: [Colors.blue, Colors.red, Colors.blue, Colors.red]),
          const Tube(colors: []),
        ],
      );

  @override
  GameLevel generate(int levelNumber) => _make(levelNumber);

  @override
  GameLevel generateRandom({
    required int colorCount,
    required int seed,
    int capacity = 4,
  }) =>
      _make(-1);
}

LevelSolveResult _found(List<WaterSortMove> moves) => LevelSolveResult(
      status: LevelSolveStatus.found,
      moves: moves,
      visited: 1,
      maxVisited: 150000,
      maxDepth: 384,
      maxDuration: const Duration(seconds: 4),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameViewModel model;
  late _FakeProgressRepository repository;
  late _FakeLevelGenerator generator;

  setUp(() async {
    repository = _FakeProgressRepository();
    generator = _FakeLevelGenerator();
    model = GameViewModel(
      progressRepository: repository,
      levelGenerator: generator,
    );
    await model.loadLevel(1);
  });

  tearDown(() {
    if (model.mounted) model.dispose();
  });

  test('default compute runner returns a real hint', () async {
    expect(await model.showHint(), isTrue);
    expect(model.state.hintFromIndex, isNull);
    expect(model.state.hintToIndex, isNull);
    expect(model.state.pouringFromIndex, isNotNull);
    expect(model.state.pouringToIndex, isNotNull);
    expect(model.state.moveCount, 0);
    expect(model.state.moveHistory, isEmpty);
    await model.completePendingPour();
    expect(model.state.moveCount, 1);
    expect(model.state.moveHistory, hasLength(1));
  });

  test('repeated operations advance the cache without recalculating', () async {
    var calls = 0;
    model.dispose();
    model = GameViewModel(
      progressRepository: repository,
      levelGenerator: generator,
      hintRunner: (tubes) async {
        calls++;
        return _found([
          WaterSortMove(fromIndex: 0, toIndex: 2),
          WaterSortMove(fromIndex: 1, toIndex: 0),
        ]);
      },
    );
    await model.loadLevel(1);
    expect(await model.showHint(), isTrue);
    expect(model.state.pouringFromIndex, 0);
    expect(model.state.pouringToIndex, 2);
    expect(model.state.moveCount, 0);
    expect(await model.showHint(), isFalse);
    expect(calls, 1);
    expect(model.state.pouringFromIndex, 0);
    await model.completePendingPour();
    expect(await model.showHint(), isTrue);
    expect(calls, 1);
    expect(model.state.pouringFromIndex, 1);
    expect(model.state.pouringToIndex, 0);
    expect(model.state.hintFromIndex, isNull);
    expect(model.state.hintToIndex, isNull);
  });

  test('instant pouring applies one step and undo restores the board', () async {
    var calls = 0;
    model.dispose();
    repository.instantPouring = true;
    model = GameViewModel(
      progressRepository: repository,
      levelGenerator: generator,
      hintRunner: (tubes) async {
        calls++;
        return _found([
          WaterSortMove(fromIndex: 0, toIndex: 2),
          WaterSortMove(fromIndex: 1, toIndex: 0),
        ]);
      },
    );
    await model.loadLevel(1);
    final originalTubes = model.state.level!.tubes;
    expect(await model.showHint(), isTrue);
    expect(calls, 1);
    expect(model.state.pouringFromIndex, isNull);
    expect(model.state.pouringToIndex, isNull);
    expect(model.state.moveCount, 1);
    expect(model.state.moveHistory, hasLength(1));
    expect(model.state.level!.tubes, isNot(originalTubes));
    expect(model.state.hintFromIndex, isNull);
    expect(model.state.hintToIndex, isNull);
    model.undoMove();
    expect(model.state.level!.tubes, originalTubes);
    expect(model.state.moveHistory, isEmpty);
    expect(await model.showHint(), isTrue);
    expect(calls, 2);
  });

  test('busy guard prevents a second request and limit is not shown as no solution', () async {
    final pending = Completer<LevelSolveResult>();
    var calls = 0;
    model.dispose();
    model = GameViewModel(
      progressRepository: repository,
      levelGenerator: generator,
      hintRunner: (tubes) {
        calls++;
        return pending.future;
      },
    );
    await model.loadLevel(1);
    final first = model.showHint();
    await Future<void>.delayed(Duration.zero);
    expect(model.state.isSolvingHint, isTrue);
    expect(await model.showHint(), isFalse);
    expect(calls, 1);
    pending.complete(LevelSolveResult(
      status: LevelSolveStatus.limitReached,
      moves: const [],
      visited: 1,
      maxVisited: 1,
      maxDepth: 384,
      maxDuration: const Duration(seconds: 4),
    ));
    expect(await first, isFalse);
    expect(model.state.hintMessage, contains('limit'));
    expect(model.state.hintMessage, isNot(contains('No solution')));
    expect(model.state.pouringFromIndex, isNull);
    expect(model.state.moveCount, 0);
  });

  test('different state invalidates old cache and requests a fresh hint', () async {
    var calls = 0;
    model.dispose();
    model = GameViewModel(
      progressRepository: repository,
      levelGenerator: generator,
      hintRunner: (tubes) async {
        calls++;
        return _found([WaterSortMove(fromIndex: 0, toIndex: 2)]);
      },
    );
    await model.loadLevel(1);
    await model.showHint();
    await model.loadLevel(2);
    await model.showHint();
    expect(calls, 2);
  });

  test('move, load, and dispose discard an in-flight result', () async {
    final pending = Completer<LevelSolveResult>();
    model.dispose();
    model = GameViewModel(
      progressRepository: repository,
      levelGenerator: generator,
      hintRunner: (tubes) => pending.future,
    );
    await model.loadLevel(1);
    final request = model.showHint();
    await Future<void>.delayed(Duration.zero);
    model.selectTube(0);
    model.selectTube(2);
    await model.completePendingPour();
    pending.complete(_found([WaterSortMove(fromIndex: 0, toIndex: 1)]));
    expect(await request, isFalse);
    expect(model.state.hintFromIndex, isNull);
    expect(model.state.isSolvingHint, isFalse);
    expect(model.state.moveCount, 1);

    final secondPending = Completer<LevelSolveResult>();
    model.dispose();
    model = GameViewModel(
      progressRepository: repository,
      levelGenerator: generator,
      hintRunner: (tubes) => secondPending.future,
    );
    await model.loadLevel(1);
    final loadRequest = model.showHint();
    await Future<void>.delayed(Duration.zero);
    await model.loadLevel(2);
    secondPending.complete(_found([WaterSortMove(fromIndex: 0, toIndex: 2)]));
    expect(await loadRequest, isFalse);
    expect(model.state.level?.levelNumber, 2);

    model.dispose();
    final disposalPending = Completer<LevelSolveResult>();
    model = GameViewModel(
      progressRepository: repository,
      levelGenerator: generator,
      hintRunner: (tubes) => disposalPending.future,
    );
    await model.loadLevel(1);
    final disposalRequest = model.showHint();
    model.dispose();
    disposalPending.complete(_found([WaterSortMove(fromIndex: 0, toIndex: 2)]));
    expect(await disposalRequest, isFalse);
  });

  test('undo discards an in-flight hint and restores the board', () async {
    final pending = Completer<LevelSolveResult>();
    model.dispose();
    model = GameViewModel(
      progressRepository: repository,
      levelGenerator: generator,
      hintRunner: (tubes) => pending.future,
    );
    await model.loadLevel(1);
    final originalTubes = model.state.level!.tubes;
    model.selectTube(0);
    model.selectTube(2);
    await model.completePendingPour();
    final request = model.showHint();
    model.undoMove();
    pending.complete(_found([WaterSortMove(fromIndex: 1, toIndex: 0)]));
    expect(await request, isFalse);
    expect(model.state.level!.tubes, originalTubes);
    expect(model.state.hintFromIndex, isNull);
    expect(model.state.isSolvingHint, isFalse);
  });
}
