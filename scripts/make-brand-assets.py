"""Makes every logo file and app icon of Yummy Chops from the owner's two brand pictures (docs/adr/0029-new-logo-and-app-icon.md).

    python scripts/make-brand-assets.py          (needs Pillow and numpy: pip install pillow numpy)

The two masters, in assets/brand:
  - yummychops-logo.webp, the logo (1080 px square): the chef in her kitchen under an arch, with the "Yummy Chops"
    ribbon (the emblem); the name "Yummy247" (dark brown "Yummy", red "247"); a red swoosh; the line "Good Food.
    Great Mood."; a rider on a scooter and three small badges;
  - yummychops-app-icon.png, the app icon (1190 px square): a white chef's hat with a green "yc" and a yellow
    sparkle, on red.
Each place uses what reads at its size:
  - the whole logo: the sign-in screens of the apps and the websites, the apps' launch screens, link previews;
  - the emblem beside the name: website headers;
  - the app icon: both apps' launcher icons (the rider app's on chocolate brown instead of red, so the two tell
    apart on one phone), the websites' browser-tab and home-screen icons, the apps' browser builds.
Everything is cut from the two pictures; nothing is redrawn. The cut-outs keep the logo's own white where it is part
of the drawing and lose the white around them, so they sit on any light background; the name loses all its white
(also inside the letters), so it sits on dark backgrounds too. The icon's red is lifted off its drawing the same way,
so the drawing can sit on another colour or keep clear of the launchers' masks.
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
BRAND = ROOT / "assets" / "brand"
LOGO = BRAND / "yummychops-logo.webp"
ICON = BRAND / "yummychops-app-icon.png"

WHITE = (255, 255, 255, 255)
#: The rider app's icon ground: the logo's dark brown (docs/adr/0022-brand.md).
CHOCOLATE = (58, 13, 5, 255)
#: The website apps that get favicons and the logo files.
WEBSITES = ("web", "partner", "admin")


def load(path: Path, side: int) -> Image.Image:
    im = Image.open(path).convert("RGBA")
    assert im.size == (side, side), f"expected the {side} px square {path.name}, got {im.size}"
    return im


def clear_background(im: Image.Image) -> Image.Image:
    """The white around the drawing becomes transparent (white inside it stays)."""
    out = im.copy()
    w, h = out.size
    for seed in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
        if out.getpixel(seed)[3]:
            ImageDraw.floodfill(out, seed, (255, 255, 255, 0), thresh=40)
    # Soften the light fringe the anti-aliasing leaves: near-white pixels next to the cleared area fade out.
    px = out.load()
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            r, g, b, a = px[x, y]
            if a and r > 235 and g > 235 and b > 235:
                if not (px[x - 1, y][3] and px[x + 1, y][3] and px[x, y - 1][3] and px[x, y + 1][3]):
                    px[x, y] = (r, g, b, 0)
    return out


def is_red(c) -> bool:
    r, g, b = c[:3]
    return r > 140 and g < 110 and b < 110 and r > g + 60


def emblem(im: Image.Image) -> Image.Image:
    """The chef under her arch, with the "Yummy Chops" ribbon (rows 30 to 425 of the logo; the name starts at 428)."""
    out = clear_background(im.crop((290, 24, 790, 427)))
    return out.crop(out.getbbox())


def white_to_alpha(im: Image.Image) -> Image.Image:
    """Every bit of white becomes transparency, also the soft edges: a pixel that is the drawing's colour mixed
    with white becomes that colour, partly transparent. For art with no white of its own (the name)."""
    rgba = np.asarray(im.convert("RGBA"), dtype=np.float64) / 255
    rgb, alpha_in = rgba[..., :3], rgba[..., 3]
    lightest = rgb.min(axis=2)
    alpha = 1 - lightest
    alpha[alpha < 0.08] = 0  # the background's faint noise (off-white specks would become faint coloured dust)
    safe = np.maximum(alpha, 1e-6)[..., None]
    colour = np.clip(1 - (1 - rgb) / safe, 0, 1)
    out = np.dstack([colour, alpha * alpha_in]) * 255
    return Image.fromarray(out.round().astype(np.uint8), "RGBA").copy()  # a copy can be drawn on


def wordmark(im: Image.Image) -> Image.Image:
    """The name "Yummy247" (rows 428 to 593 of the logo; the swoosh and the tagline start at 601)."""
    out = white_to_alpha(im.crop((30, 426, 1050, 597)))
    return out.crop(out.getbbox())


def on_dark(art: Image.Image) -> Image.Image:
    """The same art for dark backgrounds: its dark brown ("Yummy") turns cream; the red stays."""
    out = art.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a and r + g + b < 260 and not is_red((r, g, b)):
                px[x, y] = (251, 240, 234, a)
    return out


def ground_of(icon: Image.Image) -> tuple[int, int, int, int]:
    """The icon's background colour: the middle value of a 40 px strip along its edges (an even red)."""
    a = np.asarray(icon.convert("RGB"), dtype=np.float64)
    strip = np.concatenate([a[:40].reshape(-1, 3), a[-40:].reshape(-1, 3), a[:, :40].reshape(-1, 3), a[:, -40:].reshape(-1, 3)])
    r, g, b = (int(round(v)) for v in np.median(strip, axis=0))
    return (r, g, b, 255)


