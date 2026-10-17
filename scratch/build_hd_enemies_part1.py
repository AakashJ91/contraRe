import os, math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops

def ensure_dir(d):
    os.makedirs(d, exist_ok=True)

def create_arcade_outline(im, pad=10, outline_color=(15, 18, 25, 255)):
    w, h = im.size
    new_w = w + pad * 2
    new_h = h + pad * 2
    padded = Image.new('RGBA', (new_w, new_h), (0, 0, 0, 0))
    padded.paste(im, (pad, pad))
    
    alpha = padded.split()[3]
    dilated = alpha.filter(ImageFilter.MaxFilter(5))
    outline_img = Image.new('RGBA', (new_w, new_h), outline_color)
    outline_mask = Image.new('L', (new_w, new_h), 0)
    for y in range(new_h):
        for x in range(new_w):
            d = dilated.getpixel((x, y))
            a = alpha.getpixel((x, y))
            if d > 20 and a < 220:
                border_strength = min(255, int((d - a) * 2.2))
                outline_mask.putpixel((x, y), border_strength)
    combined = Image.composite(padded, outline_img, alpha)
    final_alpha = ImageChops.lighter(alpha, outline_mask)
    combined.putalpha(final_alpha)
    return combined

def save_enemy_suite(folder_name, draw_frame_fn, draw_death_fn, w, h, pad=10):
    folder = f'assets/enemies/{folder_name}'
    ensure_dir(folder)
    ensure_dir(f'{folder}/movement')
    ensure_dir(f'{folder}/death')
    
    # 4 movement frames
    for i in range(4):
        im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        draw_frame_fn(d, w, h, i)
        out = create_arcade_outline(im, pad=pad)
        out.save(f'{folder}/movement/walk_{i}.png')
        if i == 0:
            out.save(f'{folder}/{folder_name}.png')
            
    # 4 death frames
    for i in range(4):
        im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        draw_death_fn(d, w, h, i)
        out = create_arcade_outline(im, pad=pad)
        out.save(f'{folder}/death/destroy_{i}.png')
    print(f"Generated suite for {folder_name}")

