# VoxOS - generator tapety motywu "dot" (python3 + numpy + pillow)
# Użycie: python3 generate-wallpaper.py  -> wallpaper.jpg w bieżącym folderze
# Czarne tło, siatka kropek, półtonowa kula z kropek i jedna czerwona kropka.
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFont

W, H = 3840, 2160
SS = 2                      # supersampling dla gładkich kropek
STEP = 30                   # odstęp siatki (px w docelowej rozdzielczości)
RED = (215, 25, 33)
HERE = os.path.dirname(os.path.abspath(__file__))
FONT = os.path.join(HERE, "..", "..", "dotfiles", "fonts", ".local", "share", "fonts", "voxos", "VoxDot-Bold.ttf")

img = Image.new("RGB", (W*SS, H*SS), (0, 0, 0))
d = ImageDraw.Draw(img)

# Kula: środek i promień, światło z lewej góry
cx, cy, R = W*0.66, H*0.47, H*0.36
light = np.array([-0.55, -0.6, 0.58]); light /= np.linalg.norm(light)

for gy in range(STEP//2, H, STEP):
    for gx in range(STEP//2, W, STEP):
        dx, dy = (gx-cx)/R, (gy-cy)/R
        r2 = dx*dx + dy*dy
        if r2 < 1:
            nz = np.sqrt(1-r2)
            shade = max(0.0, float(np.dot([dx, dy, nz], light)))
            shade = 0.12 + 0.88*shade**1.4
            rad = 2.0 + 9.5*shade
            v = int(70 + 185*shade)
            col = (v, v, v)
        else:
            # tło: drobna siatka, delikatnie jaśniejsza blisko kuli (poświata)
            glow = max(0.0, 1 - (np.sqrt(r2)-1)/1.2)
            rad = 1.6 + 0.6*glow
            v = int(26 + 22*glow)
            col = (v, v, v)
        x, y, r = gx*SS, gy*SS, rad*SS
        d.ellipse((x-r, y-r, x+r, y+r), fill=col)

# Czerwony akcent: jedna kropka na orbicie kuli
ax, ay, ar = cx + R*1.18*np.cos(-0.72), cy + R*1.18*np.sin(-0.72), 14
ax, ay = round(ax/STEP)*STEP + STEP/2 - STEP, round(ay/STEP)*STEP + STEP/2
d.ellipse(((ax-ar)*SS, (ay-ar)*SS, (ax+ar)*SS, (ay+ar)*SS), fill=RED)

# Podpis kropkami w lewym dolnym rogu
font = ImageFont.truetype(FONT, 64*SS)
d.text((150*SS, (H-150)*SS), "voxos", font=font, fill=(90, 90, 90), anchor="ls")
x1 = d.textbbox((150*SS, (H-150)*SS), "voxos", font=font, anchor="ls")[2]
r = 7*SS
d.ellipse((x1 + 6*SS, (H-150)*SS - 2*r, x1 + 6*SS + 2*r, (H-150)*SS), fill=RED)

img = img.resize((W, H), Image.LANCZOS)
img.save("wallpaper.jpg", quality=92, subsampling=0)
img.resize((960, 540), Image.LANCZOS).save("preview.png")
