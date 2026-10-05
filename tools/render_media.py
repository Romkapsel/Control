"""Tegner bildene til Control (fase 9: glatte kanter i stedet for stablede flater og streker).

    python tools/render_media.py

Alt tegnes i 4x størrelse og skaleres ned (glatte kanter), og lagres som ukomprimert 32-bit TGA i Media/.
Mål i «enheter» er de samme som i UI/Medallion.lua (medaljongen er 64 enheter). y går oppover som i spillet.
Symbolene er hvite og farges i spillet (SetVertexColor), så mus-over-lyset virker som før.
Sverdet tegnes av tools/sword_render.py.
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "Media")
SS = 4


def hexc(h, a=255):
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def mul(c, k):
    return (min(255, round(c[0] * k)), min(255, round(c[1] * k)), min(255, round(c[2] * k)), c[3])


BLACK = (0, 0, 0, 255)
WHITE = (255, 255, 255, 255)
BRONZE_LIGHT, BRONZE_DARK = hexc("F0CF86"), hexc("6A4A1C")
CORE_HI, CORE, CORE_LO = hexc("3B2F22"), hexc("17110C"), hexc("0B0806")


class Canvas:
    """Et lerret på px piksler som dekker ±half enheter, tegnet i SS ganger størrelsen."""

    def __init__(self, px, half):
        self.px, self.half = px, half
        self.n = px * SS
        self.s = self.n / (2 * half)
        self.img = Image.new("RGBA", (self.n, self.n), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img)

    def P(self, x, y):
        return (self.n / 2 + x * self.s, self.n / 2 - y * self.s)

    def disc(self, x, y, r, fill):
        cx, cy = self.P(x, y)
        rr = r * self.s
        self.d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=fill)

    def seg(self, x1, y1, x2, y2, t, fill=WHITE):
        """Strek med runde ender (rund i knekkpunkter når to streker møtes)."""
        self.d.line([self.P(x1, y1), self.P(x2, y2)], fill=fill, width=max(1, round(t * self.s)))
        for x, y in ((x1, y1), (x2, y2)):
            self.disc(x, y, t / 2, fill)

    def poly(self, pts, t, fill=WHITE):
        for i in range(1, len(pts)):
            self.seg(pts[i - 1][0], pts[i - 1][1], pts[i][0], pts[i][1], t, fill)

    def layer(self):
        """Nytt, tomt lag av samme størrelse (for å kunne komponere med alfa)."""
        c = Canvas(self.px, self.half)
        return c

    def over(self, other, alpha=1.0):
        im = other.img
        if alpha < 1.0:
            a = im.getchannel("A").point(lambda v: round(v * alpha))
            im = im.copy()
            im.putalpha(a)
        self.img = Image.alpha_composite(self.img, im)
        self.d = ImageDraw.Draw(self.img)

    def clear_disc(self, x, y, r):
        mask = Image.new("L", (self.n, self.n), 255)
        md = ImageDraw.Draw(mask)
        cx, cy = self.P(x, y)
        rr = r * self.s
        md.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=0)
        a = Image.composite(self.img.getchannel("A"), Image.new("L", (self.n, self.n), 0), mask)
        self.img.putalpha(a)
        self.d = ImageDraw.Draw(self.img)

    def save(self, name):
        small = self.img.resize((self.px, self.px), Image.LANCZOS)
        small.save(os.path.join(OUT, name + ".tga"))
        return small


# ---------------------------------------------------------------------------------------------- medaljongen
# Alle fire bildene dekker ±40 enheter (80 i spillet), så skygge og glød får plass rundt sirkelen på 64.
MEDAL_PX, MEDAL_HALF = 256, 40


def medal_base():
    c = Canvas(MEDAL_PX, MEDAL_HALF)
    # Myk skygge, 2 enheter ned
    sh = c.layer()
    sh.disc(0, -2, 34, (0, 0, 0, 140))
    sh.img = sh.img.filter(ImageFilter.GaussianBlur(1.6 * c.s))
    c.over(sh)
    c.disc(0, 0, 32, BLACK)
    # Bronse: loddrett overgang fra mørk (nede) til lys (oppe), i hvilestyrke (87 %, som før)
    br = c.layer()
    grad = Image.new("RGBA", (c.n, c.n))
    top, bot = mul(BRONZE_LIGHT, 0.87), mul(BRONZE_DARK, 0.87)
    for yy in range(c.n):
        k = yy / (c.n - 1)  # 0 øverst, 1 nederst
        col = tuple(round(top[i] + (bot[i] - top[i]) * k) for i in range(3)) + (255,)
        ImageDraw.Draw(grad).line([(0, yy), (c.n, yy)], fill=col)
    mask = Image.new("L", (c.n, c.n), 0)
    cx, cy = c.P(0, 0)
    rr = 31 * c.s
    ImageDraw.Draw(mask).ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=255)
    br.img = Image.composite(grad, br.img, mask)
    c.over(br)
    # Lys innerkant i bronsen, svart linje, rom for statusringen, kjernen
    edge = c.layer()
    edge.disc(0, 0, 28, BRONZE_LIGHT)
    c.over(edge, 0.30)
    c.disc(0, 0, 27, BLACK)
    # Kjernen: samme farge og overgang som bakgrunnen i menyene (Style.Frame: 130E0A nede, 201812 oppe),
    # uten sirklene som skulle være lys (Daniel 5. okt)
    core = c.layer()
    grad = Image.new("RGBA", (c.n, c.n))
    top, bot = hexc("201812"), hexc("130E0A")
    for yy in range(c.n):
        k = yy / (c.n - 1)
        col = tuple(round(top[i] + (bot[i] - top[i]) * k) for i in range(3)) + (255,)
        ImageDraw.Draw(grad).line([(0, yy), (c.n, yy)], fill=col)
    mask = Image.new("L", (c.n, c.n), 0)
    rr = 24 * c.s
    ImageDraw.Draw(mask).ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=255)
    core.img = Image.composite(grad, core.img, mask)
    c.over(core)
    c.save("medal_base")


def medal_ring():
    # Statusringen: hvit ring mellom 24 og 26, farges rød/oransje/svart i spillet
    c = Canvas(MEDAL_PX, MEDAL_HALF)
    c.disc(0, 0, 26, WHITE)
    c.clear_disc(0, 0, 24)
    c.save("medal_ring")


def medal_glow():
    # Gløden: myk, hvit, sterkest rett utenfor kanten; farges som ringen
    c = Canvas(MEDAL_PX, MEDAL_HALF)
    px = c.img.load()
    for yy in range(c.n):
        for xx in range(c.n):
            x = (xx - c.n / 2) / c.s
            y = (c.n / 2 - yy) / c.s
            r = math.hypot(x, y)
            if r < 29 or r > 40:
                continue
            k = max(0.0, 1 - (r - 30) / 9.5) if r >= 30 else 1.0
            px[xx, yy] = (255, 255, 255, round(255 * 0.62 * k ** 1.7))
    c.save("medal_glow")


def medal_rim():
    # Lyset i bronsen ved mus over (legges på med ADD): ringen mellom 27 og 31, sterkest oppe
    c = Canvas(MEDAL_PX, MEDAL_HALF)
    c.disc(0, 0, 31, WHITE)
    c.clear_disc(0, 0, 27)
    a = c.img.getchannel("A")
    fade = Image.linear_gradient("L").rotate(180).resize((c.n, c.n))  # 255 oppe, 0 nede
    fade = fade.point(lambda v: 110 + round(v * 145 / 255))
    c.img.putalpha(Image.composite(fade, Image.new("L", (c.n, c.n), 0), a))
    c.save("medal_rim")


# ---------------------------------------------------------------------------------------------- symbolene
SYM_PX, SYM_HALF = 64, 12  # 24 enheter
STROKE = 1.3


def sym_lock(open_):
    # Låsen er det høyeste symbolet (bøylen). 80 % størrelse og senket 0,35, så den holder seg innenfor
    # statusringen også når den vokser ved mus over (Daniel 5. okt: «passer ikke helt inn»). Streken er som de andre.
    c = Canvas(SYM_PX, SYM_HALF)
    k, dy = 0.8, -0.35

    def T(pts):
        return [(x * k, (y + dy) * k) for x, y in pts]

    w, h, by = 4.5, 3.5, -2.2
    c.poly(T([(-w, by - h), (w, by - h), (w, by + h), (-w, by + h), (-w, by - h)]), STROKE)
    lift = 1.6 if open_ else 0
    sx, top, r = 2.8, 5.6 + lift, 1.3
    right = (sx, top - 2.6) if open_ else (sx, by + h)
    c.poly(T([(-sx, by + h), (-sx, top - r), (-sx + r, top), (sx - r, top), (sx, top - r), right]), STROKE)
    c.disc(0, (by + dy) * k, 0.9 * k, WHITE)  # nøkkelhull
    c.save("sym_lock_open" if open_ else "sym_lock_closed")


def sym_menu():
    c = Canvas(SYM_PX, SYM_HALF)
    for y in (3.5, 0, -3.5):
        c.seg(-4.5, y, 4.5, y, STROKE)
    c.save("sym_menu")


def person(c, x, s):
    c.disc(x, 2.6 * s, 2.7 * s, WHITE)
    c.clear_disc(x, 2.6 * s, 2.7 * s - STROKE)
    pts = [(x + 4 * s * math.cos(math.pi * i / 12), -5.2 * s + 3.6 * s * math.sin(math.pi * i / 12)) for i in range(13)]
    c.poly(pts, STROKE)


def sym_one():
    c = Canvas(SYM_PX, SYM_HALF)
    person(c, 0, 1)
    c.save("sym_one")


def sym_two():
    c = Canvas(SYM_PX, SYM_HALF)
    person(c, 2.4, 0.78)
    c.clear_disc(-2.2, 2.6 * 0.78, 2.7 * 0.78)  # den fremste personen dekker den bakerste
    person(c, -2.2, 0.78)
    c.save("sym_two")


def sym_check():
    c = Canvas(SYM_PX, SYM_HALF)
    c.poly([(-7, 1), (-2, -5), (8, 6)], 3)
    c.save("sym_check")


def sym_move():
    c = Canvas(SYM_PX, SYM_HALF)
    ring = c.layer()
    ring.disc(0, 0, 11, WHITE)
    ring.clear_disc(0, 0, 9.5)
    c.over(ring, 0.45)
    c.seg(-7, 0, 7, 0, 1.6)
    c.seg(0, -7, 0, 7, 1.6)
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        tx, ty = 7 * dx, 7 * dy
        px, py = -dy * 2.5, dx * 2.5
        c.seg(tx, ty, tx - 2.5 * dx + px, ty - 2.5 * dy + py, 1.4)
        c.seg(tx, ty, tx - 2.5 * dx - px, ty - 2.5 * dy - py, 1.4)
    c.save("sym_move")


def disc_img():
    c = Canvas(SYM_PX, SYM_HALF)
    c.disc(0, 0, 12, WHITE)
    c.save("disc")


def soft_img():
    c = Canvas(SYM_PX, SYM_HALF)
    px = c.img.load()
    for yy in range(c.n):
        for xx in range(c.n):
            r = math.hypot(xx - c.n / 2, yy - c.n / 2) / (c.n / 2)
            if r < 1:
                px[xx, yy] = (255, 255, 255, round(255 * (1 - r) ** 2))
    c.save("soft")


def chevrons():
    for name, pts in (("chevron_h", [(2, -4), (-2, 0), (2, 4)]), ("chevron_v", [(-4, -2), (0, 2), (4, -2)])):
        c = Canvas(32, 6)  # 12 enheter
        c.poly(pts, 2)
        c.save(name)


def medal_arc():
    # Lysbuen langs ringen ved mus over (SPEC §7.1): myk bue på bronsekanten (r = 29), ±40°, peker mot høyre (0°).
    # Roteres i spillet mot sonen musa er i, farges lyst gull og legges på med ADD.
    c = Canvas(MEDAL_PX, MEDAL_HALF)
    px = c.img.load()
    for yy in range(c.n):
        for xx in range(c.n):
            x = (xx - c.n / 2) / c.s
            y = (c.n / 2 - yy) / c.s
            r = math.hypot(x, y)
            ang = abs(math.degrees(math.atan2(y, x)))
            if ang > 40 or abs(r - 29) > 6:
                continue
            a = math.exp(-((r - 29) / 2.0) ** 2) * math.cos(math.pi / 2 * ang / 40) ** 2
            px[xx, yy] = (255, 255, 255, round(255 * a))
    c.save("medal_arc")


def glow_btn():
    # Gløden rundt en knapp på 40 (Daniel 5. okt: de harde båndene så pikselerte ut): en lys kant rett innenfor
    # knappens kant og et mykt skinn utenfor. Bildet dekker 64 × 64 enheter, sentrert på knappen. Hvit, farges i spillet.
    px_size, half = 128, 32
    c = Canvas(px_size, half)
    px = c.img.load()
    B, R = 20.0, 1.5  # knappens halve side, hjørneradius
    for yy in range(c.n):
        for xx in range(c.n):
            x = abs((xx - c.n / 2) / c.s)
            y = abs((c.n / 2 - yy) / c.s)
            qx, qy = x - (B - R), y - (B - R)
            outside = math.hypot(max(qx, 0), max(qy, 0)) + min(max(qx, qy), 0) - R  # avstand til knappens kant
            # Tynn kant (Daniel: «trangt», strekene for tykke) og et skinn som stopper før neste knapp (6 unna)
            if -1.25 <= outside <= 0:
                a = 1.0
            elif 0 < outside <= 6:
                a = 0.5 * (1 - outside / 6) ** 2
            elif -1.75 < outside < -1.25:
                a = (outside + 1.75) / 0.5
            else:
                continue
            px[xx, yy] = (255, 255, 255, round(255 * a))
    c.save("glow_btn")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    medal_arc()
    glow_btn()
    medal_base()
    medal_ring()
    medal_glow()
    medal_rim()
    sym_lock(True)
    sym_lock(False)
    sym_menu()
    sym_one()
    sym_two()
    sym_check()
    sym_move()
    disc_img()
    soft_img()
    chevrons()
    print("ok:", ", ".join(sorted(f for f in os.listdir(OUT) if f.endswith(".tga"))))
