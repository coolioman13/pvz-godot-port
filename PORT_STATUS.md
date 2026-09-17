# Port status (Godot 4.7 port of the PvZ QE-Wide decomp)

Approach: faithful 1:1 translation of the decomp C++ (`C:\Users\nik\Music\PVZ-QEWide-Tweaks-main`) to GDScript,
snake_case names, same logic/constants. Minigames, survival and puzzle modes are out of scope for now
(their code paths may exist as stubs).

Tools:
- `python tools/port_coverage.py [Class...]` lists decomp methods with no snake_case GDScript counterpart
  (generic names like Draw/Update give false "covered" results for widgets).
- `godot --headless --path . -s tools/check_scripts.gd` compile-checks every script
  (`App` autoload errors in this mode are expected).
- `godot --headless --path . -s tools/verify_defs.gd` parses every compiled reanim/particle/trail.
- `godot --headless --path . res://tools/check_all.tscn` compile-checks every script with the App autoload active.
- `godot --headless --path . res://tools/smoke_test.tscn` drives App through every menu, dialog and screen
  (with a mouse sweep over each) plus a 1-1 intro; any `SCRIPT ERROR` in the log is a regression.
- `godot --path . res://tools/capture_screens.tscn -- <dir>` (windowed) saves PNGs of the menus/dialogs for visual checks.

Conventions:
- IDs (ZombieID, ReanimationID...) are object references; `freed` marks deleted objects;
  `BoardCore.try_get`, `Zombie.zv`, `Plant.rv` replace DataArrayTryToGet.
- Blocking `WaitForResult` / `LawnMessageBox` are coroutines: `await dialog.wait_for_result(true)`.
- Rendering is immediate mode through `Graphics` -> `RenderTarget` canvas-item segments.

Done: core (res, defs, reanim, particles, trails, attachments, fonts, strings, music, foley, languages),
widgets (incl. ListWidget, Widget::Layout, ShowFinger), board (core/update/input/draw), plant, projectile, coin,
seed bank/packet, grid items, mowers, zombie (all types + boss), app (LawnApp), cut scenes, challenge (adventure parts),
zen garden, save game, pool effect, achievements, typing checks.
Screens/dialogs: TitleScreen, GameSelector, QuickPlay, SeedChooserScreen, StoreScreen, AwardScreen, AlmanacDialog,
NewOptionsDialog (+ 4 advanced pages), CreditScreen (music video, synced to the song), MiniCreditsScreen, AchievementScreen,
ChallengeScreen, ChallengePagesDialog, UserDialog, NewUserDialog, ContinueDialog, CheatDialog, GameOverDialog.
All 87 scripts compile; the smoke test runs clean.

Intentionally skipped: ImitaterDialog (never created in the QE build; the seed chooser picks the imitater inline),
DRM/Discord/update checks, resource packs (none ship; the options page shows "no resource pack").

Todo: playtesting adventure 1-1 through 5-10 against the original (visual/timing diffs), minigames/survival/puzzle
gameplay (out of scope for now; their screens exist), Godot-native animation support alongside reanims for future content.
