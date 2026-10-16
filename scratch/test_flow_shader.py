import numpy as np
from PIL import Image, ImageDraw

def test_flow_clean():
    base_img = Image.open('d:/GitHub/contraRe/assets/tiles/ground_waterfall_edge_left.png').convert('RGBA')
    w, h = base_img.size
    base_arr = np.array(base_img, dtype=np.float32)

    r = base_arr[:, :, 0]
    g = base_arr[:, :, 1]
    b = base_arr[:, :, 2]
    a = base_arr[:, :, 3]

    # Water mask
    is_foam = (a > 100) & (r > 195) & (g > 205) & (b > 215)
    is_blue_water = (a > 100) & (b > r + 25) & (b > 130) & (g > 100)
    water_cand = is_foam | is_blue_water

    y_coords = np.arange(h)[:, None]
    x_coords = np.arange(w)[None, :]

    is_moss_zone = (x_coords > 270) & (y_coords < 160)
    is_green_moss = (g > b + 15) & (r < 130)
    valid_zone = (x_coords < 245) | ((y_coords < 90) & (x_coords < 380)) | ((x_coords >= 280) & (x_coords <= 390) & (y_coords >= 210) & (y_coords <= 560))
    water_mask = water_cand & (~is_moss_zone) & (~is_green_moss) & valid_zone & (a > 50)

    # Direction field
    dir_x = np.where(y_coords < 65, -1.0, np.where((y_coords < 95) & (x_coords > 160), -0.6, -0.12))
    dir_y = np.where(y_coords < 65, 0.25, np.where((y_coords < 95) & (x_coords > 160), 0.8, 1.0))
    flow_mag = np.sqrt(dir_x**2 + dir_y**2)
    dir_x = dir_x / np.maximum(flow_mag, 1e-4)
    dir_y = dir_y / np.maximum(flow_mag, 1e-4)

    # Speed variation per column: center moves slightly faster (velocity factor 0.85 to 1.15)
    # Waterfall center is around X=150
    center_dist = np.abs(x_coords - 150.0)
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

        # Valid sampling only
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
        np.random.seed(200 + f * 43)
        for i in range(32):
            col_x = np.random.randint(70, 215)
            # Y position advances each frame by 6 to 10 pixels
            base_y = np.random.randint(70, 660)
            cur_y = (base_y + int(t * 32.0 * speed_factor[0, col_x])) % 590 + 70
            strand_len = np.random.randint(4, 12)
            
            if 0 <= cur_y < h and 0 <= col_x < w and water_mask[cur_y, col_x]:
                for k in range(strand_len):
                    py = cur_y + k
                    px = col_x + int(k * dir_x[min(h-1, py), col_x])
                    if 0 <= py < h and 0 <= px < w and water_mask[py, px]:
                        val = 255 if k == 0 else np.random.randint(220, 250)
                        draw.point((px, py), fill=(val, val, 255, 230))

        # 2. Dynamic spray droplets at base (y > 640)
        for _ in range(15):
            sp_x = np.random.randint(45, 175)
            sp_y = np.random.randint(645, 720)
            draw.point((sp_x, sp_y), fill=(255, 255, 255, 240))
            if np.random.rand() > 0.5:
                draw.point((sp_x - 1, sp_y - 1), fill=(215, 245, 255, 200))

        # 3. Churning crest at weir lip (y: 52 to 62, x: 170 to 220)
        phase = t * 2.0 * np.pi
        for lx in range(170, 220, 2):
            w_offset = int(np.sin(lx * 0.35 + phase * 2.0) * 1.5)
            ly = 56 + w_offset
            if water_mask[ly, lx]:
                draw.point((lx, ly), fill=(255, 255, 255, 255))
                draw.point((lx, ly + 1), fill=(240, 250, 255, 220))

        frames.append(img_out)

    frames[0].save('d:/GitHub/contraRe/scratch/test_clean_0.png')
    frames[1].save('d:/GitHub/contraRe/scratch/test_clean_1.png')
    frames[2].save('d:/GitHub/contraRe/scratch/test_clean_2.png')
    frames[3].save('d:/GitHub/contraRe/scratch/test_clean_3.png')
    print('Clean flow test generated!')

if __name__ == '__main__':
    test_flow_clean()