# =============================================================================
# STAGE 1: GUERRILLA GUNNER & FLAME TROOPER
# =============================================================================
def make_guerrilla_gunner():
    w, h = 96, 104
    c_camo_dark = (38, 52, 26, 255)
    c_camo_mid = (65, 88, 44, 255)
    c_camo_light = (98, 128, 68, 255)
    c_camo_tan = (130, 110, 75, 255)
    c_skin_shadow = (145, 85, 60, 255)
    c_skin_mid = (210, 140, 105, 255)
    c_skin_high = (245, 185, 150, 255)
    c_red_dark = (140, 25, 25, 255)
    c_red_mid = (215, 40, 35, 255)
    c_red_high = (255, 95, 80, 255)
    c_metal_black = (18, 22, 28, 255)
    c_metal_dark = (38, 44, 54, 255)
    c_metal_mid = (70, 80, 96, 255)
    c_metal_high = (140, 155, 180, 255)
    c_boot_dark = (22, 24, 26, 255)
    c_boot_mid = (45, 48, 52, 255)

    def draw_frame(d, w, h, f):
        leg_bob = [-2, 2, 0, -1][f]
        arm_bob = [0, -2, 1, -1][f]
        
        # Bandana tail flapping
        t_off = [-2, 2, -1, 3][f]
        d.polygon([(30, 28), (14 + t_off, 34), (18 + t_off, 44), (32, 34)], fill=c_red_dark)
        d.polygon([(30, 30), (16 + t_off, 36), (20 + t_off, 42), (32, 34)], fill=c_red_mid)

        # Back leg & Boot
        b_leg_y = 62 + leg_bob
        d.rectangle([34, b_leg_y, 46, 88 + leg_bob], fill=c_camo_dark)
        d.rectangle([36, b_leg_y + 6, 44, b_leg_y + 14], fill=c_camo_mid)
        d.rectangle([38, b_leg_y + 18, 46, b_leg_y + 24], fill=c_camo_tan)
        d.polygon([(32, 88 + leg_bob), (48, 88 + leg_bob), (52, 98 + leg_bob), (30, 98 + leg_bob)], fill=c_boot_dark)
        d.rectangle([32, 90 + leg_bob, 46, 94 + leg_bob], fill=c_boot_mid)

        # Front leg & Boot
        f_leg_y = 64 - leg_bob
        d.rectangle([48, f_leg_y, 62, 90 - leg_bob], fill=c_camo_mid)
        d.rectangle([50, f_leg_y + 4, 58, f_leg_y + 14], fill=c_camo_light)
        d.rectangle([52, f_leg_y + 8, 60, f_leg_y + 20], fill=c_camo_dark)
        d.rectangle([48, f_leg_y + 8, 58, f_leg_y + 16], fill=(28, 30, 32, 255)) # Knee pad
        d.polygon([(46, 90 - leg_bob), (66, 90 - leg_bob), (72, 100 - leg_bob), (44, 100 - leg_bob)], fill=c_boot_dark)
        d.rectangle([(46, 92 - leg_bob), (64, 96 - leg_bob)], fill=c_boot_mid)
        d.rectangle([(62, 94 - leg_bob), (70, 98 - leg_bob)], fill=c_metal_mid)

        # Torso & Tactical Vest
        d.rectangle([36, 36, 62, 66], fill=c_camo_dark)
        d.polygon([(38, 36), (60, 36), (58, 64), (36, 64)], fill=c_camo_mid)
        d.polygon([(40, 40), (52, 38), (48, 50), (42, 48)], fill=c_camo_light)
        d.polygon([(46, 52), (58, 50), (56, 62), (48, 60)], fill=c_camo_tan)
        d.rectangle([40, 56, 48, 66], fill=(30, 25, 20, 255))
        d.rectangle([42, 58, 46, 64], fill=(70, 60, 48, 255))
        d.rectangle([50, 56, 58, 66], fill=(30, 25, 20, 255))

        # Head, Face & Bandana
        d.rectangle([40, 18, 56, 36], fill=c_skin_mid)
        d.rectangle([40, 30, 54, 36], fill=c_skin_shadow)
        d.rectangle([46, 22, 54, 28], fill=c_skin_high)
        d.line([(44, 28), (52, 30)], fill=c_camo_dark, width=2) # War paint
        d.rectangle([48, 22, 54, 24], fill=(20, 15, 12, 255))
        d.rectangle([50, 24, 54, 26], fill=(255, 255, 255, 255))
        d.point((52, 25), fill=(40, 90, 140, 255))
        d.rectangle([38, 16, 58, 22], fill=c_red_dark)
        d.rectangle([40, 16, 58, 20], fill=c_red_mid)
        d.line([(42, 17), (56, 17)], fill=c_red_high, width=1)
        d.polygon([(38, 16), (36, 10), (44, 14)], fill=(40, 30, 20, 255))
        d.polygon([(42, 14), (46, 8), (50, 14)], fill=(50, 38, 25, 255))

        # Rifle & Arms
        gy = 44 + arm_bob
        d.rectangle([44, gy, 88, gy + 8], fill=c_metal_black)
        d.rectangle([46, gy + 1, 86, gy + 6], fill=c_metal_dark)
        d.line([(48, gy + 2), (84, gy + 2)], fill=c_metal_mid, width=2)
        d.line([(52, gy + 2), (80, gy + 2)], fill=c_metal_high, width=1)
        d.polygon([(36, gy), (46, gy), (46, gy + 8), (32, gy + 10)], fill=(75, 45, 28, 255)) # Stock
        d.polygon([(56, gy + 8), (64, gy + 8), (60, gy + 24), (54, gy + 22)], fill=c_metal_black) # Mag
        d.rectangle([86, gy + 2, 92, gy + 6], fill=c_metal_mid) # Muzzle
        d.rectangle([64, gy - 4, 76, gy], fill=c_metal_black) # Laser sight
        d.point((76, gy - 2), fill=(255, 30, 20, 255))
        # Front arm
        d.rectangle([42, 38 + arm_bob, 52, 48 + arm_bob], fill=c_skin_mid)
        d.rectangle([48, 46 + arm_bob, 56, 54 + arm_bob], fill=(35, 38, 42, 255))
        
        # Muzzle blast on frame 2
        if f == 2:
            d.ellipse([90, gy - 4, 98, gy + 12], fill=(255, 220, 60, 255))
            d.ellipse([92, gy - 1, 96, gy + 9], fill=(255, 255, 240, 255))

    def draw_death(d, w, h, f):
        s = 1.0 - f * 0.22
        cx, cy = 48, 52 + f * 6
        r = int(28 * s)
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, int(140 * s), 30, int(240 * s)))
        d.ellipse([cx - int(r*0.6), cy - int(r*0.6), cx + int(r*0.6), cy + int(r*0.6)], fill=(255, 240, 120, int(255 * s)))
        # Shrapnel
        for a in [0.4, 1.8, 3.2, 4.6]:
            px = cx + math.cos(a + f) * (f * 14 + 10)
            py = cy + math.sin(a + f) * (f * 14 + 10)
            d.rectangle([px - 2, py - 2, px + 2, py + 2], fill=(50, 40, 30, int(255 * s)))

    save_enemy_suite('guerrilla_gunner', draw_frame, draw_death, w, h)

