import numpy as np
from PIL import Image, ImageDraw
import os

def generate_waterfall_edge_frames(image_path, is_left=True):
    base_img = Image.open(image_path).convert('RGBA')
    w, h = base_img.size
    base_arr = np.array(base_img, dtype=np.float32)

    r = base_arr[:, :, 0]
    g = base_arr[:, :, 1]
    b = base_arr[:, :, 2]
    a = base_arr[:, :, 3]

    # Water mask identification
    is_foam = (a > 100) & (r > 195) & (g > 205) & (b > 215)
    is_blue_water = (a > 100) & (b > r + 25) & (b > 130) & (g > 100)
    water_cand = is_foam | is_blue_water

    y_coords = np.arange(h)[:, None]
    x_coords = np.arange(w)[None, :]

    if is_left:
        is_moss_zone = (x_coords > 270) & (y_coords < 160)
        valid_zone = (x_coords < 245) | ((y_coords < 90) & (x_coords < 380)) | ((x_coords >= 280) & (x_coords <= 390) & (y_coords >= 210) & (y_coords <= 560))
    else:
        is_moss_zone = (x_coords < 200) & (y_coords < 160)
        valid_zone = (x_coords > 225) | ((y_coords < 90) & (x_coords > 90)) | ((x_coords >= 80) & (x_coords <= 190) & (y_coords >= 210) & (y_coords <= 560))

    is_green_moss = (g > b + 15) & (r < 130)
    water_mask = water_cand & (~is_moss_zone) & (~is_green_moss) & valid_zone & (a > 50)

    # Direction field
    if is_left:
        dir_x = np.where(y_coords < 65, -1.0, np.where((y_coords < 95) & (x_coords > 160), -0.6, -0.12))
        dir_y = np.where(y_coords < 65, 0.25, np.where((y_coords < 95) & (x_coords > 160), 0.8, 1.0))
        center_x = 150.0
    else:
        dir_x = np.where(y_coords < 65, 1.0, np.where((y_coords < 95) & (x_coords < 310), 0.6, 0.12))
        dir_y = np.where(y_coords < 65, 0.25, np.where((y_coords < 95) & (x_coords < 310), 0.8, 1.0))
        center_x = 320.0

    flow_mag = np.sqrt(dir_x**2 + dir_y**2)
    dir_x = dir_x / np.maximum(flow_mag, 1e-4)
    dir_y = dir_y / np.maximum(flow_mag, 1e-4)

    # Speed variation per column
    center_dist = np.abs(x_coords - center_x)
    speed_factor = np.clip(1.15 - (center_dist / 120.0) * 0.3, 0.85, 1.15)

    cycle_length = 24.0
    num_frames = 4
    frames = []

    for f in range(num_frames):
        t = float(f) / float(num_frames)
        
        # Dual-phase advection
        offset_A = (t * cycle_length) * speed_factor
        weight_A = 0.5 + 0.5 * np.cos(2.0 * np.pi * t)

        offset_B = (((t + 0.5) % 1.0) * cycle_length) * speed_factor
        weight_B = 1.0 - weight_A

        src_ya = np.clip(np.round(y_coords - dir_y * offset_A).astype(int), 0, h - 1)
        src_xa = np.clip(np.round(x_coords - dir_x * offset_A).astype(int), 0, w - 1)

        src_yb = np.clip(np.round(y_coords - dir_y * offset_B).astype(int), 0, h - 1)
        src_xb = np.clip(np.round(x_coords - dir_x * offset_B).astype(int), 0, w - 1)

        sample_A = base_arr[src_ya, src_xa, :]
        sample_B = base_arr[src_yb, src_xb, :]

        blended_water = weight_A * sample_A + weight_B * sample_B

        # Apply to valid sampled water pixels
        mask_a = water_mask[src_ya, src_xa]
        mask_b = water_mask[src_yb, src_xb]
        valid_sample = mask_a & mask_b & water_mask

        frame_arr = base_arr.copy()
        for c in range(3):
            frame_arr[:, :, c] = np.where(valid_sample, blended_water[:, :, c], base_arr[:, :, c])
        frame_arr[:, :, 3] = base_arr[:, :, 3]

        img_out = Image.fromarray(np.clip(frame_arr, 0, 255).astype(np.uint8), mode='RGBA')
        draw = ImageDraw.Draw(img_out)

        # 1. Moving pixel foam strands traveling with the current
        np.random.seed(300 + f * 53 + (0 if is_left else 500))
        for _ in range(34):
            if is_left:
                col_x = np.random.randint(70, 215)
            else:
                col_x = np.random.randint(255, 400)

            base_y = np.random.randint(70, 660)
            cur_y = (base_y + int(t * 32.0 * speed_factor[0, col_x])) % 590 + 70
            strand_len = np.random.randint(4, 14)
            
            if 0 <= cur_y < h and 0 <= col_x < w and water_mask[cur_y, col_x]:
                for k in range(strand_len):
                    py = cur_y + k
                    px = col_x + int(k * dir_x[min(h-1, py), col_x])
                    if 0 <= py < h and 0 <= px < w and water_mask[py, px]:
                        val = 255 if k == 0 else np.random.randint(225, 252)
                        draw.point((px, py), fill=(val, val, 255, 235))

        # 2. Dynamic spray droplets at base (y > 640)
        for _ in range(16):
            if is_left:
                sp_x = np.random.randint(45, 175)
            else:
                sp_x = np.random.randint(295, 425)
            sp_y = np.random.randint(645, 720)
            draw.point((sp_x, sp_y), fill=(255, 255, 255, 240))
            if np.random.rand() > 0.5:
                dx = -1 if is_left else 1
                draw.point((sp_x + dx, sp_y - 1), fill=(215, 245, 255, 200))

        # 3. Churning crest at weir lip (y: 52 to 62)
        phase = t * 2.0 * np.pi
        lip_range = (170, 220) if is_left else (250, 300)
        for lx in range(lip_range[0], lip_range[1], 2):
            w_offset = int(np.sin(lx * 0.35 + phase * 2.0) * 1.5)
            ly = 56 + w_offset
            if 0 <= ly < h and 0 <= lx < w and water_mask[ly, lx]:
                draw.point((lx, ly), fill=(255, 255, 255, 255))
                draw.point((lx, ly + 1), fill=(240, 250, 255, 220))

        frames.append(img_out)

    return frames

def build_all_waterfall_edge_assets():
    targets = [
        ('assets/tiles/ground_waterfall_edge_left.png', 'ground_waterfall_edge_left', True),
        ('assets/tiles/ground_waterfall_edge_right.png', 'ground_waterfall_edge_right', False),
    ]

    for src_path, prefix, is_left in targets:
        print(f"Processing {src_path}...")
        frames = generate_waterfall_edge_frames(src_path, is_left=is_left)
        w, h = frames[0].size

        # Save individual frames
        for i, frame in enumerate(frames):
            out_name = f"assets/tiles/{prefix}_{i}.png"
            frame.save(out_name)
            print(f"  Saved {out_name} ({w}x{h})")

        # Save horizontal strip
        strip = Image.new('RGBA', (w * 4, h))
        for i, frame in enumerate(frames):
            strip.paste(frame, (i * w, 0))
        strip_path = f"assets/tiles/{prefix}_strip.png"
        strip.save(strip_path)
        print(f"  Saved {strip_path} ({w*4}x{h})")

        # Update base image to frame 0
        frames[0].save(src_path)
        print(f"  Updated base {src_path}")

if __name__ == '__main__':
    build_all_waterfall_edge_assets()
    print("All waterfall edge assets generated successfully!")
