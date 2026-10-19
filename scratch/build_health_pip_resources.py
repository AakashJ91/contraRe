import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

def create_health_pip(state: str, width=24, height=32):
    # State: 'full', 'warning', 'critical', 'empty'
    # Create high-detail 4x supersampled canvas for ultra-crisp anti-aliased pixel rendering
    scale = 4
    sw = width * scale
    sh = height * scale
    img = Image.new('RGBA', (sw, sh), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, 'RGBA')

    # Color definitions
    c_outer_border = (18, 26, 38, 255)
    c_metal_cap_top = (110, 140, 175, 255)
    c_metal_cap_mid = (65, 85, 115, 255)
    c_metal_cap_bot = (35, 48, 68, 255)
    c_glass_bg = (10, 15, 24, 235)

    pad_x = 2 * scale
    pad_y = 2 * scale
    pw = sw - pad_x * 2
    ph = sh - pad_y * 2

    # 1. Outer Dark Chassis Housing with rounded corners
    corner_r = 3 * scale
    draw.rounded_rectangle([pad_x, pad_y, pad_x + pw, pad_y + ph], radius=corner_r, fill=c_outer_border)

    # 2. Top and Bottom Metallic Terminal Contacts (Caps)
    cap_h = 5 * scale
    # Top Cap
    draw.rounded_rectangle([pad_x + 2 * scale, pad_y + 1 * scale, pad_x + pw - 2 * scale, pad_y + cap_h],
                           radius=2 * scale, fill=c_metal_cap_mid)
    draw.line([pad_x + 3 * scale, pad_y + 2 * scale, pad_x + pw - 3 * scale, pad_y + 2 * scale],
              fill=c_metal_cap_top, width=scale)
    
    # Bottom Cap
    draw.rounded_rectangle([pad_x + 2 * scale, pad_y + ph - cap_h, pad_x + pw - 2 * scale, pad_y + ph - 1 * scale],
                           radius=2 * scale, fill=c_metal_cap_bot)
    draw.line([pad_x + 3 * scale, pad_y + ph - 2 * scale, pad_x + pw - 3 * scale, pad_y + ph - 2 * scale],
              fill=(20, 28, 40, 255), width=scale)

    # 3. Inner Glass Reservoir Chamber
    glass_top = pad_y + cap_h + 1 * scale
    glass_bot = pad_y + ph - cap_h - 1 * scale
    glass_left = pad_x + 2 * scale
    glass_right = pad_x + pw - 2 * scale
    gw = glass_right - glass_left
    gh = glass_bot - glass_top

    draw.rectangle([glass_left, glass_top, glass_right, glass_bot], fill=c_glass_bg)

    # 4. Fill according to state
    if state == 'full':
        # Radiant Bio-Nanotech Green
        core_center = (45, 255, 120, 255)
        core_mid = (20, 205, 75, 255)
        core_edge = (8, 130, 45, 255)
        glow_col = (100, 255, 160, 180)
        highlight_col = (210, 255, 230, 230)
    elif state == 'warning':
        # Solar Charged Amber / Gold
        core_center = (255, 215, 35, 255)
        core_mid = (255, 160, 15, 255)
        core_edge = (195, 95, 5, 255)
        glow_col = (255, 230, 120, 180)
        highlight_col = (255, 250, 200, 230)
    elif state == 'critical':
        # High-Voltage Danger Crimson
        core_center = (255, 50, 50, 255)
        core_mid = (220, 18, 25, 255)
        core_edge = (145, 8, 12, 255)
        glow_col = (255, 130, 130, 180)
        highlight_col = (255, 210, 210, 230)
    else: # 'empty'
        core_center = None

    if core_center is not None:
        # Plasma core fill
        margin_x = 1 * scale
        margin_y = 1 * scale
        cw = gw - margin_x * 2
        ch = gh - margin_y * 2
        cx0 = glass_left + margin_x
        cy0 = glass_top + margin_y

        # Gradient layers across horizontal width
        for x in range(cw):
            t = abs((x / float(cw - 1)) - 0.5) * 2.0  # 0 at center, 1 at edge
            r = int(core_center[0] * (1.0 - t) + core_edge[0] * t)
            g = int(core_center[1] * (1.0 - t) + core_edge[1] * t)
            b = int(core_center[2] * (1.0 - t) + core_edge[2] * t)
            draw.line([cx0 + x, cy0, cx0 + x, cy0 + ch], fill=(r, g, b, 255), width=1)

        # Top liquid meniscus / energy wave highlight
        draw.line([cx0, cy0, cx0 + cw, cy0], fill=highlight_col, width=scale)
        draw.line([cx0 + 1 * scale, cy0 + 1 * scale, cx0 + cw - 1 * scale, cy0 + 1 * scale], fill=glow_col, width=scale)

        # Bottom reflection tick
        draw.line([cx0 + 2 * scale, cy0 + ch - 1 * scale, cx0 + cw - 2 * scale, cy0 + ch - 1 * scale],
                  fill=core_mid, width=scale)
    else:
        # Empty chamber: inert cathode filament and dark glass grid
        mid_x = (glass_left + glass_right) // 2
        draw.line([mid_x, glass_top + 2 * scale, mid_x, glass_bot - 2 * scale], fill=(42, 60, 85, 200), width=scale)
        # 2 subtle tick marks
        draw.line([glass_left + 2 * scale, glass_top + gh // 3, glass_right - 2 * scale, glass_top + gh // 3],
                  fill=(30, 42, 60, 140), width=1)
        draw.line([glass_left + 2 * scale, glass_top + (gh * 2) // 3, glass_right - 2 * scale, glass_top + (gh * 2) // 3],
                  fill=(30, 42, 60, 140), width=1)

    # 5. Glossy Cylindrical Specular Glare (Glass reflection down left quadrant)
    glare_x = glass_left + 1 * scale
    draw.line([glare_x, glass_top + 2 * scale, glare_x, glass_bot - 2 * scale],
              fill=(255, 255, 255, 110), width=scale)

    # 6. Outer Bevel Highlight & Shadow on Metal Frame
    # Left highlight
    draw.line([pad_x + 1 * scale, pad_y + corner_r, pad_x + 1 * scale, pad_y + ph - corner_r],
              fill=(85, 115, 150, 180), width=scale)
    # Right shadow
    draw.line([pad_x + pw - 1 * scale, pad_y + corner_r, pad_x + pw - 1 * scale, pad_y + ph - corner_r],
              fill=(10, 14, 20, 200), width=scale)

    # Downscale smoothly to native target size
    final_img = img.resize((width, height), Image.Resampling.LANCZOS)
    return final_img

def main():
    os.makedirs('assets/ui', exist_ok=True)
    os.makedirs('resources/ui', exist_ok=True)

    states = ['full', 'warning', 'critical', 'empty']
    images = {}

    for s in states:
        im = create_health_pip(s, width=16, height=22)
        out_p = f'assets/ui/health_pip_{s}.png'
        im.save(out_p)
        images[s] = im
        print(f'Saved {out_p}')

    # Also build horizontal strip
    w, h = 16, 22
    strip = Image.new('RGBA', (w * 4, h), (0, 0, 0, 0))
    for idx, s in enumerate(['empty', 'critical', 'warning', 'full']):
        strip.paste(images[s], (idx * w, 0))
    strip_p = 'assets/ui/health_pip_strip.png'
    strip.save(strip_p)
    print(f'Saved {strip_p}')

    # Create larger HD 48x66 preview sheet for crystal-clear visual confirmation
    preview = Image.new('RGBA', (48 * 4 + 30, 66 + 20), (14, 18, 28, 255))
    for idx, s in enumerate(['empty', 'critical', 'warning', 'full']):
        im_large = create_health_pip(s, width=48, height=66)
        preview.paste(im_large, (10 + idx * (48 + 5), 10), im_large)
    preview.save('scratch/health_pips_preview.png')
    print('Saved scratch/health_pips_preview.png')

if __name__ == '__main__':
    main()