def make_flame_trooper():
    w, h = 104, 108
    c_suit_dark = (45, 48, 52, 255)
    c_suit_mid = (75, 80, 88, 255)
    c_suit_high = (110, 118, 128, 255)
    c_tank_red = (220, 45, 30, 255)
    c_tank_dark = (140, 25, 20, 255)
    c_brass = (210, 170, 50, 255)
    c_visor_gold = (255, 195, 45, 255)

    def draw_frame(d, w, h, f):
        bob = [-2, 2, 0, -1][f]
        
        # Heavy fuel tank on back
        d.rectangle([20, 28 + bob, 36, 68 + bob], fill=c_tank_dark)
        d.rectangle([24, 30 + bob, 34, 66 + bob], fill=c_tank_red)
        d.rectangle([20, 44 + bob, 36, 50 + bob], fill=(20, 22, 24, 255)) # Hazard strap
        d.rectangle([22, 46 + bob, 34, 48 + bob], fill=c_brass)
        # Pressure gauge
        d.ellipse([26, 24 + bob, 34, 32 + bob], fill=c_brass)
        d.ellipse([28, 26 + bob, 32, 30 + bob], fill=(255, 255, 255, 255))

        # Legs
        d.rectangle([34, 66, 48, 94 + bob], fill=c_suit_dark)
        d.rectangle([36, 68, 46, 90 + bob], fill=c_suit_mid)
        d.rectangle([30, 94 + bob, 50, 102 + bob], fill=(25, 28, 30, 255))
        d.rectangle([54, 68, 68, 96 - bob], fill=c_suit_mid)
        d.rectangle([56, 70, 66, 92 - bob], fill=c_suit_high)
        d.rectangle([52, 96 - bob, 72, 104 - bob], fill=(25, 28, 30, 255))

        # Heavy Hazard Torso
        d.rectangle([34, 32 + bob, 66, 68 + bob], fill=c_suit_dark)
        d.rectangle([36, 34 + bob, 64, 66 + bob], fill=c_suit_mid)
        d.rectangle([40, 36 + bob, 60, 62 + bob], fill=c_suit_high)
        # Chest hazard markings
        d.line([(42, 44 + bob), (58, 44 + bob)], fill=(220, 45, 30, 255), width=3)
        d.line([(42, 52 + bob), (58, 52 + bob)], fill=(220, 45, 30, 255), width=3)

        # Heavy Blast Helmet
        d.rectangle([40, 14 + bob, 62, 34 + bob], fill=c_suit_dark)
        d.ellipse([40, 12 + bob, 62, 30 + bob], fill=c_suit_mid)
        d.rectangle([44, 18 + bob, 60, 26 + bob], fill=c_visor_gold)
        d.line([(46, 20 + bob), (58, 20 + bob)], fill=(255, 255, 240, 255), width=1)

        # Heavy Flamethrower Cannon
        gy = 48 + bob
        # Hose from tank to gun
        d.line([(28, 64 + bob), (44, 66 + bob), (52, gy + 8)], fill=(30, 32, 35, 255), width=4)
        # Gun body
        d.rectangle([50, gy, 88, gy + 12], fill=(30, 34, 38, 255))
        d.rectangle([52, gy + 2, 86, gy + 10], fill=(55, 60, 68, 255))
        d.rectangle([86, gy - 2, 94, gy + 14], fill=c_brass) # Heavy nozzle
        d.rectangle([94, gy + 1, 98, gy + 11], fill=(18, 20, 22, 255))

        # Pilot flame
        fl = [8, 14, 20, 12][f]
        d.polygon([(98, gy + 6), (98 + fl, gy + 2), (98 + fl + 4, gy + 6), (98 + fl, gy + 10)], fill=(255, 120, 20, 255))
        d.polygon([(98, gy + 6), (98 + fl - 3, gy + 4), (98 + fl, gy + 6), (98 + fl - 3, gy + 8)], fill=(255, 235, 80, 255))

    def draw_death(d, w, h, f):
        # Massive fuel tank fireball
        s = 1.0 - f * 0.2
        cx, cy = 52, 54
        r = int(36 * (1.0 + f * 0.35))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 90, 20, int(220 * s)))
        d.ellipse([cx - int(r*0.7), cy - int(r*0.7), cx + int(r*0.7), cy + int(r*0.7)], fill=(255, 200, 40, int(240 * s)))
        d.ellipse([cx - int(r*0.35), cy - int(r*0.35), cx + int(r*0.35), cy + int(r*0.35)], fill=(255, 255, 230, int(255 * s)))

    save_enemy_suite('flame_trooper', draw_frame, draw_death, w, h)

