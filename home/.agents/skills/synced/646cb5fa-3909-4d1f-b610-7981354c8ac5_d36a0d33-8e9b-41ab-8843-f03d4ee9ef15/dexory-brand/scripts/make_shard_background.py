#!/usr/bin/env python3
"""
Generate an on-brand Dexory "shard pattern" background.

The shard pattern (navy base, translucent blue/navy parallelogram shards, a soft
blue glow) is Dexory's signature graphic device for presentation covers, section
dividers and closing slides. This produces a faithful *approximation* of it so
decks get a branded cover without hand-made art.

NOTE: the official brand guidelines ask that final, high-stakes customer-facing
shard artwork be produced/approved by the marketing team (marketing@dexory.com).
Use this generator freely for internal work and drafts; for flagship external
covers, prefer official shard art if available.

Usage:
    python make_shard_background.py OUT.png [--variant cover|divider|closing]
                                           [--size WIDTHxHEIGHT]
Defaults: --variant cover  --size 1920x1080  (16:9, maps to 13.33in x 7.5in)
"""
import argparse
import math
import random

from PIL import Image, ImageDraw, ImageFilter

NAVY = (11, 26, 72)        # #0B1A48
BLUE = (86, 49, 234)       # #5631EA
DARK_NAVY = (7, 16, 46)    # slightly deeper than navy for low shards


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def radial_glow(size, center, radius, color, max_alpha):
    """A soft radial glow (color fading to transparent) as an RGBA layer."""
    w, h = size
    glow = Image.new("RGBA", size, (0, 0, 0, 0))
    px = glow.load()
    cx, cy = center
    for y in range(h):
        for x in range(w):
            d = math.hypot(x - cx, y - cy) / radius
            if d >= 1:
                continue
            a = int(max_alpha * (1 - d) ** 2)
            px[x, y] = (color[0], color[1], color[2], a)
    return glow.filter(ImageFilter.GaussianBlur(size[0] * 0.02))


def parallelogram(cx, cy, w, h, skew):
    """Return 4 points of a leaning parallelogram (Dexory shard shape)."""
    return [
        (cx - w / 2 + skew, cy - h / 2),
        (cx + w / 2 + skew, cy - h / 2),
        (cx + w / 2 - skew, cy + h / 2),
        (cx - w / 2 - skew, cy + h / 2),
    ]


def build(variant, size):
    w, h = size
    img = Image.new("RGB", size, NAVY)

    # Base vertical gradient: dark navy top -> navy, for depth.
    base = Image.new("RGB", size)
    bp = base.load()
    for y in range(h):
        t = y / h
        row = lerp(DARK_NAVY, NAVY, min(1, t * 1.2))
        for x in range(w):
            bp[x, y] = row
    img = base

    rng = random.Random(42 if variant == "cover" else (7 if variant == "divider" else 21))

    # A bright blue glow gives the signature gradient. Placement per variant.
    if variant == "cover":
        glow = radial_glow(size, (w * 0.82, h * 0.18), w * 0.75, BLUE, 235)
    elif variant == "closing":
        glow = radial_glow(size, (w * 0.80, h * 0.22), w * 0.80, BLUE, 210)
    else:  # divider
        glow = radial_glow(size, (w * 0.90, h * 0.30), w * 0.65, BLUE, 170)
    img = Image.alpha_composite(img.convert("RGBA"), glow)

    shard = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(shard)

    if variant in ("cover", "closing"):
        # A few large, bold leaning shards — sophisticated, not busy.
        big = [
            (w * 0.30, h * 0.55, w * 0.55, h * 1.7, BLUE, 55),
            (w * 0.62, h * 0.40, w * 0.62, h * 1.9, BLUE, 40),
            (w * 0.18, h * 0.45, w * 0.30, h * 1.6, DARK_NAVY, 150),
            (w * 0.90, h * 0.75, w * 0.45, h * 1.6, DARK_NAVY, 120),
        ]
        for cx, cy, sw, sh, col, a in big:
            skew = sh * 0.18
            d.polygon(parallelogram(cx, cy, sw, sh, skew), fill=(col[0], col[1], col[2], a))
    else:
        # Divider: scattered smaller diamonds receding into the distance.
        rows = 5
        for r in range(rows):
            y = h * (0.12 + r * 0.19)
            depth = r / rows
            count = 4 + r
            for c in range(count):
                x = w * (c + 0.5) / count + rng.uniform(-w * 0.03, w * 0.03)
                sw = w * (0.11 - depth * 0.05)
                sh = sw * 0.72
                col = BLUE if rng.random() > 0.45 else DARK_NAVY
                a = int((30 + 70 * (1 - depth)) * (1.1 if col == BLUE else 1.4))
                a = min(a, 200)
                skew = sh * 0.55
                d.polygon(parallelogram(x, y, sw, sh, skew),
                          fill=(col[0], col[1], col[2], a))

    shard = shard.filter(ImageFilter.GaussianBlur(1.2))
    img = Image.alpha_composite(img, shard)
    return img.convert("RGB")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("--variant", default="cover", choices=["cover", "divider", "closing"])
    ap.add_argument("--size", default="1920x1080")
    args = ap.parse_args()
    w, h = (int(v) for v in args.size.lower().split("x"))
    build(args.variant, (w, h)).save(args.out, "PNG")
    print(f"wrote {args.out} ({args.variant}, {w}x{h})")


if __name__ == "__main__":
    main()
