import os, math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops

def ensure_dir(d):
    os.makedirs(d, exist_ok=True)

def create_arcade_outline(im, pad=12, outline_color=(15, 18, 25, 255)):
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

def save_miniboss_suite(folder_name, draw_frame_fn, draw_death_fn, w, h, pad=12):
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
        out.save(f'{folder}/death/death_{i}.png')
    print(f"Generated complete mini-boss suite for {folder_name}")

# =============================================================================
# STAGE 3: CHITIN BEHEMOTH (Alien Hive Bio-Cavern Mini-Boss)
# =============================================================================
def make_stage3_miniboss():
    w, h = 190, 210
    c_carapace_dark = (48, 18, 52, 255)
    c_carapace_mid = (85, 30, 92, 255)
    c_carapace_light = (135, 50, 145, 255)
    c_flesh_dark = (110, 20, 40, 255)
    c_flesh_mid = (175, 35, 65, 255)
    c_flesh_light = (225, 75, 110, 255)
    c_acid_green = (60, 235, 80, 255)
    c_acid_glow = (180, 255, 120, 255)
    c_bone_white = (230, 225, 200, 255)
    c_bone_shadow = (160, 150, 130, 255)

    def draw_frame(d, w, h, f):
        bob = [3, -4, 3, -2][f]
        leg_step = [-10, 8, -6, 12][f]
        
        # 1. Undulating Spiked Bio-Tail
        tail_wave = math.sin(f * 1.5) * 8.0
        d.polygon([(150, 110 + bob), (175 + tail_wave, 90 + bob), (185 + tail_wave, 105 + bob), (160, 130 + bob)], fill=c_flesh_dark)
        d.polygon([(170 + tail_wave, 95 + bob), (185 + tail_wave, 80 + bob), (180 + tail_wave, 100 + bob)], fill=c_bone_white) # Tail stinger

        # 2. Quadruped Chitin Limbs (Back legs)
        d.polygon([(115, 110 + bob), (145 + leg_step, 145 + bob), (135 + leg_step, 195), (115 + leg_step, 195), (130 + leg_step, 145 + bob), (105, 115 + bob)], fill=c_carapace_dark)
        d.polygon([(125 + leg_step, 190), (145 + leg_step, 195), (115 + leg_step, 202)], fill=c_bone_white) # Claws

        # 3. Swollen Translucent Acid Sac (Back Abdomen)
        pulse = math.sin(f * 1.8) * 3.0
        d.ellipse([95 - pulse, 65 + bob, 165 + pulse, 135 + bob], fill=c_flesh_dark)
        d.ellipse([100 - pulse, 70 + bob, 160 + pulse, 130 + bob], fill=c_acid_green)
        d.ellipse([115, 80 + bob, 150, 115 + bob], fill=c_acid_glow)
        # Internal acid bubbles
        d.circle((125, 92 + bob), 4, fill=(255, 255, 255, 220))
        d.circle((140, 105 + bob), 3, fill=(255, 255, 255, 200))
        d.circle((118, 112 + bob), 2, fill=(255, 255, 255, 190))

        # 4. Heavy Segmented Thorax & Carapace Ribs
        d.polygon([(50, 60 + bob), (120, 65 + bob), (110, 130 + bob), (45, 125 + bob)], fill=c_carapace_dark)
        d.polygon([(55, 65 + bob), (115, 70 + bob), (105, 125 + bob), (50, 120 + bob)], fill=c_carapace_mid)
        # Rib arches
        for ry in [75, 90, 105]:
            d.line([(55, ry + bob), (110, ry + 4 + bob)], fill=c_carapace_light, width=4)
            d.line([(58, ry + 1 + bob), (105, ry + 4 + bob)], fill=c_bone_white, width=2)

        # 5. Massive Forelegs & Scythe Talons (Front limbs)
        f_step = -leg_step
        d.polygon([(55, 105 + bob), (30 + f_step, 135 + bob), (20 + f_step, 195), (40 + f_step, 195), (45 + f_step, 140 + bob), (75, 110 + bob)], fill=c_carapace_mid)
        d.polygon([(60, 110 + bob), (35 + f_step, 138 + bob), (28 + f_step, 185), (38 + f_step, 142 + bob)], fill=c_carapace_light)
        # Heavy curved bone scythe blade
        d.polygon([(15 + f_step, 165 + bob), (5 + f_step, 190), (35 + f_step, 202), (40 + f_step, 190), (28 + f_step, 175 + bob)], fill=c_bone_white)
        d.line([(18 + f_step, 170 + bob), (10 + f_step, 195)], fill=c_bone_shadow, width=2)

        # 6. Grotesque Bio-Armored Head & Mandibles
        d.polygon([(20, 75 + bob), (60, 65 + bob), (65, 105 + bob), (35, 115 + bob)], fill=c_flesh_mid)
        d.polygon([(25, 70 + bob), (55, 60 + bob), (62, 85 + bob), (30, 90 + bob)], fill=c_carapace_dark)
        # Glowing crimson/yellow compound eyes
        d.ellipse([28, 78 + bob, 38, 88 + bob], fill=(255, 40, 60, 255))
        d.ellipse([31, 80 + bob, 36, 85 + bob], fill=(255, 235, 80, 255))
        d.ellipse([38, 74 + bob, 45, 82 + bob], fill=(255, 40, 60, 255))
        # Giant dripping mandible fangs
        d.polygon([(18, 92 + bob), (32, 98 + bob), (8, 120 + bob)], fill=c_bone_white)
        d.polygon([(28, 102 + bob), (42, 106 + bob), (22, 130 + bob)], fill=c_bone_white)
        # Acid drip from fangs
        d.ellipse([6, 122 + bob, 11, 130 + bob], fill=c_acid_green)
        d.ellipse([20, 132 + bob, 24, 138 + bob], fill=c_acid_glow)

    def draw_death(d, w, h, f):
        # Rupturing biological acid explosion
        s = 1.0 - f * 0.2
        cx, cy = 95, 115
        r = int(55 * (1.0 + f * 0.4))
        # Corrosive acid wave
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(40, 220, 70, int(210 * s)))
        d.ellipse([cx - int(r*0.7), cy - int(r*0.7), cx + int(r*0.7), cy + int(r*0.7)], fill=(180, 255, 80, int(240 * s)))
        d.ellipse([cx - int(r*0.35), cy - int(r*0.35), cx + int(r*0.35), cy + int(r*0.35)], fill=(255, 255, 200, int(255 * s)))
        # Splattering chitin chunks
        for a in [0.3, 1.2, 2.1, 3.2, 4.4, 5.5]:
            dist = 30 + f * 28
            px = cx + math.cos(a) * dist
            py = cy + math.sin(a) * dist
            d.rectangle([px - 5, py - 5, px + 5, py + 5], fill=c_carapace_dark)
            d.line([(px, py), (px - math.cos(a)*12, py - math.sin(a)*12)], fill=c_flesh_mid, width=3)

    save_miniboss_suite('mini_boss_stage3', draw_frame, draw_death, w, h)