# =============================================================================
# STAGE 2: SCUBA COMMANDO & TORPEDO DRONE
# =============================================================================
def make_scuba_commando():
    w, h = 96, 104
    c_suit_deep = (20, 38, 58, 255)
    c_suit_mid = (35, 68, 98, 255)
    c_suit_aqua = (45, 110, 140, 255)
    c_goggle_glow = (40, 255, 160, 255)
    c_steel_harpoon = (180, 200, 220, 255)

    def draw_frame(d, w, h, f):
        bob = [-2, 2, 0, -1][f]
        
        # Dual rebreather tanks on back
        d.rectangle([22, 28 + bob, 32, 64 + bob], fill=(40, 75, 105, 255))
        d.rectangle([24, 30 + bob, 30, 62 + bob], fill=c_suit_aqua)
        d.rectangle([30, 26 + bob, 38, 62 + bob], fill=(30, 60, 85, 255))

        # Legs & Flipper boots
        d.rectangle([34, 64, 46, 90 + bob], fill=c_suit_deep)
        d.polygon([(30, 90 + bob), (52, 90 + bob), (58, 98 + bob), (28, 98 + bob)], fill=(15, 25, 38, 255))
        d.rectangle([48, 66, 60, 92 - bob], fill=c_suit_mid)
        d.polygon([(44, 92 - bob), (66, 92 - bob), (74, 100 - bob), (42, 100 - bob)], fill=(15, 25, 38, 255))

        # Neoprene Wetsuit Torso
        d.rectangle([34, 34 + bob, 62, 66 + bob], fill=c_suit_deep)
        d.polygon([(36, 34 + bob), (60, 34 + bob), (58, 64 + bob), (36, 64 + bob)], fill=c_suit_mid)
        d.line([(42, 38 + bob), (56, 38 + bob)], fill=c_suit_aqua, width=3)
        d.line([(44, 48 + bob), (54, 48 + bob)], fill=c_suit_aqua, width=2)

        # Dive Mask & Hood
        d.rectangle([40, 16 + bob, 58, 34 + bob], fill=c_suit_deep)
        d.ellipse([42, 14 + bob, 58, 30 + bob], fill=c_suit_mid)
        # Night vision glowing dual goggles
        d.ellipse([48, 20 + bob, 56, 26 + bob], fill=c_goggle_glow)
        d.ellipse([54, 20 + bob, 60, 26 + bob], fill=c_goggle_glow)
        d.ellipse([50, 22 + bob, 54, 24 + bob], fill=(255, 255, 255, 255))

        # High-Pressure Harpoon Gun
        gy = 46 + bob
        d.rectangle([46, gy, 88, gy + 8], fill=(25, 35, 45, 255))
        d.rectangle([48, gy + 2, 86, gy + 6], fill=(50, 65, 80, 255))
        # Steel Spearhead
        d.line([(86, gy + 4), (96, gy + 4)], fill=c_steel_harpoon, width=3)
        d.polygon([(96, gy + 1), (102, gy + 4), (96, gy + 7)], fill=(220, 240, 255, 255)) # Barb
        # Arm
        d.rectangle([42, 40 + bob, 52, 50 + bob], fill=c_suit_mid)

        # Water bubbles around diver
        bx = 20 - f * 3
        by = 24 - f * 4
        d.ellipse([bx, by, bx + 4, by + 4], fill=(120, 220, 255, 180))

    def draw_death(d, w, h, f):
        s = 1.0 - f * 0.22
        cx, cy = 48, 52
        r = int(32 * (1.0 + f * 0.3))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(40, 150, 220, int(200 * s)))
        d.ellipse([cx - int(r*0.6), cy - int(r*0.6), cx + int(r*0.6), cy + int(r*0.6)], fill=(180, 240, 255, int(240 * s)))
        # Water droplets
        for i in range(6):
            ang = i * (math.pi / 3.0) + f
            px = cx + math.cos(ang) * (f * 12 + 14)
            py = cy + math.sin(ang) * (f * 12 + 14)
            d.ellipse([px - 3, py - 3, px + 3, py + 3], fill=(100, 200, 255, int(230 * s)))

    save_enemy_suite('scuba_commando', draw_frame, draw_death, w, h)

