import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:watersort/data/repositories/progress_repository.dart';
import 'package:watersort/domain/models/game_level.dart';
import 'package:watersort/domain/models/tube.dart';
import 'package:watersort/domain/use_cases/level_generator.dart';
import 'package:watersort/domain/use_cases/level_solver.dart';

typedef HintSolverRunner = Future<LevelSolveResult> Function(List<Tube> tubes);

Map<String, dynamic> _solveHintInIsolate(Map<String, dynamic> payload) {
  final tubes = (payload['tubes'] as List<dynamic>).map((tube) {
    final map = tube as Map<dynamic, dynamic>;
    return Tube(
      capacity: map['capacity'] as int,
      colors: (map['colors'] as List<dynamic>)
          .map((value) => Color(value as int))
          .toList(),
    );
  }).toList();
  final solver = LevelSolver();
  return solver.solveDetailed(tubes).toMap();
}

Future<LevelSolveResult> _defaultHintRunner(List<Tube> tubes) async {
  final payload = <String, dynamic>{
    'tubes': tubes
        .map((tube) => {
              'capacity': tube.capacity,
              'colors': tube.colors.map((color) => color.toARGB32()).toList(),
            })
        .toList(),
  };
  // compute requires a top-level callback and a transferable color snapshot.
  final result = await compute<Map<String, dynamic>, Map<String, dynamic>>(_solveHintInIsolate, payload);
  return LevelSolveResult.fromMap(result);
}

@immutable
class MoveSnapshot {
  const MoveSnapshot({required this.tubes, required this.moveCount});
  final List<Tube> tubes;
  final int moveCount;
}

@immutable
class GameViewModelState {
  const GameViewModelState({
    this.level,
    this.isLoading = false,
    this.isComplete = false,
    this.selectedTubeIndex,
    this.pouringFromIndex,
    this.pouringToIndex,
    this.moveCount = 0,
    this.error,
    this.isRandomMode = false,
    this.randomDifficulty,
    this.randomSeed,
    this.randomColorCount,
    this.randomCapacity,
    this.moveHistory = const [],
    this.timeLeft,
    this.isTimeOut = false,
    this.isProgressSaved = false,
    this.isSuperHardModeEnabled = false,
    this.isBlurSolvedTubesEnabled = false,
    this.isInstantPouringEnabled = false,
    this.isHintHelperEnabled = false,
    this.isUndoDecrementsMovesEnabled = false,
    this.isSoundEffectsEnabled = true,
    this.tubeSize = 'medium',
    this.hintFromIndex,
    this.hintToIndex,
    this.isSolvingHint = false,
    this.hintMessage,
    this.customBackgroundImagePath,
  });

  final GameLevel? level;
  final bool isLoading;
  final bool isComplete;
  final int? selectedTubeIndex;
  final int? pouringFromIndex;
  final int? pouringToIndex;
  final int moveCount;
  final String? error;
  final bool isRandomMode;
  final String? randomDifficulty;
  final int? randomSeed;
  final int? randomColorCount;
  final int? randomCapacity;
  final List<MoveSnapshot> moveHistory;
  final int? timeLeft;
  final bool isTimeOut;
  final bool isProgressSaved;
  final bool isSuperHardModeEnabled;
  final bool isBlurSolvedTubesEnabled;
  final bool isInstantPouringEnabled;
  final bool isHintHelperEnabled;
  final bool isUndoDecrementsMovesEnabled;
  final bool isSoundEffectsEnabled;
  final String tubeSize;
  final int? hintFromIndex;
  final int? hintToIndex;
  final bool isSolvingHint;
  final String? hintMessage;
  final String? customBackgroundImagePath;

  bool get canUndo => moveHistory.isNotEmpty && !isComplete && !isTimeOut && pouringFromIndex == null;

  bool get canShowHint => level != null &&
      !isLoading &&
      !isComplete &&
      !isTimeOut &&
      !isSolvingHint &&
      pouringFromIndex == null;


