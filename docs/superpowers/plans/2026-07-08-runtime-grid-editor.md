# Runtime Grid Editor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a minimal in-game 32x18 grid editor so the user can click cells, type Chinese characters, and save/load a JSON map.

**Architecture:** Keep gameplay truth in `GridWorld`. Add `MapEditorIO` as a small serialization boundary between `GridWorld` and `levels/hero_trial_fist_edit.json`; add edit-mode rendering and input to `main.gd`.

**Tech Stack:** Godot 4.7 GDScript, JSON via `FileAccess` and `JSON`, existing `GridWorld`/`WordEntity` classes.

---

### Task 1: Map Editor Data Round Trip

**Files:**
- Create: `scripts/map_editor_io.gd`
- Create: `tests/test_map_editor_io.gd`
- Modify: `tools/run_all_tests.ps1`

- [x] **Step 1: Write failing test**

Create `tests/test_map_editor_io.gd` that preloads `MapEditorIO`, exports the current fist map, saves it to `user://map_editor_io_test.json`, loads it back, converts it to a `GridWorld` level, and asserts key cells survive.

- [x] **Step 2: Run test to verify it fails**

Run: `E:\Godot\Godot_v4.7-stable_win64_console.exe --headless --path "E:\wordgame copy\勇者试炼" -s res://tests/test_map_editor_io.gd`

Expected: failure because `res://scripts/map_editor_io.gd` does not exist.

- [x] **Step 3: Implement serializer**

Create `MapEditorIO` with `world_to_editor_data`, `editor_data_to_level`, `save_editor_data`, and `load_editor_data`.

- [x] **Step 4: Run test to verify it passes**

Run the same Godot test command. Expected: `map_editor_io tests passed`.

### Task 2: Runtime Editing UI

**Files:**
- Modify: `scripts/main.gd`
- Create: `levels/hero_trial_fist_edit.json`

- [x] **Step 1: Add edit-mode controls**

Add `F9` toggle, grid line drawing, selected-cell highlight, coordinate/status label, and a `LineEdit` for Chinese input.

- [x] **Step 2: Add map editing behavior**

Left click selects a cell, text input writes one cell, Backspace/Delete clears, arrows move selection, Alt+P/Alt+D/Alt+S toggle pushable/deletable/solid, Ctrl+S saves, Ctrl+R reloads, F10 hides/shows grid.

- [x] **Step 3: Verify manually and with smoke test**

Run `tools/run_all_tests.ps1`, then open Godot and try `F9` editing.

### Task 3: Documentation

**Files:**
- Modify: `README.md`
- Modify: `docs/测试复用指南.md`

- [x] **Step 1: Document controls and file format**

Add the editor controls and JSON path so teammates can use the tool without reading code.

- [x] **Step 2: Commit**

Commit all files with message `feat: add runtime grid map editor`.
