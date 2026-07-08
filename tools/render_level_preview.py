from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def load_font(size: int) -> ImageFont.ImageFont:
    font_path = Path(__file__).resolve().parents[1] / "Fonts" / "Zpix.ttf"
    if font_path.exists():
        return ImageFont.truetype(str(font_path), size)
    return ImageFont.load_default()


def render_level(level_path: Path, output_path: Path, cell_size: int | None = None, draw_grid: bool = False) -> None:
    data = json.loads(level_path.read_text(encoding="utf-8"))
    screen_size = data.get("screen_size", [32, 18])
    cols, rows = int(screen_size[0]), int(screen_size[1])
    cell = int(cell_size or data.get("cell_size", 24))
    image = Image.new("RGB", (cols * cell, rows * cell), (0, 0, 0))
    draw = ImageDraw.Draw(image)
    font = load_font(round(cell * 0.78))

    if draw_grid:
        for x in range(cols + 1):
            draw.line([(x * cell, 0), (x * cell, rows * cell)], fill=(20, 70, 110), width=1)
        for y in range(rows + 1):
            draw.line([(0, y * cell), (cols * cell, y * cell)], fill=(20, 70, 110), width=1)

    for cell_data in data.get("cells", []):
        text = str(cell_data.get("text", ""))
        if not text:
            continue
        x = int(cell_data.get("x", 0)) * cell
        y = int(cell_data.get("y", 0)) * cell
        color = (255, 242, 72) if bool(cell_data.get("highlighted", False)) else (238, 238, 238)
        bbox = draw.textbbox((0, 0), text, font=font)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        draw.text((x + (cell - tw) / 2, y + (cell - th) / 2 - bbox[1]), text, font=font, fill=color)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(output_path)


def main() -> int:
    parser = argparse.ArgumentParser(description="Render an editor JSON level to a PNG preview.")
    parser.add_argument("level_json")
    parser.add_argument("output")
    parser.add_argument("--cell-size", type=int, default=None)
    parser.add_argument("--grid", action="store_true")
    args = parser.parse_args()

    render_level(Path(args.level_json), Path(args.output), args.cell_size, args.grid)
    print(args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
