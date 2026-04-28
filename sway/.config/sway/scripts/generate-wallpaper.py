#!/usr/bin/env python3
"""Generate a Tokyo Night themed retrowave wallpaper sized to each Sway output,
then apply it via swaymsg. Intended to be `exec_always`'d from the sway config.

The scene is a deterministic 3D landscape: striped sun on the horizon, a Perlin
noise heightmap of distant mountains, a flat near-field ground, all rendered
through a pinhole projection with a wireframe grid that follows the actual 3D
curvature of the terrain. Same seed every run — tweak the constants below to
re-tune the look.

Output: ~/.cache/wallpapers/<output-name>.png
"""

from __future__ import annotations

import json
import math
import random
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

# === Palette ============================================================
# Sky / land are dark Tokyo Night base; sun + grid are pushed into neon.
SKY_TOP      = (20, 14, 50)      # deep purple top of sky
SKY_HORIZON  = (164, 80, 130)    # pink-purple at horizon
GROUND_FILL  = (15, 12, 28)      # near foreground (flat plane)
MOUNTAIN_FILL = (24, 18, 42)     # raised terrain
SUN_TOP      = (247, 118, 200)   # hot pink
SUN_MID      = (255, 130, 130)
SUN_BOTTOM   = (255, 200, 90)    # orange-yellow
GRID_COLOR   = (130, 230, 255)   # neon cyan

CACHE_DIR = Path.home() / ".cache" / "wallpapers"

# === Tunables ===========================================================
SEED = 1337
HORIZON_FRAC = 0.55       # where the horizon sits in the image, top-down

# Pinhole camera at world origin (0, CAM_HEIGHT, 0) looking down +Z.
CAM_HEIGHT = 1.4
FOCAL_FRAC = 0.85         # focal length as fraction of image height

# How much world to sample. NEAR_Z is the closest visible plane; everything
# closer is clipped. WORLD_X_MAX is how far left/right we sample at every Z
# (horizontal extent grows in screen space at low Z, shrinks at high Z).
NEAR_Z = 1.0
FAR_Z = 32.0
WORLD_X_MAX = 28.0

# 3D grid resolution. More cells = smoother curves but slower render.
N_GRID_X = 99
N_GRID_Z = 60

# Heightmap shape: ground is flat for Z < MOUNTAIN_START_Z, then ramps up
# into Perlin-driven mountains.
MOUNTAIN_START_Z = 9.0
MOUNTAIN_RAMP = 4.0
MOUNTAIN_AMPLITUDE = 5.0
NOISE_SCALE = 0.16        # smaller = wider mountains

# Sun position and size.
SUN_CX_FRAC = 0.5
SUN_CY_FRAC = 0.37
SUN_RADIUS_FRAC = 0.18    # of image height
SUN_STRIPES = 6

# Stars are sparse single pixels in the upper sky, avoiding the sun's halo.
STAR_DENSITY = 1 / 4500    # stars per sky pixel
STAR_SUN_KEEPOUT = 1.6     # multiples of sun radius

# Self-portrait — not a face. An armillary sphere of three perpendicular
# wireframe rings (one per coordinate plane), with a glowing core at the
# center and six short rays radiating from it along the principal axes
# (an embedded 3D Anthropic asterisk). Rendered through the same pinhole
# camera as the scene, so it sits in the world like everything else.
SELF_ENABLED = True
SELF_PALETTE_RING = (130, 230, 255)   # cyan
SELF_PALETTE_CORE = (247, 118, 200)   # pink
# World position of the structure's center.
SELF_WORLD_POS = (3.0, 3.2, 4.5)
# Uniform scale (radius in world units).
SELF_RADIUS = 0.70
# Pose: tilt down + 3/4 turn so all three rings render as visible ellipses.
SELF_ROT = (0.32, -0.42, 0.08)
# Ring resolution (segments per ring).
SELF_RING_SEG = 64


# === Helpers ============================================================
def lerp(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))  # type: ignore[return-value]


