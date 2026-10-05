"""Tegner ett sverd (spiss opp til venstre) som 128x128 RGBA med glatte kanter (4x oversampling).
Enheter som i Medallion.lua: aksen a går fra knappen (-46) til spissen (56), b på tvers. Boksen er ±48 enheter."""
import math, os, sys
from PIL import Image, ImageDraw, ImageFilter

OUT = sys.argv[1] if len(sys.argv) > 1 else "."
SS = 4
SIZE = 128
UNITS = 48.0                      # halv boks i enheter
S = SIZE * SS / (2 * UNITS)       # piksler per enhet i oversamplet bilde
C = SIZE * SS / 2
R2 = 1 / math.sqrt(2)
UX, UY = -R2, R2                  # spissen opp til venstre (matematisk y opp)
PX, PY = -UY, UX                  # på tvers

def P(a, b):
    x = a * UX + b * PX
    y = a * UY + b * PY
    return (C + x * S, C - y * S)

def poly(draw, pts, fill):
    draw.polygon([P(a, b) for a, b in pts], fill=fill)

def thick(pts, grow):
    """Samme form, litt større (for omriss): flytt hvert punkt ut fra sentroiden langs b og a."""
    out = []
    for a, b in pts:
        out.append((a + (grow if a > 0 else -grow) * 0.6, b + (grow if b >= 0 else -grow)))
    return out

def circle(draw, a, b, r, fill):
    x, y = P(a, b)
    draw.ellipse([x - r * S, y - r * S, x + r * S, y + r * S], fill=fill)

img = Image.new("RGBA", (SIZE * SS, SIZE * SS), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

BLACK = (8, 6, 4, 255)
STEEL_L = (226, 231, 238, 255)
STEEL_D = (138, 146, 158, 255)
EDGE = (250, 252, 255, 255)
GOLD = (222, 178, 74, 255)
GOLD_D = (150, 108, 38, 255)
GOLD_L = (255, 232, 160, 255)
LEATHER = (96, 60, 34, 255)
LEATHER_D = (58, 34, 18, 255)

# Blad: venstre (lys) og høyre (mørk) halvdel gir fasett, spiss i a = 56
blade = [(-30, -4.3), (45, -3.4), (56, 0), (45, 3.4), (-30, 4.3)]  # bredere blad: sverd, ikke dolk
grip = [(-42.5, -1.9), (-32.5, -1.9), (-32.5, 1.9), (-42.5, 1.9)]
guard = [(-33.6, -10.5), (-29.4, -10.5), (-29.4, 10.5), (-33.6, 10.5)]

# Svart omriss (litt større former under)
poly(d, thick(blade, 1.3), BLACK)
poly(d, thick(grip, 1.2), BLACK)
poly(d, thick(guard, 1.2), BLACK)
circle(d, -45.5, 0, 4.4, BLACK)
circle(d, -31.5, -10.6, 2.9, BLACK)
circle(d, -31.5, 10.6, 2.9, BLACK)

# Bladet
poly(d, [(-30, -4.3), (45, -3.4), (56, 0), (-30, 0)], STEEL_D)
poly(d, [(-30, 0), (56, 0), (45, 3.4), (-30, 4.3)], STEEL_L)
poly(d, [(-27, -0.5), (46, -0.35), (52, 0), (46, 0.35), (-27, 0.5)], EDGE)  # rygg

# Grep med vikling
poly(d, grip, LEATHER)
for a in [-41.5, -39.3, -37.1, -34.9]:
    poly(d, [(a, -1.9), (a + 0.9, -1.9), (a + 2.0, 1.9), (a + 1.1, 1.9)], LEATHER_D)

# Parerstang med knotter
poly(d, guard, GOLD)
poly(d, [(-33.6, -10.5), (-32.4, -10.5), (-32.4, 10.5), (-33.6, 10.5)], GOLD_D)
poly(d, [(-30.4, -10.5), (-29.4, -10.5), (-29.4, 10.5), (-30.4, 10.5)], GOLD_L)
circle(d, -31.5, -10.6, 2.0, GOLD)
circle(d, -31.5, 10.6, 2.0, GOLD)

# Knapp med glans
circle(d, -45.5, 0, 3.3, GOLD)
circle(d, -45.0, 0.9, 1.3, GOLD_L)

small = img.resize((SIZE, SIZE), Image.LANCZOS)
os.makedirs(OUT, exist_ok=True)
small.save(os.path.join(OUT, "sword.tga"))
small.save(os.path.join(OUT, "sword.png"))
print("ok", small.size, small.mode)
