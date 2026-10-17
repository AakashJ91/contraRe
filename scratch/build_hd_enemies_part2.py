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
# STAGE 5: SLAG MECH & CONVEYOR DROID
# =============================================================================
def make_slag_mech():
    w, h = 112, 116
    c_iron_black = (24, 26, 30, 255)
    c_iron_dark = (48, 52, 60, 255)
    c_hazard_yellow = (235, 185, 30, 255)
    c_molten_orange = (255, 110, 20, 255)
    c_molten_glow = (255, 235, 80, 255)

    def draw_frame(d, w, h, f):
        stomp = [-3, 3, -1, 1][f]
        
        # Heavy Hydraulic Piston Legs
        # Back leg
        d.rectangle([28, 64, 44, 98 + stomp], fill=c_iron_black)
        d.rectangle([32, 66, 40, 92 + stomp], fill=(90, 100, 115, 255)) # Piston shaft
        d.polygon([(24, 98 + stomp), (48, 98 + stomp), (52, 108 + stomp), (20, 108 + stomp)], fill=c_iron_black)
        d.rectangle([24, 100 + stomp, 46, 104 + stomp], fill=c_hazard_yellow)

        # Front leg
        d.rectangle([60, 66, 76, 100 - stomp], fill=c_iron_black)
        d.rectangle([64, 68, 72, 94 - stomp], fill=(90, 100, 115, 255))
        d.polygon([(54, 100 - stomp), (82, 100 - stomp), (86, 110 - stomp), (50, 110 - stomp)], fill=c_iron_black)
        d.rectangle([56, 102 - stomp, 80, 106 - stomp], fill=c_hazard_yellow)

        # Main Heavy Cockpit Chassis
        d.polygon([(30, 28 + stomp), (82, 28 + stomp), (88, 68 + stomp), (26, 68 + stomp)], fill=c_iron_black)
        d.polygon([(34, 32 + stomp), (78, 32 + stomp), (84, 64 + stomp), (30, 64 + stomp)], fill=c_iron_dark)
        # Yellow and black hazard stripes on armor plate
        d.line([(36, 56 + stomp), (48, 56 + stomp)], fill=c_hazard_yellow, width=4)
        d.line([(54, 56 + stomp), (66, 56 + stomp)], fill=c_hazard_yellow, width=4)
        d.line([(72, 56 + stomp), (82, 56 + stomp)], fill=c_hazard_yellow, width=4)

        # Reinforced Cockpit Grate with Molten Furnace Glow
        d.rectangle([46, 36 + stomp, 70, 52 + stomp], fill=c_iron_black)
        d.rectangle([48, 38 + stomp, 68, 50 + stomp], fill=c_molten_orange)
        d.ellipse([52, 40 + stomp, 64, 48 + stomp], fill=c_molten_glow)
        # Iron cage bars
        for bx in [52, 58, 64]:
            d.line([(bx, 36 + stomp), (bx, 52 + stomp)], fill=c_iron_black, width=2)

        # Twin Slag Pouring Ladle Arms (Forward Arm)
        d.line([(74, 46 + stomp), (92, 52 + stomp)], fill=c_iron_black, width=6)
        # Scoop crucible
        d.ellipse([88, 48 + stomp, 106, 68 + stomp], fill=c_iron_black)
        d.ellipse([90, 50 + stomp, 104, 64 + stomp], fill=c_molten_orange)
        d.ellipse([94, 54 + stomp, 100, 60 + stomp], fill=c_molten_glow)
        # Molten slag dripping
        d.ellipse([96, 68 + stomp + f*2, 100, 74 + stomp + f*2], fill=c_molten_orange)

    def draw_death(d, w, h, f):
        s = 1.0 - f * 0.22
        cx, cy = 56, 58
        r = int(40 * (1.0 + f * 0.35))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 90, 20, int(220 * s)))
        d.ellipse([cx - int(r*0.6), cy - int(r*0.6), cx + int(r*0.6), cy + int(r*0.6)], fill=(255, 230, 80, int(255 * s)))
        # Flying molten steel shards
        for ang in [0.5, 1.8, 3.1, 4.4, 5.7]:
            px = cx + math.cos(ang) * (f * 16 + 14)
            py = cy + math.sin(ang) * (f * 16 + 14)
            d.ellipse([px - 4, py - 4, px + 4, py + 4], fill=(255, 180, 40, int(240 * s)))

    save_enemy_suite('slag_mech', draw_frame, draw_death, w, h)

