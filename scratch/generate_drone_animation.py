import os, math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

def create_drone_animations():
    base_drone_path = "scratch/drone_extracted.png"
    base_drone = Image.open(base_drone_path).convert("RGBA")
    w, h = base_drone.size # ~1148 x 517
    
    os.makedirs("assets/enemies/drone/movement", exist_ok=True)
    os.makedirs("assets/enemies/drone/death", exist_ok=True)
    
    # Save base static drone
    base_drone.save("assets/enemies/drone/drone.png")
    base_drone.save("assets/enemies/enemy_drone.png")
    print("Saved base drone.png and enemy_drone.png")
    
    # -------------------------------------------------------------------------
    # Helper: Draw pixel fireball
    # -------------------------------------------------------------------------
    def draw_pixel_fireball(target_img, cx, cy, radius, seed=0):
        np.random.seed(seed)
        draw = ImageDraw.Draw(target_img, 'RGBA')
        num_lobes = 12
        lobes = []
        for i in range(num_lobes):
            ang = (i / float(num_lobes)) * 2 * np.pi + np.random.uniform(-0.25, 0.25)
            dist = np.random.uniform(0.12, 0.55) * radius
            rad = np.random.uniform(0.38, 0.65) * radius
            lobes.append((cx + np.cos(ang) * dist, cy + np.sin(ang) * dist, rad))
            
        palette = [
            (35, 12, 8, 245),       # Charcoal crust
            (170, 30, 10, 255),     # Deep crimson flame
            (245, 110, 15, 255),    # Vivid burning orange
            (255, 205, 30, 255),    # Fiery golden amber
            (255, 255, 220, 255)    # Incandescent white core
        ]
        radii = [1.22, 1.0, 0.72, 0.44, 0.22]
        for col, factor in zip(palette, radii):
            for lx, ly, lr in lobes:
                r = lr * factor
                draw.ellipse([lx - r, ly - r, lx + r, ly + r], fill=col)
                
        # Pixel sparks
        spark_col = palette[3]
        for _ in range(int(radius * 0.25)):
            ang = np.random.uniform(0, 2 * np.pi)
            dist = np.random.uniform(radius * 0.70, radius * 1.55)
            sx = cx + np.cos(ang) * dist
            sy = cy + np.sin(ang) * dist
            sz = np.random.choice([3, 4, 6])
            draw.rectangle([sx, sy, sx + sz, sy + sz], fill=spark_col)

    def draw_pixel_smoke(target_img, cx, cy, radius, seed=0):
        np.random.seed(seed)
        draw = ImageDraw.Draw(target_img, 'RGBA')
        num_lobes = 10
        lobes = []
        for i in range(num_lobes):
            ang = (i / float(num_lobes)) * 2 * np.pi + np.random.uniform(-0.35, 0.35)
            dist = np.random.uniform(0.1, 0.6) * radius
            rad = np.random.uniform(0.35, 0.65) * radius
            lobes.append((cx + np.cos(ang) * dist, cy + np.sin(ang) * dist, rad))
        palette = [
            (22, 24, 30, 230),   # Dark charcoal
            (52, 56, 68, 240),   # Deep slate
            (88, 95, 110, 245),  # Mid ash
            (135, 145, 160, 250) # Highlight rim
        ]
        radii = [1.2, 1.0, 0.68, 0.32]
        for col, factor in zip(palette, radii):
            for lx, ly, lr in lobes:
                r = lr * factor
                draw.ellipse([lx - r, ly - r, lx + r, ly + r], fill=col)

    # -------------------------------------------------------------------------
    # 1. MOVEMENT / FLIGHT ANIMATION LOOP (fly_0 .. fly_3)
    # -------------------------------------------------------------------------
    fly_frames = []
    
    # Turbine blade parameters
    # Rear turbine center & elliptical radii in base image
    rt_cx, rt_cy = 880, 168
    rt_rx, rt_ry = 145, 62
    
    # Front-left turbine center
    ft_cx, ft_cy = 135, 192
    ft_rx, ft_ry = 110, 48
    
    # Optic eye center & radius
    eye_cx, eye_cy = 115, 305
    eye_r = 28
    
    hover_offsets = [0, -6, -10, -5]
    
    for frame_idx in range(4):
        f = base_drone.copy()
        draw = ImageDraw.Draw(f, 'RGBA')
        
        theta = frame_idx * (np.pi / 4.0 / 4.0) # 0, 11.25, 22.5, 33.75 deg
        
        # 1. Animate Rear Turbine Fan Blades (8 blades)
        # Draw fan blades inside the rear turbine duct opening
        for k in range(8):
            phi = theta + k * (2.0 * np.pi / 8.0)
            # Tip of blade in elliptical projection
            bx = rt_cx + rt_rx * np.cos(phi)
            by = rt_cy + rt_ry * np.sin(phi)
            
            # Root of blade near spinner cone
            rx = rt_cx + 26.0 * np.cos(phi)
            ry = rt_cy + 12.0 * np.sin(phi)
            
            # Shading depends on blade angle
            norm_sin = (np.sin(phi) + 1.0) * 0.5
            blade_col = (int(50 + 75 * norm_sin), int(55 + 80 * norm_sin), int(65 + 90 * norm_sin), 235)
            edge_col  = (int(160 + 80 * norm_sin), int(175 + 75 * norm_sin), int(195 + 60 * norm_sin), 245)
            
            # Blade line and highlight
            draw.line([(rx, ry), (bx, by)], fill=blade_col, width=6)
            draw.line([(rx, ry - 1), (bx, by - 1)], fill=edge_col, width=2)
            
        # Redraw center spinner cone
        draw.ellipse([rt_cx - 24, rt_cy - 14, rt_cx + 24, rt_cy + 14], fill=(70, 78, 88, 255), outline=(20, 24, 28, 255), width=2)
        draw.ellipse([rt_cx - 14, rt_cy - 8, rt_cx + 14, rt_cy + 8], fill=(160, 175, 190, 255))
        
        # 2. Animate Front-Left Turbine Fan Blades (visible portion behind the fuselage)
        for k in range(8):
            phi = theta + k * (2.0 * np.pi / 8.0)
            bx = ft_cx + ft_rx * np.cos(phi)
            by = ft_cy + ft_ry * np.sin(phi)
            rx = ft_cx + 20.0 * np.cos(phi)
            ry = ft_cy + 10.0 * np.sin(phi)
            # Only draw in upper/left quadrant where duct is visible
            if bx < 210 and by < 240:
                draw.line([(rx, ry), (bx, by)], fill=(70, 76, 85, 230), width=5)
                draw.line([(rx, ry - 1), (bx, by - 1)], fill=(150, 165, 180, 240), width=2)
                
        # 3. Animate Glowing Cyclops Optic Visor Scanner
        # Frame 0: steady ruby with bright dot
        # Frame 1: scanning slit glint sweeping left-to-right
        # Frame 2: maximum acquisition pulse bloom
        # Frame 3: contracted sharp pupil
        if frame_idx == 0:
            draw.ellipse([eye_cx - eye_r, eye_cy - eye_r, eye_cx + eye_r, eye_cy + eye_r], fill=(195, 15, 25, 255))
            draw.ellipse([eye_cx - 18, eye_cy - 18, eye_cx + 18, eye_cy + 18], fill=(240, 45, 60, 255))
            draw.ellipse([eye_cx - 10, eye_cy - 12, eye_cx - 2, eye_cy - 4], fill=(255, 255, 255, 255))
        elif frame_idx == 1:
            draw.ellipse([eye_cx - eye_r, eye_cy - eye_r, eye_cx + eye_r, eye_cy + eye_r], fill=(215, 25, 35, 255))
            draw.ellipse([eye_cx - 18, eye_cy - 18, eye_cx + 18, eye_cy + 18], fill=(255, 75, 85, 255))
            # Horizontal laser sweep line
            draw.line([(eye_cx - 22, eye_cy), (eye_cx + 22, eye_cy)], fill=(255, 240, 240, 255), width=3)
            draw.ellipse([eye_cx - 6, eye_cy - 6, eye_cx + 6, eye_cy + 6], fill=(255, 255, 255, 255))
        elif frame_idx == 2:
            # Full acquisition bloom corona
            draw.ellipse([eye_cx - eye_r - 8, eye_cy - eye_r - 8, eye_cx + eye_r + 8, eye_cy + eye_r + 8], fill=(255, 40, 50, 90))
            draw.ellipse([eye_cx - eye_r, eye_cy - eye_r, eye_cx + eye_r, eye_cy + eye_r], fill=(255, 20, 30, 255))
            draw.ellipse([eye_cx - 20, eye_cy - 20, eye_cx + 20, eye_cy + 20], fill=(255, 110, 110, 255))
            draw.ellipse([eye_cx - 12, eye_cy - 12, eye_cx + 12, eye_cy + 12], fill=(255, 255, 255, 255))
        elif frame_idx == 3:
            draw.ellipse([eye_cx - eye_r, eye_cy - eye_r, eye_cx + eye_r, eye_cy + eye_r], fill=(180, 10, 20, 255))
            draw.ellipse([eye_cx - 16, eye_cy - 16, eye_cx + 16, eye_cy + 16], fill=(230, 35, 45, 255))
            draw.ellipse([eye_cx - 6, eye_cy - 6, eye_cx + 6, eye_cy + 6], fill=(255, 220, 220, 255))
            
        # 4. Animated Rear Thruster Vectoring Exhaust Plasma Jet
        # Rear exhaust nozzle is at x ≈ 640..660, y ≈ 335
        nozzle_x = 648
        nozzle_y = 338
        jet_lens = [32.0, 50.0, 68.0, 42.0]
        jl = jet_lens[frame_idx]
        
        # Outer flame cone
        draw.polygon([
            (nozzle_x, nozzle_y - 12),
            (nozzle_x + jl, nozzle_y),
            (nozzle_x, nozzle_y + 12)
        ], fill=(30, 140, 255, 200))
        # Inner cyan core
        draw.polygon([
            (nozzle_x, nozzle_y - 7),
            (nozzle_x + jl * 0.65, nozzle_y),
            (nozzle_x, nozzle_y + 7)
        ], fill=(140, 240, 255, 240))
        # White hot spark base
        draw.ellipse([nozzle_x - 4, nozzle_y - 5, nozzle_x + 8, nozzle_y + 5], fill=(255, 255, 255, 255))
        
        # Apply hover offset dy
        dy = hover_offsets[frame_idx]
        final_im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        final_im.paste(f, (0, dy), f)
        
        out_path = f"assets/enemies/drone/movement/fly_{frame_idx}.png"
        final_im.save(out_path)
        fly_frames.append(final_im)
        print(f"Saved flight frame: {out_path}")
        
    # -------------------------------------------------------------------------
    # 2. DEATH / CRASH ANIMATION LOOP (crash_0 .. crash_3)
    # -------------------------------------------------------------------------
    for frame_idx in range(4):
        f = base_drone.copy()
        draw = ImageDraw.Draw(f, 'RGBA')
        
        if frame_idx == 0:
            # Frame 0: Chassis fracture, shattered optic lens, electrical arcing
            # Shattered optic eye
            draw.ellipse([eye_cx - eye_r, eye_cy - eye_r, eye_cx + eye_r, eye_cy + eye_r], fill=(20, 20, 25, 255))
            draw.line([(eye_cx - 24, eye_cy - 12), (eye_cx + 18, eye_cy + 14)], fill=(255, 180, 50, 255), width=3)
            draw.line([(eye_cx - 10, eye_cy + 20), (eye_cx + 14, eye_cy - 18)], fill=(255, 255, 255, 255), width=2)
            
            # Electric short-circuit arcs across fuselage
            arc_pts = [
                (140, 290), (190, 260), (260, 275), (340, 230),
                (420, 250), (510, 210), (620, 235), (710, 190)
            ]
            for p in range(len(arc_pts) - 1):
                mid_x = (arc_pts[p][0] + arc_pts[p+1][0]) * 0.5 + np.random.uniform(-15, 15)
                mid_y = (arc_pts[p][1] + arc_pts[p+1][1]) * 0.5 + np.random.uniform(-15, 15)
                draw.line([arc_pts[p], (mid_x, mid_y), arc_pts[p+1]], fill=(120, 240, 255, 240), width=3)
                draw.line([arc_pts[p], (mid_x, mid_y), arc_pts[p+1]], fill=(255, 255, 255, 255), width=1)
                
            # Initial combustion pop on the front engine
            draw_pixel_fireball(f, 320, 280, radius=55, seed=10)
            
        elif frame_idx == 1:
            # Frame 1: Internal fuel cell explosion, severed turbine, flying shrapnel
            draw_pixel_fireball(f, 450, 260, radius=110, seed=20)
            draw_pixel_fireball(f, 280, 320, radius=80, seed=21)
            draw_pixel_smoke(f, 400, 210, radius=70, seed=22)
            
            # Flying metal shrapnel
            for _ in range(12):
                sx = np.random.uniform(200, 700)
                sy = np.random.uniform(150, 380)
                sw = np.random.uniform(10, 25)
                sh = np.random.uniform(6, 14)
                draw.rectangle([sx, sy, sx + sw, sy + sh], fill=(45, 50, 60, 255), outline=(180, 70, 20, 255))
                
        elif frame_idx == 2:
            # Frame 2: Massive cascading fireball engulfing entire fuselage, thick smoke
            draw_pixel_fireball(f, 500, 270, radius=170, seed=30)
            draw_pixel_fireball(f, 300, 290, radius=130, seed=31)
            draw_pixel_fireball(f, 750, 240, radius=120, seed=32)
            draw_pixel_smoke(f, 450, 160, radius=110, seed=33)
            draw_pixel_smoke(f, 650, 140, radius=95, seed=34)
            draw_pixel_smoke(f, 250, 200, radius=85, seed=35)
            
        elif frame_idx == 3:
            # Frame 3: Charred shattered ruin breaking apart with dissipating smoke & embers
            # Darken original fuselage hull
            arr = np.array(f, dtype=np.float32)
            gray = np.mean(arr[:, :, :3], axis=2)
            arr[:, :, 0] = np.clip(gray * 0.35 + 20.0, 0, 255)
            arr[:, :, 1] = np.clip(gray * 0.30 + 15.0, 0, 255)
            arr[:, :, 2] = np.clip(gray * 0.30 + 15.0, 0, 255)
            arr[:, :, 3] = arr[:, :, 3] * 0.75 # fading alpha
            f = Image.fromarray(arr.astype(np.uint8), mode='RGBA')
            
            draw_pixel_smoke(f, 520, 220, radius=130, seed=40)
            draw_pixel_smoke(f, 320, 250, radius=105, seed=41)
            draw_pixel_smoke(f, 740, 200, radius=90, seed=42)
            
            # Molten slag glow
            draw = ImageDraw.Draw(f, 'RGBA')
            for _ in range(15):
                ex = np.random.uniform(250, 780)
                ey = np.random.uniform(220, 380)
                er = np.random.uniform(5, 14)
                draw.ellipse([ex - er, ey - er*0.6, ex + er, ey + er*0.6], fill=(255, 90, 15, 230))
                draw.ellipse([ex - er*0.5, ey - er*0.3, ex + er*0.5, ey + er*0.3], fill=(255, 220, 60, 255))
        
        out_path = f"assets/enemies/drone/death/crash_{frame_idx}.png"
        f.save(out_path)
        print(f"Saved crash frame: {out_path}")
        
    # -------------------------------------------------------------------------
    # Generate Animated GIFs & Showcase Matrix
    # -------------------------------------------------------------------------
    gif_move_path = r"C:\Users\aakas\.gemini\antigravity-ide\brain\29613d14-c9d7-4e89-b64b-644c91b2da16\drone_fly_loop.gif"
    fly_frames[0].save(gif_move_path, save_all=True, append_images=fly_frames[1:], duration=150, loop=0)
    
    death_frames = [Image.open(f"assets/enemies/drone/death/crash_{i}.png") for i in range(4)]
    gif_death_path = r"C:\Users\aakas\.gemini\antigravity-ide\brain\29613d14-c9d7-4e89-b64b-644c91b2da16\drone_crash_loop.gif"
    death_frames[0].save(gif_death_path, save_all=True, append_images=death_frames[1:], duration=150, loop=0)
    
    # 4x2 matrix showcase image
    showcase = Image.new("RGBA", (w * 4, h * 2), (18, 22, 28, 255))
    for i in range(4):
        showcase.paste(fly_frames[i], (i * w, 0), fly_frames[i])
        showcase.paste(death_frames[i], (i * w, h), death_frames[i])
    
    # Resize showcase to manageable display resolution (~1280 x 576)
    thumb_w = 1280
    thumb_h = int(showcase.height * (float(thumb_w) / float(showcase.width)))
    showcase_thumb = showcase.resize((thumb_w, thumb_h), resample=Image.BICUBIC)
    
    showcase_path = r"C:\Users\aakas\.gemini\antigravity-ide\brain\29613d14-c9d7-4e89-b64b-644c91b2da16\drone_animations_showcase.png"
    showcase_thumb.save(showcase_path)
    showcase_thumb.save("scratch/drone_showcase.png")
    print("Showcase saved to", showcase_path)

if __name__ == "__main__":
    create_drone_animations()
