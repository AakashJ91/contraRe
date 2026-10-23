import math, os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

def draw_medal_high_res(frame_idx, total_frames=8, width=64, height=88):
    # Scale 4x for smooth anti-aliased geometry before final downscale
    scale = 4
    sw = width * scale   # 256
    sh = height * scale  # 352
    
    img = Image.new('RGBA', (sw, sh), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, 'RGBA')
    
    # Progress of the shimmer sweep: moves smoothly across the medal
    phase = float(frame_idx) / float(total_frames)
    
    # Luxurious Gold metallic palette
    c_gold_hi = (255, 248, 195, 255)
    c_gold_bright = (255, 225, 75, 255)
    c_gold_mid = (235, 180, 40, 255)
    c_gold_dark = (160, 105, 18, 255)
    c_gold_shadow = (90, 50, 10, 255)
    c_gold_core = (255, 255, 245, 255)
    
    # -------------------------------------------------------------
    # 1. TOP BROOCH / MOUNTING BAR (Golden beveled bar)
    # -------------------------------------------------------------
    bar_w = 176
    bar_h = 36
    bx0 = (sw - bar_w) // 2
    by0 = 12
    draw.rounded_rectangle([bx0, by0, bx0 + bar_w, by0 + bar_h], radius=7, fill=c_gold_mid, outline=c_gold_shadow, width=4)
    # Upper rim specular highlight
    draw.line([bx0 + 8, by0 + 4, bx0 + bar_w - 8, by0 + 4], fill=c_gold_hi, width=4)
    # Lower shadow ledge
    draw.line([bx0 + 6, by0 + bar_h - 4, bx0 + bar_w - 6, by0 + bar_h - 4], fill=c_gold_shadow, width=4)
    # Rivets / Studs on left and right
    draw.ellipse([bx0 + 12, by0 + 9, bx0 + 26, by0 + 23], fill=c_gold_hi, outline=c_gold_shadow, width=2)
    draw.ellipse([bx0 + bar_w - 26, by0 + 9, bx0 + bar_w - 12, by0 + 23], fill=c_gold_hi, outline=c_gold_shadow, width=2)
    
    # -------------------------------------------------------------
    # 2. DRAPED MILITARY RIBBON (Tricolor silk with golden cords)
    # -------------------------------------------------------------
    rib_w = 146
    rib_h = 92
    rx0 = (sw - rib_w) // 2
    ry0 = by0 + bar_h - 2
    
    c_red = (212, 26, 38, 255)
    c_red_dark = (115, 12, 20, 255)
    c_navy = (22, 44, 98, 255)
    c_stripe = (255, 218, 80, 255)
    
    # Red background
    draw.rectangle([rx0, ry0, rx0 + rib_w, ry0 + rib_h], fill=c_red)
    draw.line([rx0, ry0, rx0, ry0 + rib_h], fill=c_red_dark, width=6)
    draw.line([rx0 + rib_w, ry0, rx0 + rib_w, ry0 + rib_h], fill=c_red_dark, width=6)
    
    # Navy center band
    stripe_w = 38
    cx = rx0 + (rib_w - stripe_w) // 2
    draw.rectangle([cx, ry0, cx + stripe_w, ry0 + rib_h], fill=c_navy)
    # Flanking gold cords
    draw.line([cx - 5, ry0, cx - 5, ry0 + rib_h], fill=c_stripe, width=6)
    draw.line([cx + stripe_w + 5, ry0, cx + stripe_w + 5, ry0 + rib_h], fill=c_stripe, width=6)
    
    # Subtle silk weave shading line
    draw.line([rx0 + 4, ry0 + rib_h - 3, rx0 + rib_w - 4, ry0 + rib_h - 3], fill=(0, 0, 0, 80), width=4)
    
    # -------------------------------------------------------------
    # 3. CONNECTING EYELET / RING
    # -------------------------------------------------------------
    ring_cx = sw // 2
    ring_cy = ry0 + rib_h + 8
    draw.ellipse([ring_cx - 16, ring_cy - 12, ring_cx + 16, ring_cy + 12], outline=c_gold_mid, width=8)
    draw.ellipse([ring_cx - 14, ring_cy - 10, ring_cx + 14, ring_cy + 10], outline=c_gold_hi, width=2)
    
    # -------------------------------------------------------------
    # 4. CIRCULAR STAR MEDALLION PENDANT
    # -------------------------------------------------------------
    pend_r = 76
    pend_cx = sw // 2
    pend_cy = ring_cy + pend_r + 10
    
    # Outer gold rim disc
    draw.ellipse([pend_cx - pend_r, pend_cy - pend_r, pend_cx + pend_r, pend_cy + pend_r],
                 fill=c_gold_mid, outline=c_gold_shadow, width=7)
    # Beveled rim highlights
    draw.arc([pend_cx - pend_r + 3, pend_cy - pend_r + 3, pend_cx + pend_r - 3, pend_cy + pend_r - 3],
             start=135, end=315, fill=c_gold_hi, width=7)
    draw.arc([pend_cx - pend_r + 3, pend_cy - pend_r + 3, pend_cx + pend_r - 3, pend_cy + pend_r - 3],
             start=315, end=135, fill=c_gold_shadow, width=7)
             
    # Recessed inner disc
    in_r = pend_r - 15
    draw.ellipse([pend_cx - in_r, pend_cy - in_r, pend_cx + in_r, pend_cy + in_r],
                 fill=c_gold_dark, outline=c_gold_shadow, width=4)
                 
    # 5-pointed 3D Star
    star_r_out = float(in_r - 4)
    star_r_in = star_r_out * 0.40
    
    outer_pts = []
    inner_pts = []
    for p in range(5):
        ang_out = -math.pi / 2.0 + float(p) * (2.0 * math.pi / 5.0)
        ang_in = ang_out + math.pi / 5.0
        outer_pts.append((pend_cx + math.cos(ang_out) * star_r_out, pend_cy + math.sin(ang_out) * star_r_out))
        inner_pts.append((pend_cx + math.cos(ang_in) * star_r_in, pend_cy + math.sin(ang_in) * star_r_in))
        
    for p in range(5):
        prev_in = inner_pts[(p - 1) % 5]
        cur_out = outer_pts[p]
        cur_in = inner_pts[p]
        # Light facet
        draw.polygon([(pend_cx, pend_cy), prev_in, cur_out], fill=c_gold_hi)
        # Shaded facet
        draw.polygon([(pend_cx, pend_cy), cur_out, cur_in], fill=c_gold_mid)
        # Spine line
        draw.line([(pend_cx, pend_cy), cur_out], fill=c_gold_core, width=3)
        
    # Center diamond jewel
    draw.ellipse([pend_cx - 10, pend_cy - 10, pend_cx + 10, pend_cy + 10], fill=c_gold_core, outline=c_gold_dark, width=2)
    
    # -------------------------------------------------------------
    # 5. DYNAMIC SHIMMER SWEEP (Frames 1-6)
    # -------------------------------------------------------------
    if 1 <= frame_idx <= 6:
        sweep_layer = Image.new('RGBA', (sw, sh), (0, 0, 0, 0))
        sw_draw = ImageDraw.Draw(sweep_layer)
        
        # Diagonal band traveling from top-left to bottom-right
        sweep_t = float(frame_idx - 1) / 5.0  # 0.0 to 1.0
        # Intercept along x + y: range from 60 to (sw + sh - 40)
        diag_center = 70.0 + sweep_t * (float(sw + sh) - 130.0)
        band_width = 38.0
        
        for y in range(sh):
            cx_diag = diag_center - float(y)
            if -band_width <= cx_diag <= sw + band_width:
                # Soft Gaussian profile for the shimmer beam
                sw_draw.line([cx_diag - band_width * 0.5, y, cx_diag + band_width * 0.5, y],
                             fill=(255, 255, 245, 120), width=3)
                sw_draw.line([cx_diag - band_width * 0.2, y, cx_diag + band_width * 0.2, y],
                             fill=(255, 255, 255, 180), width=2)
                             
        # Mask sweep strictly onto the opaque medal pixels
        arr_base = np.array(img)
        arr_sweep = np.array(sweep_layer)
        mask = arr_base[:, :, 3] > 30
        arr_sweep[~mask] = 0
        sweep_masked = Image.fromarray(arr_sweep, 'RGBA')
        img = Image.alpha_composite(img, sweep_masked)
        
    # -------------------------------------------------------------
    # 6. STARBURST DIAMOND FLARE (Peak gleam on frames 3, 4, 5)
    # -------------------------------------------------------------
    if frame_idx in [3, 4, 5]:
        flare_draw = ImageDraw.Draw(img)
        if frame_idx == 3:
            # Flare at top point of star
            fx, fy = pend_cx, pend_cy - int(star_r_out * 0.82)
            intensity = 0.75
        elif frame_idx == 4:
            # Massive brilliant flare at medallion center
            fx, fy = pend_cx, pend_cy
            intensity = 1.0
        else: # frame 5
            # Flare at lower-right star point
            fx = pend_cx + int(math.cos(-math.pi/2.0 + 2 * (2.0*math.pi/5.0)) * star_r_out * 0.8)
            fy = pend_cy + int(math.sin(-math.pi/2.0 + 2 * (2.0*math.pi/5.0)) * star_r_out * 0.8)
            intensity = 0.70
            
        r_main = 36.0 * intensity
        r_thick = 5.0 * intensity
        
        # Horizontal & Vertical radiant rays
        flare_draw.line([fx - r_main, fy, fx + r_main, fy], fill=(255, 255, 255, int(250 * intensity)), width=int(r_thick))
        flare_draw.line([fx, fy - r_main, fx, fy + r_main], fill=(255, 255, 255, int(250 * intensity)), width=int(r_thick))
        
        # Diagonal secondary rays
        r_diag = r_main * 0.52
        flare_draw.line([fx - r_diag, fy - r_diag, fx + r_diag, fy + r_diag], fill=(255, 245, 180, int(200 * intensity)), width=2)
        flare_draw.line([fx - r_diag, fy + r_diag, fx + r_diag, fy - r_diag], fill=(255, 245, 180, int(200 * intensity)), width=2)
        
        # Core diamond light
        flare_draw.ellipse([fx - 6, fy - 6, fx + 6, fy + 6], fill=(255, 255, 255, 255))
        flare_draw.ellipse([fx - 10, fy - 10, fx + 10, fy + 10], outline=(255, 240, 160, int(150 * intensity)), width=2)
        
    return img