def make_conveyor_droid():
    w, h = 96, 96
    c_sphere_black = (24, 26, 30, 255)
    c_sphere_dark = (50, 55, 62, 255)
    c_sphere_mid = (85, 92, 105, 255)
    c_bronze = (180, 130, 45, 255)
    c_eye_red = (255, 30, 20, 255)

    def draw_frame(d, w, h, f):
        rot = f * (math.pi / 2.0)
        
        # Heavy Magnetic Rolling Sphere
        d.ellipse([20, 20, 76, 76], fill=c_sphere_black)
        d.ellipse([22, 22, 74, 74], fill=c_sphere_dark)
        d.ellipse([26, 26, 70, 70], fill=c_sphere_mid)
        # Specular sheen highlight on sphere
        d.ellipse([32, 28, 48, 44], fill=(140, 155, 175, 180))

        # Bronze Industrial Riveted Seam Bands (rotating)
        cos_r = math.cos(rot)
        d.line([(48 - cos_r * 24, 24), (48 + cos_r * 24, 72)], fill=c_bronze, width=3)
        # Rivets along the band
        for t in [-16, 0, 16]:
            rx = 48 + cos_r * t
            ry = 48 + t
            d.ellipse([rx - 2, ry - 2, rx + 2, ry + 2], fill=(240, 200, 100, 255))

        # Central Cyclops Laser Eye Aperture
        d.ellipse([40, 40, 56, 56], fill=c_sphere_black)
        d.ellipse([42, 42, 54, 54], fill=(120, 20, 15, 255))
        d.ellipse([44, 44, 52, 52], fill=c_eye_red)
        d.point((47, 47), fill=(255, 255, 255, 255))

        # Magnetic Floor Track Contact Sparks
        if f % 2 == 1:
            d.line([(44, 76), (36, 82)], fill=(255, 230, 100, 240), width=2)
            d.line([(52, 76), (60, 82)], fill=(255, 230, 100, 240), width=2)

    def draw_death(d, w, h, f):
        s = 1.0 - f * 0.22
        cx, cy = 48, 48
        r = int(30 * (1.0 + f * 0.3))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 80, 20, int(220 * s)))
        d.ellipse([cx - int(r*0.6), cy - int(r*0.6), cx + int(r*0.6), cy + int(r*0.6)], fill=(255, 220, 80, int(255 * s)))
        # Hemispheres splitting apart
        shift = f * 10
        d.arc([20 - shift, 20, 76 - shift, 76], math.pi * 0.5, math.pi * 1.5, fill=(40, 45, 50, int(255 * s)), width=6)
        d.arc([20 + shift, 20, 76 + shift, 76], -math.pi * 0.5, math.pi * 0.5, fill=(40, 45, 50, int(255 * s)), width=6)

    save_enemy_suite('conveyor_droid', draw_frame, draw_death, w, h)

