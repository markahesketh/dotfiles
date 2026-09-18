#!/usr/bin/env python3
"""
Cover-crop a photo to an exact box aspect ratio so it can be placed with plain w/h
(in pptx or docx) with NO distortion — the renderer-proof alternative to pptxgenjs
`sizing:{type:"cover"}` (which stretches when top-level w/h is also set).

Usage:
    python crop_to_box.py SRC.jpg OUT.jpg WIDTH_IN HEIGHT_IN [PPI]
Example (a 7.73in x 7.5in cover panel):
    python crop_to_box.py hero.jpg cover_right.jpg 7.73 7.5
"""
import sys
from PIL import Image, ImageOps

def main():
    src, out, win, hin = sys.argv[1], sys.argv[2], float(sys.argv[3]), float(sys.argv[4])
    ppi = float(sys.argv[5]) if len(sys.argv) > 5 else 150.0
    w, h = int(round(win * ppi)), int(round(hin * ppi))
    im = ImageOps.fit(Image.open(src).convert("RGB"), (w, h), Image.LANCZOS, centering=(0.5, 0.5))
    im.save(out, "JPEG", quality=86)
    print(f"wrote {out} ({w}x{h}) for a {win}in x {hin}in box")

if __name__ == "__main__":
    main()
