import os, math
import numpy as np
from PIL import Image, ImageDraw
from collections import deque

def extract_clean_sprite(raw_path):
    img = Image.open(raw_path).convert('RGB')
    w, h = img.size
    arr = np.array(img)

    is_white = (arr[:,:,0] > 230) & (arr[:,:,1] > 230) & (arr[:,:,2] > 230)
    visited = np.zeros((h, w), dtype=bool)
    q = deque()

    for x in range(w):
        if is_white[0, x]: q.append((0, x)); visited[0, x] = True
        if is_white[h-1, x]: q.append((h-1, x)); visited[h-1, x] = True
    for y in range(h):
        if is_white[y, 0]: q.append((y, 0)); visited[y, 0] = True
        if is_white[y, w-1]: q.append((y, w-1)); visited[y, w-1] = True

    while q:
        y, x = q.popleft()
        for dy, dx in [(-1,0), (1,0), (0,-1), (0,1)]:
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx] and is_white[ny, nx]:
                visited[ny, nx] = True
                q.append((ny, nx))

    alpha = np.where(visited, 0, 255).astype(np.uint8)
    rgba = np.dstack([arr, alpha])
    return Image.fromarray(rgba, 'RGBA')

def build_radar_dish_animation():
    raw_path = r'C:\Users\aakas\.gemini\antigravity-ide\brain\29613d14-c9d7-4e89-b64b-644c91b2da16\radar_dish_realistic_1792163097971.jpg'
    base_img = extract_clean_sprite(raw_path)
    w, h = base_img.size

    # Turntable joint is at cx=505, cy=565
    cx, cy = 505, 565

    upper_mask = Image.new('L', (w, h), 0)
    d_um = ImageDraw.Draw(upper_mask)
    d_um.rectangle([0, 0, w, 565], fill=255)

    upper_img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    upper_img.paste(base_img, (0, 0), upper_mask)

    lower_mask = Image.new('L', (w, h), 0)
    d_lm = ImageDraw.Draw(lower_mask)
    d_lm.rectangle([0, 565, w, h], fill=255)
    lower_img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    lower_img.paste(base_img, (0, 0), lower_mask)

    angles = [0.0, 3.0, 6.0, 2.0]
    frames = []

    for f_idx, ang in enumerate(angles):
        frame = Image.new('RGBA', (w, h), (0, 0, 0, 0))

        if abs(ang) > 0.01:
            rot_upper = upper_img.rotate(-ang, center=(cx, cy), resample=Image.Resampling.BICUBIC)
        else:
            rot_upper = upper_img.copy()

        frame.paste(lower_img, (0, 0), lower_img)
        frame.paste(rot_upper, (0, 0), rot_upper)

        draw = ImageDraw.Draw(frame, 'RGBA')

        # Feed horn probe position
        hx_base, hy_base = 610.0, 195.0
        rad_a = math.radians(-ang)
        dx_h = hx_base - cx
        dy_h = hy_base - cy
        hx = cx + dx_h * math.cos(rad_a) - dy_h * math.sin(rad_a)
        hy = cy + dx_h * math.sin(rad_a) + dy_h * math.cos(rad_a)

        # Transmission waves from horn (subtle cyan surveillance pings, NO red glow)
        if f_idx == 1:
            for w_r in [30, 55]:
                draw.arc([hx - w_r, hy - w_r, hx + w_r, hy + w_r], start=-60, end=40, fill=(0, 230, 255, int(150 - w_r * 2)), width=2)
            draw.circle((hx, hy), 4, fill=(180, 255, 255, 220))
        elif f_idx == 2:
            for w_r in [65, 95]:
                draw.arc([hx - w_r, hy - w_r, hx + w_r, hy + w_r], start=-70, end=30, fill=(0, 220, 255, int(120 - w_r)), width=2)
            draw.circle((hx, hy), 3, fill=(0, 240, 255, 180))
        elif f_idx == 3:
            draw.circle((hx, hy), 4, fill=(160, 255, 255, 200))
        else:
            draw.circle((hx, hy), 3, fill=(0, 230, 180, 180))

        # Pedestal indicator LEDs (subtle green/gray, NO red glow)
        if f_idx % 2 == 0:
            draw.circle((372, 892), 3, fill=(0, 255, 120, 230))
            draw.circle((372, 905), 3, fill=(180, 190, 200, 200))
        else:
            draw.circle((372, 892), 3, fill=(180, 190, 200, 200))
            draw.circle((372, 905), 3, fill=(0, 255, 120, 230))

        frames.append(frame)

    prop_size = 48
    strip_img = Image.new('RGBA', (prop_size * 4, prop_size), (0, 0, 0, 0))

    for idx, f in enumerate(frames):
        low = f.resize((prop_size, prop_size), Image.Resampling.LANCZOS)
        low.save(f'assets/bg_props/radar_dish_{idx}.png')
        strip_img.paste(low, (idx * prop_size, 0))
        print(f'Saved assets/bg_props/radar_dish_{idx}.png')

    strip_img.save('assets/bg_props/radar_dish_strip.png')
    print('Saved assets/bg_props/radar_dish_strip.png without red glow')

if __name__ == '__main__':
    build_radar_dish_animation()
