import os, math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

def create_lightning_branch(draw, start, end, segments=5, max_offset=8, core_col=(255, 255, 255, 255), glow_col=(0, 245, 255, 180), width=1):
    points = [start]
    dx = end[0] - start[0]
    dy = end[1] - start[1]
    dist = math.hypot(dx, dy)
    if dist < 2.0:
        return
    nx = -dy / dist
    ny = dx / dist
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
        draw.line([points[i], points[i+1]], fill=glow_col, width=width + 2)
    # Bright inner core
    for i in range(len(points) - 1):
        draw.line([points[i], points[i+1]], fill=core_col, width=width)

def render_alien_core_frame(size=256, frame=0):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, 'RGBA')
    cx, cy = size / 2.0, size / 2.0
    scale = size / 256.0
    
    np.random.seed(frame * 4242 + 77)

    # 1. External Base Mechanical Pedestal
    ped_w, ped_h = 138 * scale, 38 * scale
    ped_y = cy + 58 * scale
    # Outer dark chassis
    draw.polygon([
        (cx - ped_w * 0.44, ped_y),
        (cx + ped_w * 0.44, ped_y),
        (cx + ped_w * 0.55, ped_y + ped_h),
        (cx - ped_w * 0.55, ped_y + ped_h)
    ], fill=(16, 20, 26, 255))
    # Beveled inner plate
    draw.polygon([
        (cx - ped_w * 0.40, ped_y + 3 * scale),
        (cx + ped_w * 0.40, ped_y + 3 * scale),
        (cx + ped_w * 0.50, ped_y + ped_h - 3 * scale),
        (cx - ped_w * 0.50, ped_y + ped_h - 3 * scale)
    ], fill=(36, 42, 52, 255))
    # Top highlight bevel rim
    draw.line([
        (cx - ped_w * 0.40, ped_y + 3 * scale),
        (cx + ped_w * 0.40, ped_y + 3 * scale)
    ], fill=(90, 105, 125, 255), width=max(1, int(2 * scale)))
    
    # Yellow / Black Warning Chevrons on Pedestal
    chev_y = ped_y + 13 * scale
    for ch in range(-4, 5):
        chx = cx + ch * 14 * scale
        col_c = (245, 180, 20, 240) if ch % 2 == 0 else (18, 20, 24, 240)
        draw.polygon([
            (chx - 5 * scale, chev_y + 11 * scale),
            (chx + 3 * scale, chev_y),
            (chx + 9 * scale, chev_y),
            (chx + 1 * scale, chev_y + 11 * scale)
        ], fill=col_c)

    # Base Heavy Rivets
    for rx in [-55, -35, 35, 55]:
        draw.circle((cx + rx * scale, ped_y + ped_h - 7 * scale), 2.5 * scale, fill=(12, 14, 18, 255))
        draw.circle((cx + rx * scale, ped_y + ped_h - 7.5 * scale), 1.2 * scale, fill=(140, 155, 175, 255))

    # 2. Top Armored Exhaust Hub & Cooling Vent
    cap_w, cap_h = 108 * scale, 30 * scale
    cap_y = cy - 92 * scale
    draw.polygon([
        (cx - cap_w * 0.52, cap_y),
        (cx + cap_w * 0.52, cap_y),
        (cx + cap_w * 0.38, cap_y + cap_h),
        (cx - cap_w * 0.38, cap_y + cap_h)
    ], fill=(16, 20, 26, 255))
    draw.polygon([
        (cx - cap_w * 0.46, cap_y + 4 * scale),
        (cx + cap_w * 0.46, cap_y + 4 * scale),
        (cx + cap_w * 0.32, cap_y + cap_h - 3 * scale),
        (cx - cap_w * 0.32, cap_y + cap_h - 3 * scale)
    ], fill=(42, 48, 60, 255))
    draw.line([
        (cx - cap_w * 0.46, cap_y + 4 * scale),
        (cx + cap_w * 0.46, cap_y + 4 * scale)
    ], fill=(100, 115, 135, 255), width=max(1, int(2 * scale)))
    
    # Top exhaust vent grilles (animated heat/plasma emission)
    for vx in [-22, -11, 0, 11, 22]:
        draw.line([
            (cx + vx * scale, cap_y + 7 * scale),
            (cx + vx * scale, cap_y + cap_h - 7 * scale)
        ], fill=(12, 15, 20, 255), width=max(1, int(3.5 * scale)))
        vent_glow = (0, 230, 255, int(120 + 80 * math.sin(frame * 1.5 + vx)))
        draw.line([
            (cx + vx * scale, cap_y + 9 * scale),
            (cx + vx * scale, cap_y + cap_h - 9 * scale)
        ], fill=vent_glow, width=max(1, int(1.5 * scale)))

    # 3. Lateral Hydraulic Brackets & Capacitors
    pylon_rad = 82 * scale
    for side in [-1, 1]:
        px = cx + side * pylon_rad
        # Heavy hydraulic arms
        draw.line([(cx + side * 38 * scale, cap_y + cap_h - 2 * scale), (px, cy - 12 * scale)], fill=(20, 24, 32, 255), width=max(1, int(10 * scale)))
        draw.line([(cx + side * 38 * scale, cap_y + cap_h - 2 * scale), (px, cy - 12 * scale)], fill=(65, 75, 92, 255), width=max(1, int(5 * scale)))
        draw.line([(cx + side * 46 * scale, ped_y + 2 * scale), (px, cy + 12 * scale)], fill=(20, 24, 32, 255), width=max(1, int(10 * scale)))
        draw.line([(cx + side * 46 * scale, ped_y + 2 * scale), (px, cy + 12 * scale)], fill=(65, 75, 92, 255), width=max(1, int(5 * scale)))
        
        # Power terminal housing
        draw.ellipse([px - 14 * scale, cy - 18 * scale, px + 14 * scale, cy + 18 * scale], fill=(16, 20, 26, 255))
        draw.ellipse([px - 10 * scale, cy - 14 * scale, px + 10 * scale, cy + 14 * scale], fill=(45, 52, 65, 255))
        draw.line([(px - 8 * scale, cy - 12 * scale), (px + 8 * scale, cy - 12 * scale)], fill=(110, 125, 145, 255), width=max(1, int(2 * scale)))
        
        # High-voltage cyan capacitor eye with intense radial glow
        draw.circle((px, cy), 6.5 * scale, fill=(0, 160, 200, 120))
        draw.circle((px, cy), 4.5 * scale, fill=(0, 245, 255, 240))
        draw.circle((px, cy), 2.2 * scale, fill=(255, 255, 255, 255))

    # 4. Heavy Power Conduits / Bio-Synthetic Energy Cables
    for side in [-1, 1]:
        draw.line([
            (cx + side * 42 * scale, ped_y + ped_h * 0.45),
            (cx + side * 74 * scale, ped_y + ped_h * 0.45),
            (cx + side * (pylon_rad - 4 * scale), cy + 26 * scale)
        ], fill=(12, 16, 22, 255), width=max(1, int(5 * scale)))
        draw.line([
            (cx + side * 42 * scale, ped_y + ped_h * 0.45),
            (cx + side * 74 * scale, ped_y + ped_h * 0.45),
            (cx + side * (pylon_rad - 4 * scale), cy + 26 * scale)
        ], fill=(0, 220, 240, 200), width=max(1, int(2 * scale)))

    # 5. Reinforced Spherical Containment Chamber
    chamber_r = 65 * scale
    # Outer dark titanium rim
    draw.ellipse([cx - chamber_r - 5 * scale, cy - chamber_r - 5 * scale, cx + chamber_r + 5 * scale, cy + chamber_r + 5 * scale], fill=(10, 14, 18, 255))
    draw.ellipse([cx - chamber_r - 1 * scale, cy - chamber_r - 1 * scale, cx + chamber_r + 1 * scale, cy + chamber_r + 1 * scale], fill=(28, 34, 44, 255))
    # Inner dark oceanic glass basin
    draw.ellipse([cx - chamber_r, cy - chamber_r, cx + chamber_r, cy + chamber_r], fill=(6, 20, 30, 245))

    # 6. Dynamic Alien Bio-Plasma Core
    pulse_map = [1.0, 1.22, 1.42, 1.12]
    pulse = pulse_map[frame % 4]
    
    # Internal pulsating bio-organic tentacles / energy veins
    vein_col = (205, 30, 75, 195)
    for v in range(8):
        v_ang = v * (math.pi / 4.0) + frame * 0.35
        vx1 = cx + math.cos(v_ang) * 10 * scale
        vy1 = cy + math.sin(v_ang) * 10 * scale
        vx2 = cx + math.cos(v_ang + 0.28) * (chamber_r * 0.74)
        vy2 = cy + math.sin(v_ang + 0.28) * (chamber_r * 0.74)
        draw.line([(vx1, vy1), (vx2, vy2)], fill=vein_col, width=max(1, int(2.5 * scale)))

    # Ambient wide plasma aura
    draw.ellipse([cx - chamber_r * 0.88 * pulse, cy - chamber_r * 0.88 * pulse, cx + chamber_r * 0.88 * pulse, cy + chamber_r * 0.88 * pulse], fill=(0, 180, 220, 65))
    # Mid luminous cyan plasma sphere
    draw.ellipse([cx - 40 * scale * pulse, cy - 40 * scale * pulse, cx + 40 * scale * pulse, cy + 40 * scale * pulse], fill=(0, 240, 225, 175))
    # Hot bio-nucleus (vivid magenta / crimson heart)
    draw.ellipse([cx - 26 * scale * pulse, cy - 26 * scale * pulse, cx + 26 * scale * pulse, cy + 26 * scale * pulse], fill=(235, 35, 110, 225))
    draw.ellipse([cx - 16 * scale * pulse, cy - 16 * scale * pulse, cx + 16 * scale * pulse, cy + 16 * scale * pulse], fill=(255, 140, 190, 245))
    # Brilliant white singularity core
    draw.ellipse([cx - 8 * scale, cy - 8 * scale, cx + 8 * scale, cy + 8 * scale], fill=(255, 255, 255, 255))

    # Frame-specific energetic discharges
    if frame == 0:
        # Steady baseline humming with 4 diagonal electrostatic branches
        for a in [math.pi * 0.25, math.pi * 0.75, math.pi * 1.25, math.pi * 1.75]:
            tx = cx + math.cos(a) * chamber_r * 0.84
            ty = cy + math.sin(a) * chamber_r * 0.84
            create_lightning_branch(draw, (cx, cy), (tx, ty), segments=4, max_offset=5 * scale, width=max(1, int(1.2 * scale)))
            draw.circle((tx, ty), 3 * scale, fill=(200, 255, 255, 230))
    elif frame == 1:
        # Core pulse flare with glowing expansion ring and 6 branching arcs
        draw.ellipse([cx - chamber_r * 0.88, cy - chamber_r * 0.88, cx + chamber_r * 0.88, cy + chamber_r * 0.88], outline=(0, 245, 255, 210), width=max(1, int(2.5 * scale)))
        for a in [0.0, math.pi * 0.35, math.pi * 0.70, math.pi * 1.05, math.pi * 1.40, math.pi * 1.75]:
            tx = cx + math.cos(a + 0.15) * chamber_r * 0.86
            ty = cy + math.sin(a + 0.15) * chamber_r * 0.86
            create_lightning_branch(draw, (cx, cy), (tx, ty), segments=5, max_offset=7 * scale, width=max(1, int(1.5 * scale)))
            draw.circle((tx, ty), 3.5 * scale, fill=(230, 255, 255, 240))
    elif frame == 2:
        # Peak critical flux with bright lightning striking side capacitors and nodes
        draw.ellipse([cx - chamber_r * 0.94, cy - chamber_r * 0.94, cx + chamber_r * 0.94, cy + chamber_r * 0.94], outline=(255, 255, 255, 230), width=max(1, int(3.5 * scale)))
        targets = [
            (cx - pylon_rad, cy), (cx + pylon_rad, cy),
            (cx - 42 * scale, cy - 42 * scale), (cx + 42 * scale, cy - 42 * scale),
            (cx - 42 * scale, cy + 42 * scale), (cx + 42 * scale, cy + 42 * scale),
            (cx, cy - chamber_r * 0.85), (cx, cy + chamber_r * 0.85)
        ]
        for tx, ty in targets:
            create_lightning_branch(draw, (cx, cy), (tx, ty), segments=6, max_offset=10 * scale, core_col=(255, 255, 255, 255), glow_col=(0, 255, 235, 240), width=max(1, int(2 * scale)))
            draw.circle((tx, ty), 4.5 * scale, fill=(255, 255, 255, 255))
    elif frame == 3:
        # Swirling electromagnetic ion vortex & cooling rings
        ring_r = 46 * scale
        draw.arc([cx - ring_r, cy - ring_r, cx + ring_r, cy + ring_r], start=30, end=330, fill=(0, 245, 255, 220), width=max(1, int(3 * scale)))
        for a in [0.5, 2.1, 3.7, 5.3]:
            ox = cx + math.cos(a) * ring_r
            oy = cy + math.sin(a) * ring_r
            draw.circle((ox, oy), 4 * scale, fill=(255, 255, 255, 255))
        create_lightning_branch(draw, (cx, cy), (cx + math.cos(1.0) * chamber_r * 0.82, cy + math.sin(1.0) * chamber_r * 0.82), segments=4, max_offset=6 * scale)

    # 7. Front Specular Curved Glass Glare & Reflection
    draw.arc([cx - chamber_r * 0.82, cy - chamber_r * 0.82, cx + chamber_r * 0.82, cy + chamber_r * 0.82], start=125, end=215, fill=(255, 255, 255, 175), width=max(1, int(3.5 * scale)))
    draw.arc([cx - chamber_r * 0.74, cy - chamber_r * 0.74, cx + chamber_r * 0.74, cy + chamber_r * 0.74], start=135, end=205, fill=(255, 255, 255, 95), width=max(1, int(1.8 * scale)))

    return img

