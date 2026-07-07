import argparse
import json
import re
import sys
from pathlib import Path


NODE_RE = re.compile(r'^\[node name="(?P<name>[^"]+)"')
NOW_POS_RE = re.compile(r"now_pos = Vector2\( (?P<x>-?\d+), (?P<y>-?\d+) \)")
BIG_TEXT_RE = re.compile(r'big_text = "(?P<text>.*)', re.DOTALL)


def parse_nodes(text: str) -> dict:
    nodes = {}
    current_name = None
    current_lines = []
    for line in text.splitlines():
        match = NODE_RE.match(line)
        if match:
            if current_name is not None:
                nodes[current_name] = "\n".join(current_lines)
            current_name = match.group("name")
            current_lines = [line]
        elif current_name is not None:
            current_lines.append(line)
    if current_name is not None:
        nodes[current_name] = "\n".join(current_lines)
    return nodes


def extract_quoted_multiline(block: str, key: str) -> str:
    marker = f'{key} = "'
    start = block.find(marker)
    if start == -1:
        return ""
    i = start + len(marker)
    result = []
    escaped = False
    while i < len(block):
        ch = block[i]
        if escaped:
            result.append(ch)
            escaped = False
        elif ch == "\\":
            escaped = True
        elif ch == '"':
            return "".join(result)
        else:
            result.append(ch)
        i += 1
    return "".join(result)


def text_cells(text: str, origin: tuple[int, int], blank_chars: set[str]) -> list[dict]:
    ox, oy = origin
    cells = []
    rows = text.splitlines()
    while rows and rows[0] == "":
        rows.pop(0)
    for y, row in enumerate(rows):
        for x, char in enumerate(row):
            if char in blank_chars:
                continue
            cells.append({"text": char, "x": ox + x, "y": oy + y})
    return cells


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="Extract grid coordinates from a Godot tscn big_text node.")
    parser.add_argument("tscn", type=Path)
    parser.add_argument("node_name")
    parser.add_argument("--blank", default="＿ _", help="Characters treated as empty cells.")
    parser.add_argument("--json", action="store_true", help="Print JSON instead of a text table.")
    args = parser.parse_args()

    source = args.tscn.read_text(encoding="utf-8")
    nodes = parse_nodes(source)
    if args.node_name not in nodes:
        raise SystemExit(f"node not found: {args.node_name}")
    block = nodes[args.node_name]

    now_pos = NOW_POS_RE.search(block)
    if not now_pos:
        raise SystemExit(f"node has no now_pos: {args.node_name}")
    origin = (int(now_pos.group("x")), int(now_pos.group("y")))

    big_text = extract_quoted_multiline(block, "big_text")
    if not big_text:
        raise SystemExit(f"node has no big_text: {args.node_name}")

    cells = text_cells(big_text, origin, set(args.blank))
    payload = {"node": args.node_name, "origin": {"x": origin[0], "y": origin[1]}, "cells": cells}
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print(f"{args.node_name} origin={origin}")
        for cell in cells:
            print(f"{cell['text']}\t{cell['x']}\t{cell['y']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
