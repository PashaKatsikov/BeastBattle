from pathlib import Path
import hashlib
from PIL import Image, ImageDraw, ImageFont

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


def wash(width, height):
    column = Image.new("RGB", (1, height))
    top = (28, 14, 62)
    bottom = (7, 2, 24)
    for y in range(height):
        t = y / (height - 1)
        column.putpixel((0, y), tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return column.resize((width, height), Image.Resampling.BILINEAR).convert("RGBA")


def paint(src_name, dest_name, headline, subtitle, portrait, wide_scale=1.0, wide_lift=0, wide_anchor=0.5, wide_max=None):
    if portrait:
        img = wash(1080, 1920)
        max_w = 920
        head_size, sub_size = 54, 32
        y = 860
        anchor = img.width / 2
    else:
        img = wash(1920, 1080)
        max_w = wide_max if wide_max is not None else int(round(820 * wide_scale))
        head_size = int(round(42 * wide_scale))
        sub_size = int(round(26 * wide_scale))
        y = 560 - wide_lift
        anchor = img.width * wide_anchor
    draw = ImageDraw.Draw(img)
    head_font = ImageFont.truetype(str(BOLD), head_size)
    sub_font = ImageFont.truetype(str(REG), sub_size)
    head_lines = wrap(draw, headline, head_font, max_w)
    sub_lines = wrap(draw, subtitle, sub_font, max_w)
    gap = 14
    line_gap = 8
    sizes = []
    for line in head_lines:
        box = draw.textbbox((0, 0), line, font=head_font)
        h = box[3] - box[1]
        sizes.append((line, head_font, h, True))
    for line in sub_lines:
        box = draw.textbbox((0, 0), line, font=sub_font)
        h = box[3] - box[1]
        sizes.append((line, sub_font, h, False))

    cursor = y
    for line, font, h, is_head in sizes:
        if not is_head and cursor == y:
            cursor += gap
        tw = draw.textlength(line, font=font)
        x = anchor - tw / 2
        x = max(36, min(x, img.width - tw - 36))
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
    wide_scale=1.5,
    wide_lift=100,
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
    wide_scale=1.5,
    wide_lift=100,
)
