# Water Sort

## Solver fork

This fork adds an always-visible **HINT** button beside the move controls.
Tap it to calculate a solution offline and automatically perform exactly the
next legal pour. The normal pour animation, move count, history, undo, and
completion flow are preserved. Each tap performs one move.

The search runs in a background isolate. Each automatically executed step reuses
the remaining steps; changing the board, undoing, restarting, or loading another
level invalidates stale results. A search has a four-second, 150,000-state and
384-move budget. Reaching a budget is reported separately from an exhausted
search. Solutions are valid paths, and are not guaranteed to be the shortest.

中文：点击底部右侧灯泡按钮，离线计算并自动执行恰好下一步倒水。
保留原有倒水动画、步数、撤销和完成流程，不显示额外编号或提示高亮，
不会一次自动通关。复杂局面可能达到搜索上限；此时可撤销或重开。

### Build and verify

Requires Flutter 3.44 or later and Dart 3.12.2 or later. Run:

```sh
flutter pub get
flutter test --exclude-tags benchmark
flutter test --tags benchmark --reporter expanded
flutter build apk --release
```

The **Solver checks and APK** GitHub Actions workflow runs analysis, regression
tests, timing samples, and an APK build. Its artifact contains an installable APK
and timing logs. Timing samples measure solver CPU time separately from puzzle
generation; they are not a guarantee for every phone or puzzle.

The fork uses the Android app ID `com.sidhant.watersort.solver` and name
**Water Sort Solver**, so it can coexist with the original game. Without a
configured release keystore, local and CI APKs use the development signing key.
The original GPL v3 license remains in force.

A relaxing and addictive color-sorting puzzle game built with Flutter.

---

[![AI-DECLARATION: pair](https://img.shields.io/badge/䷼%20AI--DECLARATION-pair-ffedd5?labelColor=ffedd5)](AI-DECLARATION.md)

---

| Google Play | F-Droid |
| :---: | :---: |
| <a href="https://play.google.com/store/apps/details?id=com.sidhant.watersort"><img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Get it on Google Play" height="40" /></a> | <a href="https://f-droid.org/packages/com.sidhant.watersort"><img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png" alt="Get it on F-Droid" height="60" /></a> |

---

<a href="https://ko-fi.com/M4M01C1R6J" target="_blank">
  <img src="https://storage.ko-fi.com/cdn/kofi2.png?v=6" alt="Buy Me a Coffee at ko-fi.com" height="36" />
</a>

## About

Sort the colored water in the tubes until each tube contains only one color. Simple to learn, challenging to master.

## Features

- **Infinite Levels** — Endless procedurally generated puzzles. No level cap, no waiting, no energy system. Play as long as you want.
- **100% Offline** — Works entirely offline. No internet required, no data collected.
- **Zero Tracking** — No analytics, no trackers, no fingerprints. Your gameplay stays on your device.
- **Ad-Free** — No banner ads, no interstitials, no rewarded videos. Just pure gameplay.
- **Privacy First** — No permissions required beyond basic storage. No network access. Your data never leaves your phone.
- **Clean UI** — Minimalist design with smooth animations and a relaxing color palette.

---

## Themes & Custom Skins

Water Sort includes a theme selection system with custom skins. If you use it , support by giving a star to repo.

*   **Unlock Code**: `THANKYOU` (Enter this code to unlock all themes & custom skins instantly).

---


## License

GPL v3
