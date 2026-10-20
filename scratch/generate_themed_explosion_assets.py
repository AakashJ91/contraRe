import os
import math
import random
from PIL import Image, ImageDraw

def create_explosion_themes():
    base_dir = "d:/GitHub/contraRe/assets/vfx/explosions"
    os.makedirs(base_dir, exist_ok=True)
    
    # 7 Distinct Themed Explosions
    themes = {
        "fiery": {
            "w": 96, "h": 96, "num_frames": 8,
            "core": (255, 255, 255, 255),
            "yellow": (255, 240, 130, 255),
            "orange": (255, 145, 30, 255),
            "red": (230, 55, 20, 240),
            "deep": (150, 25, 15, 220),
            "smoke": (60, 55, 65, 190),
            "debris": (255, 200, 80, 255),
            "style": "classic"
        },
        "electric": {
            "w": 96, "h": 96, "num_frames": 8,
            "core": (255, 255, 255, 255),
            "yellow": (180, 245, 255, 255),
            "orange": (40, 200, 255, 255),
            "red": (20, 120, 250, 240),
            "deep": (10, 50, 180, 220),
            "smoke": (35, 45, 70, 190),
            "debris": (140, 230, 255, 255),
            "style": "arc"
        },
        "alien": {
            "w": 96, "h": 96, "num_frames": 8,
            "core": (255, 255, 240, 255),
            "yellow": (220, 255, 120, 255),
            "orange": (120, 245, 40, 255),
            "red": (50, 180, 25, 240),
            "deep": (20, 110, 20, 220),
            "smoke": (45, 60, 40, 190),
            "debris": (180, 255, 90, 255),
            "style": "bio"
        },
        "nuclear": {
            "w": 112, "h": 112, "num_frames": 8,
            "core": (255, 255, 255, 255),
            "yellow": (255, 255, 180, 255),
            "orange": (255, 185, 50, 255),
            "red": (255, 90, 20, 240),
            "deep": (200, 40, 15, 220),
            "smoke": (75, 60, 70, 200),
            "debris": (255, 240, 150, 255),
            "style": "supernova"
        },
        "cryo": {
            "w": 96, "h": 96, "num_frames": 8,
            "core": (255, 255, 255, 255),
            "yellow": (210, 250, 255, 255),
            "orange": (110, 215, 255, 255),
            "red": (45, 150, 235, 240),
            "deep": (20, 85, 175, 220),
            "smoke": (55, 75, 95, 180),
            "debris": (200, 245, 255, 255),
            "style": "frost"
        },
        "magma": {
            "w": 96, "h": 96, "num_frames": 8,
            "core": (255, 255, 220, 255),
            "yellow": (255, 210, 80, 255),
            "orange": (255, 110, 20, 255),
            "red": (195, 30, 10, 240),
            "deep": (120, 15, 10, 220),
            "smoke": (50, 40, 45, 200),
            "debris": (255, 140, 30, 255),
            "style": "volcanic"
        },
        "mini_burst": {
            "w": 64, "h": 64, "num_frames": 6,
            "core": (255, 255, 255, 255),
            "yellow": (255, 245, 140, 255),
            "orange": (255, 150, 30, 255),
            "red": (230, 60, 20, 240),
            "deep": (160, 25, 15, 220),
            "smoke": (65, 60, 70, 180),
            "debris": (255, 210, 90, 255),
            "style": "punchy"
        }
    }
    
    for theme_name, cfg in themes.items():
        theme_dir = os.path.join(base_dir, theme_name)
        os.makedirs(theme_dir, exist_ok=True)
        w, h = cfg["w"], cfg["h"]
        num_frames = cfg["num_frames"]
        frames = []
        cx, cy = w / 2, h / 2
        random.seed(1337 + len(theme_name))
        
        for f in range(num_frames):
            im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
            draw = ImageDraw.Draw(im)
            t = f / float(num_frames - 1) # 0.0 to 1.0
            
            if f == 0:
                # Frame 0: Initial ignition flash
                rad = w * 0.14
                draw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=cfg["orange"])
                draw.ellipse([cx - rad * 0.7, cy - rad * 0.7, cx + rad * 0.7, cy + rad * 0.7], fill=cfg["yellow"])
                draw.ellipse([cx - rad * 0.4, cy - rad * 0.4, cx + rad * 0.4, cy + rad * 0.4], fill=cfg["core"])
                
                # Star flares
                flare_len = w * 0.32
                for dx, dy in [(0, -flare_len), (0, flare_len), (-flare_len, 0), (flare_len, 0)]:
                    draw.line([(cx, cy), (cx + dx, cy + dy)], fill=cfg["core"], width=2)
                for dx, dy in [(-flare_len * 0.55, -flare_len * 0.55), (flare_len * 0.55, -flare_len * 0.55),
                               (-flare_len * 0.55, flare_len * 0.55), (flare_len * 0.55, flare_len * 0.55)]:
                    draw.line([(cx, cy), (cx + dx, cy + dy)], fill=cfg["yellow"], width=1)
            
            elif f == 1:
                # Frame 1: Rapid expanding fireball & shockwave halo
                rad = w * 0.28
                draw.ellipse([cx - rad * 1.25, cy - rad * 1.25, cx + rad * 1.25, cy + rad * 1.25], outline=cfg["orange"], width=2)
                draw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=cfg["red"])
                draw.ellipse([cx - rad * 0.75, cy - rad * 0.75, cx + rad * 0.75, cy + rad * 0.75], fill=cfg["orange"])
                draw.ellipse([cx - rad * 0.5, cy - rad * 0.5, cx + rad * 0.5, cy + rad * 0.5], fill=cfg["yellow"])
                draw.ellipse([cx - rad * 0.25, cy - rad * 0.25, cx + rad * 0.25, cy + rad * 0.25], fill=cfg["core"])
                
                # Arcs / spikes for electric or bio
                if cfg["style"] == "arc":
                    for a_idx in range(6):
                        ang = a_idx * (math.pi / 3.0) + 0.2
                        p1 = (cx + math.cos(ang) * rad * 0.7, cy + math.sin(ang) * rad * 0.7)
                        p2 = (cx + math.cos(ang + 0.15) * rad * 1.4, cy + math.sin(ang + 0.15) * rad * 1.4)
                        draw.line([p1, p2], fill=cfg["core"], width=2)
            
            elif f == 2 or f == 3:
                # Frame 2-3: Peak explosive bloom with turbulent lobes
                num_lobes = 10 if f == 2 else 12
                lobe_dist = w * (0.24 if f == 2 else 0.32)
                lobe_rad = w * (0.15 if f == 2 else 0.18)
                
                # Outer deep/red lobes
                for i in range(num_lobes):
                    ang = i * (2 * math.pi / num_lobes) + ((i * 13) % 7) * 0.08
                    r = lobe_dist + ((i * 17) % 5) * (w * 0.04)
                    lx = cx + math.cos(ang) * r
                    ly = cy + math.sin(ang) * r
                    draw.ellipse([lx - lobe_rad, ly - lobe_rad, lx + lobe_rad, ly + lobe_rad], fill=cfg["deep"])
                
                # Mid orange lobes
                for i in range(num_lobes):
                    ang = i * (2 * math.pi / num_lobes)
                    r = lobe_dist * 0.75 + ((i * 7) % 3) * (w * 0.03)
                    lx = cx + math.cos(ang) * r
                    ly = cy + math.sin(ang) * r
                    draw.ellipse([lx - lobe_rad * 0.8, ly - lobe_rad * 0.8, lx + lobe_rad * 0.8, ly + lobe_rad * 0.8], fill=cfg["orange"])
                
                # Inner blazing core
                core_r = w * (0.20 if f == 2 else 0.16)
                draw.ellipse([cx - core_r, cy - core_r, cx + core_r, cy + core_r], fill=cfg["yellow"])
                draw.ellipse([cx - core_r * 0.55, cy - core_r * 0.55, cx + core_r * 0.55, cy + core_r * 0.55], fill=cfg["core"])
                
                # Flying shrapnel / sparks
                num_spk = 10
                for s in range(num_spk):
                    ang = s * (2 * math.pi / num_spk) + 0.25
                    dist = w * (0.38 if f == 2 else 0.44)
                    spx = cx + math.cos(ang) * dist
                    spy = cy + math.sin(ang) * dist
                    draw.line([(cx + math.cos(ang) * (dist - 8), cy + math.sin(ang) * (dist - 8)), (spx, spy)], fill=cfg["debris"], width=2)
            
            elif f == 4:
                # Frame 4: Fireball breaking into rising smoke with incandescent pockets
                num_lobes = 12
                lobe_dist = w * 0.33
                lobe_rad = w * 0.16
                for i in range(num_lobes):
                    ang = i * (2 * math.pi / num_lobes)
                    r = lobe_dist + (i % 3) * (w * 0.03)
                    lx = cx + math.cos(ang) * r
                    ly = cy + math.sin(ang) * r - 3
                    draw.ellipse([lx - lobe_rad, ly - lobe_rad, lx + lobe_rad, ly + lobe_rad], fill=cfg["smoke"])
                
                # Retained fire pockets
                for i in range(7):
                    ang = i * (2 * math.pi / 7) + 0.3
                    lx = cx + math.cos(ang) * (w * 0.18)
                    ly = cy + math.sin(ang) * (w * 0.18) - 2
                    draw.ellipse([lx - 9, ly - 9, lx + 9, ly + 9], fill=cfg["red"])
                    draw.ellipse([lx - 5, ly - 5, lx + 5, ly + 5], fill=cfg["orange"])
                draw.ellipse([cx - 10, cy - 10, cx + 10, cy + 10], fill=cfg["yellow"])
            
            elif f == 5:
                # Frame 5: Cooling smoke plumes and tiny glowing embers
                num_lobes = 10
                lobe_dist = w * 0.34
                lobe_rad = w * 0.14
                for i in range(num_lobes):
                    ang = i * (2 * math.pi / num_lobes) + 0.2
                    r = lobe_dist + (i % 2) * (w * 0.03)
                    lx = cx + math.cos(ang) * r
                    ly = cy + math.sin(ang) * r - 6
                    c_smoke = (cfg["smoke"][0], cfg["smoke"][1], cfg["smoke"][2], 160)
                    draw.ellipse([lx - lobe_rad, ly - lobe_rad, lx + lobe_rad, ly + lobe_rad], fill=c_smoke)
                
                # Lingering ember sparks
                for ex, ey in [(-10, -5), (12, 6), (0, -14), (-8, 12), (9, -10)]:
                    draw.ellipse([cx + ex - 2, cy + ey - 2, cx + ex + 2, cy + ey + 2], fill=cfg["orange"])
            
            elif f >= 6:
                # Frame 6-7: Dissipating, translucent smoke wisps
                num_lobes = 8
                lobe_dist = w * 0.36
                lobe_rad = w * 0.12
                alpha = 90 if f == 6 else 45
                for i in range(num_lobes):
                    ang = i * (2 * math.pi / num_lobes)
                    lx = cx + math.cos(ang) * lobe_dist
                    ly = cy + math.sin(ang) * lobe_dist - (10 if f == 6 else 15)
                    c_smoke = (cfg["smoke"][0], cfg["smoke"][1], cfg["smoke"][2], alpha)
                    draw.ellipse([lx - lobe_rad, ly - lobe_rad, lx + lobe_rad, ly + lobe_rad], fill=c_smoke)
            
            frame_path = os.path.join(theme_dir, f"frame_{f}.png")
            im.save(frame_path)
            frames.append(im)
            
        # Spritesheet
        sheet_w = w * num_frames
        sheet = Image.new("RGBA", (sheet_w, h), (0, 0, 0, 0))
        for i, frame in enumerate(frames):
            sheet.paste(frame, (i * w, 0))
        sheet_path = os.path.join(theme_dir, "sheet.png")
        sheet.save(sheet_path)
        print(f"Generated theme '{theme_name}': {num_frames} frames + sheet ({sheet_w}x{h})")

if __name__ == "__main__":
    create_explosion_themes()