def main():
    os.makedirs('assets/bg_props', exist_ok=True)
    os.makedirs('assets/enemies', exist_ok=True)
    os.makedirs('scratch', exist_ok=True)

    # 1. Generate High-Res Enemy Sprite (256x256)
    enemy_sprite = render_alien_core_frame(size=256, frame=1)
    enemy_sprite.save('assets/enemies/alien_core.png')
    print('Saved assets/enemies/alien_core.png')

    # 2. Generate Animated Prop Frames (48x48) & Horizontal Strip (192x48)
    prop_frames = []
    prop_size = 48
    strip_img = Image.new('RGBA', (prop_size * 4, prop_size), (0, 0, 0, 0))
    
    for f in range(4):
        # Render at 192x192 and downsample with Lanczos for anti-aliasing pixel crispness
        hi = render_alien_core_frame(size=192, frame=f)
        frame_48 = hi.resize((prop_size, prop_size), Image.Resampling.LANCZOS)
        frame_48.save(f'assets/bg_props/alien_core_{f}.png')
        strip_img.paste(frame_48, (f * prop_size, 0))
        prop_frames.append(frame_48)
        print(f'Saved assets/bg_props/alien_core_{f}.png')

    strip_img.save('assets/bg_props/alien_core_strip.png')
    print('Saved assets/bg_props/alien_core_strip.png')

    # Save animated preview GIF in scratch
    gif_frames = [f.convert('RGBA') for f in prop_frames]
    gif_frames[0].save(
        'scratch/alien_core_anim.gif',
        save_all=True,
        append_images=gif_frames[1:],
        duration=250,
        loop=0,
        disposal=2
    )
    print('Saved scratch/alien_core_anim.gif')

if __name__ == '__main__':
    main()
