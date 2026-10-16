import os, math
import numpy as np
from PIL import Image, ImageDraw

def test_rotation():
    img = Image.open('scratch/extracted_fan.png').convert('RGBA')
    cx, cy = 600, 420
    r = 265

    # 1. Extract circular rotor region
    # Mask for inner circular opening
    mask = Image.new('L', (r * 2, r * 2), 0)
    d_mask = ImageDraw.Draw(mask)
    d_mask.ellipse([0, 0, r * 2, r * 2], fill=255)

    rotor_crop = img.crop((cx - r, cy - r, cx + r, cy + r))

    # Also extract front hub cone (radius ~65)
    hub_r = 65
    hub_crop = img.crop((cx - hub_r, cy - hub_r, cx + hub_r, cy + hub_r))
    hub_mask = Image.new('L', (hub_r * 2, hub_r * 2), 0)
    d_hub = ImageDraw.Draw(hub_mask)
    d_hub.ellipse([0, 0, hub_r * 2, hub_r * 2], fill=255)

    # Wire grid and radial struts parameters
    # Strut angles: 0, 45, 90, 135, 180, 225, 270, 315
    strut_angles = [0, 45, 90, 135, 180, 225, 270, 315]

    frames = []
    # 5 blades => 72 deg cycle => 4 frames: 0, 18, 36, 54 deg
    angles = [0, 18, 36, 54]

    for f_idx, ang in enumerate(angles):
        f_img = img.copy()
        
        # Rotate rotor crop
        # When rotating, use bicubic filter
        rot_rotor = rotor_crop.rotate(-ang, resample=Image.Resampling.BICUBIC)
        
        # Composite back onto image within circular mask
        f_img.paste(rot_rotor, (cx - r, cy - r), mask)

        # Draw front wire cage grid overlay
        draw = ImageDraw.Draw(f_img, 'RGBA')
        
        # 1. Wire grid lines (subtle dark steel)
        wire_col = (45, 52, 60, 210)
        wire_hl = (110, 125, 140, 150)
        
        # Vertical grid wires
        for gx in range(cx - 240, cx + 250, 42):
            if abs(gx - cx) < r:
                h_span = math.sqrt(max(0, r**2 - (gx - cx)**2))
                y1 = cy - h_span
                y2 = cy + h_span
                draw.line([(gx, y1), (gx, y2)], fill=wire_col, width=2)
                draw.line([(gx + 1, y1), (gx + 1, y2)], fill=wire_hl, width=1)

        # Horizontal grid wires
        for gy in range(cy - 240, cy + 250, 42):
            if abs(gy - cy) < r:
                w_span = math.sqrt(max(0, r**2 - (gy - cy)**2))
                x1 = cx - w_span
                x2 = cx + w_span
                draw.line([(x1, gy), (x2, gy)], fill=wire_col, width=2)
                draw.line([(x1, gy + 1), (x2, gy + 1)], fill=wire_hl, width=1)

        # Heavy radial structural struts
        strut_col = (28, 34, 42, 255)
        strut_hl = (120, 135, 155, 220)
        for sa in strut_angles:
            s_rad = math.radians(sa)
            sx = cx + math.cos(s_rad) * r
            sy = cy + math.sin(s_rad) * r
            draw.line([(cx, cy), (sx, sy)], fill=strut_col, width=5)
            draw.line([(cx, cy), (sx, sy)], fill=strut_hl, width=2)

        # Re-paste static center spinner hub over the strut intersection
        f_img.paste(hub_crop, (cx - hub_r, cy - hub_r), hub_mask)

        # Subtle high-speed motion blur wind arcs on blades
        for a_arc in range(5):
            arc_base = (a_arc * 72 + ang * 1.5) % 360
            draw.arc([cx - r * 0.75, cy - r * 0.75, cx + r * 0.75, cy + r * 0.75], start=arc_base, end=arc_base + 35, fill=(200, 220, 240, 45), width=4)

        frames.append(f_img)

    # Save preview gif
    gif_scaled = [f.resize((256, 256), Image.Resampling.LANCZOS) for f in frames]
    gif_scaled[0].save(
        'scratch/test_fan_spin.gif',
        save_all=True,
        append_images=gif_scaled[1:],
        duration=70,
        loop=0,
        disposal=2
    )
    print('Saved scratch/test_fan_spin.gif')

if __name__ == '__main__':
    test_rotation()
