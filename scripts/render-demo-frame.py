#!/usr/bin/env python3

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


BG = "#282A36"
FG = "#F8F8F2"
DIM = "#9AA5CE"
ACCENT = "#FFB86C"
GREEN = "#50FA7B"

FONT_PATH = "/System/Library/Fonts/Menlo.ttc"
FONT_SIZE = 20
LINE_HEIGHT = 28
LEFT_PAD = 24
TOP_PAD = 22
RIGHT_PAD = 24
BOTTOM_PAD = 22


def line_color(line: str) -> str:
    stripped = line.strip()
    if not stripped:
        return FG
    if stripped.startswith("worktree▶"):
        return GREEN
    if "selected" in stripped and "^p pull" in stripped:
        return ACCENT
    if stripped.startswith("□") or stripped.startswith("■"):
        return FG
    if stripped.startswith("Selection target") or stripped.endswith("worktrees selected"):
        return FG
    if stripped.startswith("Bulk actions target") or stripped.startswith("Ctrl-P pulls") or stripped.startswith("Enter, Ctrl-O"):
        return DIM
    if stripped.startswith("… and "):
        return DIM
    if stripped.startswith("/tmp/") or stripped.startswith("/private/tmp/") or stripped.startswith("/Users/"):
        return FG
    if stripped.startswith("───") or stripped.startswith("—"):
        return FG
    if stripped.startswith("~/") or stripped.startswith("/private/tmp"):
        return DIM
    return FG


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: render-demo-frame.py <input.txt> <output.png>")

    input_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])

    lines = input_path.read_text().splitlines()
    if not lines:
        lines = [""]

    font = ImageFont.truetype(FONT_PATH, FONT_SIZE)

    max_width = 0
    for line in lines:
        width = int(font.getlength(line))
        max_width = max(max_width, width)

    width = LEFT_PAD + max_width + RIGHT_PAD
    height = TOP_PAD + len(lines) * LINE_HEIGHT + BOTTOM_PAD

    image = Image.new("RGB", (width, height), BG)
    draw = ImageDraw.Draw(image)

    y = TOP_PAD
    for line in lines:
        draw.text((LEFT_PAD, y), line, font=font, fill=line_color(line))
        y += LINE_HEIGHT

    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(output_path)


if __name__ == "__main__":
    main()