# =============================================================================
# STAGE 6: TESLA TROOPER & SPARK DRONE
# =============================================================================
def make_tesla_trooper():
    w, h = 100, 106
    c_suit_dark = (32, 40, 52, 255)
    c_suit_mid = (58, 72, 92, 255)
    c_copper = (215, 120, 45, 255)
    c_plasma_cyan = (40, 240, 255, 255)
    c_plasma_white = (220, 255, 255, 255)

    def draw_frame(d, w, h, f):
        bob = [-2, 2, 0, -1][f]
        
        # Twin Shoulder Tesla Coils on Backpack
        # Back coil
        d.rectangle([24, 22 + bob, 32, 54 + bob], fill=(25, 30, 38, 255))
        for cy in range(26, 50, 6):
            d.line([(22, cy + bob), (34, cy + bob)], fill=c_copper, width=3)
        d.ellipse([24, 16 + bob, 32, 24 + bob], fill=c_copper)
        # Front coil
        d.rectangle([32, 24 + bob, 40, 56 + bob], fill=(25, 30, 38, 255))
        for cy in range(28, 52, 6):
            d.line([(30, cy + bob), (42, cy + bob)], fill=c_copper, width=3)
        d.ellipse([32, 18 + bob, 40, 26 + bob], fill=c_copper)

        # Electric Spark Jumping Between Coils
        spark_y = [20, 22, 18, 24][f]
        d.line([(28, spark_y + bob), (36, spark_y - 2 + bob)], fill=c_plasma_cyan, width=2)

        # Dielectric Insulated Legs
        d.rectangle([34, 64, 48, 92 + bob], fill=c_suit_dark)
        d.rectangle([36, 66, 46, 88 + bob], fill=c_suit_mid)
        d.polygon([(30, 92 + bob), (50, 92 + bob), (54, 100 + bob), (28, 100 + bob)], fill=(18, 22, 28, 255))
        d.rectangle([52, 66, 66, 94 - bob], fill=c_suit_mid)
        d.rectangle([54, 68, 64, 90 - bob], fill=c_plasma_cyan)
        d.polygon([(48, 94 - bob), (68, 94 - bob), (74, 102 - bob), (46, 102 - bob)], fill=(18, 22, 28, 255))

        # Insulated Torso
        d.rectangle([34, 32 + bob, 64, 66 + bob], fill=c_suit_dark)
        d.polygon([(36, 34 + bob), (62, 34 + bob), (60, 64 + bob), (36, 64 + bob)], fill=c_suit_mid)
        d.line([(42, 40 + bob), (56, 40 + bob)], fill=c_plasma_cyan, width=3) # High voltage node

        # Dielectric Helmet
        d.rectangle([38, 14 + bob, 60, 34 + bob], fill=c_suit_dark)
        d.ellipse([40, 12 + bob, 58, 30 + bob], fill=c_suit_mid)
        d.rectangle([44, 18 + bob, 58, 24 + bob], fill=c_plasma_cyan) # Visor

        # Front Arm & Translucent Energy Shield
        d.rectangle([44, 40 + bob, 54, 52 + bob], fill=c_suit_mid)
        # Front Deflector Shield Arc
        d.arc([54, 30 + bob, 90, 72 + bob], -math.pi * 0.45, math.pi * 0.45, fill=(40, 220, 255, 180), width=5)
        d.arc([54, 30 + bob, 90, 72 + bob], -math.pi * 0.45, math.pi * 0.45, fill=c_plasma_white, width=2)

    def draw_death(d, w, h, f):
        s = 1.0 - f * 0.22
        cx, cy = 50, 52
        r = int(32 * (1.0 + f * 0.3))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(30, 180, 255, int(220 * s)))
        d.ellipse([cx - int(r*0.6), cy - int(r*0.6), cx + int(r*0.6), cy + int(r*0.6)], fill=(220, 250, 255, int(255 * s)))
        # Lightning discharge cross
        d.line([(cx - r - 8, cy), (cx + r + 8, cy)], fill=c_plasma_white, width=3)
        d.line([(cx, cy - r - 8), (cx, cy + r + 8)], fill=c_plasma_white, width=3)

    save_enemy_suite('tesla_trooper', draw_frame, draw_death, w, h)

