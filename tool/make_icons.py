"""Draws the DAB Fitness mark (a bold "D" with a dumbbell in its counter)
and writes the PNGs that flutter_launcher_icons / flutter_native_splash and
the app use.

    python tool/make_icons.py

Re-run after changing the mark, then:

    dart run flutter_launcher_icons
    dart run flutter_native_splash:create
"""
from pathlib import Path

from PIL import Image, ImageDraw

TEAL = (15, 157, 138, 255)  # AppTheme.seed #0F9D8A
WHITE = (255, 255, 255, 255)
CLEAR = (0, 0, 0, 0)
SS = 4  # supersampling factor for smooth edges

ROOT = Path(__file__).resolve().parent.parent


def mark(size: int) -> Image.Image:
    """The mark alone, on transparent, filling a [size] square."""
    n = 1024 * SS
    img = Image.new('RGBA', (n, n), CLEAR)
    d = ImageDraw.Draw(img)

    def s(*v):
        return [x * SS for x in v]

    # Outer D: stem (rounded outer corners) + right half-ellipse.
    d.rounded_rectangle(s(232, 192, 420, 832), radius=48 * SS, fill=TEAL)
    d.rectangle(s(320, 192, 512, 832), fill=TEAL)
    d.pieslice(s(232, 192, 792, 832), -90, 90, fill=TEAL)
    # Counter (cut out).
    d.rectangle(s(372, 332, 512, 692), fill=CLEAR)
    d.pieslice(s(332, 332, 652, 692), -90, 90, fill=CLEAR)
    # Dumbbell centred in the counter, clear of the stem.
    d.rounded_rectangle(s(424, 497, 600, 527), radius=15 * SS, fill=TEAL)
    for x in (438, 556):  # inner plates
        d.rounded_rectangle(s(x, 436, x + 30, 588), radius=15 * SS, fill=TEAL)
    for x in (414, 590):  # outer plates
        d.rounded_rectangle(s(x, 468, x + 20, 556), radius=10 * SS, fill=TEAL)

    return img.resize((size, size), Image.LANCZOS)


def on_canvas(size: int, scale: float, background) -> Image.Image:
    """[size] square with the mark at [scale] of the width, centred."""
    canvas = Image.new('RGBA', (size, size), background)
    m = mark(int(size * scale))
    offset = (size - m.width) // 2
    canvas.alpha_composite(m, (offset, offset))
    return canvas


def main():
    icon_dir = ROOT / 'assets' / 'icon'
    icon_dir.mkdir(parents=True, exist_ok=True)

    # Launcher icon: teal mark on white (iOS and legacy Android).
    on_canvas(1024, 0.78, WHITE).convert('RGB').save(icon_dir / 'app_icon.png')
    # Adaptive icon foreground: keep the mark inside the ~61% safe zone.
    on_canvas(1024, 0.56, CLEAR).save(icon_dir / 'app_icon_foreground.png')
    # Native splash (pre-Android 12 and iOS).
    on_canvas(512, 1.0, CLEAR).save(icon_dir / 'splash_mark.png')
    # Android 12+ splash: 1152 square, content within the central 768 circle.
    on_canvas(1152, 0.5, CLEAR).save(icon_dir / 'splash_android12.png')
    # In-app logo (Welcome, Login, Sign-up, splash screen).
    on_canvas(512, 1.0, CLEAR).save(ROOT / 'assets' / 'images' / 'logo_mark.png')
    print('icons written to', icon_dir)


if __name__ == '__main__':
    main()
