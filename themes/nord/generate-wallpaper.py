# VoxOS - generator tapety w palecie Nord (python3 + numpy + pillow)
# Użycie: python3 generate-wallpaper.py  -> voxos-nord.jpg (zmień nazwę na wallpaper.jpg)
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
W, H = 3840, 2160
rng = np.random.default_rng(1030)
def hx(h): h=h.lstrip('#'); return np.array([int(h[i:i+2],16) for i in (0,2,4)], float)
nord = {i: hx(c) for i, c in enumerate("2E3440 3B4252 434C5E 4C566A D8DEE9 E5E9F0 ECEFF4 8FBCBB 88C0D0 81A1C1 5E81AC BF616A D08770 EBCB8B A3BE8C B48EAD".split())}

# Niebo: gradient od polarnej nocy do lekko rozjaśnionego horyzontu
y = np.linspace(0, 1, H)[:, None]
top, mid, hor = nord[0]*0.82, nord[1], nord[2]*0.9 + nord[10]*0.1
t1 = np.clip(y/0.55, 0, 1); t2 = np.clip((y-0.55)/0.3, 0, 1)
sky = (top*(1-t1) + mid*t1)[:, None, :] * np.ones((1, W, 1))
sky = sky*(1-t2[:, :, None]) + hor*t2[:, :, None]
img = sky.copy()

# Zorza: miękkie, falujące pasy w kolorach Frost i zieleni
aur = np.zeros((H, W, 3))
xs = np.linspace(0, 1, W)
for color, base, amp, freq, phase, width, alpha in [
    (nord[7], 0.30, 0.06, 1.3, 0.2, 0.040, 0.55),
    (nord[8], 0.25, 0.05, 1.9, 1.7, 0.030, 0.45),
    (nord[14], 0.35, 0.04, 1.1, 3.1, 0.035, 0.30),
    (nord[9], 0.21, 0.03, 2.6, 0.9, 0.020, 0.35),
]:
    center = base + amp*np.sin(2*np.pi*freq*xs + phase) + 0.015*np.sin(2*np.pi*7*xs + phase*2)
    fade = np.clip(np.sin(np.pi*np.clip((xs-0.05)/0.9, 0, 1)), 0, 1)**1.5
    d = (y - center[None, :]) / width
    band = np.exp(-np.where(d < 0, d*d*0.35, d*d*2.2))  # dłuższy ogon w górę
    rays = np.ones_like(xs)
    for _ in range(6):
        rays += rng.uniform(0.03, 0.08)*np.sin(2*np.pi*rng.uniform(8, 45)*xs + rng.uniform(0, 6))
    rays = rays[None, :]
    aur += (band*fade[None, :]*rays*alpha)[:, :, None] * color[None, None, :]
img = img + aur*0.55

# Gwiazdy w górnej części nieba
for _ in range(900):
    sx, sy = rng.integers(0, W), int(rng.beta(1.2, 3.5)*H*0.6)
    b = rng.uniform(0.15, 0.6); r = 1 if rng.random() < 0.85 else 2
    img[max(0,sy-r):sy+r, max(0,sx-r):sx+r] = img[max(0,sy-r):sy+r, max(0,sx-r):sx+r]*(1-b) + nord[6]*b

# Grzbiety górskie (przesunięcie punktu środkowego), od najdalszego do najbliższego
def ridge(n, rough, seed):
    r = np.random.default_rng(seed); pts = np.zeros(2**n+1); pts[0], pts[-1] = r.uniform(-1,1,2)
    step, scale = 2**n, 1.0
    while step > 1:
        half = step//2
        for i in range(half, 2**n, step):
            pts[i] = (pts[i-half]+pts[i+half])/2 + r.uniform(-1,1)*scale
        step, scale = half, scale*rough
    return np.interp(np.linspace(0, 2**n, W), np.arange(2**n+1), pts)
layers = [  # (wysokość bazowa, amplituda, kolor, chropowatość)
    (0.60, 0.12, nord[3]*0.80 + nord[9]*0.20, 0.58),
    (0.68, 0.13, nord[3]*0.85 + nord[2]*0.15, 0.56),
    (0.76, 0.12, nord[2]*0.75 + nord[1]*0.25, 0.54),
    (0.84, 0.11, nord[1]*0.70 + nord[0]*0.30, 0.52),
    (0.93, 0.08, nord[0]*0.78, 0.50),
]
rows = np.arange(H)[:, None]
for k, (base, amp, col, rough) in enumerate(layers):
    h = (base - amp*ridge(10, rough, 40+k)) * H
    mask = rows >= h[None, :]
    # lekka mgiełka u podnóża warstwy
    depth = np.clip((rows - h[None, :]) / (H*0.12), 0, 1)
    shade = col[None, None, :]*(1 - 0.10*depth[:, :, None]) + nord[10][None, None, :]*0.04*(1-depth[:, :, None])
    img = np.where(mask[:, :, None], shade, img)
    rim = np.clip(1 - np.abs(rows - h[None, :] - 2) / 3.0, 0, 1) * (0.22 - 0.04*k)
    img = img*(1 - rim[:, :, None]) + nord[8][None, None, :]*rim[:, :, None]

# Delikatny dithering przeciw pasmom w gradiencie
img += rng.normal(0, 0.9, img.shape)
out = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))

# Podpis
d = ImageDraw.Draw(out)
font = ImageFont.truetype("/usr/share/fonts/opentype/inter/Inter-Light.otf", 46)
d.text((W-90, H-80), "voxos", font=font, fill=tuple(int(v) for v in nord[3]), anchor="rs")
out.save("voxos-nord.jpg", quality=93, subsampling=0)
out.resize((960, 540), Image.LANCZOS).save("preview.png")
