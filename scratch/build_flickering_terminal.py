import os, math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

def draw_radar_wedge(draw, cx, cy, radius, start_deg, sweep_deg=45, color=(0, 255, 120, 160)):
    # Draw a smooth sweeping radar wedge with falloff
    steps = 15
    for s in range(steps):
        t = s / float(steps)
        deg = start_deg - (1.0 - t) * sweep_deg
        rad = math.radians(deg)
        alpha = int(color[3] * (t ** 1.8))
        col = (color[0], color[1], color[2], alpha)
        px = cx + math.cos(rad) * radius
        py = cy + math.sin(rad) * radius
        draw.line([(cx, cy), (px, py)], fill=col, width=3)
    # Bright leading edge
    lead_rad = math.radians(start_deg)
    lx = cx + math.cos(lead_rad) * radius
    ly = cy + math.sin(lead_rad) * radius
    draw.line([(cx, cy), (lx, ly)], fill=(200, 255, 220, 240), width=2)

def build_terminal_animation():
    extracted_path = 'scratch/extracted_terminal.png'
    base_img = Image.open(extracted_path).convert('RGBA')
    w, h = base_img.size

    # CRT Screen boundaries
    # x: 365 .. 760, y: 150 .. 585
    # Radar center: cx=532, cy=286, radius=80
    rcx, rcy = 532, 286
    r_radius = 80

    frames = []

    for f in range(4):
        np.random.seed(f * 7777 + 42)
        frame = base_img.copy()
        draw = ImageDraw.Draw(frame, 'RGBA')

        # Radar sweep angle
        # Frame 0: -45° (top-right)
        # Frame 1: 45° (bottom-right)
        # Frame 2: 135° (bottom-left)
        # Frame 3: 225° (top-left)
        angles = [-45, 45, 135, 225]
        curr_ang = angles[f]

        # 1. Draw radar sweep beam
        draw_radar_wedge(draw, rcx, rcy, r_radius, curr_ang, sweep_deg=50, color=(0, 255, 110, 150))

        # 2. Dynamic Target Blips on Radar
        if f == 0:
            # Steady locked target (amber blip)
            bx, by = rcx + 22, rcy + 24
            draw.circle((bx, by), 4, fill=(255, 100, 40, 230))
            draw.circle((bx, by), 2, fill=(255, 255, 180, 255))
        elif f == 1:
            # Expanding ping radar wave from target
            bx, by = rcx + 22, rcy + 24
            draw.ellipse([bx - 10, by - 10, bx + 10, by + 10], outline=(255, 180, 40, 180), width=2)
            draw.circle((bx, by), 5, fill=(255, 140, 30, 255))
            draw.circle((bx, by), 2.5, fill=(255, 255, 220, 255))
        elif f == 2:
            # Target alert acquired with yellow tracking box
            bx, by = rcx + 22, rcy + 24
            draw.rectangle([bx - 8, by - 8, bx + 8, by + 8], outline=(255, 235, 30, 220), width=2)
            draw.line([(bx - 12, by), (bx + 12, by)], fill=(255, 235, 30, 180), width=1)
            draw.line([(bx, by - 12), (bx, by + 12)], fill=(255, 235, 30, 180), width=1)
            draw.circle((bx, by), 3, fill=(255, 60, 40, 240))
            # Secondary blip appears on sweep
            b2x, b2y = rcx - 45, rcy + 35
            draw.circle((b2x, b2y), 4, fill=(0, 255, 200, 230))
        elif f == 3:
            # Residual target glow & secondary contact confirmed
            bx, by = rcx + 22, rcy + 24
            draw.circle((bx, by), 4, fill=(255, 120, 40, 200))
            b2x, b2y = rcx - 45, rcy + 35
            draw.circle((b2x, b2y), 3, fill=(0, 255, 180, 190))

        # 3. Screen Glitch / Scanline Flicker
        if f == 2:
            # Glitch frame: Horizontal static interference lines across CRT screen
            for g in range(8):
                gy = np.random.randint(165, 570)
                gh = np.random.randint(2, 6)
                gx1 = np.random.randint(375, 420)
                gx2 = np.random.randint(710, 755)
                # Chromatic noise line
                draw.rectangle([gx1, gy, gx2, gy + gh], fill=(0, 255, 180, 130))
                draw.line([(gx1, gy), (gx2, gy)], fill=(255, 255, 255, 190), width=1)
            
            # CRT horizontal scan-roll beam
            draw.rectangle([375, 340, 750, 360], fill=(0, 255, 140, 45))
            
            # Warning LED blinks red on top sensor bezel
            draw.circle((665, 435), 5, fill=(255, 40, 30, 240))
        else:
            # Subtle rolling CRT scanline in other frames
            roll_y = 180 + f * 95
            draw.rectangle([375, roll_y, 750, roll_y + 16], fill=(0, 255, 140, 25))

        # 4. Control Deck Animated Backlit Keys & LEDs
        # Keys region: y=470..590, x=380..760
        # Button matrix lights shift
        if f % 2 == 1:
            draw.rectangle([390, 502, 420, 514], fill=(0, 255, 160, 200))
            draw.rectangle([455, 502, 485, 514], fill=(255, 190, 30, 220))
            draw.circle((705, 470), 4, fill=(0, 255, 120, 230))
        else:
            draw.rectangle([425, 502, 450, 514], fill=(0, 255, 160, 200))
            draw.rectangle([490, 502, 520, 514], fill=(255, 80, 40, 220))
            draw.circle((725, 470), 4, fill=(255, 160, 20, 230))

        # 5. CRT Phosphor Screen Glow Atmosphere
        # Subtle vignette / screen glare
        draw.line([(385, 165), (385, 560)], fill=(255, 255, 255, 35), width=3)
        draw.line([(392, 175), (392, 550)], fill=(255, 255, 255, 18), width=2)

        frames.append(frame)

    return frames

def main():
    print('Generating animated terminal frames...')
    frames = build_terminal_animation()

    prop_size = 48
    strip_img = Image.new('RGBA', (prop_size * 4, prop_size), (0, 0, 0, 0))
    low_frames = []

    for idx, f_img in enumerate(frames):
        # Resize to 48x48 with high quality Lanczos filter
        low = f_img.resize((prop_size, prop_size), Image.Resampling.LANCZOS)
        low.save(f'assets/bg_props/flickering_terminal_{idx}.png')
        strip_img.paste(low, (idx * prop_size, 0))
        low_frames.append(low)
        print(f'Saved assets/bg_props/flickering_terminal_{idx}.png')

    strip_img.save('assets/bg_props/flickering_terminal_strip.png')
    print('Saved assets/bg_props/flickering_terminal_strip.png')

    # Save animated GIF preview
    gif_scaled = [f.resize((256, 256), Image.Resampling.LANCZOS) for f in frames]
    gif_scaled[0].save(
        'scratch/flickering_terminal_anim.gif',
        save_all=True,
        append_images=gif_scaled[1:],
        duration=220,
        loop=0,
        disposal=2
    )
    print('Saved scratch/flickering_terminal_anim.gif')

if __name__ == '__main__':
    main()
