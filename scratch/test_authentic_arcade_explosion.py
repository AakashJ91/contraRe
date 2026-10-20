import math
import random
from PIL import Image, ImageDraw

def generate_authentic_pixel_explosion():
    # Render at native 16-bit retro resolution (64x64) then upscale 2x nearest-neighbor to 128x128
    # for genuine chunky arcade pixel-art aesthetic (Neo-Geo / CPS2 arcade style)
    w, h = 64, 64
    out_dir = "d:/GitHub/contraRe/scratch"
    
    # 5-tone 16-bit arcade palette
    PALETTE = {
        "outline": (18, 12, 22, 255),
        "dark_red": (140, 24, 18, 255),
        "bright_red": (215, 52, 20, 255),
        "orange": (250, 140, 25, 255),
        "yellow": (255, 225, 80, 255),
        "core_white": (255, 255, 240, 255),
        "smoke_dark": (45, 40, 50, 255),
        "smoke_mid": (85, 75, 90, 255),
        "smoke_light": (140, 130, 145, 255)
    }
    
    frames = []
    
    for f in range(8):
        t = f / 7.0
        # Grid of pixel values: 0 = transparent, 1 = outline, 2 = dark_red, 3 = bright_red, 4 = orange, 5 = yellow, 6 = core_white
        grid = [[0 for _ in range(w)] for _ in range(h)]
        cx, cy = 32, 32
        
        # Cellular flame clusters with turbulent angle displacement
        random.seed(42 + f * 99)
        num_lobes = 7 + int(t * 8) if t < 0.6 else 14
        
        # Max radius over time
        if t < 0.2:
            max_r = 10 + t * 50
        elif t < 0.5:
            max_r = 20 + (t - 0.2) * 20
        else:
            max_r = 26 + (t - 0.5) * 6
            
        lobes = []
        for i in range(num_lobes):
            ang = i * (2 * math.pi / num_lobes) + random.uniform(-0.25, 0.25)
            # Jagged flame tongues
            dist = random.uniform(max_r * 0.35, max_r)
            if (i % 2 == 1) and t < 0.6:
                dist *= 1.25 # Sharp flame spike
            lx = cx + math.cos(ang) * dist
            ly = cy + math.sin(ang) * dist - (t * 6 if t > 0.4 else 0) # Rising smoke
            rad = random.uniform(max_r * 0.3, max_r * 0.55)
            lobes.append((lx, ly, rad))
            
        # Rasterize distance field
        for y in range(h):
            for x in range(w):
                # Distance to closest lobe or center
                min_dist_val = 999.0
                for lx, ly, lrad in lobes:
                    d = math.hypot(x - lx, y - ly) - lrad
                    if d < min_dist_val:
                        min_dist_val = d
                
                # Center pull
                d_center = math.hypot(x - cx, y - cy) - max_r * 0.6
                val = min(min_dist_val, d_center)
                
                # Map val to color tier based on frame time
                if val <= 0:
                    # Inside explosion
                    depth = -val # How deep inside
                    
                    if t < 0.45:
                        # Early fire burst
                        if depth > 12:
                            col_idx = 6 # White
                        elif depth > 8:
                            col_idx = 5 # Yellow
                        elif depth > 4:
                            col_idx = 4 # Orange
                        elif depth > 1.8:
                            col_idx = 3 # Bright red
                        else:
                            col_idx = 2 # Dark red
                    elif t < 0.7:
                        # Transition to rolling smoke
                        # Crevices have fire, outer has smoke
                        if depth > 8 and random.random() > 0.3:
                            col_idx = 5 if depth > 11 else 4
                        elif depth > 4:
                            col_idx = 3 if (x + y) % 2 == 0 else 7 # Dithered smoke/fire
                        elif depth > 2:
                            col_idx = 8 # Smoke mid
                        else:
                            col_idx = 7 # Smoke dark
                    else:
                        # Cooling dissipating smoke
                        if depth > 6 and (x * 7 + y * 13) % 11 == 0:
                            col_idx = 4 # Tiny dying ember
                        elif depth > 3:
                            col_idx = 8 if (x + y) % 2 == 0 else 7
                        else:
                            col_idx = 7
                            
                    grid[y][x] = col_idx
                    
        # Apply dark outline around non-zero pixels
        final_grid = [[grid[y][x] for x in range(w)] for y in range(h)]
        for y in range(1, h - 1):
            for x in range(1, w - 1):
                if grid[y][x] == 0:
                    # Check if neighbor is solid
                    has_solid = False
                    for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                        if grid[y + dy][x + dx] > 1:
                            has_solid = True
                            break
                    if has_solid:
                        final_grid[y][x] = 1 # Outline
                        
        # Render image
        im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        palette_map = {
            1: PALETTE["outline"],
            2: PALETTE["dark_red"],
            3: PALETTE["bright_red"],
            4: PALETTE["orange"],
            5: PALETTE["yellow"],
            6: PALETTE["core_white"],
            7: PALETTE["smoke_dark"],
            8: PALETTE["smoke_mid"],
            9: PALETTE["smoke_light"]
        }
        
        for y in range(h):
            for x in range(w):
                val = final_grid[y][x]
                if val in palette_map:
                    im.putpixel((x, y), palette_map[val])
                    
        # Upscale 2x nearest neighbor to 128x128
        im_upscaled = im.resize((128, 128), Image.Resampling.NEAREST)
        frames.append(im_upscaled)
        im_upscaled.save(f"{out_dir}/pixel_arcade_frame_{f}.png")
        
    # Spritesheet
    sheet = Image.new("RGBA", (128 * 8, 128), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        sheet.paste(frame, (i * 128, 0))
    sheet.save(f"{out_dir}/pixel_arcade_sheet.png")
    print("Generated authentic pixel arcade explosion spritesheet!")

if __name__ == "__main__":
    generate_authentic_pixel_explosion()
