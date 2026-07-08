from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / "tools"
OUT = ROOT / "test-output" / "map-review"


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
    print("map review tools passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
