import os
import math
from PIL import Image, ImageDraw

os.makedirs('assets/powerups/sensor/themes', exist_ok=True)

W, H = 40, 48

# Themes mapping:
# 1: military (Jungle) - Olive/camo metal, Red Falcon ruby optic, orange ion repulsor
# 2: aqua (Waterfall) - Marine navy/steel, aqua turquoise optic, cyan hydro thruster
# 3: alien (Hive) - Chitinous insectoid purple/carapace, pulsing bio-eye amber, acid mist
# 4: cryo (Tundra) - Arctic frost white/silver, glacial ice-blue core, cold blue exhaust
# 5: magma (Refinery) - Heavy carbon forge iron, molten magma orange/yellow core, fire jet
# 6: tesla (Dynamo) - Dielectric blue & bronze, electric violet spark core, lightning field
# 7: stealth (Hangar) - Matte obsidian / gold trim, quantum violet visor, warp repulsor
# 8: sanctum (Mother Brain) - Bio-mechanical crimson/bone, psionic alien optic, eldritch glow

THEMES = {
    "military": {
        "hull_dark": (30, 40, 32, 255),
        "hull_mid": (48, 64, 50, 255),
        "hull_hi": (95, 128, 98, 255),
        "base_dark": (24, 28, 30, 255),
        "base_hi": (70, 80, 85, 255),
        "core_outer": (255, 50, 30),
        "core_mid": (255, 130, 40),
        "core_hot": (255, 230, 160),
        "thruster_col": (255, 140, 30),
        "beacon_col": (255, 40, 40),
        "has_wings": False
    },
    "aqua": {
        "hull_dark": (20, 36, 52, 255),
        "hull_mid": (34, 60, 88, 255),
        "hull_hi": (70, 130, 180, 255),
        "base_dark": (18, 30, 44, 255),
        "base_hi": (65, 105, 140, 255),
        "core_outer": (0, 180, 240),
        "core_mid": (60, 220, 255),
        "core_hot": (220, 250, 255),
        "thruster_col": (40, 200, 255),
        "beacon_col": (30, 220, 255),
        "has_wings": True
    },
    "alien": {
        "hull_dark": (45, 18, 48, 255),
        "hull_mid": (75, 30, 80, 255),
        "hull_hi": (140, 60, 150, 255),
        "base_dark": (35, 14, 40, 255),
        "base_hi": (90, 40, 100, 255),
        "core_outer": (240, 160, 10),
        "core_mid": (255, 210, 40),
        "core_hot": (255, 255, 180),
        "thruster_col": (140, 240, 60),
        "beacon_col": (255, 180, 20),
        "has_wings": True
    },
    "cryo": {
        "hull_dark": (35, 48, 62, 255),
        "hull_mid": (70, 95, 120, 255),
        "hull_hi": (160, 205, 240, 255),
        "base_dark": (28, 38, 50, 255),
        "base_hi": (110, 145, 175, 255),
        "core_outer": (60, 180, 255),
        "core_mid": (140, 220, 255),
        "core_hot": (240, 250, 255),
        "thruster_col": (100, 210, 255),
        "beacon_col": (120, 220, 255),
        "has_wings": False
    },
    "magma": {
        "hull_dark": (32, 24, 22, 255),
        "hull_mid": (58, 42, 36, 255),
        "hull_hi": (120, 85, 75, 255),
        "base_dark": (26, 18, 16, 255),
        "base_hi": (80, 55, 48, 255),
        "core_outer": (255, 70, 20),
        "core_mid": (255, 160, 30),
        "core_hot": (255, 240, 160),
        "thruster_col": (255, 100, 20),
        "beacon_col": (255, 60, 20),
        "has_wings": False
    },
    "tesla": {
        "hull_dark": (22, 30, 48, 255),
        "hull_mid": (40, 56, 90, 255),
        "hull_hi": (180, 150, 60, 255), # bronze/gold conductors
        "base_dark": (20, 26, 40, 255),
        "base_hi": (70, 90, 130, 255),
        "core_outer": (140, 70, 255),
        "core_mid": (190, 120, 255),
        "core_hot": (245, 230, 255),
        "thruster_col": (120, 80, 255),
        "beacon_col": (180, 100, 255),
        "has_wings": True
    },
    "stealth": {
        "hull_dark": (18, 20, 24, 255),
        "hull_mid": (32, 35, 42, 255),
        "hull_hi": (80, 85, 95, 255),
        "base_dark": (14, 16, 20, 255),
        "base_hi": (60, 65, 75, 255),
        "core_outer": (220, 40, 120),
        "core_mid": (255, 90, 180),
        "core_hot": (255, 220, 245),
        "thruster_col": (200, 50, 180),
        "beacon_col": (240, 60, 140),
        "has_wings": True
    },
    "sanctum": {
        "hull_dark": (40, 16, 28, 255),
        "hull_mid": (70, 28, 48, 255),
        "hull_hi": (150, 70, 105, 255),
        "base_dark": (32, 14, 22, 255),
        "base_hi": (95, 42, 68, 255),
        "core_outer": (255, 30, 90),
        "core_mid": (255, 100, 150),
        "core_hot": (255, 230, 240),
        "thruster_col": (255, 50, 110),
        "beacon_col": (255, 30, 90),
        "has_wings": True
    }
}