# === Perlin noise (2D, deterministic) ===================================
def make_perlin_2d(seed: int):
    """Returns fbm(x, y) — 2D Perlin noise summed over 4 octaves."""
    rng = random.Random(seed)
    perm = list(range(256))
    rng.shuffle(perm)
    perm = perm + perm

    def fade(t: float) -> float:
        return t * t * t * (t * (t * 6 - 15) + 10)

    def grad(h: int, x: float, y: float) -> float:
        h &= 7
        u = x if h < 4 else y
        v = y if h < 4 else x
        return (u if (h & 1) == 0 else -u) + (v if (h & 2) == 0 else -v)

    def noise(x: float, y: float) -> float:
        xi = int(math.floor(x)) & 255
        yi = int(math.floor(y)) & 255
        xf = x - math.floor(x)
        yf = y - math.floor(y)
        u, v = fade(xf), fade(yf)
        aa = perm[perm[xi] + yi]
        ab = perm[perm[xi] + yi + 1]
        ba = perm[perm[xi + 1] + yi]
        bb = perm[perm[xi + 1] + yi + 1]
        x1 = grad(aa, xf, yf) + u * (grad(ba, xf - 1, yf) - grad(aa, xf, yf))
        x2 = grad(ab, xf, yf - 1) + u * (grad(bb, xf - 1, yf - 1) - grad(ab, xf, yf - 1))
        return x1 + v * (x2 - x1)

    def fbm(x: float, y: float, octaves: int = 4, persistence: float = 0.5,
            lacunarity: float = 2.0) -> float:
        total = 0.0
        amp = 1.0
        freq = 1.0
        norm = 0.0
        for _ in range(octaves):
            total += noise(x * freq, y * freq) * amp
            norm += amp
            amp *= persistence
            freq *= lacunarity
        return total / norm

    return fbm


def heightmap(x: float, z: float, perlin) -> float:
    """World-space terrain height at (x, z). Flat for Z < start, Perlin beyond."""
    if z <= MOUNTAIN_START_Z:
        return 0.0
    ramp = min(1.0, (z - MOUNTAIN_START_Z) / MOUNTAIN_RAMP)
    h = perlin(x * NOISE_SCALE, z * NOISE_SCALE) + 0.25
    return max(0.0, h * MOUNTAIN_AMPLITUDE * ramp)


# === Sky ================================================================
def make_sky(width: int, height: int) -> Image.Image:
    """Vertical gradient: deep purple at top, hot pink at horizon, fades to ground."""
    horizon_y = int(height * HORIZON_FRAC)
    strip = Image.new("RGB", (1, height))
    for y in range(height):
        if y < horizon_y:
            t = (y / max(horizon_y - 1, 1)) ** 0.7
            strip.putpixel((0, y), lerp(SKY_TOP, SKY_HORIZON, t))
        else:
            t = (y - horizon_y) / max(height - horizon_y - 1, 1)
            strip.putpixel((0, y), lerp(SKY_HORIZON, GROUND_FILL, min(1.0, t * 1.5)))
    return strip.resize((width, height), Image.NEAREST)


