import os, math
import numpy as np
from PIL import Image, ImageDraw

def build_recon_blimp():
    img_path = 'scratch/extracted_blimp.png'
    base_img = Image.open(img_path).convert('RGBA')

    # Crop tightly to the bounding box with a 4px margin
    bbox = base_img.getbbox()
    margin = 6
    crop_box = (
        max(0, bbox[0] - margin),
        max(0, bbox[1] - margin),
        min(base_img.width, bbox[2] + margin),
        min(base_img.height, bbox[3] + margin)
    )
    cropped_base = base_img.crop(crop_box)
    w, h = cropped_base.size

    # In cropped coordinates:
    # Turbine fan center:
    # original tx was ~770, ty was ~475
    tx = 770 - crop_box[0]
    ty = 475 - crop_box[1]
    t_radius = 48

    # Extract turbine rotor circle
    mask_turb = Image.new('L', (t_radius * 2, t_radius * 2), 0)
    d_tm = ImageDraw.Draw(mask_turb)
    d_tm.ellipse([0, 0, t_radius * 2, t_radius * 2], fill=255)

    rotor_crop = cropped_base.crop((tx - t_radius, ty - t_radius, tx + t_radius, ty + t_radius))

    # Center spinner cone
    hub_r = 14
    hub_crop = cropped_base.crop((tx - hub_r, ty - hub_r, tx + hub_r, ty + hub_r))
    hub_mask = Image.new('L', (hub_r * 2, hub_r * 2), 0)
    d_hm = ImageDraw.Draw(hub_mask)
    d_hm.ellipse([0, 0, hub_r * 2, hub_r * 2], fill=255)

    # Ventral sensor pod position
    # original: sx ~ 505, sy ~ 755
    sx = 505 - crop_box[0]
    sy = 755 - crop_box[1]

    # Cockpit bridge window area:
    # x: 380-crop_box[0] .. 550-crop_box[0], y: 600-crop_box[1] .. 635-crop_box[1]
    # Exhaust nozzle:
    # x: 800-crop_box[0] .. 850-crop_box[0], y: 610-crop_box[1] .. 640-crop_box[1]
    ex_x = 830 - crop_box[0]
    ex_y = 625 - crop_box[1]

    frames = []
    # 4 animation frames: turbine rotation 0, 30, 60, 90 deg
    rot_angles = [0, 30, 60, 90]

    for f_idx, r_ang in enumerate(rot_angles):
        f_img = cropped_base.copy()

        # Rotate turbine rotor
        rot_rotor = rotor_crop.rotate(-r_ang, resample=Image.Resampling.BICUBIC)
        f_img.paste(rot_rotor, (tx - t_radius, ty - t_radius), mask_turb)
        # Re-paste static center spinner hub
        f_img.paste(hub_crop, (tx - hub_r, ty - hub_r), hub_mask)

        draw = ImageDraw.Draw(f_img, 'RGBA')

        # 1. Ventral Surveillance Conical Beam (subtle atmospheric cyan spotlight)
        beam_angles = [32, 45, 58, 42]
        b_ang = math.radians(beam_angles[f_idx])
        beam_len = 160
        spread = 0.22
        
        # Conical beam polygon
        p1 = (sx, sy)
        p2 = (sx + math.cos(b_ang - spread) * beam_len, sy + math.sin(b_ang - spread) * beam_len)
        p3 = (sx + math.cos(b_ang + spread) * beam_len, sy + math.sin(b_ang + spread) * beam_len)
        
        beam_alpha = 40 if f_idx % 2 == 0 else 60
        draw.polygon([p1, p2, p3], fill=(0, 240, 255, beam_alpha))
        # Beam focal point lens
        draw.circle((sx, sy), 5, fill=(0, 255, 255, 230))
        draw.circle((sx, sy), 2, fill=(255, 255, 255, 255))

        # 2. Cockpit Bridge Window Pulse (glowing cyan tactical display)
        c_alpha = 180 if f_idx % 2 == 0 else 240
        draw.line([(395 - crop_box[0], 615 - crop_box[1]), (430 - crop_box[0], 615 - crop_box[1])], fill=(0, 255, 255, c_alpha), width=3)
        draw.line([(450 - crop_box[0], 615 - crop_box[1]), (485 - crop_box[0], 615 - crop_box[1])], fill=(0, 255, 255, c_alpha), width=3)

        # 3. Secondary Engine Exhaust Thermal Shimmer
        thrust_len = 35 + (f_idx % 2) * 20
        draw.line([(ex_x, ex_y), (ex_x + thrust_len, ex_y)], fill=(0, 220, 255, 160), width=4)
        draw.line([(ex_x, ex_y), (ex_x + int(thrust_len * 0.6), ex_y)], fill=(255, 255, 255, 220), width=2)

        # 4. Navigation Strobe Light (White/Cyan on wingtip, NO red glow)
        wing_tip = (695 - crop_box[0], 720 - crop_box[1])
        if f_idx == 1 or f_idx == 3:
            draw.circle(wing_tip, 4, fill=(255, 255, 255, 240))
        else:
            draw.circle(wing_tip, 2, fill=(180, 220, 255, 180))

        frames.append(f_img)

    # Prop dimensions: 60x36
    target_w, target_h = 60, 36
    strip_img = Image.new('RGBA', (target_w * 4, target_h), (0, 0, 0, 0))

    os.makedirs('assets/bg_sky', exist_ok=True)

    for idx, f in enumerate(frames):
        low = f.resize((target_w, target_h), Image.Resampling.LANCZOS)
        low.save(f'assets/bg_sky/recon_blimp_{idx}.png')
        strip_img.paste(low, (idx * target_w, 0))
        print(f'Saved assets/bg_sky/recon_blimp_{idx}.png')

    strip_img.save('assets/bg_sky/recon_blimp_strip.png')
    print('Saved assets/bg_sky/recon_blimp_strip.png')

if __name__ == '__main__':
    build_recon_blimp()