def make_spark_drone():
    w, h = 96, 96
    c_chrome_dark = (35, 42, 54, 255)
    c_chrome_mid = (75, 88, 110, 255)
    c_copper = (215, 125, 45, 255)
    c_core_blue = (40, 180, 255, 255)
    c_core_white = (240, 255, 255, 255)

    def draw_frame(d, w, h, f):
        wobble = [0, -2, 0, 2][f]
        rot = f * (math.pi / 2.0)
        
        # Outer Electromagnetic Ring Rotor
        d.ellipse([16, 16 + wobble, 80, 80 + wobble], fill=c_chrome_dark)
        d.ellipse([20, 20 + wobble, 76, 76 + wobble], fill=c_chrome_mid)
        d.ellipse([28, 28 + wobble, 68, 68 + wobble], fill=(15, 18, 25, 0)) # Hollow center

        # Rotating Stator Copper Teeth
        for i in range(4):
            ang = rot + i * (math.pi / 2.0)
            tx = 48 + math.cos(ang) * 26
            ty = 48 + wobble + math.sin(ang) * 26
            d.ellipse([tx - 4, ty - 4, tx + 4, ty + 4], fill=c_copper)

        # Central Floating Plasma Energy Core
        core_r = [10, 13, 16, 12][f]
        d.ellipse([48 - core_r, 48 + wobble - core_r, 48 + core_r, 48 + wobble + core_r], fill=(30, 120, 255, 160))
        d.ellipse([48 - int(core_r*0.7), 48 + wobble - int(core_r*0.7), 48 + int(core_r*0.7), 48 + wobble + int(core_r*0.7)], fill=c_core_blue)
        d.ellipse([48 - int(core_r*0.35), 48 + wobble - int(core_r*0.35), 48 + int(core_r*0.35), 48 + wobble + int(core_r*0.35)], fill=c_core_white)

        # 4 Electric Tether Arcs to Outer Ring
        if f % 2 == 1:
            d.line([(48, 48 + wobble), (24, 48 + wobble)], fill=c_core_white, width=2)
            d.line([(48, 48 + wobble), (72, 48 + wobble)], fill=c_core_white, width=2)

    def draw_death(d, w, h, f):
        s = 1.0 - f * 0.22
        cx, cy = 48, 48
        r = int(32 * (1.0 + f * 0.35))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(30, 140, 255, int(220 * s)))
        d.ellipse([cx - int(r*0.6), cy - int(r*0.6), cx + int(r*0.6), cy + int(r*0.6)], fill=(200, 245, 255, int(255 * s)))
        # Expanding EMP shockwave ring
        d.arc([cx - r - 6, cy - r - 6, cx + r + 6, cy + r + 6], 0, math.tau, fill=(100, 220, 255, int(200 * s)), width=4)

    save_enemy_suite('spark_drone', draw_frame, draw_death, w, h)

