import os
import math
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
import numpy as np

def create_boss_core_frames():
    os.makedirs('d:/GitHub/contraRe/assets/enemies/boss_hydro_goliath/movement', exist_ok=True)
    os.makedirs('d:/GitHub/contraRe/assets/enemies/boss_hydro_goliath/death', exist_ok=True)
    
    base = Image.open('scratch/cut_boss.png').convert('RGBA')
    w, h = base.size
    cx, cy = 453, 461
    radius = 92
    
    # Save base boss image
    base.save('d:/GitHub/contraRe/assets/enemies/boss_hydro_goliath/boss_hydro_goliath.png')
    
    # Crop the turbine circle
    turbine_box = (cx - radius, cy - radius, cx + radius, cy + radius)
    turbine_crop = base.crop(turbine_box)
    
    # Create circular mask for turbine
    mask = Image.new('L', (radius * 2, radius * 2), 0)
    draw_mask = ImageDraw.Draw(mask)
    draw_mask.ellipse((2, 2, radius * 2 - 3, radius * 2 - 3), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(1.5))
    
    # Generate 4 core spinning / energy pulsing frames
    angles = [0.0, 22.5, 45.0, 67.5]
    for i, ang in enumerate(angles):
        frame = base.copy()
        
        # Rotate turbine
        rot_turbine = turbine_crop.rotate(ang, resample=Image.BICUBIC, center=(radius, radius))
        frame.paste(rot_turbine, (cx - radius, cy - radius), mask)
        
        # Add dynamic energy glow & spark arcs
        overlay = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(overlay)
        
        # Conduit pulse intensity
        pulse = 0.7 + 0.3 * math.sin(float(i) * math.pi * 0.5)
        core_col = (int(30 * pulse), int(230 * pulse), int(255 * pulse), int(180 * pulse))
        spark_col = (200, 255, 255, int(220 * pulse))
        
        # Draw energy arcs around turbine ring
        ring_r = 102
        for s in range(6):
            arc_ang = float(s) * (math.pi / 3.0) + float(i) * 0.4
            p1_x = cx + math.cos(arc_ang) * (ring_r - 8)
            p1_y = cy + math.sin(arc_ang) * (ring_r - 8)
            p2_x = cx + math.cos(arc_ang + 0.2) * (ring_r + 6)
            p2_y = cy + math.sin(arc_ang + 0.2) * (ring_r + 6)
            d.line([(p1_x, p1_y), (p2_x, p2_y)], fill=spark_col, width=3)
            d.ellipse((p2_x - 3, p2_y - 3, p2_x + 3, p2_y + 3), fill=(255, 255, 255, 220))
            
        # Water-steam vents puffing at rear
        steam_offsets = [(780, 140), (840, 150), (960, 480)]
        for sx, sy in steam_offsets:
            puff_s = 14 + int(6 * math.sin(float(i) * 1.5 + sx))
            d.ellipse((sx - puff_s, sy - puff_s - i * 3, sx + puff_s, sy + puff_s - i * 3), fill=(200, 235, 255, 70))
            d.ellipse((sx - puff_s*0.6, sy - puff_s*0.6 - i*3, sx + puff_s*0.6, sy + puff_s*0.6 - i*3), fill=(255, 255, 255, 90))
            
        frame = Image.alpha_composite(frame, overlay)
        frame.save(f'd:/GitHub/contraRe/assets/enemies/boss_hydro_goliath/movement/core_{i}.png')
        print(f'Saved movement/core_{i}.png')

