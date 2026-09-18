#!/usr/bin/env python3
"""
lock_brand_elements.py — Lock the Dexory logo and copyright line on every slide.

Finds shapes by their defining characteristics (not by name, since pptxgenjs
doesn't forward the `name` option to the XML `name` attr):
  • Copyright text shape: contains the literal string "Dexory. All rights reserved"
  • Logo image: a <p:pic> whose x offset is ~548640 EMU (0.6") and y ~457200 EMU (0.5")
    OR whose descr attribute contains "wordmark"

Locking applied:
  • Text/shape  → <a:spLocks> with noSelect, noMove, noResize, noRot, noEditPoints,
                  noAdjustHandles, noChangeArrowheads, noChangeShapeType
  • Image/pic   → <a:picLocks> with noSelect, noMove, noResize, noRot, noChangeAspect

Usage:
    python lock_brand_elements.py input.pptx [output.pptx]

If output is omitted the file is modified in place.
"""
import re, shutil, sys, zipfile
from pathlib import Path

SP_LOCKS  = ('noSelect="1" noMove="1" noResize="1" noRot="1" '
             'noEditPoints="1" noAdjustHandles="1" '
             'noChangeArrowheads="1" noChangeShapeType="1"')
PIC_LOCKS = ('noSelect="1" noMove="1" noResize="1" '
             'noRot="1" noChangeAspect="1"')

SLIDE_RE  = re.compile(r'^ppt/slides/slide\d+\.xml$')
COPY_TEXT = "Dexory. All rights reserved"      # substring that identifies the copyright shape
LOGO_DESCR_RE = re.compile(r'wordmark', re.IGNORECASE)
# Logo x ≈ 0.6" = 548640 EMU (allow ±1 EMU for rounding)
LOGO_X_EMU = 548640

# ── XML helpers ─────────────────────────────────────────────────────────────

def _inject_sp_locks(cNvSpPr_tag: str) -> str:
    """Replace <p:cNvSpPr.../> or <p:cNvSpPr>...</p:cNvSpPr> with locked version."""
    # self-closing
    if cNvSpPr_tag.rstrip().endswith('/>'):
        return f'<p:cNvSpPr><a:spLocks {SP_LOCKS}/></p:cNvSpPr>'
    # already has children — inject before closing tag
    return re.sub(
        r'(</p:cNvSpPr>)',
        f'<a:spLocks {SP_LOCKS}/>' + r'\1',
        cNvSpPr_tag, count=1
    )

def _inject_pic_locks(cNvPicPr_tag: str) -> str:
    """Replace <p:cNvPicPr>...</p:cNvPicPr> with fully locked version."""
    # Replace any existing picLocks or inject fresh ones
    if 'a:picLocks' in cNvPicPr_tag:
        return re.sub(r'<a:picLocks[^/]*/>', f'<a:picLocks {PIC_LOCKS}/>', cNvPicPr_tag)
    return re.sub(
        r'(</p:cNvPicPr>)',
        f'<a:picLocks {PIC_LOCKS}/>' + r'\1',
        cNvPicPr_tag, count=1
    )

# ── Shape-block locators ─────────────────────────────────────────────────────

# Match a complete <p:sp>...</p:sp> block (non-greedy, dotall)
SP_BLOCK_RE  = re.compile(r'<p:sp>.*?</p:sp>', re.DOTALL)
# Match a complete <p:pic>...</p:pic> block
PIC_BLOCK_RE = re.compile(r'<p:pic>.*?</p:pic>', re.DOTALL)
# Match the cNvSpPr element (self-closing or with children)
CNV_SP_RE    = re.compile(r'<p:cNvSpPr(?:\s[^>]*)?>.*?</p:cNvSpPr>|<p:cNvSpPr(?:\s[^>]*)?/>', re.DOTALL)
# Match the cNvPicPr element
CNV_PIC_RE   = re.compile(r'<p:cNvPicPr(?:\s[^>]*)?>.*?</p:cNvPicPr>', re.DOTALL)
# Match the x offset inside an xfrm block
XFRM_X_RE    = re.compile(r'<a:off\s+x="(\d+)"')


def _is_copyright_shape(sp_block: str) -> bool:
    return COPY_TEXT in sp_block


def _is_logo_pic(pic_block: str) -> bool:
    # Check descr attr for "wordmark"
    if LOGO_DESCR_RE.search(pic_block):
        return True
    # Fall back to x-offset check (logo is at x≈0.6")
    m = XFRM_X_RE.search(pic_block)
    if m and abs(int(m.group(1)) - LOGO_X_EMU) <= 5000:  # ±5000 EMU tolerance
        return True
    return False


def lock_sp(block: str) -> str:
    """Lock a <p:sp> block."""
    cnv = CNV_SP_RE.search(block)
    if not cnv:
        return block
    locked = _inject_sp_locks(cnv.group())
    return block[:cnv.start()] + locked + block[cnv.end():]


def lock_pic(block: str) -> str:
    """Lock a <p:pic> block."""
    cnv = CNV_PIC_RE.search(block)
    if not cnv:
        return block
    locked = _inject_pic_locks(cnv.group())
    return block[:cnv.start()] + locked + block[cnv.end():]


def process_slide(xml_bytes: bytes) -> bytes:
    xml = xml_bytes.decode('utf-8')
    out = []
    pos = 0

    # Process all sp blocks
    for m in SP_BLOCK_RE.finditer(xml):
        out.append(xml[pos:m.start()])
        block = m.group()
        if _is_copyright_shape(block):
            block = lock_sp(block)
        out.append(block)
        pos = m.end()
    out.append(xml[pos:])
    xml = ''.join(out)

    # Process all pic blocks
    out = []
    pos = 0
    for m in PIC_BLOCK_RE.finditer(xml):
        out.append(xml[pos:m.start()])
        block = m.group()
        if _is_logo_pic(block):
            block = lock_pic(block)
        out.append(block)
        pos = m.end()
    out.append(xml[pos:])

    return ''.join(out).encode('utf-8')


def lock_pptx(src: Path, dst: Path):
    if src != dst:
        shutil.copy2(src, dst)

    with zipfile.ZipFile(dst, 'r') as zin:
        names = zin.namelist()
        files = {n: zin.read(n) for n in names}

    locked_count = 0
    for name in names:
        if SLIDE_RE.match(name):
            original = files[name]
            patched  = process_slide(original)
            if patched != original:
                locked_count += 1
            files[name] = patched

    dst.unlink()
    with zipfile.ZipFile(dst, 'w', zipfile.ZIP_DEFLATED) as zout:
        for name, data in files.items():
            zout.writestr(name, data)

    print(f"Locked brand elements on {locked_count} slide(s) → {dst}")


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    src = Path(sys.argv[1])
    dst = Path(sys.argv[2]) if len(sys.argv) > 2 else src
    lock_pptx(src, dst)