def make_torpedo_drone():
    w, h = 100, 96
    c_hull_dark = (22, 35, 52, 255)
    c_hull_mid = (42, 65, 92, 255)
    c_hull_high = (75, 110, 150, 255)
    c_turbine = (140, 170, 200, 255)
    c_sonar_red = (255, 40, 40, 255)

    def draw_frame(d, w, h, f):
        y_wobble = [0, -3, 0, 3][f]
        
        # Upper Sonar Sensor Dome
        d.ellipse([44, 22 + y_wobble, 56, 34 + y_wobble], fill=c_hull_dark)
        d.ellipse([46, 24 + y_wobble, 54, 32 + y_wobble], fill=c_sonar_red if f % 2 == 0 else (255, 200, 200, 255))

        # Main Submersible Aerodynamic Fuselage
        d.ellipse([26, 32 + y_wobble, 78, 62 + y_wobble], fill=c_hull_dark)
        d.ellipse([28, 34 + y_wobble, 76, 58 + y_wobble], fill=c_hull_mid)
        d.ellipse([34, 38 + y_wobble, 70, 52 + y_wobble], fill=c_hull_high)
        # Cockpit visor slit
        d.rectangle([60, 42 + y_wobble, 74, 48 + y_wobble], fill=(20, 240, 255, 255))

        # Twin Hydro-Jet Turbines (Top and Bottom or Left and Right)
        # Left turbine
        d.rectangle([14, 38 + y_wobble, 26, 56 + y_wobble], fill=(30, 40, 50, 255))
        d.rectangle([16, 40 + y_wobble, 24, 54 + y_wobble], fill=c_turbine)
        # Churning water cavitation
        turb_blur = [4, 8, 12, 6][f]
        d.line([(14, 46 + y_wobble), (14 - turb_blur, 46 + y_wobble)], fill=(160, 230, 255, 200), width=4)

        # Ventral Depth Charge Rack
        d.rectangle([40, 60 + y_wobble, 64, 66 + y_wobble], fill=(20, 24, 30, 255))
        # Depth Charge Bomb
        d.ellipse([44, 64 + y_wobble, 60, 78 + y_wobble], fill=(60, 25, 20, 255))
        d.ellipse([46, 66 + y_wobble, 58, 76 + y_wobble], fill=(220, 60, 30, 255))
        d.line([(48, 71 + y_wobble), (56, 71 + y_wobble)], fill=(255, 230, 80, 255), width=2)

    def draw_death(d, w, h, f):
        s = 1.0 - f * 0.22
        cx, cy = 50, 48
        r = int(32 * (1.0 + f * 0.35))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 120, 30, int(220 * s)))
        d.ellipse([cx - int(r*0.6), cy - int(r*0.6), cx + int(r*0.6), cy + int(r*0.6)], fill=(255, 240, 120, int(255 * s)))
        # Flying metal hull fragments
        for ang in [0.8, 2.2, 3.6, 5.0]:
            px = cx + math.cos(ang) * (f * 14 + 12)
            py = cy + math.sin(ang) * (f * 14 + 12)
            d.rectangle([px - 4, py - 3, px + 4, py + 3], fill=(30, 50, 70, int(255 * s)))

    save_enemy_suite('torpedo_drone', draw_frame, draw_death, w, h)

# =============================================================================
# STAGE 3: ACID SPITTER & CEILING STALKER
# =============================================================================
def make_acid_spitter():
    w, h = 104, 100
    c_chitin_dark = (35, 18, 48, 255)
    c_chitin_mid = (70, 35, 95, 255)
    c_chitin_high = (115, 65, 145, 255)
    c_acid_glow = (60, 255, 80, 255)
    c_acid_deep = (30, 160, 45, 255)

    def draw_frame(d, w, h, f):
        leg_phase = [0, 1, 2, 3][f]
        
        # Giant Swollen Translucent Acid Sac (Abdomen)
        sac_pulse = [0, 2, 4, 1][f]
        d.ellipse([12 - sac_pulse, 28 - sac_pulse, 54 + sac_pulse, 68 + sac_pulse], fill=c_chitin_dark)
        d.ellipse([16, 32, 50, 64], fill=c_acid_deep)
        d.ellipse([20, 36, 46, 60], fill=c_acid_glow)
        # Inner glowing toxic bubbles
        d.ellipse([24 + f, 42, 28 + f, 46], fill=(220, 255, 180, 240))
        d.ellipse([34 - f, 48, 40 - f, 54], fill=(220, 255, 180, 240))

        # Quadruped Jointed Barbed Insect Legs
        # Hind legs
        d.line([(32, 54), (18, 70), (12, 88 + (2 if f%2==0 else -2))], fill=c_chitin_dark, width=5)
        d.line([(32, 54), (18, 70), (12, 88 + (2 if f%2==0 else -2))], fill=c_chitin_mid, width=3)
        d.line([(44, 56), (36, 72), (32, 90 - (2 if f%2==0 else -2))], fill=c_chitin_dark, width=5)
        d.line([(44, 56), (36, 72), (32, 90 - (2 if f%2==0 else -2))], fill=c_chitin_mid, width=3)
        # Fore legs
        d.line([(64, 56), (78, 68), (86, 90 + (2 if f%2==0 else -2))], fill=c_chitin_dark, width=5)
        d.line([(64, 56), (78, 68), (86, 90 + (2 if f%2==0 else -2))], fill=c_chitin_high, width=3)
        d.line([(58, 54), (70, 70), (74, 88 - (2 if f%2==0 else -2))], fill=c_chitin_dark, width=5)
        d.line([(58, 54), (70, 70), (74, 88 - (2 if f%2==0 else -2))], fill=c_chitin_mid, width=3)

        # Armored Thorax Carapace
        d.polygon([(46, 38), (72, 34), (76, 58), (48, 60)], fill=c_chitin_dark)
        d.polygon([(48, 40), (70, 36), (74, 56), (50, 58)], fill=c_chitin_mid)
        d.line([(54, 40), (66, 38)], fill=c_chitin_high, width=3)

        # Head & Gaping Mandibles
        d.polygon([(70, 38), (92, 42), (90, 60), (68, 56)], fill=c_chitin_dark)
        d.polygon([(72, 40), (88, 44), (86, 56), (70, 54)], fill=c_chitin_mid)
        # Glowing multi-eyes
        d.ellipse([78, 42, 84, 48], fill=c_acid_glow)
        d.point((80, 44), fill=(255, 255, 255, 255))
        # Dripping Acid Fangs
        d.polygon([(88, 54), (98, 56), (92, 66)], fill=(200, 220, 200, 255)) # Upper fang
        d.polygon([(84, 58), (94, 62), (86, 70)], fill=(200, 220, 200, 255)) # Lower fang
        d.ellipse([92, 66, 96, 72 + f], fill=c_acid_glow) # Dripping droplet

    def draw_death(d, w, h, f):
        # Corrosive neon-green bio explosion
        s = 1.0 - f * 0.22
        cx, cy = 52, 50
        r = int(34 * (1.0 + f * 0.35))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(40, 220, 60, int(220 * s)))
        d.ellipse([cx - int(r*0.6), cy - int(r*0.6), cx + int(r*0.6), cy + int(r*0.6)], fill=(180, 255, 120, int(250 * s)))
        # Splattering acid globs
        for ang in [0.5, 1.6, 2.7, 3.8, 5.2]:
            px = cx + math.cos(ang) * (f * 14 + 14)
            py = cy + math.sin(ang) * (f * 14 + 14)
            d.ellipse([px - 4, py - 4, px + 4, py + 4], fill=(80, 255, 90, int(240 * s)))

    save_enemy_suite('acid_spitter', draw_frame, draw_death, w, h)

