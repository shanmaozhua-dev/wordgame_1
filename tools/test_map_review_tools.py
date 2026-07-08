from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / "tools"
OUT = ROOT / "test-output" / "map-review"
DOCX_EXTRACT = ROOT / "test-output" / "docx-extract"

DOCX_BATCH = [
    ("image1.png", "scene_01", "hero_trial_fist_scene_01.json"),
    ("image2.png", "scene_02", "hero_trial_fist_scene_02.json"),
    ("image3.png", "life_line_without_good", "hero_trial_fist_state_life_line_without_good.json"),
    ("image4.png", "one_gesture", "hero_trial_fist_state_one_gesture.json"),
    ("image5.png", "good_gesture", "hero_trial_fist_state_good_gesture.json"),
    ("image6.png", "two_gesture", "hero_trial_fist_state_two_gesture.json"),
    ("image7.png", "win_gesture", "hero_trial_fist_state_win_gesture.json"),
    ("image8.png", "release_opened", "hero_trial_fist_state_release_opened.json"),
]


def run(*args: str) -> None:
    subprocess.run([sys.executable, *args], cwd=ROOT, check=True)


def assert_nonempty(path: Path) -> None:
    if not path.exists() or path.stat().st_size <= 0:
        raise AssertionError(f"missing or empty output: {path}")


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    level = ROOT / "levels" / "hero_trial_fist_scene_01.json"
    preview = OUT / "scene_01_preview.png"
    grid = OUT / "scene_01_grid_reference.png"
    compare = OUT / "scene_01_compare.png"

    run(str(TOOLS / "render_level_preview.py"), str(level), str(preview), "--grid")
    run(str(TOOLS / "make_grid_reference.py"), str(preview), str(grid))
    run(str(TOOLS / "compare_level_to_screenshot.py"), str(preview), str(level), str(compare))

    for path in [preview, grid, compare]:
        assert_nonempty(path)

    if (DOCX_EXTRACT / "image1.png").exists():
        for image_name, map_id, level_name in DOCX_BATCH:
            screenshot = DOCX_EXTRACT / image_name
            level_path = ROOT / "levels" / level_name
            if not screenshot.exists():
                raise AssertionError(f"missing batch screenshot: {screenshot}")
            grid_path = OUT / f"{map_id}_grid.png"
            preview_path = OUT / f"{map_id}_preview.png"
            compare_path = OUT / f"{map_id}_compare.png"
            run(str(TOOLS / "make_grid_reference.py"), str(screenshot), str(grid_path))
            run(str(TOOLS / "render_level_preview.py"), str(level_path), str(preview_path), "--grid")
            run(str(TOOLS / "compare_level_to_screenshot.py"), str(screenshot), str(level_path), str(compare_path))
            for path in [grid_path, preview_path, compare_path]:
                assert_nonempty(path)

    print("map review tools passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
