import os, math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from collections import deque

def extract_clean_sprite(raw_path):
    img = Image.open(raw_path).convert('RGB')
    w, h = img.size
    arr = np.array(img)

    # Floodfill transparent background from borders where pixels are near-white
    is_white = (arr[:,:,0] > 232) & (arr[:,:,1] > 232) & (arr[:,:,2] > 232)
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

def create_lightning(draw, start, end, segments=6, max_offset=14, core_col=(255, 255, 255, 255), glow_col=(0, 245, 255, 210), width=2):
    dx = end[0] - start[0]
    dy = end[1] - start[1]
    dist = math.hypot(dx, dy)
    if dist < 4.0:
        return
    nx = -dy / dist
    ny = dx / dist
    points = [start]
    for i in range(1, segments):
        t = i / float(segments)
        px = start[0] + dx * t
        py = start[1] + dy * t
        envelope = math.sin(t * math.pi)
        offset = np.random.uniform(-max_offset, max_offset) * envelope
        points.append((px + nx * offset, py + ny * offset))
    points.append(end)
    
    # Outer glow
    for i in range(len(points) - 1):
        draw.line([points[i], points[i+1]], fill=glow_col, width=width + 3)
    # Bright inner core
    for i in range(len(points) - 1):
        draw.line([points[i], points[i+1]], fill=core_col, width=width)

def generate_animated_frames(base_sprite):
    # Glass chamber bounding box
    # x: 338 .. 668, y: 320 .. 720, center: cx=503, cy=520
    cx, cy = 503, 520
    cw_half = 160
    ch_half = 195

    frames = []

    # Extract static background (metal frame) and the core chamber
    # To animate the plasma cleanly, we can composite dynamic plasma effects on top
    for f in range(4):
        np.random.seed(f * 9999 + 1337)
        frame_img = base_sprite.copy()
        draw = ImageDraw.Draw(frame_img, 'RGBA')

        # Frame parameters
        if f == 0:
            # FRAME 0: Steady Baseline Hum
            # Add subtle electrostatic arcs and a breathing aura
            pulse = 1.0
            # Central core flare
            draw.ellipse([cx - 35, cy - 35, cx + 35, cy + 35], fill=(0, 240, 255, 60))
            draw.ellipse([cx - 18, cy - 18, cx + 18, cy + 18], fill=(220, 255, 255, 120))
            draw.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=(255, 255, 255, 200))
            
            # 4 diagonal arcs
            targets = [(cx - 95, cy - 110), (cx + 90, cy - 115), (cx - 100, cy + 110), (cx + 95, cy + 115)]
            for tx, ty in targets:
                create_lightning(draw, (cx, cy), (tx, ty), segments=5, max_offset=10, width=2)
                draw.circle((tx, ty), 4, fill=(200, 255, 255, 220))

        elif f == 1:
            # FRAME 1: Energy Surge & Expansion
            # Plasma expansion ring and brightened tendrils
            pulse = 1.18
            draw.ellipse([cx - 85, cy - 85, cx + 85, cy + 85], outline=(0, 245, 255, 160), width=3)
            draw.ellipse([cx - 55, cy - 55, cx + 55, cy + 55], fill=(0, 230, 255, 90))
            draw.ellipse([cx - 30, cy - 30, cx + 30, cy + 30], fill=(240, 60, 140, 140))
            draw.ellipse([cx - 16, cy - 16, cx + 16, cy + 16], fill=(255, 255, 255, 240))

            # 6 energetic arcs
            targets = [
                (cx - 120, cy - 60), (cx + 120, cy - 60),
                (cx - 110, cy + 70), (cx + 110, cy + 70),
                (cx, cy - 145), (cx, cy + 145)
            ]
            for tx, ty in targets:
                create_lightning(draw, (cx, cy), (tx, ty), segments=6, max_offset=14, width=3)
                draw.circle((tx, ty), 5, fill=(255, 255, 255, 240))

        elif f == 2:
            # FRAME 2: Critical Peak Discharge
            # Incandescent bloom + massive branching lightning striking the walls and clamps
            pulse = 1.35
            draw.ellipse([cx - 130, cy - 130, cx + 130, cy + 130], fill=(0, 210, 255, 75))
            draw.ellipse([cx - 75, cy - 75, cx + 75, cy + 75], fill=(0, 245, 235, 140))
            draw.ellipse([cx - 42, cy - 42, cx + 42, cy + 42], fill=(255, 40, 120, 210))
            draw.ellipse([cx - 24, cy - 24, cx + 24, cy + 24], fill=(255, 255, 255, 255))
            draw.ellipse([cx - 140, cy - 140, cx + 140, cy + 140], outline=(255, 255, 255, 220), width=4)

            # 8 intense lightning bolts striking metal clamps
            targets = [
                (cx - 135, cy - 100), (cx + 135, cy - 100),
                (cx - 135, cy + 100), (cx + 135, cy + 100),
                (cx - 65, cy - 155), (cx + 65, cy - 155),
                (cx - 65, cy + 155), (cx + 65, cy + 155)
            ]
            for tx, ty in targets:
                create_lightning(draw, (cx, cy), (tx, ty), segments=7, max_offset=18, core_col=(255, 255, 255, 255), glow_col=(0, 255, 240, 255), width=3)
                draw.circle((tx, ty), 6, fill=(255, 255, 255, 255))

            # Indicator lights flash critical warning
            # Top sensor pods (left: 260, 60; right: 750, 60)
            draw.circle((255, 75), 8, fill=(0, 255, 255, 240))
            draw.circle((750, 75), 8, fill=(255, 50, 50, 240))

        elif f == 3:
            # FRAME 3: Electromagnetic Vortex Recharge
            # Swirling ion ring + cooling plasma contraction
            pulse = 0.95
            orbit_r = 90
            draw.arc([cx - orbit_r, cy - orbit_r, cx + orbit_r, cy + orbit_r], start=45, end=315, fill=(0, 245, 255, 220), width=3)
            for a in [0.4, 2.0, 3.6, 5.2]:
                ox = cx + math.cos(a) * orbit_r
                oy = cy + math.sin(a) * orbit_r
                draw.circle((ox, oy), 6, fill=(255, 255, 255, 255))

            draw.ellipse([cx - 45, cy - 45, cx + 45, cy + 45], fill=(0, 220, 245, 90))
            draw.ellipse([cx - 22, cy - 22, cx + 22, cy + 22], fill=(255, 100, 160, 170))
            draw.ellipse([cx - 10, cy - 10, cx + 10, cy + 10], fill=(255, 255, 255, 240))

            targets = [(cx - 70, cy + 95), (cx + 80, cy - 85)]
            for tx, ty in targets:
                create_lightning(draw, (cx, cy), (tx, ty), segments=5, max_offset=10, width=2)

        # Glass Specular curved reflection highlight
        draw.line([(355, 340), (355, 700)], fill=(255, 255, 255, 80), width=5)
        draw.line([(365, 350), (365, 690)], fill=(255, 255, 255, 45), width=3)

        frames.append(frame_img)

    return frames