# =============================================================================
# STAGE 4: POLAR SIEGE COLOSSUS (Snowfield Tundra Mini-Boss)
# =============================================================================
def make_stage4_miniboss():
    w, h = 180, 210
    c_armor_white = (235, 242, 250, 255)
    c_armor_cyan = (175, 215, 235, 255)
    c_armor_shadow = (110, 140, 165, 255)
    c_metal_black = (24, 28, 35, 255)
    c_metal_dark = (48, 56, 68, 255)
    c_metal_mid = (80, 95, 115, 255)
    c_glow_ice = (60, 220, 255, 255)
    c_glow_core = (200, 250, 255, 255)

    def draw_frame(d, w, h, f):
        stomp = [-3, 4, -2, 2][f]
        leg_l = [12, -4, -14, 2][f]
        leg_r = [-14, 2, 12, -4][f]

        # 1. Dual Overhead Cryo-Mortar Pods (Shoulder Artillery)
        # Left pod
        d.rectangle([35, 20 + stomp, 75, 52 + stomp], fill=c_metal_dark)
        d.rectangle([38, 22 + stomp, 72, 50 + stomp], fill=c_armor_cyan)
        d.polygon([(25, 18 + stomp), (45, 18 + stomp), (40, 48 + stomp), (20, 48 + stomp)], fill=c_metal_black) # Mortar tube 1
        d.ellipse([20, 15 + stomp, 42, 25 + stomp], fill=c_glow_ice)
        # Right pod
        d.rectangle([110, 20 + stomp, 150, 52 + stomp], fill=c_metal_dark)
        d.rectangle([113, 22 + stomp, 147, 50 + stomp], fill=c_armor_cyan)
        d.polygon([(140, 18 + stomp), (160, 18 + stomp), (155, 48 + stomp), (135, 48 + stomp)], fill=c_metal_black) # Mortar tube 2
        d.ellipse([138, 15 + stomp, 160, 25 + stomp], fill=c_glow_ice)

        # 2. Heavy Hydraulic Cleat Legs (Back leg)
        by = 125 + stomp
        d.rectangle([105 + leg_r, by, 135 + leg_r, by + 45], fill=c_metal_dark)
        d.rectangle([110 + leg_r, by + 40, 130 + leg_r, 195], fill=c_metal_black)
        d.polygon([(95 + leg_r, 190), (145 + leg_r, 190), (150 + leg_r, 202), (90 + leg_r, 202)], fill=c_metal_dark) # Foot cleat
        d.line([(95 + leg_r, 202), (105 + leg_r, 208)], fill=c_metal_black, width=3) # Spikes
        d.line([(135 + leg_r, 202), (145 + leg_r, 208)], fill=c_metal_black, width=3)

        # 3. Main Armored Torso Chassis & Reinforced Cockpit
        d.polygon([(45, 50 + stomp), (140, 50 + stomp), (130, 130 + stomp), (55, 130 + stomp)], fill=c_metal_dark)
        d.polygon([(50, 55 + stomp), (135, 55 + stomp), (125, 125 + stomp), (60, 125 + stomp)], fill=c_armor_white)
        d.polygon([(65, 65 + stomp), (120, 65 + stomp), (115, 115 + stomp), (70, 115 + stomp)], fill=c_armor_cyan)
        # Front armored snowplow wedge
        d.polygon([(70, 100 + stomp), (115, 100 + stomp), (105, 135 + stomp), (80, 135 + stomp)], fill=c_armor_shadow)
        d.line([(70, 100 + stomp), (105, 135 + stomp)], fill=c_metal_black, width=2)
        # Cockpit Visor / Target Scanner
        d.rectangle([68, 72 + stomp, 118, 86 + stomp], fill=c_metal_black)
        d.rectangle([72, 75 + stomp, 114, 83 + stomp], fill=c_glow_ice)
        d.line([(75, 78 + stomp), (110, 78 + stomp)], fill=c_glow_core, width=2)

        # 4. Heavy Front Leg & Hydraulic Piston
        fy = 120 + stomp
        d.rectangle([45 + leg_l, fy, 80 + leg_l, fy + 48], fill=c_armor_white)
        d.rectangle([50 + leg_l, fy + 4, 75 + leg_l, fy + 42], fill=c_armor_cyan)
        d.rectangle([55 + leg_l, fy + 45, 72 + leg_l, 195], fill=c_metal_dark) # Hydraulic piston shaft
        d.line([(62 + leg_l, fy + 45), (62 + leg_l, 195)], fill=c_glow_ice, width=3)
        # Foot cleat
        d.polygon([(35 + leg_l, 190), (90 + leg_l, 190), (95 + leg_l, 202), (30 + leg_l, 202)], fill=c_metal_dark)
        d.line([(38 + leg_l, 202), (48 + leg_l, 208)], fill=c_metal_black, width=4)
        d.line([(78 + leg_l, 202), (88 + leg_l, 208)], fill=c_metal_black, width=4)

        # 5. Heavy Twin Autocannon (Right Arm)
        gy = 85 + stomp
        d.rectangle([15, gy, 55, gy + 18], fill=c_metal_dark)
        d.rectangle([0, gy + 2, 25, gy + 7], fill=c_metal_black) # Top barrel
        d.rectangle([0, gy + 11, 25, gy + 16], fill=c_metal_black) # Bottom barrel
        d.rectangle([-4, gy + 1, 4, gy + 8], fill=c_metal_mid) # Muzzle brakes
        d.rectangle([-4, gy + 10, 4, gy + 17], fill=c_metal_mid)
        # Ammo feed chute
        d.line([(50, gy + 16), (55, 115 + stomp)], fill=c_metal_black, width=5)

    def draw_death(d, w, h, f):
        s = 1.0 - f * 0.2
        cx, cy = 90, 110
        r = int(52 * (1.0 + f * 0.35))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 130, 30, int(220 * s)))
        d.ellipse([cx - int(r*0.7), cy - int(r*0.7), cx + int(r*0.7), cy + int(r*0.7)], fill=(255, 220, 60, int(240 * s)))
        # Flash-freezing ice shards flying out
        for a in [0.4, 1.4, 2.5, 3.6, 4.7, 5.8]:
            dist = 25 + f * 32
            px = cx + math.cos(a) * dist
            py = cy + math.sin(a) * dist
            d.polygon([(px, py - 8), (px + 6, py), (px, py + 8), (px - 6, py)], fill=c_glow_ice)
            d.polygon([(px, py - 4), (px + 3, py), (px, py + 4), (px - 3, py)], fill=c_glow_core)

    save_miniboss_suite('mini_boss_stage4', draw_frame, draw_death, w, h)