def lift(icon: Image.Image, ground) -> Image.Image:
    """The icon's drawing without its ground colour, at its own size and place. Each pixel gets the least opacity
    that explains it as the drawing's colour over the ground, so soft edges stay soft and keep their true colour
    (the hat's edge is white, not pink) on any new ground. Put back on the same ground it is the icon again."""
    rgb = np.asarray(icon.convert("RGB"), dtype=np.float64)
    bg = np.array(ground[:3], dtype=np.float64)
    # The red varies by up to 8 levels; a channel near 0 (its green and blue) would turn that into a lot of opacity.
    noise = 8
    up = np.maximum(rgb - bg - noise, 0) / np.maximum(255 - bg, 1e-6)
    down = np.maximum(bg - rgb - noise, 0) / np.maximum(bg, 1e-6)
    alpha = np.minimum(np.maximum(up, down).max(axis=2), 1)
    alpha[alpha < 0.06] = 0
    safe = np.maximum(alpha, 1e-6)[..., None]
    colour = np.clip(bg + (rgb - bg) / safe, 0, 255)
    out = np.dstack([colour, alpha * 255])
    return Image.fromarray(out.round().astype(np.uint8), "RGBA")


def shape_layer(size: int, fill, shape: str = "square") -> Image.Image:
    """A `size` square holding `shape` ("square", "rounded" or "circle") in `fill`, with smooth edges: it is drawn
    four times larger and shrunk."""
    if shape == "square":
        return Image.new("RGBA", (size, size), fill)
    big = size * 4
    layer = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    if shape == "rounded":
        draw.rounded_rectangle((0, 0, big - 1, big - 1), radius=round(big * 16 / 72), fill=fill)
    else:
        draw.ellipse((0, 0, big - 1, big - 1), fill=fill)
    return layer.resize((size, size), Image.LANCZOS)