def main():
    os.makedirs('assets/ui/medal_anim', exist_ok=True)
    os.makedirs('scratch', exist_ok=True)
    
    total_frames = 8
    target_w, target_h = 32, 44
    mini_w, mini_h = 16, 22
    preview_w, preview_h = 64, 88
    
    frames_32 = []
    frames_16 = []
    frames_preview = []
    
    print('Generating 8-frame animated life medal suite...')
    for i in range(total_frames):
        im_hires = draw_medal_high_res(i, total_frames, width=preview_w, height=preview_h)
        frames_preview.append(im_hires)
        
        # Downscale to 32x44 (retina / 2x UI size)
        im_32 = im_hires.resize((target_w, target_h), Image.Resampling.LANCZOS)
        frames_32.append(im_32)
        im_32.save(f'assets/ui/medal_anim/frame_{i}.png')
        
        # Downscale to 16x22 (classic 1x UI size)
        im_16 = im_hires.resize((mini_w, mini_h), Image.Resampling.LANCZOS)
        frames_16.append(im_16)
        im_16.save(f'assets/ui/medal_anim/mini_{i}.png')
        
    # 1. Primary horizontal sprite sheet (32x44 * 8 frames = 256x44)
    sheet_32 = Image.new('RGBA', (target_w * total_frames, target_h), (0, 0, 0, 0))
    for i in range(total_frames):
        sheet_32.paste(frames_32[i], (i * target_w, 0))
    sheet_32.save('assets/ui/medal_life_anim.png')
    print('Saved assets/ui/medal_life_anim.png (256x44)')
    
    # 2. Mini horizontal sprite sheet (16x22 * 8 frames = 128x22)
    sheet_16 = Image.new('RGBA', (mini_w * total_frames, mini_h), (0, 0, 0, 0))
    for i in range(total_frames):
        sheet_16.paste(frames_16[i], (i * mini_w, 0))
    sheet_16.save('assets/ui/medal_life_anim_16.png')
    print('Saved assets/ui/medal_life_anim_16.png (128x22)')
    
    # 3. Update master static icon assets/ui/medal_life.png with frame 0
    frames_32[0].save('assets/ui/medal_life.png')
    print('Saved assets/ui/medal_life.png (32x44 high-detail)')
    
    # 4. Animated GIF preview in scratch/medal_anim_preview.gif
    frames_preview[0].save(
        'scratch/medal_anim_preview.gif',
        save_all=True,
        append_images=frames_preview[1:],
        duration=100, # 10 FPS
        loop=0,
        disposal=2
    )
    print('Saved scratch/medal_anim_preview.gif (10 FPS animated preview)')
    
    # 5. Composite preview showcase sheet (scratch/medal_showcase.png)
    # Shows all 8 frames in a row with dark HUD backing
    showcase_w = (preview_w + 8) * total_frames + 16
    showcase_h = preview_h + 40
    showcase = Image.new('RGBA', (showcase_w, showcase_h), (16, 22, 34, 255))
    s_draw = ImageDraw.Draw(showcase)
    s_draw.rectangle([0, 0, showcase_w - 1, showcase_h - 1], outline=(40, 56, 85, 255), width=2)
    for i in range(total_frames):
        x = 12 + i * (preview_w + 8)
        showcase.paste(frames_preview[i], (x, 10), frames_preview[i])
        # Text label frame 0..7
        s_draw.text((x + 24, preview_h + 16), f'F{i}', fill=(180, 205, 235, 255))
    showcase.save('scratch/medal_showcase.png')
    print('Saved scratch/medal_showcase.png')
    
    print('All animated medal assets generated successfully!')

if __name__ == '__main__':
    main()