# =============================================================================
# STAGE 5: VULCAN FOUNDRY DREADNOUGHT (Steel Refinery Mini-Boss)
# =============================================================================
def make_stage5_miniboss():
    w, h = 190, 215
    c_cast_black = (26, 28, 34, 255)
    c_cast_dark = (45, 50, 60, 255)
    c_cast_mid = (75, 82, 95, 255)
    c_hazard_yellow = (245, 195, 25, 255)
    c_hazard_black = (20, 22, 26, 255)
    c_lava_dark = (160, 30, 15, 255)
    c_lava_mid = (255, 95, 20, 255)
    c_lava_bright = (255, 225, 75, 255)
    c_molten_metal = (255, 245, 210, 255)

    def draw_frame(d, w, h, f):
        stomp = [-4, 4, -2, 2][f]
        leg_l = [14, -6, -14, 4][f]
        leg_r = [-14, 4, 14, -6][f]

        # 1. Twin Exhaust Funnels with billowing fire/smoke
        for fx in [55, 135]:
            d.polygon([(fx - 12, 10 + stomp), (fx + 12, 10 + stomp), (fx + 8, 45 + stomp), (fx - 8, 45 + stomp)], fill=c_cast_dark)
            d.rectangle([fx - 14, 8 + stomp, fx + 14, 15 + stomp], fill=c_cast_black)
            # Flame exhaust plume
            fl_len = [14, 22, 18, 25][f]
            d.polygon([(fx - 8, 8 + stomp), (fx, 8 + stomp - fl_len), (fx + 8, 8 + stomp)], fill=c_lava_mid)
            d.polygon([(fx - 4, 8 + stomp), (fx, 8 + stomp - int(fl_len*0.6)), (fx + 4, 8 + stomp)], fill=c_lava_bright)

        # 2. Heavy Piston Walker Legs (Back Leg)
        by = 125 + stomp
        d.rectangle([110 + leg_r, by, 145 + leg_r, by + 45], fill=c_cast_black)
        d.rectangle([118 + leg_r, by + 42, 138 + leg_r, 195], fill=(130, 140, 155, 255)) # Chrome piston
        d.polygon([(100 + leg_r, 192), (155 + leg_r, 192), (160 + leg_r, 205), (95 + leg_r, 205)], fill=c_cast_black)
        d.rectangle([105 + leg_r, 195, 150 + leg_r, 200], fill=c_hazard_yellow)

        # 3. Heavy Iron Hull & Glowing Molten Crucible Core
        d.polygon([(45, 45 + stomp), (145, 45 + stomp), (135, 130 + stomp), (55, 130 + stomp)], fill=c_cast_dark)
        d.polygon([(52, 52 + stomp), (138, 52 + stomp), (130, 122 + stomp), (60, 122 + stomp)], fill=c_cast_black)
        # Hazard Stripes across upper torso
        d.rectangle([55, 52 + stomp, 135, 66 + stomp], fill=c_hazard_yellow)
        for hx in range(55, 130, 14):
            d.polygon([(hx, 66 + stomp), (hx + 8, 52 + stomp), (hx + 14, 52 + stomp), (hx + 6, 66 + stomp)], fill=c_hazard_black)

        # Central Molten Steel Crucible (Glowing intensely)
        d.ellipse([70, 72 + stomp, 120, 118 + stomp], fill=c_cast_black)
        d.ellipse([74, 76 + stomp, 116, 114 + stomp], fill=c_lava_dark)
        d.ellipse([78, 80 + stomp, 112, 110 + stomp], fill=c_lava_mid)
        d.ellipse([84, 85 + stomp, 106, 104 + stomp], fill=c_lava_bright)
        d.circle((95, 94 + stomp), 5, fill=c_molten_metal)
        # Protective iron cage bars across furnace
        d.line([(95, 74 + stomp), (95, 116 + stomp)], fill=c_cast_dark, width=3)
        d.line([(76, 95 + stomp), (114, 95 + stomp)], fill=c_cast_dark, width=3)

        # 4. Front Walking Leg
        fy = 120 + stomp
        d.rectangle([48 + leg_l, fy, 85 + leg_l, fy + 46], fill=c_cast_dark)
        d.rectangle([54 + leg_l, fy + 4, 79 + leg_l, fy + 40], fill=c_cast_mid)
        d.rectangle([58 + leg_l, fy + 44, 76 + leg_l, 195], fill=(130, 140, 155, 255))
        d.polygon([(40 + leg_l, 192), (95 + leg_l, 192), (100 + leg_l, 205), (35 + leg_l, 205)], fill=c_cast_black)
        d.rectangle([45 + leg_l, 195, 90 + leg_l, 200], fill=c_hazard_yellow)

        # 5. Massive Pneumatic Ram Fist / Rivet Cannon Arm
        gy = 80 + stomp
        d.rectangle([15, gy, 55, gy + 32], fill=c_cast_black)
        d.rectangle([18, gy + 4, 50, gy + 28], fill=c_cast_dark)
        # Giant hydraulic ram piston extending
        ram_ext = [0, 14, 24, 8][f]
        d.rectangle([-15 - ram_ext, gy + 8, 18, gy + 24], fill=(160, 170, 185, 255))
        # Spiked Ram Fist Plate
        d.polygon([(-28 - ram_ext, gy + 2), (-12 - ram_ext, gy + 2), (-12 - ram_ext, gy + 30), (-28 - ram_ext, gy + 30)], fill=c_cast_black)
        d.polygon([(-36 - ram_ext, gy + 6), (-28 - ram_ext, gy + 2), (-28 - ram_ext, gy + 12)], fill=c_lava_bright)
        d.polygon([(-36 - ram_ext, gy + 22), (-28 - ram_ext, gy + 18), (-28 - ram_ext, gy + 28)], fill=c_lava_bright)

    def draw_death(d, w, h, f):
        s = 1.0 - f * 0.2
        cx, cy = 95, 115
        r = int(56 * (1.0 + f * 0.4))
        # Giant molten furnace blast
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 80, 15, int(220 * s)))
        d.ellipse([cx - int(r*0.7), cy - int(r*0.7), cx + int(r*0.7), cy + int(r*0.7)], fill=(255, 195, 30, int(240 * s)))
        d.ellipse([cx - int(r*0.4), cy - int(r*0.4), cx + int(r*0.4), cy + int(r*0.4)], fill=(255, 255, 220, int(255 * s)))
        # Flying molten steel globs
        for a in [0.2, 1.1, 2.2, 3.4, 4.5, 5.6]:
            dist = 28 + f * 34
            px = cx + math.cos(a) * dist
            py = cy + math.sin(a) * dist
            d.circle((px, py), 6, fill=c_lava_bright)
            d.line([(px, py), (px - math.cos(a)*14, py - math.sin(a)*14)], fill=c_lava_mid, width=4)

    save_miniboss_suite('mini_boss_stage5', draw_frame, draw_death, w, h)