# =============================================================================
# STAGE 7: JETPACK MARINE & RAIL TURRET
# =============================================================================
def make_jetpack_marine():
    w, h = 96, 104
    c_armor_dark = (25, 32, 44, 255)
    c_armor_mid = (45, 62, 85, 255)
    c_armor_high = (75, 105, 140, 255)
    c_visor_gold = (255, 195, 40, 255)
    c_flame_orange = (255, 110, 20, 255)

    def draw_frame(d, w, h, f):
        bob = [-2, 2, 0, -1][f]
        
        # Dual Rocket Thrusters on Back
        d.rectangle([20, 28 + bob, 32, 58 + bob], fill=c_armor_dark)
        d.rectangle([22, 30 + bob, 30, 56 + bob], fill=c_armor_high)
        # Thruster exhaust flame
        fl = [12, 18, 14, 22][f]
        d.polygon([(22, 58 + bob), (30, 58 + bob), (26, 58 + fl + bob)], fill=c_flame_orange)
        d.polygon([(24, 58 + bob), (28, 58 + bob), (26, 58 + int(fl*0.6) + bob)], fill=(255, 250, 120, 255))

        # Legs in flight pose (bent knees)
        d.line([(38, 64 + bob), (44, 78 + bob), (52, 94 + bob)], fill=c_armor_dark, width=6)
        d.line([(38, 64 + bob), (44, 78 + bob), (52, 94 + bob)], fill=c_armor_mid, width=3)
        d.line([(48, 64 + bob), (56, 76 + bob), (66, 92 + bob)], fill=c_armor_mid, width=6)
        d.line([(48, 64 + bob), (56, 76 + bob), (66, 92 + bob)], fill=c_armor_high, width=3)

        # Titanium Flight Armor Torso
        d.rectangle([34, 32 + bob, 64, 66 + bob], fill=c_armor_dark)
        d.polygon([(36, 34 + bob), (62, 34 + bob), (60, 64 + bob), (36, 64 + bob)], fill=c_armor_mid)
        # Micro-missile pod on shoulder
        d.rectangle([32, 26 + bob, 44, 34 + bob], fill=c_armor_dark)
        d.ellipse([34, 28 + bob, 38, 32 + bob], fill=(220, 40, 30, 255))
        d.ellipse([38, 28 + bob, 42, 32 + bob], fill=(220, 40, 30, 255))

        # Flight Helmet with Gold Visor
        d.rectangle([40, 14 + bob, 62, 32 + bob], fill=c_armor_dark)
        d.ellipse([42, 12 + bob, 60, 30 + bob], fill=c_armor_mid)
        d.rectangle([46, 18 + bob, 62, 24 + bob], fill=c_visor_gold)
        d.line([(48, 20 + bob), (60, 20 + bob)], fill=(255, 255, 240, 255), width=1)

        # High-Caliber Tactical Carbine
        gy = 46 + bob
        d.rectangle([48, gy, 86, gy + 8], fill=(20, 24, 30, 255))
        d.rectangle([50, gy + 1, 84, gy + 6], fill=(45, 55, 68, 255))
        d.line([(52, gy + 2), (80, gy + 2)], fill=c_armor_high, width=1)
        d.polygon([(42, gy), (50, gy), (48, gy + 8), (40, gy + 8)], fill=(30, 35, 42, 255)) # Stock
        # Arm
        d.rectangle([42, 40 + bob, 54, 48 + bob], fill=c_armor_mid)

    def draw_death(d, w, h, f):
        s = 1.0 - f * 0.22
        cx, cy = 50, 50
        r = int(36 * (1.0 + f * 0.35))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 100, 20, int(220 * s)))
        d.ellipse([cx - int(r*0.6), cy - int(r*0.6), cx + int(r*0.6), cy + int(r*0.6)], fill=(255, 220, 60, int(255 * s)))
        for ang in [0.7, 2.1, 3.5, 4.9]:
            px = cx + math.cos(ang) * (f * 15 + 14)
            py = cy + math.sin(ang) * (f * 15 + 14)
            d.rectangle([px - 4, py - 3, px + 4, py + 3], fill=(35, 45, 60, int(255 * s)))

    save_enemy_suite('jetpack_marine', draw_frame, draw_death, w, h)

def make_rail_turret():
    w, h = 96, 96
    c_rail_steel = (45, 50, 58, 255)
    c_turret_dark = (28, 32, 38, 255)
    c_turret_mid = (65, 75, 88, 255)
    c_laser_red = (255, 30, 20, 255)
    c_energy_blue = (40, 200, 255, 255)

    def draw_frame(d, w, h, f):
        shift = f * 3
        
        # Overhead Ceiling I-Beam Trolley Clamps
        d.rectangle([20, 10, 76, 20], fill=c_rail_steel)
        # Roller wheels
        for wx in [28 + shift % 6, 44 + shift % 6, 60 + shift % 6]:
            d.ellipse([wx - 4, 14, wx + 4, 22], fill=(20, 22, 25, 255))
            d.ellipse([wx - 2, 16, wx + 2, 20], fill=(160, 175, 195, 255))

        # Suspended Armored Turret Housing
        d.polygon([(30, 22), (66, 22), (72, 48), (24, 48)], fill=c_turret_dark)
        d.polygon([(34, 26), (62, 26), (68, 44), (28, 44)], fill=c_turret_mid)
        # Coolant energy lines
        d.line([(32, 36), (64, 36)], fill=c_energy_blue, width=3)

        # Twin Particle Accelerator Barrels (Pointing downwards)
        # Barrel 1
        d.rectangle([36, 48, 44, 78], fill=c_turret_dark)
        d.rectangle([38, 48, 42, 74], fill=c_turret_mid)
        d.rectangle([34, 74, 46, 80], fill=(20, 22, 25, 255)) # Muzzle
        # Barrel 2
        d.rectangle([52, 48, 60, 78], fill=c_turret_dark)
        d.rectangle([54, 48, 58, 74], fill=c_turret_mid)
        d.rectangle([50, 74, 62, 80], fill=(20, 22, 25, 255))

        # Red Target Tracking Sight Emitter
        d.ellipse([45, 42, 51, 48], fill=c_laser_red)
        # Downward targeting beam
        d.line([(48, 48), (48, 96)], fill=(255, 30, 20, 120), width=1)

    def draw_death(d, w, h, f):
        s = 1.0 - f * 0.22
        cx, cy = 48, 48
        r = int(32 * (1.0 + f * 0.3))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 120, 30, int(220 * s)))
        d.ellipse([cx - int(r*0.6), cy - int(r*0.6), cx + int(r*0.6), cy + int(r*0.6)], fill=(255, 235, 100, int(255 * s)))
        # Falling sheared barrels
        drop = f * 12
        d.rectangle([36, 48 + drop, 44, 78 + drop], fill=(40, 45, 50, int(255 * s)))

    save_enemy_suite('rail_turret', draw_frame, draw_death, w, h)