for theme_name, theme in THEMES.items():
    theme_dir = f'assets/powerups/sensor/themes/{theme_name}'
    os.makedirs(theme_dir, exist_ok=True)
    
    for frame_idx in range(6):
        img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        t = frame_idx / 6.0
        pulse = math.sin(t * math.pi)
        
        # 1. Anti-Gravity Repulsor Nozzles underneath pod (Y: 34..44)
        # Dual angled thrust pods / magnetic stabilizer cones
        draw.polygon([(10, 36), (15, 36), (14, 43), (11, 43)], fill=theme["base_dark"], outline=(12, 14, 18, 255))
        draw.polygon([(25, 36), (30, 36), (29, 43), (26, 43)], fill=theme["base_dark"], outline=(12, 14, 18, 255))
        
        # Active hover plasma jet cones discharging below nozzles (frames 0..5 animate jet flame)
        jet_len = int(4.0 + 3.0 * math.sin(t * math.pi * 3.0))
        tc = theme["thruster_col"]
        # Left jet
        draw.polygon([(11, 43), (14, 43), (12.5, 43 + jet_len)], fill=(tc[0], tc[1], tc[2], 210))
        draw.line([(12.5, 43), (12.5, 42 + jet_len * 0.7)], fill=(255, 255, 255, 240), width=1)
        # Right jet
        draw.polygon([(26, 43), (29, 43), (27.5, 43 + jet_len)], fill=(tc[0], tc[1], tc[2], 210))
        draw.line([(27.5, 43), (27.5, 42 + jet_len * 0.7)], fill=(255, 255, 255, 240), width=1)
        
        # Repulsor ring glow
        draw.ellipse([9, 34, 31, 39], outline=(tc[0], tc[1], tc[2], int(120 + 80 * pulse)), width=1)
        
        # 2. Aerodynamic Hover Stabilizer Fins / Wings (if enabled for theme)
        if theme["has_wings"]:
            wing_sway = int(math.sin(t * math.pi * 2.0) * 1.5)
            # Left wing
            draw.polygon([(6, 20), (1, 25 + wing_sway), (6, 28)], fill=theme["hull_mid"], outline=(12, 14, 18, 255))
            draw.line([(6, 21), (2, 25 + wing_sway)], fill=theme["hull_hi"], width=1)
            # Right wing
            draw.polygon([(34, 20), (39, 25 + wing_sway), (34, 28)], fill=theme["hull_mid"], outline=(12, 14, 18, 255))
            draw.line([(34, 21), (38, 25 + wing_sway)], fill=theme["hull_hi"], width=1)
        
        # 3. Main Armored Hover Drone Capsule Body (Y: 8..36, X: 6..34)
        hull_pts = [
            (14, 8), (26, 8),
            (33, 14), (33, 30),
            (26, 36), (14, 36),
            (7, 30), (7, 14)
        ]
        draw.polygon(hull_pts, fill=theme["hull_dark"], outline=(12, 14, 18, 255))
        draw.polygon([(15, 9), (25, 9), (31, 14), (31, 29), (25, 35), (15, 35), (9, 29), (9, 14)], fill=theme["hull_mid"])
        
        # Metallic / Carapace highlights
        draw.line([(15, 9), (25, 9)], fill=theme["hull_hi"], width=1)
        draw.line([(10, 14), (15, 9)], fill=theme["hull_hi"], width=1)
        draw.line([(30, 14), (25, 9)], fill=theme["hull_hi"], width=1)
        draw.line([(9, 15), (9, 28)], fill=theme["hull_hi"], width=1)
        
        # 4. Central Optic Sensor Aperture (center (20, 22))
        cx, cy = 20.0, 22.0
        outer_r = 8.5
        draw.ellipse([cx - outer_r, cy - outer_r, cx + outer_r, cy + outer_r], fill=(16, 18, 24, 255), outline=(10, 12, 16, 255))
        draw.arc([cx - outer_r, cy - outer_r, cx + outer_r, cy + outer_r], 0, 360, fill=theme["hull_hi"], width=1)
        
        # Aperture opening width (animates open and shut)
        aperture_openings = [1.5, 3.5, 6.5, 7.5, 4.5, 2.5]
        ap_w = aperture_openings[frame_idx]
        
        # Dynamic Optic Plasma Core
        co = theme["core_outer"]
        cm = theme["core_mid"]
        ch = theme["core_hot"]
        glow_alpha = int(100 + 140 * pulse)
        
        # Radiant energy aura
        for gr in range(int(outer_r - 1), 0, -1):
            ratio = gr / outer_r
            draw.ellipse([cx - gr, cy - gr, cx + gr, cy + gr], fill=(co[0], co[1], co[2], int(glow_alpha * (1.0 - ratio * 0.6))))
        
        # Focused Optic Beam Core
        core_w = ap_w
        core_h = 3.5 + 2.0 * pulse
        draw.ellipse([cx - core_w, cy - core_h, cx + core_w, cy + core_h], fill=(cm[0], cm[1], cm[2], 255))
        draw.ellipse([cx - core_w * 0.6, cy - core_h * 0.55, cx + core_w * 0.6, cy + core_h * 0.55], fill=(ch[0], ch[1], ch[2], 255))
        draw.ellipse([cx - core_w * 0.25, cy - core_h * 0.25, cx + core_w * 0.25, cy + core_h * 0.25], fill=(255, 255, 255, 255))
        
        # Horizontal Target Reticle / Scan Line
        scan_y = cy + math.sin(t * math.pi * 2.0) * 3.0
        scan_w = 7.0 + 3.0 * pulse
        draw.line([(cx - scan_w, scan_y), (cx + scan_w, scan_y)], fill=(ch[0], ch[1], ch[2], int(190 + 65 * pulse)), width=1)
        
        # Upper and lower mechanical shutter plates
        shutter_h = outer_r - ap_w * 0.6
        if shutter_h > 1.0:
            draw.chord([cx - outer_r + 1, cy - outer_r + 1, cx + outer_r - 1, cy + outer_r - 1], 190, 350, fill=theme["hull_dark"])
            draw.chord([cx - outer_r + 1, cy - outer_r + 1, cx + outer_r - 1, cy + outer_r - 1], 10, 170, fill=theme["hull_dark"])
            draw.line([(cx - outer_r + 2, cy - ap_w * 0.5), (cx + outer_r - 2, cy - ap_w * 0.5)], fill=theme["hull_hi"], width=1)
            draw.line([(cx - outer_r + 2, cy + ap_w * 0.5), (cx + outer_r - 2, cy + ap_w * 0.5)], fill=theme["hull_hi"], width=1)
        
        # 5. Top Hover Dome Antenna & Blinking Beacon (Y: 3..7)
        bc = theme["beacon_col"]
        beacon_glow = (frame_idx % 2 == 0) or (frame_idx in [2, 3])
        draw.polygon([(17, 8), (23, 8), (22, 4), (18, 4)], fill=theme["base_dark"], outline=(12, 14, 18, 255))
        b_color = (bc[0], bc[1], bc[2], 255) if beacon_glow else (int(bc[0]*0.5), int(bc[1]*0.5), int(bc[2]*0.5), 255)
        draw.ellipse([18.5, 2.5, 21.5, 5.5], fill=b_color, outline=(12, 14, 18, 255))
        if beacon_glow:
            draw.point((20, 4), fill=(255, 255, 255, 255))
            draw.ellipse([17, 1, 23, 7], outline=(bc[0], bc[1], bc[2], 120), width=1)
        
        fpath = f'{theme_dir}/frame_{frame_idx}.png'
        img.save(fpath)
    
    print(f'Generated 6 themed frames for {theme_name}')

print('All 8 stage themes generated successfully!')