def make_ceiling_stalker():
    w, h = 96, 96
    c_stalker_black = (18, 14, 24, 255)
    c_stalker_dark = (42, 28, 56, 255)
    c_stalker_mid = (75, 45, 98, 255)
    c_eye_crimson = (255, 30, 45, 255)
    c_claw_bone = (210, 205, 220, 255)

    def draw_frame(d, w, h, f):
        crawl_bob = [-2, 2, 0, -1][f]
        
        # Curled Scythe Tail
        t_whip = [-2, 2, -1, 3][f]
        d.line([(24, 40), (14 + t_whip, 28), (20 + t_whip, 16)], fill=c_stalker_dark, width=5)
        d.polygon([(18 + t_whip, 16), (28 + t_whip, 14), (22 + t_whip, 8)], fill=c_claw_bone) # Stinger blade

        # Spidery Claws (4 jointed limbs)
        # Hind claws
        d.line([(32, 44), (20, 58), (14, 76 + crawl_bob)], fill=c_stalker_black, width=4)
        d.line([(32, 44), (20, 58), (14, 76 + crawl_bob)], fill=c_stalker_mid, width=2)
        d.polygon([(12, 76 + crawl_bob), (18, 76 + crawl_bob), (14, 84 + crawl_bob)], fill=c_claw_bone)
        # Fore claws
        d.line([(60, 44), (74, 56), (82, 78 - crawl_bob)], fill=c_stalker_black, width=4)
        d.line([(60, 44), (74, 56), (82, 78 - crawl_bob)], fill=c_stalker_mid, width=2)
        d.polygon([(80, 78 - crawl_bob), (86, 78 - crawl_bob), (88, 86 - crawl_bob)], fill=c_claw_bone)

        # Ribbed Xenomorph Body Carapace
        d.ellipse([26, 32 + crawl_bob, 68, 56 + crawl_bob], fill=c_stalker_black)
        d.ellipse([28, 34 + crawl_bob, 66, 52 + crawl_bob], fill=c_stalker_dark)
        # Rib ridges
        for rx in [36, 44, 52]:
            d.line([(rx, 34 + crawl_bob), (rx, 50 + crawl_bob)], fill=c_stalker_mid, width=2)

        # Predatory Elongated Skull & Red Compound Eyes
        d.polygon([(56, 36 + crawl_bob), (84, 30 + crawl_bob), (88, 48 + crawl_bob), (58, 52 + crawl_bob)], fill=c_stalker_black)
        d.polygon([(58, 38 + crawl_bob), (82, 32 + crawl_bob), (86, 46 + crawl_bob), (60, 50 + crawl_bob)], fill=c_stalker_dark)
        # Eyes
        d.ellipse([72, 38 + crawl_bob, 78, 44 + crawl_bob], fill=c_eye_crimson)
        d.ellipse([76, 42 + crawl_bob, 82, 48 + crawl_bob], fill=c_eye_crimson)
        d.point((74, 40 + crawl_bob), fill=(255, 200, 200, 255))

    def draw_death(d, w, h, f):
        s = 1.0 - f * 0.22
        cx, cy = 48, 48
        r = int(30 * (1.0 + f * 0.3))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(120, 25, 45, int(220 * s)))
        d.ellipse([cx - int(r*0.6), cy - int(r*0.6), cx + int(r*0.6), cy + int(r*0.6)], fill=(220, 50, 70, int(240 * s)))
        for ang in [0.7, 2.1, 3.5, 4.9]:
            px = cx + math.cos(ang) * (f * 13 + 12)
            py = cy + math.sin(ang) * (f * 13 + 12)
            d.rectangle([px - 3, py - 2, px + 3, py + 2], fill=c_claw_bone)

    save_enemy_suite('ceiling_stalker', draw_frame, draw_death, w, h)

