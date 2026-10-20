import math
import random
from PIL import Image

def generate_metal_slug_explosion():
    w, h = 96, 96
    cx, cy = 48, 48
    out_dir = "d:/GitHub/contraRe/scratch"
    
    # 16-bit Neo-Geo / Contra arcade indexed palette
    C_OUTLINE = (18, 12, 22, 255)
    C_DARK_RED = (145, 22, 16, 255)
    C_MID_RED = (205, 45, 18, 255)
    C_ORANGE = (250, 125, 22, 255)
    C_YELLOW = (255, 220, 65, 255)
    C_WHITE = (255, 255, 240, 255)
    
    C_SMOKE_DEEP = (38, 32, 44, 255)
    C_SMOKE_MID = (68, 58, 76, 255)
    C_SMOKE_LIGHT = (112, 100, 124, 255)
    
    frames = []
    
    for f in range(8):
        t = f / 7.0
        grid = [[0 for _ in range(w)] for _ in range(h)]
        random.seed(100 + f * 53)
        
        # Harmonic flame contour radius function: R(theta)
        # Combines multiple sinusoidal frequencies to create jagged organic flame tongues
        harmonics = [
            (3, random.uniform(3.0, 7.0), random.uniform(0, math.tau)),
            (5, random.uniform(4.0, 9.0), random.uniform(0, math.tau)),
            (7, random.uniform(3.0, 6.0), random.uniform(0, math.tau)),
            (11, random.uniform(2.0, 4.0), random.uniform(0, math.tau)),
        ]
        
        # Base expansion curve
        if t < 0.15:
            base_r = 12.0 + t * 60.0
        elif t < 0.45:
            base_r = 21.0 + (t - 0.15) * 45.0
        else:
            base_r = 34.0 + (t - 0.45) * 8.0
            
        y_shift = -t * 10.0 if t > 0.35 else 0.0 # Rising fireball/smoke
        center_y = cy + y_shift
        
        # Sub-flame nodes to break up the shape and create turbulent crevices
        num_sub_lobes = 5 if t < 0.3 else 8
        sub_lobes = []
        for i in range(num_sub_lobes):
            ang = i * (math.tau / num_sub_lobes) + random.uniform(-0.3, 0.3)
            dist = random.uniform(base_r * 0.4, base_r * 0.9)
            sub_lobes.append((cx + math.cos(ang) * dist, center_y + math.sin(ang) * dist, random.uniform(base_r * 0.25, base_r * 0.45)))
        
        # Sparks / debris flying outward
        num_sparks = int(8 + t * 12) if t < 0.6 else int(18 * (1.0 - t))
        spark_pts = []
        for s in range(num_sparks):
            s_ang = random.uniform(0, math.tau)
            s_dist = base_r * random.uniform(1.05, 1.45)
            spark_pts.append((int(cx + math.cos(s_ang) * s_dist), int(center_y + math.sin(s_ang) * s_dist)))
        
        # Rasterize distance field
        for y in range(h):
            for x in range(w):
                dx = x - cx
                dy = y - center_y
                dist_c = math.hypot(dx, dy)
                ang = math.atan2(dy, dx)
                
                # Modulated radius
                mod_r = base_r
                for freq, amp, phase in harmonics:
                    mod_r += math.sin(ang * freq + phase) * amp
                
                # Check main body
                inside_val = dist_c - mod_r
                
                # Also check sub-lobes
                for lx, ly, lrad in sub_lobes:
                    d_l = math.hypot(x - lx, y - ly) - lrad
                    if d_l < inside_val:
                        inside_val = d_l
                
                # Map depth to color
                if inside_val <= 0:
                    depth = -inside_val
                    
                    if t < 0.42:
                        # Full incandescent flame bloom
                        if depth > base_r * 0.58:
                            val = 6 # White
                        elif depth > base_r * 0.38:
                            val = 5 # Yellow
                        elif depth > base_r * 0.20:
                            val = 4 # Orange
                        elif depth > base_r * 0.08:
                            val = 3 # Mid red
                        else:
                            val = 2 # Dark red
                    elif t < 0.70:
                        # Transitioning to rolling dark smoke with burning crevices
                        # Cellular noise for smoke/fire separation
                        noise = (math.sin(x * 0.3) + math.cos(y * 0.3)) * 0.5
                        if depth > base_r * 0.45 and noise > 0.1:
                            val = 5 if depth > base_r * 0.6 else 4 # Fire pocket
                        elif depth > base_r * 0.25 and noise > 0.0:
                            val = 3 # Red ember
                        elif depth > base_r * 0.35:
                            val = 9 # Smoke light
                        elif depth > base_r * 0.15:
                            val = 8 # Smoke mid
                        else:
                            val = 7 # Smoke dark
                    else:
                        # Cooling fading smoke cloud
                        noise = (math.sin(x * 0.25) * math.cos(y * 0.25))
                        if depth > base_r * 0.4 and (x + y * 3) % 19 == 0:
                            val = 4 # Tiny glowing spark
                        elif depth > base_r * 0.28 and noise > 0.1:
                            val = 9
                        elif depth > base_r * 0.12:
                            val = 8
                        else:
                            val = 7
                            
                    grid[y][x] = val
        
        # Add sparks
        for sx, sy in spark_pts:
            if 1 <= sx < w - 1 and 1 <= sy < h - 1:
                grid[sy][sx] = 5 if t < 0.4 else 4
                grid[sy][sx + 1] = 4
        
        # Compute crisp dark outline on outer perimeter
        final_grid = [[grid[y][x] for x in range(w)] for y in range(h)]
        for y in range(1, h - 1):
            for x in range(1, w - 1):
                if grid[y][x] == 0:
                    for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                        if grid[y + dy][x + dx] > 1:
                            final_grid[y][x] = 1 # Outline
                            break
                            
        # Render image
        im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        palette_map = {
            1: C_OUTLINE,
            2: C_DARK_RED,
            3: C_MID_RED,
            4: C_ORANGE,
            5: C_YELLOW,
            6: C_WHITE,
            7: C_SMOKE_DEEP,
            8: C_SMOKE_MID,
            9: C_SMOKE_LIGHT
        }
        
        for y in range(h):
            for x in range(w):
                v = final_grid[y][x]
                if v in palette_map:
                    im.putpixel((x, y), palette_map[v])
                    
        frames.append(im)
        im.save(f"{out_dir}/neo_geo_frame_{f}.png")
        
    # Spritesheet
    sheet = Image.new("RGBA", (w * 8, h), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        sheet.paste(frame, (i * w, 0))
    sheet.save(f"{out_dir}/neo_geo_explosion_sheet.png")
    print("Saved Neo-Geo style explosion frames!")

if __name__ == "__main__":
    generate_metal_slug_explosion()