# =============================================================================
# STAGE 8: TENTACLE WHIPPER & PSYCHIC ORB
# =============================================================================
def make_tentacle_whipper():
    w, h = 96, 112
    c_flesh_deep = (48, 18, 52, 255)
    c_flesh_mid = (95, 32, 105, 255)
    c_flesh_high = (165, 55, 160, 255)
    c_spur_bone = (235, 215, 225, 255)
    c_poison_tip = (255, 50, 120, 255)

    def draw_frame(d, w, h, f):
        sway = [-4, 4, 10, -2][f]
        
        # Organic Bio-Floor Growth Bulb (Base)
        d.ellipse([24, 84, 72, 106], fill=c_flesh_deep)
        d.ellipse([28, 86, 68, 102], fill=c_flesh_mid)
        # Vein network on bulb
        d.line([(36, 92), (48, 96)], fill=c_flesh_high, width=2)
        d.line([(58, 90), (64, 98)], fill=c_flesh_high, width=2)

        # Muscular Striated Tentacle Trunk (Bending with sway)
        # Lower section
        d.polygon([(40, 88), (56, 88), (58 + int(sway*0.3), 64), (38 + int(sway*0.3), 64)], fill=c_flesh_deep)
        d.polygon([(42, 88), (54, 88), (56 + int(sway*0.3), 64), (40 + int(sway*0.3), 64)], fill=c_flesh_mid)
        # Mid section
        d.polygon([(38 + int(sway*0.3), 64), (58 + int(sway*0.3), 64), (54 + int(sway*0.7), 40), (36 + int(sway*0.7), 40)], fill=c_flesh_deep)
        d.polygon([(40 + int(sway*0.3), 64), (56 + int(sway*0.3), 64), (52 + int(sway*0.7), 40), (38 + int(sway*0.7), 40)], fill=c_flesh_mid)
        # Upper section & scythe tip
        d.polygon([(36 + int(sway*0.7), 40), (54 + int(sway*0.7), 40), (48 + sway, 16), (42 + sway, 16)], fill=c_flesh_high)

        # Bone Spurs along the Spine
        for sy, sx_off in [(72, 36), (56, 34), (42, 32), (28, 38)]:
            sp_x = sx_off + int(sway * 0.5)
            d.polygon([(sp_x, sy), (sp_x - 8, sy - 4), (sp_x, sy - 8)], fill=c_spur_bone)

        # Lashing Poison Barb Tip
        d.polygon([(42 + sway, 16), (48 + sway, 16), (54 + sway * 2, 8), (44 + sway * 2, 8)], fill=c_poison_tip)
        d.polygon([(44 + sway * 2, 8), (54 + sway * 2, 8), (48 + sway * 2, 2)], fill=c_spur_bone)

    def draw_death(d, w, h, f):
        s = 1.0 - f * 0.22
        cx, cy = 48, 60
        r = int(32 * (1.0 + f * 0.35))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(140, 20, 110, int(220 * s)))
        d.ellipse([cx - int(r*0.6), cy - int(r*0.6), cx + int(r*0.6), cy + int(r*0.6)], fill=(240, 60, 180, int(250 * s)))
        # Alien spore cloud particles
        for ang in [0.4, 1.5, 2.6, 3.7, 4.8]:
            px = cx + math.cos(ang) * (f * 14 + 14)
            py = cy + math.sin(ang) * (f * 14 + 14)
            d.ellipse([px - 3, py - 3, px + 3, py + 3], fill=(200, 50, 180, int(230 * s)))

    save_enemy_suite('tentacle_whipper', draw_frame, draw_death, w, h)