# =============================================================================
# STAGE 4: CRYO TROOPER & SLED RAIDER
# =============================================================================
def make_cryo_trooper():
    w, h = 100, 104
    c_arctic_dark = (40, 65, 85, 255)
    c_arctic_mid = (85, 125, 155, 255)
    c_arctic_white = (220, 240, 255, 255)
    c_ice_cyan = (50, 220, 255, 255)
    c_fur_trim = (245, 250, 255, 255)

    def draw_frame(d, w, h, f):
        bob = [-2, 2, 0, -1][f]
        
        # Heavy Arctic Parka Legs & Crampons
        d.rectangle([32, 64, 46, 92 + bob], fill=c_arctic_dark)
        d.rectangle([34, 66, 44, 88 + bob], fill=c_arctic_mid)
        d.polygon([(28, 92 + bob), (48, 92 + bob), (52, 100 + bob), (26, 100 + bob)], fill=(20, 25, 30, 255))
        d.line([(28, 100 + bob), (52, 100 + bob)], fill=c_arctic_white, width=2) # Ice cleat
        d.rectangle([50, 66, 64, 94 - bob], fill=c_arctic_mid)
        d.rectangle([52, 68, 62, 90 - bob], fill=c_arctic_white)
        d.polygon([(46, 94 - bob), (66, 94 - bob), (72, 102 - bob), (44, 102 - bob)], fill=(20, 25, 30, 255))

        # Heavy Thermal Parka Torso
        d.rectangle([34, 32 + bob, 64, 66 + bob], fill=c_arctic_dark)
        d.rectangle([36, 34 + bob, 62, 64 + bob], fill=c_arctic_mid)
        # Camo ice patches
        d.polygon([(38, 38 + bob), (50, 36 + bob), (46, 48 + bob), (38, 46 + bob)], fill=c_arctic_white)
        d.polygon([(48, 50 + bob), (60, 48 + bob), (56, 60 + bob), (46, 58 + bob)], fill=c_arctic_white)

        # Fur-lined Collar Hood & Helmet
        d.rectangle([36, 14 + bob, 62, 34 + bob], fill=c_arctic_dark)
        d.ellipse([38, 12 + bob, 60, 32 + bob], fill=c_arctic_mid)
        # White fur hood border
        d.rectangle([36, 20 + bob, 62, 26 + bob], fill=c_fur_trim)
        # Cyan frost goggles
        d.rectangle([42, 22 + bob, 58, 28 + bob], fill=c_ice_cyan)
        d.line([(44, 24 + bob), (56, 24 + bob)], fill=(255, 255, 255, 255), width=1)

        # Shoulder-Mounted Frost Mortar Cannon
        gy = 34 + bob
        d.rectangle([48, gy, 84, gy + 14], fill=(30, 45, 60, 255))
        d.rectangle([50, gy + 2, 82, gy + 12], fill=(60, 85, 110, 255))
        # Thermal insulation wraps around barrel
        d.line([(58, gy + 1), (58, gy + 13)], fill=c_arctic_white, width=3)
        d.line([(68, gy + 1), (68, gy + 13)], fill=c_arctic_white, width=3)
        # Frost muzzle with cold condensation
        d.rectangle([82, gy - 2, 90, gy + 16], fill=(120, 160, 195, 255))
        d.ellipse([88, gy + 2, 94, gy + 12], fill=c_ice_cyan)

        # Arm
        d.rectangle([42, 44 + bob, 54, 54 + bob], fill=c_arctic_dark)

    def draw_death(d, w, h, f):
        # Flash-freeze explosion into 8 ice shards
        s = 1.0 - f * 0.22
        cx, cy = 50, 52
        r = int(32 * (1.0 + f * 0.3))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(80, 200, 255, int(220 * s)))
        d.ellipse([cx - int(r*0.6), cy - int(r*0.6), cx + int(r*0.6), cy + int(r*0.6)], fill=(220, 245, 255, int(255 * s)))
        for i in range(8):
            ang = i * (math.pi / 4.0)
            px = cx + math.cos(ang) * (f * 14 + 10)
            py = cy + math.sin(ang) * (f * 14 + 10)
            d.polygon([(px, py - 4), (px + 4, py), (px, py + 4), (px - 4, py)], fill=(200, 240, 255, int(255 * s)))

    save_enemy_suite('cryo_trooper', draw_frame, draw_death, w, h)