def fit(art: Image.Image, size: int, box: float, ground=None, shape: str = "square") -> Image.Image:
    """`art` scaled to fit `box` (a share of `size`) and centred on a `size` square of `ground` (None: clear),
    cut to `shape`."""
    canvas = Image.new("RGBA", (size, size), ground if ground is not None else (0, 0, 0, 0))
    limit = size * box
    scale = min(limit / art.width, limit / art.height)
    piece = art.resize((max(1, round(art.width * scale)), max(1, round(art.height * scale))), Image.LANCZOS)
    canvas.alpha_composite(piece, ((size - piece.width) // 2, (size - piece.height) // 2))
    if shape == "square":
        return canvas
    mask = shape_layer(size, WHITE, shape).split()[3]
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(canvas, (0, 0), mask)
    return out


def reach(art: Image.Image) -> float:
    """How far the drawing reaches from the middle of `art`, as a share of its side (the icon's sparkle, near a
    corner, reaches about 0.48)."""
    alpha = np.asarray(art.split()[3])
    ys, xs = np.nonzero(alpha > 40)
    if not len(xs):
        return 0.0
    cx, cy = (art.width - 1) / 2, (art.height - 1) / 2
    return float(np.sqrt((xs - cx) ** 2 + (ys - cy) ** 2).max()) / max(art.size)


def save(img: Image.Image, path: Path, *, opaque: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if opaque:  # store icons need no transparency
        flat = Image.new("RGB", img.size, (255, 255, 255))
        flat.paste(img, mask=img.split()[3])
        flat.save(path, optimize=True)
    else:
        img.save(path, optimize=True)


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(text)


def main() -> None:
    im = load(LOGO, 1080)
    full = clear_background(im)
    mark, name = emblem(im), wordmark(im)

    # Master cut-outs, kept next to the logo.
    save(full, BRAND / "yummychops-logo.png")
    save(mark, BRAND / "yummychops-emblem.png")
    save(name, BRAND / "yummychops-wordmark.png")
    save(on_dark(name), BRAND / "yummychops-wordmark-light.png")
    print(f"emblem {mark.size}, wordmark {name.size}")

    # The app icon: its drawing lifted off its red, to sit on the red again (the customer app and the websites) or on
    # chocolate brown (the rider app). `as_drawn` keeps the owner's framing; `inside` keeps every drawn pixel in a
    # centred circle (`radius`, a share of the side), so no mask cuts any of it: Android launchers always show the
    # middle 66dp of the 108dp adaptive layer (radius 33/108) and maskable web icons keep the middle 80% (radius 0.40).
    icon = load(ICON, 1190)
    red = ground_of(icon)
    drawing = lift(icon, red)
    far = reach(drawing)
    print(f"the icon's red is #{red[0]:02X}{red[1]:02X}{red[2]:02X}; its drawing reaches {far:.3f} of its side")

    def as_drawn(size: int, ground, shape: str = "square") -> Image.Image:
        return fit(drawing, size, 1.0, ground, shape)

    def inside(size: int, radius: float, ground=None, shape: str = "square") -> Image.Image:
        return fit(drawing, size, radius / far, ground, shape)

    lockup_h = 112  # the header shows the emblem 36 px tall: this covers 3x screens
    for app in WEBSITES:
        public = ROOT / "apps" / app / "public" / "brand"
        save(mark.resize((round(mark.width * lockup_h / mark.height), lockup_h), Image.LANCZOS), public / "yummychops-emblem.png")
        save(name.resize((round(name.width * 96 / name.height), 96), Image.LANCZOS), public / "yummychops-wordmark.png")
        save(on_dark(name).resize((round(name.width * 96 / name.height), 96), Image.LANCZOS), public / "yummychops-wordmark-light.png")
        # Sign-in pages show the whole logo at 160 px; WebP is under half the size of PNG for this artwork.
        full.resize((320, 320), Image.LANCZOS).save(public / "yummychops-logo.webp", quality=90, method=6)
        save(as_drawn(192, red, "rounded"), ROOT / "apps" / app / "src" / "app" / "icon.png")  # browser tab
        save(as_drawn(180, red), ROOT / "apps" / app / "src" / "app" / "apple-icon.png", opaque=True)  # home screen

    # Link previews of the customer website (WhatsApp, X, Facebook): the whole logo on white, 1200x630.
    preview = Image.new("RGBA", (1200, 630), WHITE)
    shown = full.resize((580, 580), Image.LANCZOS)
    preview.alpha_composite(shown, ((1200 - 580) // 2, 25))
    save(preview, ROOT / "apps" / "web" / "src" / "app" / "opengraph-image.png", opaque=True)

    # Phone apps: in-app logo files (customer and rider), launcher icons, launch screens, browser builds.
    densities = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}
    for app in ("customer", "rider"):
        base = ROOT / "mobile" / app
        save(full.resize((720, 720), Image.LANCZOS), base / "assets" / "brand" / "yummychops-logo.png")
        ground = red if app == "customer" else CHOCOLATE
        res = base / "android" / "app" / "src" / "main" / "res"
        for density, k in densities.items():
            # Adaptive icon layer: 108dp, launchers show the middle 72dp (a 66dp circle is always visible).
            save(inside(round(108 * k), 33 / 108), res / f"mipmap-{density}" / "ic_launcher_foreground.png")
            # Older launchers (Android 7 and before) show this one as it is.
            save(as_drawn(round(48 * k), ground, "rounded"), res / f"mipmap-{density}" / "ic_launcher.png")
        hex_ground = "#{:02X}{:02X}{:02X}".format(*ground[:3])
        write_text(res / "values" / "ic_launcher_background.xml",
                   '<?xml version="1.0" encoding="utf-8"?>\n'
                   "<!-- Made by scripts/make-brand-assets.py: the launcher icon's background colour. -->\n"
                   f'<resources>\n    <color name="ic_launcher_background">{hex_ground}</color>\n</resources>\n')
        write_text(res / "mipmap-anydpi-v26" / "ic_launcher.xml",
                   '<?xml version="1.0" encoding="utf-8"?>\n'
                   "<!-- Made by scripts/make-brand-assets.py from assets/brand/yummychops-app-icon.png. -->\n"
                   '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                   '    <background android:drawable="@color/ic_launcher_background" />\n'
                   '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
                   "</adaptive-icon>\n")
        # Launch screen (before Flutter draws): the whole logo on white.
        save(full.resize((480, 480), Image.LANCZOS), res / "drawable-nodpi" / "launch_logo.png")
        launch = ('<?xml version="1.0" encoding="utf-8"?>\n'
                  "<!-- Made by scripts/make-brand-assets.py: the Yummy Chops logo on white while the app starts. -->\n"
                  '<layer-list xmlns:android="http://schemas.android.com/apk/res/android">\n'
                  '    <item android:drawable="@android:color/white" />\n'
                  "    <item>\n"
                  '        <bitmap android:gravity="center" android:src="@drawable/launch_logo" />\n'
                  "    </item>\n"
                  "</layer-list>\n")
        for folder in ("drawable", "drawable-v21"):
            write_text(res / folder / "launch_background.xml", launch)
        # Browser builds (flutter build web): the app icon in the tab and when installed.
        web = base / "web"
        if web.exists():
            save(as_drawn(32, ground, "rounded"), web / "favicon.png")
            for n in (192, 512):
                save(as_drawn(n, ground), web / "icons" / f"Icon-{n}.png")
                save(inside(n, 0.38, ground), web / "icons" / f"Icon-maskable-{n}.png")
        # iOS: every size the asset catalogue lists (no transparency allowed; iOS rounds the corners).
        appicon = base / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
        contents = appicon / "Contents.json"
        if contents.exists():
            for entry in json.loads(contents.read_text(encoding="utf-8"))["images"]:
                if "filename" not in entry:
                    continue
                points = float(entry["size"].split("x")[0])
                px = round(points * float(entry["scale"].rstrip("x")))
                save(as_drawn(px, ground), appicon / entry["filename"], opaque=True)
        print(f"made the {app} app's icons and launch screen")


if __name__ == "__main__":
    main()
