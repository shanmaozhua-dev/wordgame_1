from __future__ import annotations

import argparse
import tempfile
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

from render_level_preview import render_level


def main() -> int:
    parser = argparse.ArgumentParser(description="Create original/preview/diff review image for a level.")
    parser.add_argument("screenshot")
    parser.add_argument("level_json")
    parser.add_argument("output")
    args = parser.parse_args()

    screenshot = Image.open(args.screenshot).convert("RGB")
    with tempfile.TemporaryDirectory() as tmp:
        preview_path = Path(tmp) / "preview.png"
        cell_size = max(1, round(screenshot.size[0] / 32))
        render_level(Path(args.level_json), preview_path, cell_size=cell_size, draw_grid=True)
        preview = Image.open(preview_path).convert("RGB").resize(screenshot.size)

    diff = ImageChops.difference(screenshot, preview)
    diff = ImageChops.multiply(diff, Image.new("RGB", diff.size, (4, 4, 4)))
    overlay = Image.blend(screenshot, preview, 0.45)
    overlay = Image.blend(overlay, diff, 0.35)

    label_h = 28
    out = Image.new("RGB", (screenshot.width * 3, screenshot.height + label_h), (16, 16, 16))
    draw = ImageDraw.Draw(out)
    labels = ["original", "level preview", "overlay diff"]
    for i, (label, image) in enumerate(zip(labels, [screenshot, preview, overlay])):
        x = i * screenshot.width
        out.paste(image, (x, label_h))
        draw.text((x + 8, 7), label, fill=(240, 240, 240))

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    out.save(output)
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