def make_psychic_orb():
    w, h = 96, 96
    c_sclera = (220, 215, 230, 255)
    c_iris_purple = (140, 30, 180, 255)
    c_iris_cyan = (30, 220, 255, 255)
    c_pupil_black = (15, 12, 20, 255)
    c_crystal_mag = (245, 60, 220, 255)

    def draw_frame(d, w, h, f):
        wobble = [0, -3, 0, 3][f]
        rot = f * (math.pi / 2.0)
        
        # Telekinetic Distortion Aura
        aura_r = [34, 38, 42, 36][f]
        d.ellipse([48 - aura_r, 48 + wobble - aura_r, 48 + aura_r, 48 + wobble + aura_r], fill=(160, 40, 220, 55))

        # Grotesque Biomechanical Eyeball Sphere
        d.ellipse([22, 22 + wobble, 74, 74 + wobble], fill=(45, 25, 55, 255))
        d.ellipse([24, 24 + wobble, 72, 72 + wobble], fill=c_sclera)
        # Red bloodshot sclera veins
        d.line([(32, 36 + wobble), (42, 42 + wobble)], fill=(200, 40, 60, 180), width=2)
        d.line([(64, 58 + wobble), (54, 52 + wobble)], fill=(200, 40, 60, 180), width=2)

        # Concentric Psionic Iris & Pupil
        d.ellipse([36, 36 + wobble, 60, 60 + wobble], fill=c_iris_purple)
        d.ellipse([40, 40 + wobble, 56, 56 + wobble], fill=c_iris_cyan)
        d.ellipse([44, 44 + wobble, 52, 52 + wobble], fill=c_pupil_black)
        d.point((46, 46 + wobble), fill=(255, 255, 255, 255))

        # 3 Orbiting Psionic Focus Crystals
        for i in range(3):
            ang = rot + i * (math.tau / 3.0)
            cx = 48 + math.cos(ang) * 36
            cy = 48 + wobble + math.sin(ang) * 22
            # Diamond crystal
            d.polygon([(cx, cy - 6), (cx + 5, cy), (cx, cy + 6), (cx - 5, cy)], fill=(90, 20, 110, 255))
            d.polygon([(cx, cy - 4), (cx + 3, cy), (cx, cy + 4), (cx - 3, cy)], fill=c_crystal_mag)
            d.point((cx, cy), fill=(255, 255, 255, 255))

    def draw_death(d, w, h, f):
        s = 1.0 - f * 0.22
        cx, cy = 48, 48
        r = int(32 * (1.0 + f * 0.35))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(160, 40, 220, int(220 * s)))
        d.ellipse([cx - int(r*0.6), cy - int(r*0.6), cx + int(r*0.6), cy + int(r*0.6)], fill=(240, 120, 255, int(255 * s)))
        # Shattered crystal glitter
        for ang in [0.5, 1.8, 3.1, 4.4, 5.7]:
            px = cx + math.cos(ang) * (f * 15 + 12)
            py = cy + math.sin(ang) * (f * 15 + 12)
            d.polygon([(px, py - 3), (px + 3, py), (px, py + 3), (px - 3, py)], fill=(255, 180, 255, int(255 * s)))

    save_enemy_suite('psychic_orb', draw_frame, draw_death, w, h)

# Run Part 2
make_slag_mech()
make_conveyor_droid()
make_tesla_trooper()
make_spark_drone()
make_jetpack_marine()
make_rail_turret()
make_tentacle_whipper()
make_psychic_orb()
print("PART 2 (STAGES 5-8) COMPLETE!")
