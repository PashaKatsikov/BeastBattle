from pathlib import Path
import hashlib
from PIL import Image, ImageDraw, ImageFont, ImageFilter

SRC = Path(r"C:\Users\Paul\.cursor\projects\c-Dev-flutter-projects-BeastBattle\assets")
OUT = Path(r"C:\Dev\flutter_projects\BeastBattle\assets\shell")
OUT.mkdir(parents=True, exist_ok=True)

BOLD = Path(r"C:\Windows\Fonts\arialbd.ttf")
REG = Path(r"C:\Windows\Fonts\arial.ttf")


def wrap(draw, text, font, max_w):
    words = text.split()
    lines, cur = [], ""
    for word in words:
        trial = word if not cur else f"{cur} {word}"
        if draw.textlength(trial, font=font) <= max_w:
            cur = trial
        else:
            if cur:
                lines.append(cur)
            cur = word
    if cur:
        lines.append(cur)
    return lines


def paint(src_name, dest_name, headline, subtitle, portrait):
    img = Image.open(SRC / src_name).convert("RGBA")
    if portrait:
        img = img.resize((1080, 1920), Image.Resampling.LANCZOS)
        max_w = 920
        head_size, sub_size = 54, 32
        y = 860
    else:
        img = img.resize((1920, 1080), Image.Resampling.LANCZOS)
        max_w = 820
        head_size, sub_size = 42, 26
        y = 560
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    head_font = ImageFont.truetype(str(BOLD), head_size)
    sub_font = ImageFont.truetype(str(REG), sub_size)
    head_lines = wrap(draw, headline, head_font, max_w)
    sub_lines = wrap(draw, subtitle, sub_font, max_w)
    gap = 14
    line_gap = 8
    block_h = 0
    sizes = []
    for line in head_lines:
        box = draw.textbbox((0, 0), line, font=head_font)
        h = box[3] - box[1]
        sizes.append((line, head_font, h, True))
        block_h += h + line_gap
    block_h += gap
    for line in sub_lines:
        box = draw.textbbox((0, 0), line, font=sub_font)
        h = box[3] - box[1]
        sizes.append((line, sub_font, h, False))
        block_h += h + line_gap

    if portrait:
        x0 = (img.width - max_w) // 2
    else:
        x0 = 980
    pad = 28
    panel = Image.new("RGBA", img.size, (0, 0, 0, 0))
    pdraw = ImageDraw.Draw(panel)
    pdraw.rounded_rectangle(
        [x0 - pad, y - pad, x0 + max_w + pad, y + block_h + pad],
        radius=28,
        fill=(7, 2, 24, 150),
    )
    panel = panel.filter(ImageFilter.GaussianBlur(radius=1.2))
    img = Image.alpha_composite(img, panel)
    draw = ImageDraw.Draw(img)
    cursor = y
    for line, font, h, is_head in sizes:
        if not is_head and cursor == y:
            cursor += gap
        tw = draw.textlength(line, font=font)
        if portrait:
            x = (img.width - tw) / 2
        else:
            x = x0 + (max_w - tw) / 2
        draw.text((x, cursor), line, font=font, fill=(255, 255, 255, 255), stroke_width=2, stroke_fill=(7, 2, 24, 220))
        cursor += h + line_gap
        if is_head and line == head_lines[-1]:
            cursor += gap

    dest = OUT / dest_name
    img.convert("RGB").save(dest, "WEBP", quality=86, method=6)
    digest = hashlib.sha256(dest.read_bytes()).hexdigest()
    print(dest_name, dest.stat().st_size, digest)


paint(
    "bb_promo_tall.png",
    "promo_tall.webp",
    "ALLOW NOTIFICATIONS ABOUT BONUSES AND PROMOS",
    "Stay tuned for special offers and rewards",
    True,
)
paint(
    "bb_promo_wide.png",
    "promo_wide.webp",
    "ALLOW NOTIFICATIONS ABOUT BONUSES AND PROMOS",
    "Stay tuned for special offers and rewards",
    False,
)
paint(
    "bb_offline_tall.png",
    "offline_tall.webp",
    "NO INTERNET CONNECTION",
    "Check your connection and try again",
    True,
)
paint(
    "bb_offline_wide.png",
    "offline_wide.webp",
    "NO INTERNET CONNECTION",
    "Check your connection and try again",
    False,
)