def main():
    raw_path = r'C:\Users\aakas\.gemini\antigravity-ide\brain\29613d14-c9d7-4e89-b64b-644c91b2da16\alien_core_realistic_1792162143342.jpg'
    print('Extracting clean sprite...')
    clean_sprite = extract_clean_sprite(raw_path)
    
    # Save main enemy sprite (scaled to crisp 512x512 for optimal in-engine performance and pixel density)
    enemy_img = clean_sprite.resize((512, 512), Image.Resampling.LANCZOS)
    enemy_img.save('assets/enemies/alien_core.png')
    print('Saved assets/enemies/alien_core.png (512x512)')

    # Generate 4 animated frames
    print('Generating animated frames...')
    anim_frames = generate_animated_frames(clean_sprite)

    # Prop frames (48x48) & strip (192x48)
    prop_size = 48
    strip_img = Image.new('RGBA', (prop_size * 4, prop_size), (0, 0, 0, 0))
    low_frames = []

    for idx, f_img in enumerate(anim_frames):
        # Downsample with Lanczos
        low = f_img.resize((prop_size, prop_size), Image.Resampling.LANCZOS)
        low.save(f'assets/bg_props/alien_core_{idx}.png')
        strip_img.paste(low, (idx * prop_size, 0))
        low_frames.append(low)
        print(f'Saved assets/bg_props/alien_core_{idx}.png')

    strip_img.save('assets/bg_props/alien_core_strip.png')
    print('Saved assets/bg_props/alien_core_strip.png')

    # Save animated GIF preview
    gif_frames = [f.convert('RGBA') for f in anim_frames]
    # Downscale gif to 256x256 for fast viewing
    gif_frames_scaled = [f.resize((256, 256), Image.Resampling.LANCZOS) for f in gif_frames]
    gif_frames_scaled[0].save(
        'scratch/alien_core_realistic_anim.gif',
        save_all=True,
        append_images=gif_frames_scaled[1:],
        duration=220,
        loop=0,
        disposal=2
    )
    print('Saved scratch/alien_core_realistic_anim.gif')

if __name__ == '__main__':
    main()
