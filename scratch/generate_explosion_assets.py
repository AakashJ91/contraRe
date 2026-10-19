import os
import math
import random
from PIL import Image, ImageDraw, ImageFilter

def generate_explosion_frames():
    out_dir = "d:/GitHub/contraRe/assets/vfx"
    os.makedirs(out_dir, exist_ok=True)
    
    # 8 frames of 96x96 explosion
    w, h = 96, 96
    frames = []
    
    # Deterministic seed for reproducible crisp artistic quality
    random.seed(42)
    
    # Palette constants
    COL_WHITE = (255, 255, 255, 255)
    COL_CORE_YELLOW = (255, 245, 140, 255)
    COL_BRIGHT_ORANGE = (255, 150, 30, 255)
    COL_FIRE_RED = (230, 60, 20, 240)
    COL_DEEP_RED = (160, 25, 15, 220)
    COL_DARK_SMOKE = (60, 55, 65, 200)
    COL_LIGHT_SMOKE = (100, 95, 105, 180)
    
    for f in range(8):
        im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        draw = ImageDraw.Draw(im)
        cx, cy = w / 2, h / 2
        
        t = f / 7.0 # 0.0 to 1.0
        
        if f == 0:
            # Ignition star flash: small super-hot white star with spikes
            draw.ellipse([cx - 10, cy - 10, cx + 10, cy + 10], fill=COL_BRIGHT_ORANGE)
            draw.ellipse([cx - 7, cy - 7, cx + 7, cy + 7], fill=COL_CORE_YELLOW)
            draw.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=COL_WHITE)
            # 4 star spikes
            for dx, dy in [(0, -22), (0, 22), (-22, 0), (22, 0)]:
                draw.line([(cx, cy), (cx + dx, cy + dy)], fill=COL_WHITE, width=2)
            for dx, dy in [(-12, -12), (12, -12), (-12, 12), (12, 12)]:
                draw.line([(cx, cy), (cx + dx, cy + dy)], fill=COL_CORE_YELLOW, width=1)
                
        elif f == 1:
            # Detonation bloom: expanding spherical blast wave
            draw.ellipse([cx - 24, cy - 24, cx + 24, cy + 24], fill=(255, 120, 20, 180))
            draw.ellipse([cx - 20, cy - 20, cx + 20, cy + 20], fill=COL_BRIGHT_ORANGE)
            draw.ellipse([cx - 14, cy - 14, cx + 14, cy + 14], fill=COL_CORE_YELLOW)
            draw.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=COL_WHITE)
            # Shockwave ring
            draw.ellipse([cx - 28, cy - 28, cx + 28, cy + 28], outline=(255, 230, 150, 220), width=2)
            
        elif f == 2:
            # Rapid multi-lobed fireball
            # Draw outer orange/red lobes
            num_lobes = 10
            for i in range(num_lobes):
                ang = i * (2 * math.pi / num_lobes) + 0.2
                r = 22 + (i % 3) * 6
                lx = cx + math.cos(ang) * r
                ly = cy + math.sin(ang) * r
                draw.ellipse([lx - 14, ly - 14, lx + 14, ly + 14], fill=COL_FIRE_RED)
            for i in range(num_lobes):
                ang = i * (2 * math.pi / num_lobes)
                r = 16 + (i % 2) * 5
                lx = cx + math.cos(ang) * r
                ly = cy + math.sin(ang) * r
                draw.ellipse([lx - 11, ly - 11, lx + 11, ly + 11], fill=COL_BRIGHT_ORANGE)
            # Inner white/yellow core
            draw.ellipse([cx - 18, cy - 18, cx + 18, cy + 18], fill=COL_CORE_YELLOW)
            draw.ellipse([cx - 10, cy - 10, cx + 10, cy + 10], fill=COL_WHITE)
            # Shrapnel sparks
            for s in range(8):
                ang = s * (math.pi / 4) + 0.3
                spx = cx + math.cos(ang) * 36
                spy = cy + math.sin(ang) * 36
                draw.line([(cx + math.cos(ang) * 26, cy + math.sin(ang) * 26), (spx, spy)], fill=COL_CORE_YELLOW, width=2)
                
        elif f == 3:
            # Peak inferno size
            num_lobes = 12
            for i in range(num_lobes):
                ang = i * (2 * math.pi / num_lobes) + ((i * 17) % 7) * 0.1
                r = 28 + (i % 4) * 7
                lx = cx + math.cos(ang) * r
                ly = cy + math.sin(ang) * r
                draw.ellipse([lx - 16, ly - 16, lx + 16, ly + 16], fill=COL_DEEP_RED)
            for i in range(num_lobes):
                ang = i * (2 * math.pi / num_lobes)
                r = 22 + (i % 3) * 5
                lx = cx + math.cos(ang) * r
                ly = cy + math.sin(ang) * r
                draw.ellipse([lx - 12, ly - 12, lx + 12, ly + 12], fill=COL_BRIGHT_ORANGE)
            draw.ellipse([cx - 20, cy - 20, cx + 20, cy + 20], fill=COL_CORE_YELLOW)
            draw.ellipse([cx - 11, cy - 11, cx + 11, cy + 11], fill=COL_WHITE)
            # Flying flaming debris
            for d in range(12):
                ang = d * (2 * math.pi / 12) + 0.15
                dist = 40 + (d % 3) * 4
                px = cx + math.cos(ang) * dist
                py = cy + math.sin(ang) * dist
                draw.ellipse([px - 2, py - 2, px + 2, py + 2], fill=COL_CORE_YELLOW)
                
        elif f == 4:
            # Fireball breaking into smoke with glowing fire pockets
            num_lobes = 14
            for i in range(num_lobes):
                ang = i * (2 * math.pi / num_lobes)
                r = 30 + (i % 3) * 8
                lx = cx + math.cos(ang) * r
                ly = cy + math.sin(ang) * r
                draw.ellipse([lx - 14, ly - 14, lx + 14, ly + 14], fill=COL_DARK_SMOKE)
            # Secondary fire pockets
            for i in range(8):
                ang = i * (2 * math.pi / 8) + 0.4
                r = 18 + (i % 2) * 6
                lx = cx + math.cos(ang) * r
                ly = cy + math.sin(ang) * r
                draw.ellipse([lx - 10, ly - 10, lx + 10, ly + 10], fill=COL_FIRE_RED)
            draw.ellipse([cx - 14, cy - 14, cx + 14, cy + 14], fill=COL_BRIGHT_ORANGE)
            draw.ellipse([cx - 7, cy - 7, cx + 7, cy + 7], fill=COL_CORE_YELLOW)
            
        elif f == 5:
            # Mostly swirling smoke plumes with diminishing fire embers
            num_lobes = 12
            for i in range(num_lobes):
                ang = i * (2 * math.pi / num_lobes)
                r = 32 + (i % 3) * 6
                lx = cx + math.cos(ang) * r
                ly = cy + math.sin(ang) * r - 4 # smoke rising
                draw.ellipse([lx - 13, ly - 13, lx + 13, ly + 13], fill=(70, 65, 75, 170))
            # Fire patches in crevices
            for i in [1, 3, 6, 9]:
                ang = i * (2 * math.pi / 12)
                lx = cx + math.cos(ang) * 16
                ly = cy + math.sin(ang) * 16 - 3
                draw.ellipse([lx - 7, ly - 7, lx + 7, ly + 7], fill=(220, 80, 20, 190))
                draw.ellipse([lx - 4, ly - 4, lx + 4, ly + 4], fill=COL_BRIGHT_ORANGE)
                
        elif f == 6:
            # Expanding and cooling smoke clouds
            num_lobes = 10
            for i in range(num_lobes):
                ang = i * (2 * math.pi / num_lobes) + 0.2
                r = 33 + (i % 2) * 7
                lx = cx + math.cos(ang) * r
                ly = cy + math.sin(ang) * r - 8
                draw.ellipse([lx - 12, ly - 12, lx + 12, ly + 12], fill=(60, 58, 68, 120))
            # Tiny lingering embers
            for ex, ey in [(-12, -4), (14, 8), (2, -18), (-6, 16)]:
                draw.ellipse([cx + ex - 2, cy + ey - 2, cx + ex + 2, cy + ey + 2], fill=(255, 140, 30, 160))
                
        elif f == 7:
            # Fading smoke wisps
            num_lobes = 8
            for i in range(num_lobes):
                ang = i * (2 * math.pi / num_lobes)
                r = 35 + (i % 2) * 6
                lx = cx + math.cos(ang) * r
                ly = cy + math.sin(ang) * r - 12
                draw.ellipse([lx - 10, ly - 10, lx + 10, ly + 10], fill=(50, 48, 55, 60))
                
        frames.append(im)
        im.save(f"{out_dir}/explosion_anim_{f}.png")
        print(f"Saved {out_dir}/explosion_anim_{f}.png")

    # Generate spritesheet (8 * 96 = 768 x 96)
    sheet = Image.new("RGBA", (w * 8, h), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        sheet.paste(frame, (i * w, 0))
    sheet.save(f"{out_dir}/explosion_sheet.png")
    print(f"Saved {out_dir}/explosion_sheet.png")

if __name__ == "__main__":
    generate_explosion_frames()