  GameViewModelState copyWith({
    GameLevel? level,
    bool? isLoading,
    bool? isComplete,
    int? Function()? selectedTubeIndex,
    int? Function()? pouringFromIndex,
    int? Function()? pouringToIndex,
    int? moveCount,
    String? error,
    bool? isRandomMode,
    String? randomDifficulty,
    int? randomSeed,
    int? randomColorCount,
    int? randomCapacity,
    List<MoveSnapshot>? moveHistory,
    int? Function()? timeLeft,
    bool? isTimeOut,
    bool? isProgressSaved,
    bool? isSuperHardModeEnabled,
    bool? isBlurSolvedTubesEnabled,
    bool? isInstantPouringEnabled,
    bool? isHintHelperEnabled,
    bool? isUndoDecrementsMovesEnabled,
    bool? isSoundEffectsEnabled,
    String? tubeSize,
    int? Function()? hintFromIndex,
    int? Function()? hintToIndex,
    bool? isSolvingHint,
    String? Function()? hintMessage,
    String? Function()? customBackgroundImagePath,
  }) {
    return GameViewModelState(
      level: level ?? this.level,
      isLoading: isLoading ?? this.isLoading,
      isComplete: isComplete ?? this.isComplete,
      selectedTubeIndex:
          selectedTubeIndex != null ? selectedTubeIndex() : this.selectedTubeIndex,
      pouringFromIndex:
          pouringFromIndex != null ? pouringFromIndex() : this.pouringFromIndex,
      pouringToIndex:
          pouringToIndex != null ? pouringToIndex() : this.pouringToIndex,
      moveCount: moveCount ?? this.moveCount,
      error: error,
      isRandomMode: isRandomMode ?? this.isRandomMode,
      randomDifficulty: randomDifficulty ?? this.randomDifficulty,
      randomSeed: randomSeed ?? this.randomSeed,
      randomColorCount: randomColorCount ?? this.randomColorCount,
      randomCapacity: randomCapacity ?? this.randomCapacity,
      moveHistory: moveHistory ?? this.moveHistory,
      timeLeft: timeLeft != null ? timeLeft() : this.timeLeft,
      isTimeOut: isTimeOut ?? this.isTimeOut,
      isProgressSaved: isProgressSaved ?? this.isProgressSaved,
      isSuperHardModeEnabled: isSuperHardModeEnabled ?? this.isSuperHardModeEnabled,
      isBlurSolvedTubesEnabled: isBlurSolvedTubesEnabled ?? this.isBlurSolvedTubesEnabled,
      isInstantPouringEnabled: isInstantPouringEnabled ?? this.isInstantPouringEnabled,
      isHintHelperEnabled: isHintHelperEnabled ?? this.isHintHelperEnabled,
      isUndoDecrementsMovesEnabled: isUndoDecrementsMovesEnabled ?? this.isUndoDecrementsMovesEnabled,
      isSoundEffectsEnabled: isSoundEffectsEnabled ?? this.isSoundEffectsEnabled,
      tubeSize: tubeSize ?? this.tubeSize,
      hintFromIndex:
          hintFromIndex != null ? hintFromIndex() : this.hintFromIndex,
      hintToIndex:
          hintToIndex != null ? hintToIndex() : this.hintToIndex,
      isSolvingHint: isSolvingHint ?? this.isSolvingHint,
      hintMessage: hintMessage != null ? hintMessage() : this.hintMessage,
      customBackgroundImagePath: customBackgroundImagePath != null
          ? customBackgroundImagePath()
          : this.customBackgroundImagePath,
    );
  }
}

class GameViewModel extends StateNotifier<GameViewModelState> {
  GameViewModel({
    required this._progressRepository,
    required this._levelGenerator,
    HintSolverRunner? hintRunner,
  })  : _hintRunner = hintRunner ?? _defaultHintRunner,
        super(const GameViewModelState());

  final ProgressRepository _progressRepository;
  final LevelGenerator _levelGenerator;
  final HintSolverRunner _hintRunner;

  Timer? _timer;
  int _hintRequestVersion = 0;

  void _invalidateHintRequest({bool clearCache = false}) {
    _hintRequestVersion++;
    if (clearCache) {
      _cachedSolution = null;
      _cachedSolutionKey = null;
    }
    if (!mounted) return;
    if (state.isSolvingHint || state.hintFromIndex != null || state.hintToIndex != null || state.hintMessage != null) {
      state = state.copyWith(
        isSolvingHint: false,
        hintFromIndex: () => null,
        hintToIndex: () => null,
        hintMessage: () => null,
      );
    }
  }

  bool _shouldHaveTimer({required bool isRandom, required int levelNumber, required String difficulty}) {
    if (!_progressRepository.isTimerEnabled()) {
      return false;
    }
    if (isRandom) {
      return difficulty != 'Easy';
    } else {
      return levelNumber >= 4;
    }
  }

