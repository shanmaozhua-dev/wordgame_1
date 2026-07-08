from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def load_font(size: int) -> ImageFont.ImageFont:
    font_path = Path(__file__).resolve().parents[1] / "Fonts" / "Zpix.ttf"
    if font_path.exists():
        return ImageFont.truetype(str(font_path), size)
    return ImageFont.load_default()


def main() -> int:
    parser = argparse.ArgumentParser(description="Overlay a 32x18 text grid on a screenshot.")
    parser.add_argument("screenshot")
    parser.add_argument("output")
    parser.add_argument("--cols", type=int, default=32)
    parser.add_argument("--rows", type=int, default=18)
    args = parser.parse_args()

    image = Image.open(args.screenshot).convert("RGBA")
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    width, height = image.size
    cell_w = width / args.cols
    cell_h = height / args.rows

    for x in range(args.cols + 1):
        px = round(x * cell_w)
        draw.line([(px, 0), (px, height)], fill=(30, 150, 255, 130), width=1)
    for y in range(args.rows + 1):
        py = round(y * cell_h)
        draw.line([(0, py), (width, py)], fill=(30, 150, 255, 130), width=1)

    font = load_font(max(10, round(min(cell_w, cell_h) * 0.36)))
    for x in range(args.cols):
        draw.text((round(x * cell_w) + 2, 1), str(x), font=font, fill=(255, 230, 80, 210))
    for y in range(args.rows):
        draw.text((2, round(y * cell_h) + 1), str(y), font=font, fill=(255, 230, 80, 210))

    result = Image.alpha_composite(image, overlay)
    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    result.convert("RGB").save(out)
    print(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