# =============================================================================
# STAGE 6: TESLA STORM OVERLORD (Electric Dynamo Mini-Boss)
# =============================================================================
def make_stage6_miniboss():
    w, h = 185, 215
    c_lead_black = (22, 24, 30, 255)
    c_lead_dark = (42, 48, 58, 255)
    c_lead_mid = (70, 80, 95, 255)
    c_copper_dark = (145, 75, 30, 255)
    c_copper_mid = (215, 120, 50, 255)
    c_copper_light = (255, 175, 90, 255)
    c_spark_cyan = (50, 220, 255, 255)
    c_spark_white = (225, 250, 255, 255)

    def draw_frame(d, w, h, f):
        stomp = [-3, 3, -1, 1][f]
        leg_l = [12, -4, -12, 4][f]
        leg_r = [-12, 4, 12, -4][f]

        # 1. Dual Towering Copper Tesla Coils
        for tx in [45, 140]:
            # Coil support mast
            d.rectangle([tx - 8, 15 + stomp, tx + 8, 70 + stomp], fill=c_lead_dark)
            # Wound copper windings
            for wy in range(25, 65, 6):
                d.rectangle([tx - 12, wy + stomp, tx + 12, wy + 4 + stomp], fill=c_copper_mid)
                d.line([(tx - 10, wy + stomp), (tx + 10, wy + stomp)], fill=c_copper_light, width=1)
            # Top Toroid Terminal Sphere
            d.ellipse([tx - 18, 5 + stomp, tx + 18, 25 + stomp], fill=c_copper_dark)
            d.ellipse([tx - 15, 7 + stomp, tx + 15, 23 + stomp], fill=c_copper_light)
            # Arcing sparks dancing between orbs
            arc_phase = math.sin(f * 2.5 + tx) * 6.0
            d.line([(tx, 15 + stomp), (tx + arc_phase, 2 + stomp)], fill=c_spark_cyan, width=2)
            d.line([(tx + arc_phase, 2 + stomp), (tx + arc_phase * 1.5, -4 + stomp)], fill=c_spark_white, width=1)

        # Spark jumping between the two coils
        d.line([(45, 15 + stomp), (70, 5 + stomp), (115, 20 + stomp), (140, 15 + stomp)], fill=c_spark_cyan, width=2)
        d.line([(45, 15 + stomp), (90, 8 + stomp), (140, 15 + stomp)], fill=c_spark_white, width=1)

        # 2. Dielectric Walker Legs (Back Leg)
        by = 125 + stomp
        d.rectangle([110 + leg_r, by, 140 + leg_r, by + 45], fill=c_lead_black)
        d.rectangle([115 + leg_r, by + 42, 135 + leg_r, 195], fill=c_lead_dark)
        d.polygon([(95 + leg_r, 192), (150 + leg_r, 192), (155 + leg_r, 204), (90 + leg_r, 204)], fill=c_lead_black)
        d.line([(100 + leg_r, 198), (145 + leg_r, 198)], fill=c_spark_cyan, width=2)

        # 3. Main Dielectric Chassis & High-Voltage Plasma Core
        d.polygon([(40, 50 + stomp), (145, 50 + stomp), (135, 130 + stomp), (50, 130 + stomp)], fill=c_lead_dark)
        d.polygon([(48, 56 + stomp), (137, 56 + stomp), (128, 124 + stomp), (58, 124 + stomp)], fill=c_lead_black)
        # Insulator ribs
        for iy in [65, 80, 95]:
            d.line([(52, iy + stomp), (132, iy + stomp)], fill=c_lead_mid, width=3)

        # Blinding Cyan/White Fusion Plasma Reactor
        d.ellipse([70, 75 + stomp, 115, 118 + stomp], fill=c_lead_black)
        d.ellipse([75, 80 + stomp, 110, 114 + stomp], fill=(20, 120, 200, 255))
        d.ellipse([80, 84 + stomp, 105, 110 + stomp], fill=c_spark_cyan)
        d.circle((92, 97 + stomp), 7, fill=c_spark_white)

        # 4. Front Walking Leg
        fy = 120 + stomp
        d.rectangle([45 + leg_l, fy, 80 + leg_l, fy + 46], fill=c_lead_dark)
        d.rectangle([50 + leg_l, fy + 4, 75 + leg_l, fy + 40], fill=c_lead_mid)
        d.rectangle([54 + leg_l, fy + 44, 72 + leg_l, 195], fill=c_lead_black)
        d.polygon([(35 + leg_l, 192), (90 + leg_l, 192), (95 + leg_l, 204), (30 + leg_l, 204)], fill=c_lead_black)
        d.line([(40 + leg_l, 198), (85 + leg_l, 198)], fill=c_spark_cyan, width=2)

        # 5. Dual Arc Emitter Discharge Claws (Forward weapon)
        gy = 80 + stomp
        d.rectangle([15, gy, 48, gy + 28], fill=c_lead_black)
        d.polygon([(-5, gy + 2), (18, gy + 2), (15, gy + 12), (-8, gy + 8)], fill=c_copper_mid) # Upper electrode
        d.polygon([(-5, gy + 26), (18, gy + 26), (15, gy + 16), (-8, gy + 20)], fill=c_copper_mid) # Lower electrode
        # Crackling ball between electrodes
        d.circle((-10, gy + 14), 8, fill=c_spark_cyan)
        d.circle((-10, gy + 14), 4, fill=c_spark_white)

    def draw_death(d, w, h, f):
        s = 1.0 - f * 0.2
        cx, cy = 92, 112
        r = int(54 * (1.0 + f * 0.38))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(40, 160, 255, int(220 * s)))
        d.ellipse([cx - int(r*0.65), cy - int(r*0.65), cx + int(r*0.65), cy + int(r*0.65)], fill=(120, 230, 255, int(240 * s)))
        d.ellipse([cx - int(r*0.3), cy - int(r*0.3), cx + int(r*0.3), cy + int(r*0.3)], fill=(255, 255, 255, int(255 * s)))
        # High voltage lightning bolts branching out
        for a in [0.0, 1.05, 2.1, 3.14, 4.2, 5.2]:
            dist = 30 + f * 32
            px = cx + math.cos(a) * dist
            py = cy + math.sin(a) * dist
            d.line([(cx, cy), (px, py)], fill=c_spark_white, width=2)
            d.line([(px, py), (px + math.cos(a+0.6)*18, py + math.sin(a+0.6)*18)], fill=c_spark_cyan, width=1)

    save_miniboss_suite('mini_boss_stage6', draw_frame, draw_death, w, h)

