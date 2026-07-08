from __future__ import annotations

import argparse
import zipfile
from pathlib import Path


IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".bmp", ".gif", ".webp"}


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract inline images from a docx into a review workspace.")
    parser.add_argument("docx")
    parser.add_argument("output_dir")
    args = parser.parse_args()

    docx = Path(args.docx)
    output_dir = Path(args.output_dir)
    if not docx.exists():
        raise FileNotFoundError(docx)

    output_dir.mkdir(parents=True, exist_ok=True)
    extracted = []
    with zipfile.ZipFile(docx) as archive:
        media_names = [
            name for name in archive.namelist()
            if name.startswith("word/media/") and Path(name).suffix.lower() in IMAGE_EXTENSIONS
        ]
        media_names.sort()
        for index, name in enumerate(media_names, start=1):
            suffix = Path(name).suffix.lower()
            output_path = output_dir / f"image{index}{suffix}"
            output_path.write_bytes(archive.read(name))
            extracted.append(output_path)

    for path in extracted:
        print(path)
    print(f"extracted {len(extracted)} image(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
