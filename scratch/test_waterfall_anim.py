import numpy as np
from PIL import Image, ImageDraw
import math

def build_waterfall_frames(image_path, is_left=True):
    base_img = Image.open(image_path).convert('RGBA')
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

    # Filter out moss
    if is_left:
        is_moss_zone = (x_coords > 270) & (y_coords < 160)
    else:
        is_moss_zone = (x_coords < 200) & (y_coords < 160)

    is_green_moss = (g > b + 15) & (r < 130)
    water_mask = water_cand & (~is_moss_zone) & (~is_green_moss)

    # Restrict to waterfall zone
    if is_left:
        # Left edge: waterfall is mainly x < 250, plus top stream x < 380, y < 90, plus trickle x: 300-380, y: 220-560
        valid_zone = (x_coords < 245) | ((y_coords < 90) & (x_coords < 380)) | ((x_coords >= 280) & (x_coords <= 390) & (y_coords >= 210) & (y_coords <= 560))
    else:
        # Right edge: waterfall is mainly x > 225, plus top stream x > 90, y < 90, plus trickle x: 80-190, y: 220-560
        valid_zone = (x_coords > 225) | ((y_coords < 90) & (x_coords > 90)) | ((x_coords >= 80) & (x_coords <= 190) & (y_coords >= 210) & (y_coords <= 560))

    water_mask = water_mask & valid_zone & (a > 50)

    frames = []
    num_frames = 4

    # Pre-extract water colors
    # We will compute flow displacement vectors (flow_x, flow_y)
    # At top (y < 70): flows toward edge (left for is_left, right for is_right)
    # In middle and lower: flows downward (dy > 0)
    
    flow_x = np.zeros((h, w), dtype=np.float32)
    flow_y = np.zeros((h, w), dtype=np.float32)

    for y in range(h):
        for x in range(w):
            if not water_mask[y, x]:
                continue
            if is_left:
                if y < 65:
                    # Top stream flowing left toward lip
                    flow_x[y, x] = -1.2
                    flow_y[y, x] = 0.4
                elif y < 90 and x > 160:
                    # Lip curve bending downward
                    flow_x[y, x] = -0.8
                    flow_y[y, x] = 1.2
                else:
                    # Plunging vertical cascade
                    flow_x[y, x] = -0.1
                    flow_y[y, x] = 2.0
            else:
                if y < 65:
                    # Top stream flowing right toward lip
                    flow_x[y, x] = 1.2
                    flow_y[y, x] = 0.4
                elif y < 90 and x < 310:
                    # Lip curve bending downward
                    flow_x[y, x] = 0.8
                    flow_y[y, x] = 1.2
                else:
                    # Plunging vertical cascade
                    flow_x[y, x] = 0.1
                    flow_y[y, x] = 2.0

    # Vertical cycle period (pixels): 24 pixels
    period = 24.0

    for f in range(num_frames):
        frame_arr = base_arr.copy()
        phase = (float(f) / float(num_frames)) * 2.0 * np.pi
        shift_dist = (float(f) / float(num_frames)) * period

        # 1. Texture advection / sample offset
        # For water pixels, we sample color with a periodic displacement
        # To avoid boundary artifacts, we create a wave modulation of brightness and foam lines
        
        # Traveling waves along the water column:
        # Wave 1: Downward traveling wave (period 24px)
        travel_wave1 = np.sin((y_coords - shift_dist) * (2.0 * np.pi / period))
        # Wave 2: Faster higher-frequency foam ripple (period 12px)
        travel_wave2 = np.sin((y_coords - shift_dist * 1.5) * (2.0 * np.pi / 12.0) + x_coords * 0.1)
        # Lateral turbulence wobble
        lateral_wobble = np.sin(y_coords * 0.08 + phase * 2.0) * 0.5

        # Combined turbulence field
        turb = 0.6 * travel_wave1 + 0.4 * travel_wave2 + lateral_wobble

        # Modulate water channels:
        # Lightness modulation: foam ridges brighten, troughs deepen into richer blue
        foam_boost = np.clip(1.0 + turb * 0.35, 0.65, 1.45)

        # Apply to water pixels
        for c in range(3):
            orig_c = frame_arr[:, :, c]
            boosted = orig_c * foam_boost
            # Whiten peaks when turb is high
            white_add = np.clip((turb - 0.2) * 50.0, 0.0, 70.0)
            boosted = np.clip(boosted + white_add, 0.0, 255.0)
            frame_arr[:, :, c] = np.where(water_mask, boosted, orig_c)

        # 2. Add churning foam streaks moving downward
        # Foam streaks are crisp, bright white specks and vertical lines
        img_out = Image.fromarray(np.clip(frame_arr, 0, 255).astype(np.uint8), mode='RGBA')
        draw = ImageDraw.Draw(img_out)

        # Staggered foam lines along the cascade
        np.random.seed(100 + f * 37)
        num_foam_streaks = 28
        for _ in range(num_foam_streaks):
            if is_left:
                base_x = np.random.randint(65, 205)
            else:
                base_x = np.random.randint(265, 405)
            
            # Position y along the column with downward shift
            raw_y = np.random.randint(80, 680)
            streak_y = (raw_y + int(shift_dist * 2.0)) % 600 + 80
            streak_len = np.random.randint(6, 18)

            if water_mask[min(h - 1, int(streak_y)), min(w - 1, int(base_x))]:
                x_drift = -1 if is_left else 1
                end_y = min(h - 1, streak_y + streak_len)
                end_x = base_x + int(streak_len * 0.1 * x_drift)
                
                # Draw foam streak
                alpha_val = np.random.randint(200, 255)
                draw.line([(base_x, streak_y), (end_x, end_y)], fill=(245, 252, 255, alpha_val), width=1)
                # Head foam bubble
                draw.point((base_x, streak_y), fill=(255, 255, 255, 255))

        # 3. Base splash and churning mist at the bottom (y > 640)
        # Splashing spray droplets
        num_splashes = 16
        for _ in range(num_splashes):
            if is_left:
                splash_x = np.random.randint(40, 180)
            else:
                splash_x = np.random.randint(290, 430)
            splash_y = np.random.randint(650, 720)
            
            # Droplet flying slightly outward and upward
            dx = np.random.randint(-4, 5)
            dy = np.random.randint(-6, -1)
            draw.point((splash_x + dx, splash_y + dy), fill=(250, 255, 255, 230))
            if np.random.rand() > 0.5:
                draw.point((splash_x + dx + 1, splash_y + dy), fill=(210, 240, 255, 180))

        # 4. Lip overflow churn (y: 50 to 80)
        # White foam crest where water tumbles over the rock ledge
        lip_y_base = 56
        lip_x_range = (160, 230) if is_left else (240, 310)
        for lx in range(lip_x_range[0], lip_x_range[1], 3):
            wobble = int(math.sin(lx * 0.2 + phase * 2.0) * 2.0)
            ly = lip_y_base + wobble
            if 0 <= ly < h and 0 <= lx < w and water_mask[ly, lx]:
                draw.point((lx, ly), fill=(255, 255, 255, 240))
                draw.point((lx, ly + 1), fill=(240, 250, 255, 220))

        frames.append(img_out)

    return frames

if __name__ == '__main__':
    print('Testing waterfall edge animation...')
    frames_l = build_waterfall_frames('assets/tiles/ground_waterfall_edge_left.png', is_left=True)
    frames_l[0].save('scratch/test_waterfall_l0.png')
    frames_l[1].save('scratch/test_waterfall_l1.png')
    frames_l[2].save('scratch/test_waterfall_l2.png')
    frames_l[3].save('scratch/test_waterfall_l3.png')
    print('Saved scratch/test_waterfall_l0..l3.png')
