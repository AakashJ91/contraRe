import os
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy.ndimage import map_coordinates

def generate_crawler_animations():
    base_path = r"scratch/crawler_extracted.png"
    if not os.path.exists(base_path):
        raise FileNotFoundError(f"Missing {base_path}")
    
    base_img = Image.open(base_path).convert("RGBA")
    w, h = base_img.size
    print(f"Loaded base crawler sprite: {w}x{h}")
    
    # 6 Leg anchor points (x_k)
    # Group A: 0 (Hind 1), 3 (Mid 2), 5 (Fore 2)
    # Group B: 1 (Hind 2), 2 (Mid 1), 4 (Fore 1)
    leg_x = [120.0, 260.0, 420.0, 540.0, 760.0, 900.0]
    is_group_a = [True, False, False, True, False, True]
    sigma_x = 75.0
    
    # Precompute coordinate grids for backward mapping
    y_coords, x_coords = np.mgrid[0:h, 0:w].astype(np.float32)
    
    # Foreground vs Background legs contrast map:
    # Hind 1 (bg), Hind 2 (fg), Mid 1 (fg), Mid 2 (bg), Fore 1 (fg), Fore 2 (bg)
    is_fg_leg = [False, True, True, False, True, False]
    
    # Base array
    arr_base = np.array(base_img, dtype=np.float32)
    
    # Output directories
    move_dir = r"assets/enemies/crawler/movement"
    death_dir = r"assets/enemies/crawler/death"
    os.makedirs(move_dir, exist_ok=True)
    os.makedirs(death_dir, exist_ok=True)
    
    crawl_frames = []
    
    # -------------------------------------------------------------------------
    # 1. ENHANCED MOVEMENT LOOP (4 FRAMES)
    # -------------------------------------------------------------------------
    print("Generating enhanced 4-frame crawl loop...")
    for f in range(4):
        phase = (f / 4.0) * 2.0 * math.pi
        
        # Upper body vertical bob (2 cycles per stride, natural quadruped/hexapod bob)
        dy_body = 14.0 * math.sin(2.0 * phase)
        # Subtle horizontal pitch/sway
        dx_body = 7.0 * math.cos(phase)
        
        # Height factor: 0 at body (y < 260), 1 at feet (y > 540)
        leg_factor = np.clip((y_coords - 250.0) / 290.0, 0.0, 1.0)
        
        # Calculate leg displacements
        total_weight = np.zeros((h, w), dtype=np.float32)
        total_dx_leg = np.zeros((h, w), dtype=np.float32)
        total_dy_leg = np.zeros((h, w), dtype=np.float32)
        
        for k in range(6):
            lx = leg_x[k]
            wk = np.exp(-((x_coords - lx) / sigma_x) ** 2)
            
            # Leg phase
            l_phase = phase if is_group_a[k] else (phase + math.pi)
            sin_p = math.sin(l_phase)
            cos_p = math.cos(l_phase)
            
            # Increased stride amplitude for distinct readability at arcade scale
            stride_amp_x = 48.0
            lift_amp_y = 44.0
            
            leg_dx = stride_amp_x * cos_p
            if sin_p > 0:
                # Lifting and swinging forward in air
                leg_dy = -lift_amp_y * (sin_p ** 0.85)
            else:
                # Planted on ground pushing back
                leg_dy = 0.0
            
            total_dx_leg += wk * leg_dx
            total_dy_leg += wk * leg_dy
            total_weight += wk
            
        total_weight = np.maximum(total_weight, 1e-4)
        leg_dx_field = total_dx_leg / total_weight
        leg_dy_field = total_dy_leg / total_weight
        
        # Combine body movement and leg movement
        dx_field = (1.0 - leg_factor) * dx_body + leg_factor * leg_dx_field
        dy_field = (1.0 - leg_factor) * dy_body + leg_factor * leg_dy_field
        
        # Head & Mandibles articulation (x > 720)
        head_factor = np.clip((x_coords - 700.0) / 220.0, 0.0, 1.0) * (1.0 - leg_factor * 0.7)
        mandible_open = 20.0 * math.sin(phase)
        # Upper jaw (y < 420) lifts, lower fang (y >= 420) lowers
        jaw_factor = np.where(y_coords < 420.0, -1.0, 1.0)
        dy_field += head_factor * jaw_factor * mandible_open
        dx_field += head_factor * 10.0 * math.cos(phase)
        
        # Abdomen breathing / flexing (x < 420)
        ab_factor = np.clip((420.0 - x_coords) / 420.0, 0.0, 1.0) * (1.0 - leg_factor)
        dy_field -= ab_factor * 6.0 * math.sin(phase)
        
        # Backward coordinate mapping: source = target - displacement
        src_y = np.clip(y_coords - dy_field, 0, h - 1)
        src_x = np.clip(x_coords - dx_field, 0, w - 1)
        
        # Sample RGBA channels
        warped_channels = []
        coords = [src_y, src_x]
        for c in range(4):
            warped_c = map_coordinates(arr_base[:, :, c], coords, order=1, mode='nearest')
            warped_channels.append(warped_c)
        
        warped_arr = np.dstack(warped_channels)
        
        # Leg depth shading: enhance foreground legs slightly, dim background legs
        fg_weight = np.zeros((h, w), dtype=np.float32)
        bg_weight = np.zeros((h, w), dtype=np.float32)
        for k in range(6):
            lx = leg_x[k]
            wk = np.exp(-((x_coords - lx) / sigma_x) ** 2)
            if is_fg_leg[k]:
                fg_weight += wk
            else:
                bg_weight += wk
        fg_bias = (fg_weight - bg_weight) / (fg_weight + bg_weight + 1e-4) # -1 to +1
        leg_shade = 1.0 + 0.15 * fg_bias * leg_factor
        for c in range(3):
            warped_arr[:, :, c] *= leg_shade
        
        # Apply bioluminescent pulsing to green conduits and eyes
        glow_pulse = 1.0 + 0.45 * math.sin(phase * 2.0)
        g_chan = warped_arr[:, :, 1]
        mask_w = (g_chan > 100) & (g_chan > warped_arr[:, :, 0] * 1.1)
        warped_arr[:, :, 1] = np.clip(np.where(mask_w, g_chan * glow_pulse, g_chan), 0, 255)
        # Saturated eye highlights
        warped_arr[:, :, 0] = np.clip(np.where(mask_w, warped_arr[:, :, 0] * (1.0 + 0.25 * math.sin(phase * 2.0)), warped_arr[:, :, 0]), 0, 255)
        
        frame_img = Image.fromarray(np.clip(warped_arr, 0, 255).astype(np.uint8), "RGBA")
        
        out_p = os.path.join(move_dir, f"crawl_{f}.png")
        frame_img.save(out_p)
        crawl_frames.append(frame_img)
        print(f"Saved {out_p}")
        
    # Synchronize master textures
    master_p1 = r"assets/enemies/crawler/crawler.png"
    master_p2 = r"assets/enemies/enemy_crawler.png"
    crawl_frames[0].save(master_p1)
    crawl_frames[0].save(master_p2)
    print(f"Saved master textures {master_p1} and {master_p2}")
    
    # -------------------------------------------------------------------------
    # 2. ENHANCED DEATH EXPLOSION SEQUENCE (4 FRAMES)
    # -------------------------------------------------------------------------
    print("Generating enhanced 4-frame death explosion sequence...")
    death_frames = []
    
    # Frame 0: Structural Rupture & Bright Acid Fissures
    f0_img = crawl_frames[0].copy()
    draw0 = ImageDraw.Draw(f0_img)
    fissures = [
        [(250, 180), (300, 220), (360, 200), (420, 250), (480, 220)],
        [(440, 140), (500, 180), (560, 150), (630, 210), (690, 240)],
        [(640, 230), (700, 280), (760, 270), (820, 330), (880, 360)],
        [(510, 240), (490, 310), (470, 380), (440, 440)],
        [(350, 250), (330, 320), (300, 390)],
        [(750, 330), (790, 390), (810, 460)]
    ]
    for pts in fissures:
        # Outer vibrant acid green glow
        draw0.line(pts, fill=(50, 255, 30, 230), width=8)
        # Mid electric yellow-green
        draw0.line(pts, fill=(180, 255, 60, 255), width=4)
        # Inner white-hot laser core
        draw0.line(pts, fill=(245, 255, 220, 255), width=2)
    
    # Splattering acid sparks
    np.random.seed(42)
    for _ in range(50):
        sx = int(np.random.uniform(220, 850))
        sy = int(np.random.uniform(130, 480))
        rad = np.random.uniform(3, 7)
        draw0.ellipse([sx - rad, sy - rad, sx + rad, sy + rad], fill=(80, 255, 40, 250))
        draw0.ellipse([sx - rad*0.35, sy - rad*0.35, sx + rad*0.35, sy + rad*0.35], fill=(255, 255, 255, 255))
        
    p_d0 = os.path.join(death_dir, "death_0.png")
    f0_img.save(p_d0)
    death_frames.append(f0_img)
    print(f"Saved {p_d0}")
    
    # Frame 1: Organic Carapace Fracture & Internal Detonation
    # Use a jagged diagonal boundary mask along the dorsal plate seam
    f1_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    
    # Create jagged polygon masks for left and right chunks
    # Fracture boundary from top (x=500, y=0) down jaggedly through thorax to bottom
    mask_left = Image.new("L", (w, h), 0)
    draw_ml = ImageDraw.Draw(mask_left)
    jagged_pts_left = [
        (0, 0), (510, 0), (485, 120), (525, 200), (475, 280), (510, 380), (460, 500), (480, h), (0, h)
    ]
    draw_ml.polygon(jagged_pts_left, fill=255)
    
    mask_right = Image.new("L", (w, h), 0)
    draw_mr = ImageDraw.Draw(mask_right)
    jagged_pts_right = [
        (510, 0), (w, 0), (w, h), (480, h), (460, 500), (510, 380), (475, 280), (525, 200), (485, 120)
    ]
    draw_mr.polygon(jagged_pts_right, fill=255)
    
    # Separate halves using the jagged masks
    c0 = crawl_frames[0]
    left_chunk = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    left_chunk.paste(c0, (0, 0), mask_left)
    # Rotate left chunk slightly CCW (-4 deg) and shift back-left
    left_chunk = left_chunk.rotate(-5, resample=Image.Resampling.BILINEAR, center=(250, 350))
    f1_img.paste(left_chunk, (-35, -20), left_chunk)
    
    right_chunk = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    right_chunk.paste(c0, (0, 0), mask_right)
    # Rotate right chunk CW (+6 deg) and shift up-right
    right_chunk = right_chunk.rotate(6, resample=Image.Resampling.BILINEAR, center=(700, 350))
    f1_img.paste(right_chunk, (30, -35), right_chunk)
    
    # Detached spinning foreleg flying out
    foreleg_crop = c0.crop((780, 420, 960, 660)).rotate(45, expand=True)
    f1_img.paste(foreleg_crop, (740, 180), foreleg_crop)
    
    # Massive internal core acid explosion
    draw1 = ImageDraw.Draw(f1_img)
    core_x, core_y = 490, 310
    # Charcoal smoke backdrop
    for _ in range(20):
        ox = core_x + np.random.uniform(-130, 130)
        oy = core_y + np.random.uniform(-100, 90)
        r_smoke = np.random.uniform(45, 85)
        draw1.ellipse([ox - r_smoke, oy - r_smoke, ox + r_smoke, oy + r_smoke], fill=(25, 32, 26, 210))
    # Acid fireball burst lobes
    for _ in range(16):
        ox = core_x + np.random.uniform(-90, 90)
        oy = core_y + np.random.uniform(-75, 65)
        r_ball = np.random.uniform(50, 95)
        draw1.ellipse([ox - r_ball, oy - r_ball, ox + r_ball, oy + r_ball], fill=(40, 230, 30, 240))
        draw1.ellipse([ox - r_ball*0.68, oy - r_ball*0.68, ox + r_ball*0.68, oy + r_ball*0.68], fill=(160, 255, 50, 250))
        draw1.ellipse([ox - r_ball*0.35, oy - r_ball*0.35, ox + r_ball*0.35, oy + r_ball*0.35], fill=(245, 255, 210, 255))
        
    # High-velocity acid jets spraying outward
    for _ in range(35):
        jx = core_x + np.random.uniform(-180, 180)
        jy = core_y + np.random.uniform(-150, 140)
        jr = np.random.uniform(4, 9)
        draw1.ellipse([jx - jr, jy - jr, jx + jr, jy + jr], fill=(100, 255, 60, 255))
        draw1.ellipse([jx - jr*0.4, jy - jr*0.4, jx + jr*0.4, jy + jr*0.4], fill=(255, 255, 255, 255))
        
    p_d1 = os.path.join(death_dir, "death_1.png")
    f1_img.save(p_d1)
    death_frames.append(f1_img)
    print(f"Saved {p_d1}")
    
    # Frame 2: Expanding Acid Firestorm & Disintegrating Shrapnel
    f2_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw2 = ImageDraw.Draw(f2_img)
    
    # Charcoal smoke cloud backdrop
    for _ in range(30):
        ox = core_x + np.random.uniform(-200, 200)
        oy = core_y + np.random.uniform(-160, 130)
        r_smoke = np.random.uniform(60, 130)
        draw2.ellipse([ox - r_smoke, oy - r_smoke, ox + r_smoke, oy + r_smoke], fill=(22, 28, 22, 200))
        
    # Main outer green plasma firestorm
    for _ in range(25):
        ox = core_x + np.random.uniform(-150, 150)
        oy = core_y + np.random.uniform(-125, 95)
        r_ball = np.random.uniform(70, 140)
        draw2.ellipse([ox - r_ball, oy - r_ball, ox + r_ball, oy + r_ball], fill=(30, 210, 45, 225))
        draw2.ellipse([ox - r_ball*0.65, oy - r_ball*0.65, ox + r_ball*0.65, oy + r_ball*0.65], fill=(150, 255, 55, 245))
        draw2.ellipse([ox - r_ball*0.3, oy - r_ball*0.3, ox + r_ball*0.3, oy + r_ball*0.3], fill=(245, 255, 190, 255))
        
    # Flying scorched carapace shards
    for _ in range(16):
        ox = core_x + np.random.uniform(-220, 220)
        oy = core_y + np.random.uniform(-160, 140)
        sw, sh = np.random.uniform(15, 35), np.random.uniform(10, 25)
        draw2.rectangle([ox - sw*0.5, oy - sh*0.5, ox + sw*0.5, oy + sh*0.5], fill=(35, 42, 38, 250))
        draw2.line([(ox - sw*0.5, oy), (ox + sw*0.5, oy - 3)], fill=(120, 255, 80, 240), width=2)
        
    # Sizzling acid droplets & bio-splatter
    for _ in range(80):
        sx = core_x + np.random.uniform(-300, 300)
        sy = core_y + np.random.uniform(-210, 190)
        rad = np.random.uniform(3, 11)
        draw2.ellipse([sx - rad, sy - rad, sx + rad, sy + rad], fill=(40, 250, 60, 255))
        draw2.ellipse([sx - rad*0.35, sy - rad*0.35, sx + rad*0.35, sy + rad*0.35], fill=(255, 255, 220, 255))
        
    p_d2 = os.path.join(death_dir, "death_2.png")
    f2_img.save(p_d2)
    death_frames.append(f2_img)
    print(f"Saved {p_d2}")
    
    # Frame 3: Wide Sizzling Slurry Pool & Dissolving Chitin Claws
    f3_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw3 = ImageDraw.Draw(f3_img)
    
    puddle_cx, puddle_cy = 490, 560
    # Wide dissolving acid pool on floor
    draw3.ellipse([puddle_cx - 300, puddle_cy - 48, puddle_cx + 300, puddle_cy + 48], fill=(20, 130, 30, 180))
    draw3.ellipse([puddle_cx - 230, puddle_cy - 34, puddle_cx + 230, puddle_cy + 34], fill=(50, 215, 60, 215))
    draw3.ellipse([puddle_cx - 150, puddle_cy - 20, puddle_cx + 150, puddle_cy + 20], fill=(155, 255, 85, 245))
    draw3.ellipse([puddle_cx - 70, puddle_cy - 10, puddle_cx + 70, puddle_cy + 10], fill=(235, 255, 190, 255))
    
    # Scorched chitin claw remnants in pool
    for _ in range(12):
        ox = puddle_cx + np.random.uniform(-210, 210)
        oy = puddle_cy + np.random.uniform(-20, 20)
        w_chunk = np.random.uniform(15, 45)
        h_chunk = np.random.uniform(10, 26)
        draw3.rectangle([ox - w_chunk*0.5, oy - h_chunk*0.5, ox + w_chunk*0.5, oy + h_chunk*0.5], fill=(28, 34, 28, 245))
        draw3.line([(ox - w_chunk*0.5, oy), (ox + w_chunk*0.5, oy - 2)], fill=(70, 90, 70, 255), width=3)
        
    # Acid bubbles bursting
    for _ in range(20):
        bx = puddle_cx + np.random.uniform(-240, 240)
        by = puddle_cy - np.random.uniform(-25, 25)
        br = np.random.uniform(5, 15)
        draw3.ellipse([bx - br, by - br, bx + br, by + br], fill=(90, 255, 110, 230))
        draw3.ellipse([bx - br*0.3, by - br*0.3, bx + br*0.3, by + br*0.3], fill=(255, 255, 255, 255))
        
    # Rising green vapor smoke wisps
    for i in range(10):
        vx = puddle_cx + np.random.uniform(-140, 140)
        vy = puddle_cy - 45 - i * 20
        vr = np.random.uniform(18, 38)
        draw3.ellipse([vx - vr, vy - vr, vx + vr, vy + vr], fill=(35, 75, 35, int(140 - i * 13)))
        
    p_d3 = os.path.join(death_dir, "death_3.png")
    f3_img.save(p_d3)
    death_frames.append(f3_img)
    print(f"Saved {p_d3}")
    
    # -------------------------------------------------------------------------
    # 3. CREATE SHOWCASE & ANIMATED GIFS
    # -------------------------------------------------------------------------
    cell_w, cell_h = 320, 220
    showcase = Image.new("RGBA", (cell_w * 4, cell_h * 2), (18, 22, 26, 255))
    draw_sc = ImageDraw.Draw(showcase)
    
    for i in range(4):
        im = crawl_frames[i].copy()
        im.thumbnail((cell_w - 20, cell_h - 40))
        ox = i * cell_w + (cell_w - im.width) // 2
        oy = (cell_h - 20 - im.height) // 2
        showcase.paste(im, (ox, oy), im)
        draw_sc.text((i * cell_w + 15, cell_h - 25), f"CRAWL STRIDE {i}", fill=(100, 240, 130, 255))
        
    for i in range(4):
        im = death_frames[i].copy()
        im.thumbnail((cell_w - 20, cell_h - 40))
        ox = i * cell_w + (cell_w - im.width) // 2
        oy = cell_h + (cell_h - 20 - im.height) // 2
        showcase.paste(im, (ox, oy), im)
        draw_sc.text((i * cell_w + 15, cell_h * 2 - 25), f"ACID CRASH {i}", fill=(255, 140, 60, 255))
        
    sc_path = r"C:\Users\aakas\.gemini\antigravity-ide\brain\29613d14-c9d7-4e89-b64b-644c91b2da16\crawler_animations_showcase.png"
    showcase.save(sc_path)
    print(f"Saved showcase to {sc_path}")
    
    gif_crawl_path = r"C:\Users\aakas\.gemini\antigravity-ide\brain\29613d14-c9d7-4e89-b64b-644c91b2da16\crawler_crawl_loop.gif"
    gif_crawl_frames = [f.resize((360, 246), Image.Resampling.LANCZOS) for f in crawl_frames]
    gif_crawl_frames[0].save(
        gif_crawl_path,
        save_all=True,
        append_images=gif_crawl_frames[1:],
        duration=120,
        loop=0,
        disposal=2
    )
    print(f"Saved crawl GIF to {gif_crawl_path}")
    
    gif_death_path = r"C:\Users\aakas\.gemini\antigravity-ide\brain\29613d14-c9d7-4e89-b64b-644c91b2da16\crawler_death_loop.gif"
    gif_death_frames = [f.resize((360, 246), Image.Resampling.LANCZOS) for f in death_frames]
    gif_death_frames[0].save(
        gif_death_path,
        save_all=True,
        append_images=gif_death_frames[1:],
        duration=140,
        loop=0,
        disposal=2
    )
    print(f"Saved death GIF to {gif_death_path}")

if __name__ == "__main__":
    generate_crawler_animations()
