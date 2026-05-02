#!/usr/bin/env python3

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
WINDOW_CAPTURE = ROOT / "screenshots" / "raw" / "window-clean.png"
OUTPUT_DIR = ROOT / "screenshots" / "app-store"

WIDTH = 2880
HEIGHT = 1800

FONT_REGULAR = "/System/Library/Fonts/Supplemental/Arial.ttf"
FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"

SCREEN_SPECS = [
    {
        "filename": "01-main-board.png",
        "bg_top": (24, 56, 49),
        "bg_bottom": (122, 156, 138),
        "headline": "Stillgrid Sudoku",
        "body": "A calm focused Sudoku board\nfor short puzzle sessions.",
        "footer": "Minimal. Readable. Always about the board.",
        "window_scale": 0.77,
        "window_pos": (1600, 240),
    },
    {
        "filename": "02-readable-board.png",
        "bg_top": (29, 49, 66),
        "bg_bottom": (136, 168, 157),
        "headline": "Clear at a glance",
        "body": "Readable numbers, soft cell feedback,\nand a calm board surface.",
        "footer": "Easy to scan from the first move.",
        "window_scale": 0.73,
        "window_pos": (1660, 270),
    },
    {
        "filename": "03-progress-feedback.png",
        "bg_top": (26, 54, 43),
        "bg_bottom": (108, 150, 121),
        "headline": "Gentle progress",
        "body": "Completed digits and board progress\nstay visible without visual clutter.",
        "footer": "Still focus from first move to last.",
        "window_scale": 0.73,
        "window_pos": (1660, 270),
    },
]


def load_font(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size=size)


def make_gradient(top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGBA", (WIDTH, HEIGHT))
    draw = ImageDraw.Draw(image)
    for y in range(HEIGHT):
        t = y / (HEIGHT - 1)
        color = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        draw.line((0, y, WIDTH, y), fill=color + (255,))
    return image


def add_diagonal_pattern(image: Image.Image) -> None:
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    spacing = 70
    for x in range(-HEIGHT, WIDTH, spacing):
        draw.line((x, 0, x + HEIGHT, HEIGHT), fill=(255, 255, 255, 26), width=2)
    image.alpha_composite(overlay)


def add_glass_panel(image: Image.Image) -> None:
    panel = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(panel)
    bounds = (132, 210, 1350, 1285)
    draw.rounded_rectangle(bounds, radius=42, fill=(214, 229, 222, 56), outline=(255, 255, 255, 66), width=2)
    image.alpha_composite(panel)


def add_copy(image: Image.Image, headline: str, body: str, footer: str) -> None:
    draw = ImageDraw.Draw(image)
    headline_font = load_font(FONT_REGULAR, 74)
    body_font = load_font(FONT_REGULAR, 38)
    footer_font = load_font(FONT_REGULAR, 24)
    ink = (242, 247, 239, 255)
    secondary = (224, 234, 226, 230)

    draw.text((190, 365), headline, font=headline_font, fill=ink)
    draw.multiline_text((190, 585), body, font=body_font, fill=ink, spacing=18)
    draw.text((190, 1115), footer, font=footer_font, fill=secondary)


def add_window(image: Image.Image, window_capture: Image.Image, scale: float, pos: tuple[int, int]) -> None:
    new_size = (int(window_capture.width * scale), int(window_capture.height * scale))
    resized = window_capture.resize(new_size, Image.Resampling.LANCZOS)

    shadow = Image.new("RGBA", (resized.width + 80, resized.height + 80), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle((30, 24, shadow.width - 30, shadow.height - 20), radius=42, fill=(0, 0, 0, 120))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    image.alpha_composite(shadow, (pos[0] - 24, pos[1] + 30))
    image.alpha_composite(resized, pos)


def add_traffic_light_colors(window_capture: Image.Image) -> Image.Image:
    recolored = window_capture.copy()
    draw = ImageDraw.Draw(recolored, "RGBA")
    buttons = [
        ((98, 82), (255, 95, 87, 255)),
        ((145, 82), (255, 189, 46, 255)),
        ((192, 82), (40, 200, 64, 255)),
    ]
    radius = 14
    for (cx, cy), color in buttons:
        draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=color)

    title_font = load_font(FONT_BOLD, 32)
    draw.rounded_rectangle((240, 54, 520, 110), radius=8, fill=(28, 31, 31, 255))
    draw.text((260, 63), "Stillgrid Sudoku", font=title_font, fill=(92, 96, 98, 255))
    return recolored


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    window_capture = Image.open(WINDOW_CAPTURE).convert("RGBA")
    window_capture = add_traffic_light_colors(window_capture)

    for spec in SCREEN_SPECS:
        canvas = make_gradient(spec["bg_top"], spec["bg_bottom"])
        add_diagonal_pattern(canvas)
        add_glass_panel(canvas)
        add_copy(canvas, spec["headline"], spec["body"], spec["footer"])
        add_window(canvas, window_capture, spec["window_scale"], spec["window_pos"])
        canvas.save(OUTPUT_DIR / spec["filename"])


if __name__ == "__main__":
    main()