def create_boss_death_frames():
    base = Image.open('scratch/cut_boss.png').convert('RGBA')
    w, h = base.size
    cx, cy = 453, 461
    
    # 4 progressive destruction frames
    for i in range(4):
        frame = base.copy()
        
        # Color degradation: progressively desaturate and darken
        enh = ImageEnhance.Color(frame)
        frame = enh.enhance(max(0.1, 1.0 - float(i) * 0.28))
        enh_b = ImageEnhance.Brightness(frame)
        frame = enh_b.enhance(max(0.4, 1.0 - float(i) * 0.18))
        
        overlay = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(overlay)
        
        if i == 0:
            # Frame 0: Electrical rupture in core + crack lines
            d.ellipse((cx - 70, cy - 70, cx + 70, cy + 70), fill=(255, 255, 240, 180))
            for k in range(12):
                ang = float(k) * (math.pi / 6.0)
                d.line([(cx, cy), (cx + math.cos(ang) * 160, cy + math.sin(ang) * 160)], fill=(255, 200, 50, 220), width=4)
                d.line([(cx, cy), (cx + math.cos(ang + 0.1) * 120, cy + math.sin(ang + 0.1) * 120)], fill=(255, 255, 255, 240), width=2)
            d.ellipse((100, 240, 220, 360), fill=(255, 120, 20, 160)) # left cannon flash
            
        elif i == 1:
            # Frame 1: Exploded panels, fireballs & black scorched craters
            d.ellipse((cx - 85, cy - 85, cx + 85, cy + 85), fill=(40, 40, 45, 240)) # crater
            d.ellipse((cx - 60, cy - 60, cx + 60, cy + 60), fill=(255, 90, 10, 200)) # fire
            d.ellipse((cx - 30, cy - 30, cx + 30, cy + 30), fill=(255, 240, 100, 230))
            # Cannon destroyed
            d.ellipse((70, 220, 240, 380), fill=(30, 30, 35, 230))
            # Missile pod blast
            d.ellipse((700, 200, 880, 360), fill=(255, 130, 20, 190))
            d.ellipse((720, 220, 850, 330), fill=(40, 40, 45, 220))
            # Flying shrapnel
            for _ in range(25):
                rx = cx + int(np.random.uniform(-300, 300))
                ry = cy + int(np.random.uniform(-250, 200))
                d.ellipse((rx-4, ry-4, rx+4, ry+4), fill=(255, 180, 40, 220))
                
        elif i == 2:
            # Frame 2: Heavy charred ruin, chassis collapse, billowing dark smoke
            d.ellipse((cx - 100, cy - 100, cx + 100, cy + 100), fill=(20, 20, 24, 250)) # burnt core
            # Smoke clouds
            smoke_locs = [(cx, cy - 60), (cx - 140, cy - 20), (cx + 180, cy - 80), (140, 260), (780, 260)]
            for sm_x, sm_y in smoke_locs:
                for sm_r in [55, 40, 25]:
                    d.ellipse((sm_x - sm_r, sm_y - sm_r, sm_x + sm_r, sm_y + sm_r), fill=(35, 35, 40, 190))
            # Glowing embers
            for _ in range(40):
                rx = cx + int(np.random.uniform(-350, 350))
                ry = cy + int(np.random.uniform(-200, 200))
                d.ellipse((rx-3, ry-3, rx+3, ry+3), fill=(255, 80, 10, 180))
                
        elif i == 3:
            # Frame 3: Dead cold smoking husk
            d.ellipse((cx - 110, cy - 110, cx + 110, cy + 110), fill=(15, 15, 18, 255))
            # Dense black smoke columns
            for sm_x, sm_y in [(cx, cy - 90), (cx - 120, cy - 50), (cx + 160, cy - 70)]:
                d.ellipse((sm_x - 65, sm_y - 65, sm_x + 65, sm_y + 65), fill=(25, 25, 28, 210))
                d.ellipse((sm_x - 40, sm_y - 95, sm_x + 40, sm_y - 15), fill=(35, 35, 38, 170))
            # Final fading sparks
            for _ in range(12):
                rx = cx + int(np.random.uniform(-250, 250))
                ry = cy + int(np.random.uniform(-150, 150))
                d.ellipse((rx-2, ry-2, rx+2, ry+2), fill=(200, 60, 10, 130))

        frame = Image.alpha_composite(frame, overlay)
        frame.save(f'd:/GitHub/contraRe/assets/enemies/boss_hydro_goliath/death/destroy_{i}.png')
        print(f'Saved death/destroy_{i}.png')

if __name__ == '__main__':
    create_boss_core_frames()
    create_boss_death_frames()