  int _calculateTimerDuration(int colorCount) {
    return ((30 + (colorCount * 15)) * 1.5).round();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    state = state.copyWith(timeLeft: () => seconds, isTimeOut: false);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeLeft == null || state.timeLeft! <= 0) {
        timer.cancel();
        return;
      }
      final newTime = state.timeLeft! - 1;
      if (newTime == 0) {
        timer.cancel();
        _invalidateHintRequest();
        state = state.copyWith(
          timeLeft: () => 0,
          isTimeOut: true,
        );
        HapticFeedback.heavyImpact();
      } else {
        state = state.copyWith(timeLeft: () => newTime);
      }
    });
  }

  Future<void> loadLevel(int levelNumber) async {
    _timer?.cancel();
    _invalidateHintRequest(clearCache: true);
    state = const GameViewModelState(isLoading: true);

    try {
      final savedMap = _progressRepository.getSavedLevelState();
      if (savedMap != null &&
          savedMap['levelNumber'] == levelNumber &&
          savedMap['isRandomMode'] == false) {
        final savedTubes = (savedMap['tubes'] as List).map((t) {
          final tMap = Map<dynamic, dynamic>.from(t as Map);
          return Tube(
            colors: (tMap['colors'] as List).map((c) => Color(c as int)).toList(),
            capacity: tMap['capacity'] as int,
          );
        }).toList();

        final savedHistory = (savedMap['moveHistory'] as List).map((h) {
          final hMap = Map<dynamic, dynamic>.from(h as Map);
          final tubes = (hMap['tubes'] as List).map((t) {
            final tMap = Map<dynamic, dynamic>.from(t as Map);
            return Tube(
              colors: (tMap['colors'] as List).map((c) => Color(c as int)).toList(),
              capacity: tMap['capacity'] as int,
            );
          }).toList();
          return MoveSnapshot(
            tubes: tubes,
            moveCount: hMap['moveCount'] as int,
          );
        }).toList();

        final level = GameLevel(
          levelNumber: levelNumber,
          tubes: savedTubes,
          optimalMoves: savedMap['optimalMoves'] as int,
        );

        final isSuperHard = _progressRepository.isSuperHardModeEnabled();
        final isBlurSolved = _progressRepository.isBlurSolvedTubesEnabled();
        final isInstantPouring = _progressRepository.isInstantPouringEnabled();
        final isHintHelper = _progressRepository.isHintHelperEnabled();
        final isUndoDecrementsMoves = _progressRepository.isUndoDecrementsMovesEnabled();
        final isSoundEffects = _progressRepository.isSoundEffectsEnabled();
        final tubeSize = _progressRepository.getTubeSize();
        final customBgPath = _progressRepository.getCustomBackgroundImagePath();

        state = GameViewModelState(
          level: level,
          moveCount: savedMap['moveCount'] as int,
          moveHistory: savedHistory,
          isSuperHardModeEnabled: isSuperHard,
          isBlurSolvedTubesEnabled: isBlurSolved,
          isInstantPouringEnabled: isInstantPouring,
          isHintHelperEnabled: isHintHelper,
          isUndoDecrementsMovesEnabled: isUndoDecrementsMoves,
          isSoundEffectsEnabled: isSoundEffects,
          tubeSize: tubeSize,
          customBackgroundImagePath: customBgPath,
        );

        if (savedMap['timeLeft'] != null) {
          _startTimer(savedMap['timeLeft'] as int);
        }
        return;
      }

      final level = _levelGenerator.generate(levelNumber);
      final isSuperHard = _progressRepository.isSuperHardModeEnabled();
      final isBlurSolved = _progressRepository.isBlurSolvedTubesEnabled();
      final isInstantPouring = _progressRepository.isInstantPouringEnabled();
      final isHintHelper = _progressRepository.isHintHelperEnabled();
      final isUndoDecrementsMoves = _progressRepository.isUndoDecrementsMovesEnabled();
      final isSoundEffects = _progressRepository.isSoundEffectsEnabled();
      final tubeSize = _progressRepository.getTubeSize();
      final customBgPath = _progressRepository.getCustomBackgroundImagePath();
      debugPrint('LOAD LEVEL: isSuperHard = $isSuperHard');
      state = GameViewModelState(
        level: level,
        isSuperHardModeEnabled: isSuperHard,
        isBlurSolvedTubesEnabled: isBlurSolved,
        isInstantPouringEnabled: isInstantPouring,
        isHintHelperEnabled: isHintHelper,
        isUndoDecrementsMovesEnabled: isUndoDecrementsMoves,
        isSoundEffectsEnabled: isSoundEffects,
        tubeSize: tubeSize,
        customBackgroundImagePath: customBgPath,
      );

      _progressRepository.clearActiveLevelState();

      if (_shouldHaveTimer(isRandom: false, levelNumber: levelNumber, difficulty: '')) {
        _startTimer(_calculateTimerDuration(level.colorCount));
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load level: $e');
    }
  }

  Future<void> loadRandomLevel(
    String difficulty, {
    int? colorCount,
    int? capacity,
    int? seed,
  }) async {
    _timer?.cancel();
    _invalidateHintRequest(clearCache: true);
    final int levelSeed = seed ?? DateTime.now().millisecondsSinceEpoch;
    final isSuperHard = _progressRepository.isSuperHardModeEnabled();
    final isBlurSolved = _progressRepository.isBlurSolvedTubesEnabled();
    final isInstantPouring = _progressRepository.isInstantPouringEnabled();
    final isHintHelper = _progressRepository.isHintHelperEnabled();
    final isUndoDecrementsMoves = _progressRepository.isUndoDecrementsMovesEnabled();
    final isSoundEffects = _progressRepository.isSoundEffectsEnabled();
    final tubeSize = _progressRepository.getTubeSize();
    final customBgPath = _progressRepository.getCustomBackgroundImagePath();
    state = GameViewModelState(
      isLoading: true,
      isRandomMode: true,
      randomDifficulty: difficulty,
      randomSeed: levelSeed,
      randomColorCount: colorCount,
      randomCapacity: capacity,
      isSuperHardModeEnabled: isSuperHard,
      isBlurSolvedTubesEnabled: isBlurSolved,
      isInstantPouringEnabled: isInstantPouring,
      isHintHelperEnabled: isHintHelper,
      isUndoDecrementsMovesEnabled: isUndoDecrementsMoves,
      isSoundEffectsEnabled: isSoundEffects,
      tubeSize: tubeSize,
      customBackgroundImagePath: customBgPath,
    );

    try {
      final savedMap = _progressRepository.getSavedLevelState();
      final savedColorCount = savedMap?['randomColorCount'] as int?;
      final savedCapacity = savedMap?['randomCapacity'] as int?;
      if (savedMap != null &&
          savedMap['isRandomMode'] == true &&
          savedMap['randomDifficulty'] == difficulty &&
          savedColorCount == colorCount &&
          savedCapacity == capacity &&
          (seed == null || savedMap['randomSeed'] == seed)) {
        final savedTubes = (savedMap['tubes'] as List).map((t) {
          final tMap = Map<dynamic, dynamic>.from(t as Map);
          return Tube(
            colors: (tMap['colors'] as List).map((c) => Color(c as int)).toList(),
            capacity: tMap['capacity'] as int,
          );
        }).toList();

        final savedHistory = (savedMap['moveHistory'] as List).map((h) {
          final hMap = Map<dynamic, dynamic>.from(h as Map);
          final tubes = (hMap['tubes'] as List).map((t) {
            final tMap = Map<dynamic, dynamic>.from(t as Map);
            return Tube(
              colors: (tMap['colors'] as List).map((c) => Color(c as int)).toList(),
              capacity: tMap['capacity'] as int,
            );
          }).toList();
          return MoveSnapshot(
            tubes: tubes,
            moveCount: hMap['moveCount'] as int,
          );
        }).toList();

        final level = GameLevel(
          levelNumber: savedMap['levelNumber'] as int? ?? -1,
          tubes: savedTubes,
          optimalMoves: savedMap['optimalMoves'] as int? ?? 10,
        );

        state = GameViewModelState(
          level: level,
          isRandomMode: true,
          randomDifficulty: difficulty,
          randomSeed: savedMap['randomSeed'] as int?,
          randomColorCount: savedColorCount,
          randomCapacity: savedCapacity,
          moveCount: savedMap['moveCount'] as int,
          moveHistory: savedHistory,
          isSuperHardModeEnabled: isSuperHard,
          isBlurSolvedTubesEnabled: isBlurSolved,
          isInstantPouringEnabled: isInstantPouring,
          isHintHelperEnabled: isHintHelper,
          isUndoDecrementsMovesEnabled: isUndoDecrementsMoves,
          isSoundEffectsEnabled: isSoundEffects,
          tubeSize: tubeSize,
          customBackgroundImagePath: customBgPath,
        );

        if (savedMap['timeLeft'] != null) {
          _startTimer(savedMap['timeLeft'] as int);
        }
        return;
      }

      int finalColorCount = colorCount ?? 3;
      int finalCapacity = capacity ?? 4;
      if (colorCount == null && capacity == null) {
        if (difficulty == 'Medium') {
          finalColorCount = 6;
          finalCapacity = 4;
        } else if (difficulty == 'Hard') {
          finalColorCount = 9;
          finalCapacity = 5;
        } else if (difficulty == 'Super Hard') {
          finalColorCount = 12;
          finalCapacity = 5;
        } else if (difficulty == 'Super Duper Hard') {
          finalColorCount = 16;
          finalCapacity = 6;
        }
      } else {
        if (colorCount == null) {
          if (difficulty == 'Easy') finalColorCount = 3;
          else if (difficulty == 'Medium') finalColorCount = 6;
          else if (difficulty == 'Hard') finalColorCount = 9;
          else if (difficulty == 'Super Hard') finalColorCount = 12;
          else if (difficulty == 'Super Duper Hard') finalColorCount = 16;
        }
        if (capacity == null) {
          if (difficulty == 'Easy') finalCapacity = 4;
          else if (difficulty == 'Medium') finalCapacity = 4;
          else if (difficulty == 'Hard') finalCapacity = 5;
          else if (difficulty == 'Super Hard') finalCapacity = 5;
          else if (difficulty == 'Super Duper Hard') finalCapacity = 6;
        }
      }

      final level = _levelGenerator.generateRandom(
        colorCount: finalColorCount,
        seed: levelSeed,
        capacity: finalCapacity,
      );

      state = state.copyWith(
        level: level,
        isLoading: false,
        randomColorCount: finalColorCount,
        randomCapacity: finalCapacity,
      );

      _progressRepository.clearActiveLevelState();

      if (_shouldHaveTimer(isRandom: true, levelNumber: -1, difficulty: difficulty)) {
        _startTimer(_calculateTimerDuration(level.colorCount));
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load random level: $e',
      );
    }
  }

  bool isValidPour(int fromIndex, int toIndex) {
    if (state.level == null) return false;
    if (fromIndex == toIndex) return false;
    if (fromIndex < 0 || fromIndex >= state.level!.tubes.length) return false;
    if (toIndex < 0 || toIndex >= state.level!.tubes.length) return false;

    final fromTube = state.level!.tubes[fromIndex];
    final toTube = state.level!.tubes[toIndex];

    if (fromTube.isEmpty || toTube.isFull) return false;

    final colorToMove = fromTube.topColor!;
    return toTube.canReceive(colorToMove);
  }

  void selectTube(int index) {
    if (state.isComplete || state.isTimeOut || state.level == null || state.pouringFromIndex != null) return;
    if (index < 0 || index >= state.level!.tubes.length) return;

    if (state.hintFromIndex != null || state.hintToIndex != null || state.hintMessage != null) {
      state = state.copyWith(
        hintFromIndex: () => null,
        hintToIndex: () => null,
        hintMessage: () => null,
      );
    }

    if (state.selectedTubeIndex == null) {
      if (!state.level!.tubes[index].isEmpty) {
        HapticFeedback.lightImpact();
        state = state.copyWith(selectedTubeIndex: () => index);
      }
    } else {
      if (state.selectedTubeIndex == index) {
        HapticFeedback.lightImpact();
        state = state.copyWith(selectedTubeIndex: () => null);
      } else {
        if (isValidPour(state.selectedTubeIndex!, index)) {
          _pourWater(state.selectedTubeIndex!, index);
        } else {
          // If tap on another non-empty tube and we can't pour there, select that one instead
          if (!state.level!.tubes[index].isEmpty) {
            HapticFeedback.lightImpact();
            state = state.copyWith(selectedTubeIndex: () => index);
          } else {
            HapticFeedback.lightImpact();
            state = state.copyWith(selectedTubeIndex: () => null);
          }
        }
      }
    }
  }

  Future<void> _pourWater(int fromIndex, int toIndex) async {
    if (state.level == null) return;
    _invalidateHintRequest();
    HapticFeedback.mediumImpact();
    state = state.copyWith(
      pouringFromIndex: () => fromIndex,
      pouringToIndex: () => toIndex,
    );
    if (state.isInstantPouringEnabled) {
      await completePendingPour();
    }
  }

  Future<void> completePendingPour() async {
    if (state.pouringFromIndex == null || state.pouringToIndex == null || state.level == null) return;
    final fromIndex = state.pouringFromIndex!;
    final toIndex = state.pouringToIndex!;

    final fromTube = state.level!.tubes[fromIndex];
    final toTube = state.level!.tubes[toIndex];
    final colorToMove = fromTube.topColor!;

    int countToMove = 0;
    for (int i = fromTube.colors.length - 1; i >= 0; i--) {
      if (fromTube.colors[i] == colorToMove) {
        countToMove++;
      } else {
        break;
      }
    }

    final availableSpace = toTube.capacity - toTube.colors.length;
    final pourCount = countToMove.clamp(0, availableSpace);

    if (pourCount == 0) {
      state = state.copyWith(
        selectedTubeIndex: () => null,
        pouringFromIndex: () => null,
        pouringToIndex: () => null,
      );
      return;
    }

    final snapshot = MoveSnapshot(
      tubes: state.level!.tubes.map((t) => Tube(colors: List<Color>.from(t.colors), capacity: t.capacity)).toList(),
      moveCount: state.moveCount,
    );

    final newFromColors = List<Color>.from(fromTube.colors)
      ..removeRange(fromTube.colors.length - pourCount, fromTube.colors.length);
    final newToColors = List<Color>.from(toTube.colors)
      ..addAll(List.filled(pourCount, colorToMove));

    final newTubes = List<Tube>.from(state.level!.tubes);
    newTubes[fromIndex] = fromTube.copyWith(colors: newFromColors);
    newTubes[toIndex] = toTube.copyWith(colors: newToColors);

    final newLevel = state.level!.copyWith(tubes: newTubes);
    final isComplete = newLevel.isComplete;

      if (isComplete) {
        _timer?.cancel();
        _cachedSolution = null;
        _cachedSolutionKey = null;
        HapticFeedback.heavyImpact();
      }

      final previousKey = _cachedSolutionKey;
      if (_cachedSolution != null && _cachedSolution!.isNotEmpty && previousKey == _stateKey(state.level!.tubes)) {
        final expectedMove = _cachedSolution!.first;
        if (expectedMove.fromIndex == fromIndex && expectedMove.toIndex == toIndex) {
          _cachedSolution!.removeAt(0);
          _cachedSolutionKey = _stateKey(newTubes);
        } else {
          _cachedSolution = null;
          _cachedSolutionKey = null;
        }
      }

      state = state.copyWith(
        level: newLevel,
        moveCount: state.moveCount + 1,
        selectedTubeIndex: () => null,
        pouringFromIndex: () => null,
        pouringToIndex: () => null,
        isComplete: isComplete,
        moveHistory: [...state.moveHistory, snapshot],
      );

      _saveCurrentState();

      if (isComplete) {
        await completeLevel();
      }
    }

    Future<void> completeLevel() async {
      if (state.level == null || !state.isComplete || state.isProgressSaved) return;
      state = state.copyWith(isProgressSaved: true);
      _progressRepository.clearActiveLevelState();
      final filledStars = state.level!.calculateStars(state.moveCount);
      await _progressRepository.saveLevelStars(state.level!.levelNumber, filledStars);
      if (state.isRandomMode) {
        await _progressRepository.addRandomLevelMoves(state.moveCount);
      } else {
        await _progressRepository.completeLevel(state.level!.levelNumber, state.moveCount);
      }
    }

    void resetLevel() {
      _invalidateHintRequest(clearCache: true);
      _progressRepository.clearActiveLevelState();
      if (state.level != null) {
        if (state.isRandomMode) {
          loadRandomLevel(
            state.randomDifficulty ?? 'Easy',
            colorCount: state.randomColorCount,
            capacity: state.randomCapacity,
            seed: state.randomSeed,
          );
        } else {
          loadLevel(state.level!.levelNumber);
        }
      }
    }

    void undoMove() {
      if (!state.canUndo || state.level == null) return;

      _invalidateHintRequest(clearCache: true);
      HapticFeedback.lightImpact();

      final snapshot = state.moveHistory.last;
      final newHistory = List<MoveSnapshot>.from(state.moveHistory)..removeLast();

      state = state.copyWith(
        level: state.level!.copyWith(tubes: snapshot.tubes),
        moveCount: state.isUndoDecrementsMovesEnabled
            ? (state.moveCount > 0 ? state.moveCount - 1 : 0)
            : state.moveCount,
        selectedTubeIndex: () => null,
        isComplete: false,
        moveHistory: newHistory,
        hintFromIndex: () => null,
        hintToIndex: () => null,
      );

    _saveCurrentState();
  }

  void _saveCurrentState() {
    if (state.level == null || state.isComplete) {
      _progressRepository.clearActiveLevelState();
      return;
    }
    final level = state.level!;
    final stateMap = <String, dynamic>{
      'levelNumber': level.levelNumber,
      'isRandomMode': state.isRandomMode,
      'randomDifficulty': state.randomDifficulty,
      'randomSeed': state.randomSeed,
      'randomColorCount': state.randomColorCount,
      'randomCapacity': state.randomCapacity,
      'moveCount': state.moveCount,
      'timeLeft': state.timeLeft,
      'optimalMoves': level.optimalMoves,
      'tubes': level.tubes.map((t) => {
        'colors': t.colors.map((c) => c.value).toList(),
        'capacity': t.capacity,
      }).toList(),
      'moveHistory': state.moveHistory.map((s) => {
        'moveCount': s.moveCount,
        'tubes': s.tubes.map((t) => {
          'colors': t.colors.map((c) => c.value).toList(),
          'capacity': t.capacity,
        }).toList(),
      }).toList(),
    };
    _progressRepository.saveActiveLevelState(stateMap);
  }

  List<WaterSortMove>? _cachedSolution;
  String? _cachedSolutionKey;

  String _stateKey(List<Tube> tubes) => tubes
      .map((tube) => '${tube.capacity}:${tube.colors.map((color) => color.toARGB32()).join(',')}')
      .join('|');

  Future<bool> showHint() async {
    if (!state.canShowHint) return false;
    final level = state.level!;
    final currentKey = _stateKey(level.tubes);

    if (_cachedSolutionKey == currentKey && _cachedSolution != null) {
      return await _applyCachedHint(currentKey);
    }

    final requestVersion = ++_hintRequestVersion;
    final snapshot = level.tubes
        .map((tube) => Tube(colors: List<Color>.from(tube.colors), capacity: tube.capacity))
        .toList();
    state = state.copyWith(
      isSolvingHint: true,
      hintMessage: () => null,
      hintFromIndex: () => null,
      hintToIndex: () => null,
    );

    late final LevelSolveResult result;
    try {
      result = await _hintRunner(snapshot);
    } catch (error) {
      if (mounted && requestVersion == _hintRequestVersion) {
        state = state.copyWith(
          isSolvingHint: false,
          hintMessage: () => 'Unable to calculate a hint. Try again.',
        );
      }
      return false;
    }

    if (!mounted || requestVersion != _hintRequestVersion) return false;
    if (state.level == null || _stateKey(state.level!.tubes) != currentKey || state.isComplete || state.isTimeOut) {
      state = state.copyWith(isSolvingHint: false);
      return false;
    }

    state = state.copyWith(isSolvingHint: false);
    if (result.status == LevelSolveStatus.found) {
      _cachedSolution = List<WaterSortMove>.from(result.moves);
      _cachedSolutionKey = currentKey;
      return await _applyCachedHint(currentKey);
    }
    _cachedSolution = null;
    _cachedSolutionKey = null;
    state = state.copyWith(
      hintMessage: () => result.status == LevelSolveStatus.limitReached
          ? 'Search limit reached. Try undoing a move.'
          : 'Could not find a solution. Undo a move or restart.',
    );
    return false;
  }

  Future<bool> _applyCachedHint(String currentKey) async {
    if (!mounted || _cachedSolutionKey != currentKey || _cachedSolution == null || _cachedSolution!.isEmpty) {
      return false;
    }
    final nextMove = _cachedSolution!.first;
    if (!isValidPour(nextMove.fromIndex, nextMove.toIndex)) {
      _cachedSolution = null;
      _cachedSolutionKey = null;
      return false;
    }
    state = state.copyWith(
      selectedTubeIndex: () => null,
      hintFromIndex: () => null,
      hintToIndex: () => null,
      hintMessage: () => null,
    );
    await _pourWater(nextMove.fromIndex, nextMove.toIndex);
    return true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _invalidateHintRequest(clearCache: true);
    super.dispose();
  }
}