# =============================================================================
# STAGE 7: ORBITAL STRIKE VANGUARD (Aerospace Hangar Mini-Boss)
# =============================================================================
def make_stage7_miniboss():
    w, h = 195, 210
    c_titanium_white = (225, 230, 242, 255)
    c_titanium_mid = (165, 175, 195, 255)
    c_titanium_dark = (85, 95, 115, 255)
    c_aerospace_black = (25, 28, 36, 255)
    c_visor_gold = (255, 195, 45, 255)
    c_exhaust_cyan = (40, 210, 255, 255)
    c_missile_red = (235, 45, 35, 255)

    def draw_frame(d, w, h, f):
        bob = [3, -4, 3, -2][f]
        wing_flap = math.sin(f * 1.5) * 4.0
        
        # 1. Dual Swept Titanium Wings with Ion Thrusters
        # Back wing
        d.polygon([(110, 60 + bob), (175, 35 + bob + wing_flap), (185, 55 + bob + wing_flap), (125, 85 + bob)], fill=c_titanium_dark)
        d.polygon([(170, 38 + bob + wing_flap), (195, 42 + bob + wing_flap), (185, 52 + bob + wing_flap)], fill=c_aerospace_black) # Thruster bell
        # Back jet flame
        d.polygon([(195, 43 + bob + wing_flap), (215, 46 + bob + wing_flap), (195, 49 + bob + wing_flap)], fill=c_exhaust_cyan)

        # 2. Heavy Aerospace Landing Gear (Back leg)
        by = 125 + bob
        d.polygon([(115, by), (145, by + 45), (140, 192), (120, 192), (130, by + 40), (105, by)], fill=c_aerospace_black)
        d.polygon([(110, 190), (155, 190), (160, 202), (105, 202)], fill=c_titanium_dark)

        # 3. Main Stealth Fuselage & Cockpit Canopy
        d.polygon([(40, 65 + bob), (135, 50 + bob), (145, 125 + bob), (55, 135 + bob)], fill=c_titanium_dark)
        d.polygon([(45, 70 + bob), (130, 55 + bob), (138, 120 + bob), (60, 128 + bob)], fill=c_titanium_white)
        d.polygon([(55, 80 + bob), (120, 68 + bob), (125, 115 + bob), (70, 120 + bob)], fill=c_titanium_mid)
        # Gold Reflective Command Visor
        d.polygon([(35, 80 + bob), (75, 72 + bob), (70, 95 + bob), (38, 98 + bob)], fill=c_visor_gold)
        d.line([(40, 84 + bob), (70, 78 + bob)], fill=(255, 255, 240, 255), width=2)

        # 4. Quadruple Shoulder Homing Micro-Missile Pod
        d.rectangle([80, 32 + bob, 125, 58 + bob], fill=c_aerospace_black)
        d.rectangle([84, 35 + bob, 121, 55 + bob], fill=c_titanium_dark)
        # 4 missile tips
        d.circle((90, 42 + bob), 3, fill=c_missile_red)
        d.circle((102, 42 + bob), 3, fill=c_missile_red)
        d.circle((90, 49 + bob), 3, fill=c_missile_red)
        d.circle((102, 49 + bob), 3, fill=c_missile_red)

        # 5. Front Swept Wing & Thruster
        d.polygon([(65, 85 + bob), (145, 75 + bob - wing_flap), (155, 105 + bob - wing_flap), (80, 115 + bob)], fill=c_titanium_white)
        d.polygon([(75, 90 + bob), (140, 82 + bob - wing_flap), (148, 102 + bob - wing_flap), (85, 110 + bob)], fill=c_titanium_mid)
        d.polygon([(145, 82 + bob - wing_flap), (170, 86 + bob - wing_flap), (160, 98 + bob - wing_flap)], fill=c_aerospace_black)
        # Front jet flame
        d.polygon([(170, 88 + bob - wing_flap), (195, 91 + bob - wing_flap), (170, 94 + bob - wing_flap)], fill=c_exhaust_cyan)

        # 6. Front Landing Gear
        fy = 120 + bob
        d.polygon([(50, fy), (75, fy + 48), (70, 192), (52, 192), (60, fy + 42), (40, fy)], fill=c_titanium_dark)
        d.polygon([(42, 190), (82, 190), (88, 202), (36, 202)], fill=c_aerospace_black)

        # 7. Heavy Particle Beam Rotary Cannon
        gy = 100 + bob
        d.rectangle([10, gy, 50, gy + 22], fill=c_aerospace_black)
        d.rectangle([-15, gy + 4, 15, gy + 10], fill=c_titanium_mid) # Upper barrel
        d.rectangle([-15, gy + 12, 15, gy + 18], fill=c_titanium_mid) # Lower barrel
        d.ellipse([-22, gy + 2, -12, gy + 20], fill=c_exhaust_cyan) # Particle focus ring

    def draw_death(d, w, h, f):
        s = 1.0 - f * 0.2
        cx, cy = 95, 110
        r = int(55 * (1.0 + f * 0.38))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 110, 30, int(220 * s)))
        d.ellipse([cx - int(r*0.7), cy - int(r*0.7), cx + int(r*0.7), cy + int(r*0.7)], fill=(255, 210, 60, int(240 * s)))
        d.ellipse([cx - int(r*0.35), cy - int(r*0.35), cx + int(r*0.35), cy + int(r*0.35)], fill=(255, 255, 240, int(255 * s)))
        # Flying aircraft titanium shards
        for a in [0.5, 1.6, 2.7, 3.8, 4.9]:
            dist = 30 + f * 35
            px = cx + math.cos(a) * dist
            py = cy + math.sin(a) * dist
            d.polygon([(px - 8, py - 3), (px + 8, py + 3), (px, py + 8)], fill=c_titanium_white)

    save_miniboss_suite('mini_boss_stage7', draw_frame, draw_death, w, h)

