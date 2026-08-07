#!/usr/bin/env python3
"""colorscheme.py — extract a palette from a wallpaper and render themed configs.

Usage:
    colorscheme.py <image>

Reads a palette out of the image, then substitutes tokens (e.g. @{bg}) in
templates under config/templates/ and writes the result to the corresponding
runtime config file (waybar, fuzzel, wlogout, alacritty). Tokens left in a
template that are not in the palette stay untouched.
"""
import os
import re
import sys
from pathlib import Path

try:
    from PIL import Image, ImageOps, ImageStat
except ImportError:
    sys.stderr.write("missing Pillow — add python3Packages.pillow to home.nix\n")
    sys.exit(1)

# ---- palette tokens we fill in -------------------------------------------
# Derived from the image: dark bg, light fg, a saturated accent, and a few
# semantic colors derived from the accent (kept in harmony with the image).
TOKENS = ("bg", "bg_alt", "surface", "fg", "muted", "accent",
          "red", "green", "yellow", "blue", "magenta", "cyan", "bg_t")

REPO = Path(os.environ.get("REPO_DIR", "")) or Path(__file__).resolve().parent.parent
TEMPLATES = REPO / "config" / "templates"

# output path per template, relative to repo (this is the live config file)
OUTPUTS = {
    "waybar.style.css":    REPO / "config" / "waybar" / "style.css",
    "fuzzel.ini":          REPO / "config" / "fuzzel" / "fuzzel.ini",
    "wlogout.style.css":   REPO / "config" / "wlogout" / "style.css",
    "alacritty.colors.toml": REPO / "config" / "alacritty" / "colors.toml",
    "mako":                REPO / "config" / "mako" / "config",
    "gtk.css":             REPO / "config" / "gtk-3.0" / "gtk.css",
}


def clamp(v: int) -> int:
    return max(0, min(255, int(round(v))))


def hex2(r: int, g: int, b: int, a: int | None = None) -> str:
    if a is None:
        return "#{:02x}{:02x}{:02x}".format(clamp(r), clamp(g), clamp(b))
    return "#{:02x}{:02x}{:02x}{:02x}".format(clamp(r), clamp(g), clamp(b), clamp(a))


def hex_dark(r, g, b):  # transparent dark variant of a color
    return hex2(r, g, b, int(0.85 * 255))


def luminance(rgb):
    r, g, b = rgb
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def saturate(rgb, factor):
    lum = luminance(rgb)
    return (clamp(lum + (c - lum) * factor) for c in rgb)


def extract(image_path: Path):
    img = Image.open(image_path).convert("RGB")
    img = ImageOps.exif_transpose(img)
    # small sample is enough for a palette
    img = img.copy()
    img.thumbnail((96, 96))

    # dominant colors via quantization (k-means-ish)
    small = img.quantize(colors=8, method=Image.MEDIANCUT).convert("RGB")
    stat = ImageStat.Stat(small)
    mean = tuple(int(x) for x in stat.mean)
    # brightest & darkest quantized colors by luminance
    buckets = [small.convert("RGB")]
    col = small.getcolors(maxcolors=1 << 24)
    col.sort(reverse=True)  # most frequent first
    top = [rgb for _, rgb in col[:5]]

    accent = tuple(saturate(top[0] if top else mean, 0.45))
    accent = (int(accent[0]), int(accent[1]), int(accent[2]))

    bg = tuple(min(mean[i], 30) for i in range(3))          # near-black
    bg_alt = tuple(min(mean[i] * 1.25, 46) for i in range(3))
    surface = tuple(min(mean[i] * 1.6, 66) for i in range(3))
    fg = tuple(max(220, mean[i] + 120) for i in range(3))   # near-white
    muted = tuple(int(fg[i] * 0.62) for i in range(3))

    red = (247, 118, 142)
    green = (158, 206, 106)
    yellow = (224, 175, 104)
    blue = tuple(accent)
    magenta = (187, 154, 247)
    cyan = (125, 207, 255)

    return {
        "bg": hex2(*bg),
        "bg_alt": hex2(*bg_alt),
        "surface": hex2(*surface),
        "fg": hex2(*fg),
        "muted": hex2(*muted),
        "accent": hex2(*accent),
        "red": hex2(*red),
        "green": hex2(*green),
        "yellow": hex2(*yellow),
        "blue": hex2(*blue),
        "magenta": hex2(*magenta),
        "cyan": hex2(*cyan),
        "bg_t": hex_dark(*bg),
    }


def render(text: str, palette: dict) -> str:
    return re.sub(r"@\{([a-z_]+)\}", lambda m: palette.get(m.group(1), m.group(0)), text)


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: colorscheme.py <image>")
    img = Path(sys.argv[1])
    if not img.exists():
        sys.exit(f"image not found: {img}")

    palette = extract(img)

    for tpl_name, out_path in OUTPUTS.items():
        tpl = TEMPLATES / tpl_name
        if not tpl.exists():
            continue
        rendered = render(tpl.read_text(), palette)
        out_path.write_text(rendered)
        print(f"rendered -> {out_path.relative_to(REPO)}")

        # GTK overlay applies to both GTK3 and GTK4:
        if tpl_name == "gtk.css":
            gtk4 = REPO / "config" / "gtk-4.0" / "gtk.css"
            gtk4.write_text(rendered)
            print(f"rendered -> {gtk4.relative_to(REPO)}")

    print("palette:")
    for k, v in palette.items():
        print(f"  {k}: {v}")


if __name__ == "__main__":
    main()
