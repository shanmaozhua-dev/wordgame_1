# 勇者试炼 Prototype

Godot 4.7 prototype for rebuilding the 《文字游戏》第三章“添譜來堂 / 拳頭”勇者试炼 segment.

This repository is a clean recreation project. It does not copy the unpacked original project; local source/video references are only used for analysis.

## Requirements

- Godot 4.7
- Local tested executable: `E:\Godot\Godot_v4.7-stable_win64_console.exe`

## Run

Open this folder in Godot 4.7 and run `Main.tscn`. The default scene loads the 勇者试炼拳头 test map.

Controls:

- Arrow keys: move the player word `我`
- Space: interact with the word in front
- Backspace: delete a deletable word in front
- Tab: split a splittable word in front
- Alt + arrow key: pull a pushable word
- F5: autoplay the demo route
- F9: toggle runtime grid editor

Pulling rule: while Alt is held, the player may only move away from the pulled word. For example, if `我` is above the word, only Alt + Up is valid. Alt + Left, Alt + Right, or Alt + Down are rejected until Alt is released.

Merging rule: configured word parts merge automatically when the player pushes one part into the other part. For example, pushing `又` into `戈` produces `戏`.

Sentence recognition rule: recognition captions such as `已识别` are spawned as map word entities. They have collision and can later receive interaction rules.

Prompt rule: interaction prompts such as `手表可以查看人类世界的时间` are also spawned as persistent map word entities. They do not auto-disappear, have collision by default, and repeated triggering reuses the same prompt entity instead of spawning duplicates.

Runtime map editor:

- F9 enters or exits the 32 by 18 grid editor.
- Left click selects a cell; drag from outside the current selection to create a rectangular selection.
- Drag from inside the current selection to move all selected words to a new position; destination cells are overwritten like a spreadsheet.
- Type one Chinese character to fill the whole selection with that word.
- Backspace/Delete clears the whole selection; arrow keys move the selection.
- Alt+P, Alt+D, and Alt+S toggle pushable, deletable, and solid flags for every word in the selection.
- Ctrl+S saves to `res://levels/hero_trial_fist_edit.json`; Ctrl+R reloads that file.
- F10 hides or shows the grid while staying in edit mode.
- Edited cells are first stored in the running `GridWorld`; the editor status shows `未保存` after a change. After Ctrl+S, the JSON is persisted and loaded automatically on the next run.

## Test

Run from this project folder:

```powershell
.\tools\run_all_tests.ps1
```

The all-in-one script imports resources, runs gameplay/resource/level tests, starts the main scene, opens a real Godot window, captures a screenshot, and checks that the screen is not blank.

Individual checks:

```powershell
E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --path "E:\wordgame copy\勇者试炼" -s res://tests/test_hero_trial_fist.gd
E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --path "E:\wordgame copy\勇者试炼" -s res://tests/test_gameplay_core.gd
E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --path "E:\wordgame copy\勇者试炼" -s res://tests/test_precision_movement.gd
E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --path "E:\wordgame copy\勇者试炼" -s res://tests/test_visual_resources.gd
powershell -ExecutionPolicy Bypass -File "E:\wordgame copy\勇者试炼\tools\capture_visual_smoke.ps1"
```

## Project Layout

- `scripts/grid_world.gd`: core grid rules, collision, push/pull/delete/split/merge/sentence recognition, sentence effects
- `scripts/word_entity.gd`: data object for every word entity
- `scripts/level_loader.gd`: AI-friendly text-map data, including `build_hero_trial_fist_level()`
- `scripts/page_camera.gd`: page-based camera offset
- `scripts/demo_runner.gd`: autoplay demo route
- `tests/test_gameplay_core.gd`: gameplay regression tests
- `tests/test_hero_trial_fist.gd`: 勇者试炼拳头关卡 regression tests
- `tests/test_map_editor_io.gd`: runtime editor JSON round-trip tests
- `tests/test_map_editor_ops.gd`: bulk grid editor operation tests
- `tools/run_all_tests.ps1`: one-command automated verification
- `tools/capture_visual_smoke.ps1`: launches Godot, captures a real screenshot, and checks visible text pixels
- `docs/交接文档.md`: handoff notes for the next developers
- `docs/测试复用指南.md`: how to reuse the test framework for new screenshot-based levels
- `Fonts/Zpix.ttf`: original-style pixel font used by the manual test scene

## GitHub Notes

The repository should track source files, scenes, docs, tests, `.import` metadata files, and `.uid` files. It should not track `.godot/`, exported builds, logs, screenshots, or unpacked original game files.

Before pushing a public repository, confirm the font license for `Fonts/Zpix.ttf` or replace it with a clearly redistributable CJK pixel font.

## Current Scope

Implemented for this pass:

- Screen metric fixed from the original reference screenshot: one page is `32 x 18` text cells.
- The current playable scene uses a 24px render cell so the full 32 x 18 page fits the automated/manual test window without text overlap.
- `Fonts/Zpix.tres` no longer forces `fixed_size = 54`; labels can scale to the active cell size.
- First playable map for the 勇者试炼拳头 segment.
- Initial key words from source: `贏`, `不`, `二`, `讚`, `一`, `零`, `劍`, `勇`. The source also has `好`, but it is hidden behind `ch3_生命線敘述出現` and is not spawned in the initial layout.
- Upper narration and lower hand-gesture sentence as collision map text.
- Initial visible palm walls are locked against the source `零的手勢`, `生命線`, and `拇指下收` `big_text` coordinates.
- Recognition for `巨大手掌，是好的手勢`, `巨大手掌，是二的手勢`, `巨大手掌，是讚的手勢`, `巨大手掌，是贏的手勢`.
- Recognition for deleting `不` to form `會輕易放開`, which sets `hero_trial_complete`. No invented tail text is spawned by the prototype.

Known gaps: full original animations, conditional text events, all failure branches, gesture-state palm variants, and final transition scene need more source extraction plus screenshots/video notes before 1:1 recreation.