# =============================================================================
# STAGE 8: PSIONIC HIVE LEVIATHAN (Sanctum Mini-Boss)
# =============================================================================
def make_stage8_miniboss():
    w, h = 195, 220
    c_bio_purple = (55, 15, 65, 255)
    c_bio_crimson = (125, 25, 55, 255)
    c_flesh_pink = (205, 65, 105, 255)
    c_brain_pink = (245, 135, 165, 255)
    c_brain_shadow = (175, 75, 105, 255)
    c_psionic_magenta = (240, 40, 255, 255)
    c_psionic_core = (255, 220, 255, 255)
    c_bone_white = (235, 230, 210, 255)

    def draw_frame(d, w, h, f):
        bob = [3, -4, 3, -2][f]
        
        # 1. Four Orbiting Magenta Psionic Crystals
        for idx, base_angle in enumerate([0.0, 1.57, 3.14, 4.71]):
            ca = base_angle + f * 1.57
            cx = 95 + math.cos(ca) * 65.0
            cy = 75 + bob + math.sin(ca) * 35.0
            d.polygon([(cx, cy - 8), (cx + 5, cy), (cx, cy + 8), (cx - 5, cy)], fill=c_psionic_magenta)
            d.polygon([(cx, cy - 4), (cx + 2, cy), (cx, cy + 4), (cx - 2, cy)], fill=c_psionic_core)
            # Psionic beam tether to brain
            d.line([(95, 75 + bob), (cx, cy)], fill=(220, 50, 255, 90), width=1)

        # 2. Undulating Heavy Bio-Tentacle Legs (Back leg)
        t_wave = math.sin(f * 1.8) * 8.0
        d.polygon([(110, 120 + bob), (140 + t_wave, 150 + bob), (135 + t_wave, 195), (115 + t_wave, 195), (125 + t_wave, 150 + bob), (95, 125 + bob)], fill=c_bio_purple)
        d.polygon([(120 + t_wave, 190), (145 + t_wave, 195), (110 + t_wave, 205)], fill=c_bone_white)

        # 3. Massive Exposed Pulsating Alien Cerebrum (Brain Core)
        b_pulse = math.sin(f * 2.0) * 4.0
        d.ellipse([60 - b_pulse, 30 + bob, 130 + b_pulse, 88 + bob], fill=c_brain_shadow)
        d.ellipse([64 - b_pulse, 34 + bob, 126 + b_pulse, 84 + bob], fill=c_brain_pink)
        # Brain convolutions / gyri fissures
        for gy in [45, 58, 70]:
            d.arc([70, gy + bob - 5, 115, gy + bob + 8], 0.2, 3.0, fill=c_brain_shadow, width=3)
            d.arc([72, gy + bob - 4, 113, gy + bob + 7], 0.2, 3.0, fill=c_bio_crimson, width=2)
        # Bloodshot psionic veins
        d.line([(85, 38 + bob), (98, 62 + bob), (115, 68 + bob)], fill=c_psionic_magenta, width=2)

        # 4. Heavy Bio-Mechanical Armored Carapace Body
        d.polygon([(45, 75 + bob), (145, 75 + bob), (135, 135 + bob), (48, 135 + bob)], fill=c_bio_purple)
        d.polygon([(52, 80 + bob), (138, 80 + bob), (128, 128 + bob), (58, 128 + bob)], fill=c_bio_crimson)
        # Ribbed bone cage protecting the lower organs
        for ry in [90, 105, 120]:
            d.polygon([(55, ry + bob), (135, ry + bob), (130, ry + 6 + bob), (50, ry + 6 + bob)], fill=c_bone_white)

        # 5. Front Walking Tentacle Leg
        f_wave = -t_wave
        d.polygon([(50, 115 + bob), (30 + f_wave, 145 + bob), (20 + f_wave, 195), (40 + f_wave, 195), (45 + f_wave, 150 + bob), (75, 120 + bob)], fill=c_bio_crimson)
        d.polygon([(15 + f_wave, 190), (45 + f_wave, 195), (25 + f_wave, 205)], fill=c_bone_white)

        # 6. Grotesque Primary Eye & Psionic Focusing Mouth
        d.ellipse([25, 82 + bob, 48, 105 + bob], fill=c_bio_purple)
        d.ellipse([28, 85 + bob, 45, 102 + bob], fill=(240, 240, 245, 255)) # Sclera
        d.ellipse([32, 89 + bob, 42, 99 + bob], fill=c_psionic_magenta) # Psionic Iris
        d.circle((37, 94 + bob), 3, fill=c_psionic_core)
        # Venomous needle barb tip projecting from front
        d.polygon([(25, 105 + bob), (38, 108 + bob), (5, 120 + bob)], fill=c_bone_white)

    def draw_death(d, w, h, f):
        s = 1.0 - f * 0.2
        cx, cy = 95, 110
        r = int(58 * (1.0 + f * 0.4))
        # Massive psionic supernova shockwave
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(220, 30, 255, int(220 * s)))
        d.ellipse([cx - int(r*0.7), cy - int(r*0.7), cx + int(r*0.7), cy + int(r*0.7)], fill=(255, 140, 255, int(240 * s)))
        d.ellipse([cx - int(r*0.35), cy - int(r*0.35), cx + int(r*0.35), cy + int(r*0.35)], fill=(255, 255, 255, int(255 * s)))
        # Splattering brain & psychic crystal shards
        for a in [0.2, 1.3, 2.4, 3.5, 4.6, 5.7]:
            dist = 30 + f * 34
            px = cx + math.cos(a) * dist
            py = cy + math.sin(a) * dist
            d.polygon([(px, py - 6), (px + 4, py), (px, py + 6), (px - 4, py)], fill=c_psionic_magenta)
            d.circle((px, py), 4, fill=c_flesh_pink)

    save_miniboss_suite('mini_boss_stage8', draw_frame, draw_death, w, h)

if __name__ == '__main__':
    print("Building high-detail mini-boss suites for Stages 3, 4, 5, 6, 7, 8...")
    make_stage3_miniboss()
    make_stage4_miniboss()
    make_stage5_miniboss()
    make_stage6_miniboss()
    make_stage7_miniboss()
    make_stage8_miniboss()
    print("All mini-boss suites generated successfully!")