def make_sled_raider():
    w, h = 112, 96
    c_hull_dark = (35, 45, 55, 255)
    c_hull_white = (210, 230, 245, 255)
    c_tread_black = (20, 22, 25, 255)
    c_tread_metal = (65, 75, 85, 255)
    c_snow_spray = (235, 245, 255, 220)

    def draw_frame(d, w, h, f):
        bob = [-1, 2, -2, 1][f]
        
        # Heavy Rear Track Treads
        d.rectangle([14, 58 + bob, 64, 78 + bob], fill=c_tread_black)
        d.rectangle([16, 60 + bob, 62, 76 + bob], fill=c_tread_metal)
        # Rotating track teeth
        t_shift = f * 4
        for tx in range(18, 62, 8):
            d.line([(tx + t_shift % 8, 60 + bob), (tx + t_shift % 8, 76 + bob)], fill=c_tread_black, width=2)
            
        # Snow roost spray behind tracks
        sp_len = [14, 22, 18, 26][f]
        d.polygon([(14, 76 + bob), (14 - sp_len, 68 + bob), (14 - sp_len - 6, 78 + bob)], fill=c_snow_spray)

        # Front Ski Suspension Blades
        d.polygon([(64, 66 + bob), (94, 68 + bob), (104, 64 + bob), (96, 74 + bob), (64, 72 + bob)], fill=(180, 200, 220, 255))
        d.line([(70, 56 + bob), (78, 68 + bob)], fill=(100, 110, 120, 255), width=3) # Coil strut

        # Sled Armored Front Chassis & Cowling
        d.polygon([(36, 42 + bob), (82, 44 + bob), (92, 60 + bob), (40, 62 + bob)], fill=c_hull_dark)
        d.polygon([(38, 44 + bob), (80, 46 + bob), (88, 58 + bob), (42, 60 + bob)], fill=c_hull_white)
        # Hazard stripes on front plow
        d.line([(74, 48 + bob), (86, 56 + bob)], fill=(220, 40, 30, 255), width=2)
        d.line([(66, 48 + bob), (78, 56 + bob)], fill=(220, 40, 30, 255), width=2)

        # Hooded Raider Pilot
        d.rectangle([42, 22 + bob, 58, 42 + bob], fill=(45, 60, 75, 255))
        d.ellipse([44, 20 + bob, 56, 36 + bob], fill=(85, 115, 140, 255))
        d.rectangle([48, 26 + bob, 58, 30 + bob], fill=(255, 180, 30, 255)) # Visor

        # Twin Heavy Front Autocannons
        d.rectangle([76, 44 + bob, 102, 48 + bob], fill=(25, 28, 32, 255))
        d.rectangle([76, 52 + bob, 102, 56 + bob], fill=(25, 28, 32, 255))
        if f == 2: # Muzzle blast
            d.ellipse([102, 42 + bob, 108, 50 + bob], fill=(255, 220, 50, 255))
            d.ellipse([102, 50 + bob, 108, 58 + bob], fill=(255, 220, 50, 255))

    def draw_death(d, w, h, f):
        s = 1.0 - f * 0.22
        cx, cy = 56, 54
        r = int(36 * (1.0 + f * 0.35))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 110, 20, int(220 * s)))
        d.ellipse([cx - int(r*0.6), cy - int(r*0.6), cx + int(r*0.6), cy + int(r*0.6)], fill=(255, 230, 80, int(255 * s)))
        # Flying snow treads and skis
        for ang in [0.6, 2.0, 3.4, 4.8]:
            px = cx + math.cos(ang) * (f * 15 + 14)
            py = cy + math.sin(ang) * (f * 15 + 14)
            d.rectangle([px - 5, py - 3, px + 5, py + 3], fill=(40, 50, 60, int(255 * s)))

    save_enemy_suite('sled_raider', draw_frame, draw_death, w, h)

# Run Part 1
make_guerrilla_gunner()
make_flame_trooper()
make_scuba_commando()
make_torpedo_drone()
make_acid_spitter()
make_ceiling_stalker()
make_cryo_trooper()
make_sled_raider()
print("PART 1 (STAGES 1-4) COMPLETE!")
