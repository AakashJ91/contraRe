import os
import numpy as np
from PIL import Image, ImageDraw

def generate_spinning_barrels():
    # Load base fortress
    base_fortress_path = "assets/enemies/boss_fortress/boss_fortress.png"
    base_fortress = Image.open(base_fortress_path).convert("RGBA")
    w_total, h_total = base_fortress.size # 1020 x 872
    
    def animate_horizontal_barrels(crop_im, y_center, R=14.0, r_b=4.5, x_rings=[(24, 30), (58, 66), (116, 126)]):
        """Generates 4 frames of barrel rotation for a horizontal gatling."""
        frames = []
        w, h = crop_im.size
        
        for step in range(4):
            theta = step * (np.pi / 3.0 / 4.0) # 0, 15, 30, 45 degrees
            f = crop_im.copy()
            draw = ImageDraw.Draw(f)
            
            # Compute 6 barrel positions
            barrels = []
            for k in range(6):
                phi = theta + k * (2.0 * np.pi / 6.0)
                yb = y_center + R * np.sin(phi)
                zb = R * np.cos(phi) # depth: positive = toward camera
                barrels.append((zb, yb, phi))
            
            # Sort from back to front
            barrels.sort(key=lambda b: b[0])
            
            # Segments between rings
            segments = [
                (x_rings[0][1], x_rings[1][0]),
                (x_rings[1][1], x_rings[2][0])
            ]
            
            # Draw each barrel cylinder across the segments
            for zb, yb, phi in barrels:
                depth_norm = (zb + R) / (2.0 * R) # 0.0 (back) to 1.0 (front)
                if depth_norm < 0.15:
                    continue # Occluded behind other barrels
                
                # Steel shading palette
                spec = max(0.0, depth_norm - 0.5) * 2.0
                c_edge = (16, 20, 24, 255)
                c_hi   = (int(150 + 80 * spec), int(165 + 85 * spec), int(185 + 70 * spec), 255)
                c_mid  = (int(75 + 40 * depth_norm), int(85 + 45 * depth_norm), int(98 + 48 * depth_norm), 255)
                c_dark = (int(30 + 20 * depth_norm), int(35 + 24 * depth_norm), int(44 + 28 * depth_norm), 255)
                
                y_t = int(round(yb - r_b))
                y_b = int(round(yb + r_b))
                y_h1 = int(round(yb - r_b * 0.3))
                y_m1 = int(round(yb + r_b * 0.3))
                
                for s_x0, s_x1 in segments:
                    draw.line([(s_x0, y_t), (s_x1, y_t)], fill=c_edge, width=1)
                    draw.line([(s_x0, y_b), (s_x1, y_b)], fill=c_edge, width=1)
                    if y_h1 > y_t:
                        draw.rectangle([s_x0, y_t + 1, s_x1, y_h1], fill=c_hi)
                    if y_m1 > y_h1:
                        draw.rectangle([s_x0, y_h1 + 1, s_x1, y_m1], fill=c_mid)
                    if y_b - 1 >= y_m1:
                        draw.rectangle([s_x0, y_m1 + 1, s_x1, y_b - 1], fill=c_dark)
            
            # Front muzzle orifice cluster (x=0 to x_rings[0][0])
            for zb, yb, phi in barrels:
                if zb > -4.0: # Visible in front muzzle
                    y_t = int(round(yb - r_b))
                    y_b = int(round(yb + r_b))
                    m_x0 = 0
                    m_x1 = x_rings[0][0]
                    # Barrel tip tube
                    draw.rectangle([m_x0 + 6, y_t, m_x1, y_b], fill=(50, 58, 66, 255), outline=(18, 22, 26, 255))
                    draw.line([(m_x0 + 6, y_t + 1), (m_x1, y_t + 1)], fill=(140, 155, 170, 255))
                    # Dark circular/elliptical muzzle hole
                    draw.rectangle([m_x0, y_t + 1, m_x0 + 5, y_b - 1], fill=(12, 14, 16, 255), outline=(6, 8, 10, 255))
            
            # Re-apply clamp rings with metallic rim and bolts
            for rx0, rx1 in x_rings:
                r_yt = int(round(y_center - R - r_b - 1))
                r_yb = int(round(y_center + R + r_b + 1))
                draw.rectangle([rx0, r_yt, rx1, r_yb], fill=(62, 70, 80, 255), outline=(20, 24, 28, 255))
                draw.line([(rx0, r_yt + 1), (rx1, r_yt + 1)], fill=(170, 185, 200, 255)) # highlight top
                draw.line([(rx0, r_yb - 1), (rx1, r_yb - 1)], fill=(30, 35, 42, 255)) # shadow bot
                
                # Bolt studs on the ring that rotate with the barrels
                for zb, yb, phi in barrels:
                    if zb > 2.0:
                        by = int(round(yb))
                        bx = (rx0 + rx1) // 2
                        draw.point((bx, by), fill=(230, 240, 255, 255))
                        draw.point((bx, by + 1), fill=(40, 45, 52, 255))
            
            frames.append(f)
        return frames

    # 1. Generate Mid Gun frames
    mid_crop = base_fortress.crop((0, 480, 140, 570))
    mid_frames = animate_horizontal_barrels(
        mid_crop,
        y_center=54,
        R=15.0,
        r_b=4.5,
        x_rings=[(24, 30), (58, 66), (116, 126)]
    )
    
    # 2. Generate Top-Left Gun frames
    tl_crop = base_fortress.crop((165, 70, 315, 160))
    tl_frames = animate_horizontal_barrels(
        tl_crop,
        y_center=44,
        R=14.0,
        r_b=4.2,
        x_rings=[(24, 30), (56, 64), (118, 128)]
    )
    
    # 3. Generate Top-Right Gun frames with CLEAN alpha masking
    # Bounding box in base image: x: 590..840, y: 0..170
    tr_box = (590, 0, 840, 170)
    tr_crop = base_fortress.crop(tr_box)
    
    # Create mask of barrel region: only where x < 740 - 590 = 150 and alpha > 0
    tr_arr = np.array(tr_crop)
    barrel_mask_arr = np.zeros((tr_crop.height, tr_crop.width), dtype=bool)
    for y in range(tr_crop.height):
        for x in range(tr_crop.width):
            # Barrels are inside the upper-left diagonal region of the turret
            # Line from (x=140, y=140) to (x=0, y=60)
            if x < 140 and tr_arr[y, x, 3] > 30 and y < 140:
                barrel_mask_arr[y, x] = True
    barrel_mask_img = Image.fromarray((barrel_mask_arr * 255).astype(np.uint8), mode='L')
    
    # We rotate tr_crop by +29.5 deg so the barrels become horizontal
    # Pivot roughly at mount collar
    rot_angle = 29.5
    tr_rot = tr_crop.rotate(rot_angle, resample=Image.BICUBIC, expand=True)
    w_rot, h_rot = tr_rot.size
    
    # Animate horizontal barrels on the rotated image
    tr_rot_frames = animate_horizontal_barrels(
        tr_rot,
        y_center=h_rot // 2 + 5,
        R=14.0,
        r_b=4.2,
        x_rings=[(32, 40), (70, 78), (128, 138)]
    )
    
    # Rotate back and composite using the clean barrel mask
    tr_frames = []
    for rf in tr_rot_frames:
        back = rf.rotate(-rot_angle, resample=Image.BICUBIC, expand=False)
        cw, ch = tr_crop.size
        bw, bh = back.size
        x0 = (bw - cw) // 2
        y0 = (bh - ch) // 2
        back_cropped = back.crop((x0, y0, x0 + cw, y0 + ch))
        
        # Merge onto clean original tr_crop using barrel_mask_img
        clean_tr = tr_crop.copy()
        clean_tr.paste(back_cropped, (0, 0), barrel_mask_img)
        tr_frames.append(clean_tr)
    
    # -------------------------------------------------------------------------
    # Composite into the 4 core movement frames
    # -------------------------------------------------------------------------
    os.makedirs("assets/enemies/boss_fortress/movement", exist_ok=True)
    os.makedirs("assets/enemies/boss_fortress/weapons", exist_ok=True)
    
    # Save individual weapon frames
    for i in range(4):
        mid_frames[i].save(f"assets/enemies/boss_fortress/weapons/gun_mid_{i}.png")
        tl_frames[i].save(f"assets/enemies/boss_fortress/weapons/gun_tl_{i}.png")
        tr_frames[i].save(f"assets/enemies/boss_fortress/weapons/gun_tr_{i}.png")
    
    # Re-generate core movement frames cleanly from the base animation script
    # to ensure clean background without any floating artifacts
    import sys
    sys.path.append("scratch")
    from generate_boss_animations import generate_core_animations
    generate_core_animations(base_fortress)
    
    for i in range(4):
        core_path = f"assets/enemies/boss_fortress/movement/core_{i}.png"
        core_im = Image.open(core_path).convert("RGBA")
        
        # Paste mid gun
        core_im.paste(mid_frames[i], (0, 480), mid_frames[i])
        # Paste top-left gun
        core_im.paste(tl_frames[i], (165, 70), tl_frames[i])
        # Paste top-right gun
        core_im.paste(tr_frames[i], (590, 0), tr_frames[i])
        
        core_im.save(core_path)
        print(f"Updated {core_path} with spinning machinegun barrels!")
    
    # Generate animated GIF of full fortress
    final_frames = [Image.open(f"assets/enemies/boss_fortress/movement/core_{i}.png") for i in range(4)]
    final_frames[0].save(
        "scratch/boss_fortress_guns_loop.gif",
        save_all=True,
        append_images=final_frames[1:],
        duration=133,
        loop=0
    )
    
    # 2x2 grid showcase
    w, h = final_frames[0].size
    grid = Image.new('RGBA', (w * 2, h * 2))
    grid.paste(final_frames[0], (0, 0))
    grid.paste(final_frames[1], (w, 0))
    grid.paste(final_frames[2], (0, h))
    grid.paste(final_frames[3], (w, h))
    grid_thumb = grid.resize((1020, 872), resample=Image.BICUBIC)
    grid_thumb.save('scratch/fortress_all_guns_showcase.png')
    print("Showcase saved to scratch/fortress_all_guns_showcase.png")

if __name__ == "__main__":
    generate_spinning_barrels()