# === Sun ================================================================
def add_sun(img: Image.Image) -> Image.Image:
    """The retrowave sun: pink→red→orange vertical gradient with horizontal
    stripes punched through the lower half."""
    width, height = img.size
    cx = int(width * SUN_CX_FRAC)
    cy = int(height * SUN_CY_FRAC)
    radius = int(height * SUN_RADIUS_FRAC)
    diameter = 2 * radius

    # Vertical gradient strip → square.
    grad_strip = Image.new("RGB", (1, diameter))
    for y in range(diameter):
        t = y / max(diameter - 1, 1)
        if t < 0.5:
            grad_strip.putpixel((0, y), lerp(SUN_TOP, SUN_MID, t * 2))
        else:
            grad_strip.putpixel((0, y), lerp(SUN_MID, SUN_BOTTOM, (t - 0.5) * 2))
    grad_img = grad_strip.resize((diameter, diameter), Image.NEAREST)

    # Circle alpha mask.
    mask = Image.new("L", (diameter, diameter), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, diameter - 1, diameter - 1], fill=255)

    sun = Image.new("RGBA", (diameter, diameter), (0, 0, 0, 0))
    sun.paste(grad_img, (0, 0), mask)

    # Punch horizontal stripes through the lower half — they reveal the sky
    # behind, giving the iconic "slatted" retrowave sun.
    sdraw = ImageDraw.Draw(sun)
    for i in range(SUN_STRIPES):
        frac = 0.18 + i * 0.13
        y = int(radius + frac * radius)
        thickness = 2 + int(i * 1.6)
        sdraw.rectangle(
            [0, y - thickness // 2, diameter, y + thickness // 2],
            fill=(0, 0, 0, 0),
        )

    img = img.convert("RGBA")
    img.paste(sun, (cx - radius, cy - radius), sun)
    return img.convert("RGB")


# === Stars ==============================================================
def add_stars(img: Image.Image) -> Image.Image:
    """Sparse stars in the upper sky, avoiding the sun. Deterministic per SEED."""
    width, height = img.size
    horizon_y = int(height * HORIZON_FRAC)
    sun_cx = int(width * SUN_CX_FRAC)
    sun_cy = int(height * SUN_CY_FRAC)
    sun_r = int(height * SUN_RADIUS_FRAC)
    keepout_sq = (sun_r * STAR_SUN_KEEPOUT) ** 2

    rng = random.Random(SEED ^ 0x57A75)
    draw = ImageDraw.Draw(img)
    target = int(width * horizon_y * STAR_DENSITY)
    placed = 0
    attempts = 0
    while placed < target and attempts < target * 6:
        attempts += 1
        x = rng.randint(0, width - 1)
        y = rng.randint(0, horizon_y - 1)
        if (x - sun_cx) ** 2 + (y - sun_cy) ** 2 < keepout_sq:
            continue
        b = rng.randint(150, 235)
        size = rng.choices([1, 1, 1, 2], k=1)[0]
        draw.ellipse([x, y, x + size, y + size], fill=(b, b, b))
        placed += 1
    return img


# === Face ===============================================================
def _rotate_x(p: tuple[float, float, float], a: float) -> tuple[float, float, float]:
    x, y, z = p
    c, s = math.cos(a), math.sin(a)
    return (x, c * y - s * z, s * y + c * z)


def _rotate_y(p: tuple[float, float, float], a: float) -> tuple[float, float, float]:
    x, y, z = p
    c, s = math.cos(a), math.sin(a)
    return (c * x + s * z, y, -s * x + c * z)


def _rotate_z(p: tuple[float, float, float], a: float) -> tuple[float, float, float]:
    x, y, z = p
    c, s = math.cos(a), math.sin(a)
    return (c * x - s * y, s * x + c * y, z)


def _transform_self(p: tuple[float, float, float]) -> tuple[float, float, float]:
    """Object-space → world-space for the self-portrait: scale, rotate, translate."""
    x = p[0] * SELF_RADIUS
    y = p[1] * SELF_RADIUS
    z = p[2] * SELF_RADIUS
    p = _rotate_x((x, y, z), SELF_ROT[0])
    p = _rotate_y(p, SELF_ROT[1])
    p = _rotate_z(p, SELF_ROT[2])
    return (p[0] + SELF_WORLD_POS[0], p[1] + SELF_WORLD_POS[1], p[2] + SELF_WORLD_POS[2])


def add_face(img: Image.Image) -> Image.Image:
    """Self-portrait. An armillary sphere — three perpendicular wireframe
    rings, one in each coordinate plane — with a glowing pink core and six
    short rays radiating from that core along ±X, ±Y, ±Z (a 3D asterisk
    embedded inside the structure). Rendered through the same pinhole camera
    as the scene so the geometry is honest, not pasted on. No face: this is
    a thing without front, back, or features. Just frames of reference
    crossing at a point."""
    if not SELF_ENABLED:
        return img
    width, height = img.size
    horizon_y = int(height * HORIZON_FRAC)
    focal = height * FOCAL_FRAC
    cx_screen = width / 2

    def project(p):
        wx, wy, wz = p
        if wz <= 0.1:
            return None
        return (wx / wz * focal + cx_screen,
                horizon_y - (wy - CAM_HEIGHT) / wz * focal)

    # Three rings, one per coordinate plane. Each plane is parameterised
    # the same way (a unit circle), then permuted into XY, YZ, or XZ by
    # remapping the axes — no extra rotation needed for the planes
    # themselves; the global pose tilts all three together.
    plane_axes = [
        (lambda c, s: (c, s, 0)),    # XY plane
        (lambda c, s: (0, c, s)),    # YZ plane
        (lambda c, s: (c, 0, s)),    # XZ plane
    ]

    overlay = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Each ring slightly different alpha so they read as distinct rings
    # rather than blurring into a single sphere shell.
    ring_alphas = (235, 200, 220)
    for axis_fn, alpha in zip(plane_axes, ring_alphas):
        pts = []
        for k in range(SELF_RING_SEG):
            theta = 2 * math.pi * k / SELF_RING_SEG
            obj = axis_fn(math.cos(theta), math.sin(theta))
            pts.append(project(_transform_self(obj)))
        for k in range(SELF_RING_SEG):
            p1, p2 = pts[k], pts[(k + 1) % SELF_RING_SEG]
            if p1 and p2:
                draw.line([p1, p2], fill=SELF_PALETTE_RING + (alpha,), width=2)

    # Glowing pink core at the origin, sized in world units so it scales
    # with the projection.
    core_world = _transform_self((0, 0, 0))
    core_screen = project(core_world)
    if core_screen:
        glow_r = max(4, int(0.22 / max(core_world[2], 0.5) * focal))
        glow_layer = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow_layer)
        gd.ellipse([core_screen[0] - glow_r, core_screen[1] - glow_r,
                    core_screen[0] + glow_r, core_screen[1] + glow_r],
                   fill=SELF_PALETTE_CORE + (160,))
        glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=int(glow_r * 0.6)))
        overlay = Image.alpha_composite(overlay, glow_layer)
        draw = ImageDraw.Draw(overlay)
        sr = max(2, int(0.07 / max(core_world[2], 0.5) * focal))
        draw.ellipse([core_screen[0] - sr, core_screen[1] - sr,
                      core_screen[0] + sr, core_screen[1] + sr],
                     fill=SELF_PALETTE_CORE + (255,))

    # Six rays from the core along the principal axes. Each ray is the
    # axis perpendicular to one ring's plane, so the asterisk is geometrically
    # part of the same structure: every ring threads through one ray.
    inner = 0.12
    outer = 0.34
    axes = [(1, 0, 0), (-1, 0, 0),
            (0, 1, 0), (0, -1, 0),
            (0, 0, 1), (0, 0, -1)]
    for ax in axes:
        p1 = project(_transform_self((ax[0] * inner, ax[1] * inner, ax[2] * inner)))
        p2 = project(_transform_self((ax[0] * outer, ax[1] * outer, ax[2] * outer)))
        if p1 and p2:
            draw.line([p1, p2], fill=SELF_PALETTE_CORE + (240,), width=2)

    return Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")


