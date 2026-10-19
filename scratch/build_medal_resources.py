import os
import math
import numpy as np
from PIL import Image, ImageDraw

def create_medal(tier: str = 'gold', width=16, height=22):
    # Tier: 'gold', 'silver', 'bronze'
    scale = 4
    sw = width * scale      # 64
    sh = height * scale     # 88
    img = Image.new('RGBA', (sw, sh), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, 'RGBA')

    # Color palette
    if tier == 'gold':
        c_metal_hi = (255, 248, 180, 255)
        c_metal_mid = (235, 185, 45, 255)
        c_metal_dark = (165, 110, 20, 255)
        c_metal_shadow = (95, 60, 10, 255)
        c_core = (255, 255, 230, 255)
    elif tier == 'silver':
        c_metal_hi = (252, 252, 255, 255)
        c_metal_mid = (195, 205, 220, 255)
        c_metal_dark = (130, 140, 160, 255)
        c_metal_shadow = (70, 80, 95, 255)
        c_core = (255, 255, 255, 255)
    else: # bronze
        c_metal_hi = (250, 195, 145, 255)
        c_metal_mid = (205, 125, 65, 255)
        c_metal_dark = (145, 75, 30, 255)
        c_metal_shadow = (85, 40, 15, 255)
        c_core = (255, 225, 195, 255)

    # 1. Top Brooch / Mounting Bar (Width: 48, Height: 10)
    bar_w = 48
    bar_h = 10
    bx0 = (sw - bar_w) // 2
    by0 = 3
    draw.rounded_rectangle([bx0, by0, bx0 + bar_w, by0 + bar_h], radius=3, fill=c_metal_mid)
    draw.line([bx0 + 2, by0 + 1, bx0 + bar_w - 2, by0 + 1], fill=c_metal_hi, width=2)
    draw.line([bx0 + 2, by0 + bar_h - 1, bx0 + bar_w - 2, by0 + bar_h - 1], fill=c_metal_shadow, width=2)

    # 2. Suspension Ribbon (Draped military ribbon, Width: 40, Height: 26)
    rib_w = 40
    rib_h = 26
    rx0 = (sw - rib_w) // 2
    ry0 = by0 + bar_h - 1

    c_rib_red = (215, 25, 35, 255)
    c_rib_navy = (22, 42, 90, 255)
    c_rib_stripe = (250, 225, 95, 255) if tier == 'gold' else (240, 240, 250, 255)

    draw.rectangle([rx0, ry0, rx0 + rib_w, ry0 + rib_h], fill=c_rib_red)
    # Center navy stripe
    stripe_w = 10
    cx = rx0 + (rib_w - stripe_w) // 2
    draw.rectangle([cx, ry0, cx + stripe_w, ry0 + rib_h], fill=c_rib_navy)
    # Flanking gold/white pinstripes
    draw.line([cx - 2, ry0, cx - 2, ry0 + rib_h], fill=c_rib_stripe, width=3)
    draw.line([cx + stripe_w + 2, ry0, cx + stripe_w + 2, ry0 + rib_h], fill=c_rib_stripe, width=3)

    # Ribbon shade at edges
    draw.line([rx0, ry0, rx0, ry0 + rib_h], fill=(120, 10, 20, 255), width=2)
    draw.line([rx0 + rib_w, ry0, rx0 + rib_w, ry0 + rib_h], fill=(120, 10, 20, 255), width=2)

    # 3. Connecting Eyelet / Ring
    ring_cx = sw // 2
    ring_cy = ry0 + rib_h + 3
    draw.ellipse([ring_cx - 5, ring_cy - 4, ring_cx + 5, ring_cy + 4],
                 outline=c_metal_mid, width=3)

    # 4. Circular Star Medallion Pendant
    pend_r = 19
    pend_cx = sw // 2
    pend_cy = ring_cy + pend_r + 2

    # Outer medallion disc
    draw.ellipse([pend_cx - pend_r, pend_cy - pend_r, pend_cx + pend_r, pend_cy + pend_r],
                 fill=c_metal_mid, outline=c_metal_dark, width=3)

    # Beveled rim highlight (top-left light source)
    draw.arc([pend_cx - pend_r, pend_cy - pend_r, pend_cx + pend_r, pend_cy + pend_r],
             start=135, end=315, fill=c_metal_hi, width=3)
    draw.arc([pend_cx - pend_r, pend_cy - pend_r, pend_cx + pend_r, pend_cy + pend_r],
             start=315, end=135, fill=c_metal_shadow, width=3)

    # 5. Inner 5-Pointed Star
    star_r_outer = 14.0
    star_r_inner = 6.0
    star_pts = []
    for p in range(10):
        r = star_r_outer if p % 2 == 0 else star_r_inner
        ang = -math.pi / 2.0 + float(p) * (math.pi / 5.0)
        px = pend_cx + math.cos(ang) * r
        py = pend_cy + math.sin(ang) * r
        star_pts.append((px, py))

    draw.polygon(star_pts, fill=c_metal_hi, outline=c_metal_shadow)

    # Star facet highlights
    for p in range(5):
        ang_outer = -math.pi / 2.0 + float(p * 2) * (math.pi / 5.0)
        px_o = pend_cx + math.cos(ang_outer) * star_r_outer
        py_o = pend_cy + math.sin(ang_outer) * star_r_outer
        draw.line([pend_cx, pend_cy, px_o, py_o], fill=c_metal_mid, width=1)

    # Core center gleam
    draw.ellipse([pend_cx - 3, pend_cy - 3, pend_cx + 3, pend_cy + 3], fill=c_core)

    # Downscale smoothly to 16x22 target size
    final_img = img.resize((width, height), Image.Resampling.LANCZOS)
    return final_img

def main():
    os.makedirs('assets/ui', exist_ok=True)
    os.makedirs('resources/ui', exist_ok=True)

    tiers = ['gold', 'silver', 'bronze']
    images = {}

    for t in tiers:
        im = create_medal(t, width=16, height=22)
        out_p = f'assets/ui/medal_life_{t}.png'
        im.save(out_p)
        images[t] = im
        print(f'Saved {out_p}')

    # Primary medal_life.png is gold
    images['gold'].save('assets/ui/medal_life.png')
    print('Saved assets/ui/medal_life.png')

    # Build horizontal strip (Bronze, Silver, Gold)
    w, h = 16, 22
    strip = Image.new('RGBA', (w * 3, h), (0, 0, 0, 0))
    for idx, t in enumerate(['bronze', 'silver', 'gold']):
        strip.paste(images[t], (idx * w, 0))
    strip.save('assets/ui/medal_strip.png')
    print('Saved assets/ui/medal_strip.png')

    # Create high-res 48x66 preview sheet for visual verification
    preview = Image.new('RGBA', (48 * 3 + 30, 66 + 10), (14, 18, 28, 255))
    for idx, t in enumerate(['bronze', 'silver', 'gold']):
        im_large = create_medal(t, width=48, height=66)
        preview.paste(im_large, (8 + idx * (48 + 7), 5), im_large)
    preview.save('scratch/medals_preview.png')
    print('Saved scratch/medals_preview.png')

if __name__ == '__main__':
    main()