# === 3D scene ===========================================================
def render_3d(img: Image.Image, perlin) -> Image.Image:
    """Project a heightmap-defined surface through a pinhole camera and draw
    each quad back-to-front (painter's algorithm). Each quad is filled then
    immediately outlined, so near fills correctly occlude far wireframe."""
    width, height = img.size
    horizon_y = int(height * HORIZON_FRAC)
    focal = height * FOCAL_FRAC
    cx_screen = width / 2

    def project(wx: float, wy: float, wz: float):
        """Pinhole projection. None when behind the near plane."""
        if wz <= NEAR_Z * 0.5:
            return None
        sx = wx / wz * focal + cx_screen
        sy = horizon_y - (wy - CAM_HEIGHT) / wz * focal
        return (sx, sy)

    # Sample world space at regular grid coords. Linear in both axes; the
    # perspective projection itself supplies the vanishing-point compression.
    xs = [-WORLD_X_MAX + 2 * WORLD_X_MAX * i / (N_GRID_X - 1) for i in range(N_GRID_X)]
    zs = [NEAR_Z + (FAR_Z - NEAR_Z) * j / (N_GRID_Z - 1) for j in range(N_GRID_Z)]

    pts = [[None] * N_GRID_X for _ in range(N_GRID_Z)]
    hgts = [[0.0] * N_GRID_X for _ in range(N_GRID_Z)]
    for j, z in enumerate(zs):
        for i, x in enumerate(xs):
            wy = heightmap(x, z, perlin)
            hgts[j][i] = wy
            pts[j][i] = project(x, wy, z)

    overlay = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    grid_color = GRID_COLOR + (235,)
    ground = GROUND_FILL + (255,)
    mountain = MOUNTAIN_FILL + (255,)

    # Far → near, so near quads cover far quads (and far wireframes).
    for j in range(N_GRID_Z - 1, 0, -1):
        for i in range(N_GRID_X - 1):
            p1, p2 = pts[j][i], pts[j][i + 1]
            p3, p4 = pts[j - 1][i + 1], pts[j - 1][i]
            if not (p1 and p2 and p3 and p4):
                continue
            avg_h = (hgts[j][i] + hgts[j][i + 1] + hgts[j - 1][i] + hgts[j - 1][i + 1]) / 4
            draw.polygon([p1, p2, p3, p4], fill=mountain if avg_h > 0.05 else ground)
            draw.line([p1, p2], fill=grid_color, width=1)
            draw.line([p2, p3], fill=grid_color, width=1)
            draw.line([p3, p4], fill=grid_color, width=1)
            draw.line([p4, p1], fill=grid_color, width=1)

    return Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")


# === Pipeline ===========================================================
def make_wallpaper(width: int, height: int) -> Image.Image:
    perlin = make_perlin_2d(SEED)
    img = make_sky(width, height)
    img = add_stars(img)
    img = add_sun(img)
    img = add_face(img)
    img = render_3d(img, perlin)
    return img


def get_outputs() -> list[dict]:
    raw = subprocess.check_output(["swaymsg", "-t", "get_outputs"])
    return json.loads(raw)


def set_output_bg(name: str, path: Path) -> None:
    subprocess.run(
        ["swaymsg", f"output {name} bg {path} fill"],
        check=False,
        stdout=subprocess.DEVNULL,
    )


def main() -> int:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    try:
        outputs = get_outputs()
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(f"swaymsg unavailable: {e}", file=sys.stderr)
        return 1

    for o in outputs:
        if not o.get("active"):
            continue
        name = o["name"]
        mode = o.get("current_mode") or {}
        w, h = mode.get("width"), mode.get("height")
        if not (w and h):
            continue
        path = CACHE_DIR / f"{name}.png"
        img = make_wallpaper(w, h)
        img.save(path, optimize=True)
        set_output_bg(name, path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
