import os
from PIL import Image, ImageDraw, ImageFilter, ImageChops

def create_sprite(w, h, draw_fn, pad=16, outline_color=(15, 18, 25, 255)):
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    draw_fn(draw, w, h)
    
    # Pad & outline
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

def ensure_dir(d):
    os.makedirs(d, exist_ok=True)

# -----------------------------------------------------------------------------
# STAGE 1: GUERRILLA GUNNER & FLAME TROOPER
# -----------------------------------------------------------------------------
def make_stage1():
    # 1. Guerrilla Gunner (48x54)
    folder = 'assets/enemies/guerrilla_gunner'
    ensure_dir(folder)
    ensure_dir(f'{folder}/movement')
    ensure_dir(f'{folder}/death')
    
    def draw_guerrilla(d, w, h, frame=0):
        # Woodland camo jacket, bandana, assault rifle
        d.rectangle([18, 24, 30, 46], fill=(55, 75, 45, 255)) # Camo torso
        d.rectangle([20, 26, 28, 44], fill=(70, 95, 55, 255))
        d.ellipse([18, 12, 30, 24], fill=(190, 130, 95, 255)) # Head
        d.rectangle([16, 14, 32, 18], fill=(180, 40, 35, 255)) # Red bandana
        # Foliage ghillie leaves
        d.polygon([(14, 20), (10, 28), (18, 26)], fill=(35, 60, 30, 255))
        d.polygon([(34, 22), (38, 30), (30, 28)], fill=(45, 75, 35, 255))
        # Legs
        leg_offset = 2 if frame % 2 == 1 else -2
        d.rectangle([18, 46, 23, 52 + leg_offset], fill=(40, 50, 35, 255))
        d.rectangle([25, 46, 30, 52 - leg_offset], fill=(40, 50, 35, 255))
        # Rifle
        d.rectangle([28, 28, 46, 33], fill=(30, 35, 40, 255))
        d.rectangle([26, 33, 30, 39], fill=(60, 45, 30, 255)) # Grip
        if frame == 1: # Muzzle flash
            d.ellipse([45, 27, 52, 34], fill=(255, 220, 80, 255))
            d.ellipse([47, 29, 50, 32], fill=(255, 255, 240, 255))

    for i in range(4):
        im = create_sprite(54, 56, lambda d, w, h, f=i: draw_guerrilla(d, w, h, f))
        im.save(f'{folder}/movement/walk_{i}.png')
        if i == 0: im.save(f'{folder}/guerrilla_gunner.png')
    for i in range(4):
        def draw_death(d, w, h, f=i):
            s = 1.0 - (f * 0.22)
            d.ellipse([16, 20 + f*6, 16 + 24*s, 20 + f*6 + 18*s], fill=(80, 50, 40, int(255 * s)))
            d.ellipse([12 + f*4, 16 + f*8, 12 + f*4 + 8, 16 + f*8 + 8], fill=(255, 120, 30, int(220 * s)))
        create_sprite(54, 56, draw_death).save(f'{folder}/death/destroy_{i}.png')

    # 2. Flame Trooper (54x60)
    folder2 = 'assets/enemies/flame_trooper'
    ensure_dir(folder2)
    ensure_dir(f'{folder2}/movement')
    ensure_dir(f'{folder2}/death')
    
    def draw_flame(d, w, h, frame=0):
        # Heavy hazard suit, red fuel tanks on back, flamethrower nozzle
        d.rectangle([12, 20, 20, 44], fill=(210, 50, 30, 255)) # Fuel tank
        d.ellipse([12, 16, 20, 24], fill=(240, 70, 40, 255)) # Tank cap
        d.rectangle([20, 22, 34, 48], fill=(50, 55, 60, 255)) # Suit torso
        d.ellipse([22, 10, 32, 22], fill=(65, 70, 75, 255)) # Heavy helmet
        d.rectangle([23, 14, 31, 18], fill=(255, 180, 40, 255)) # Gold visor
        # Legs
        d.rectangle([20, 48, 25, 58], fill=(35, 40, 45, 255))
        d.rectangle([29, 48, 34, 58], fill=(35, 40, 45, 255))
        # Heavy Flamethrower
        d.rectangle([26, 30, 48, 36], fill=(45, 50, 55, 255))
        d.rectangle([48, 28, 52, 38], fill=(120, 125, 130, 255)) # Nozzle
        # Pilot flame
        flame_len = 10 if frame % 2 == 1 else 6
        d.polygon([(52, 33), (52 + flame_len, 30), (52 + flame_len + 4, 33), (52 + flame_len, 36)], fill=(255, 140, 20, 255))
        d.polygon([(52, 33), (52 + flame_len - 2, 32), (52 + flame_len, 33), (52 + flame_len - 2, 34)], fill=(255, 240, 100, 255))

    for i in range(4):
        im = create_sprite(68, 64, lambda d, w, h, f=i: draw_flame(d, w, h, f))
        im.save(f'{folder2}/movement/walk_{i}.png')
        if i == 0: im.save(f'{folder2}/flame_trooper.png')
    for i in range(4):
        def draw_death(d, w, h, f=i):
            d.ellipse([14, 18, 48, 52], fill=(240, 80, 30, int(255 * (1.0 - f*0.25))))
            d.ellipse([18 + f*3, 22 - f*2, 42 - f*2, 46], fill=(255, 200, 50, int(255 * (1.0 - f*0.25))))
        create_sprite(68, 64, draw_death).save(f'{folder2}/death/destroy_{i}.png')

# -----------------------------------------------------------------------------
# STAGE 2: SCUBA DIVER COMMANDO & TORPEDO HOVER DRONE
# -----------------------------------------------------------------------------
def make_stage2():
    # 3. Scuba Commando (50x54)
    folder = 'assets/enemies/scuba_commando'
    ensure_dir(folder)
    ensure_dir(f'{folder}/movement')
    ensure_dir(f'{folder}/death')
    
    def draw_scuba(d, w, h, frame=0):
        # Wetsuit, dive mask, oxygen tank, pneumatic speargun
        d.rectangle([14, 20, 20, 42], fill=(20, 110, 160, 255)) # O2 tank
        d.rectangle([20, 22, 32, 46], fill=(25, 35, 50, 255)) # Wetsuit torso
        d.ellipse([21, 10, 31, 22], fill=(20, 30, 45, 255)) # Hood
        d.ellipse([24, 13, 30, 19], fill=(60, 210, 255, 255)) # Cyan dive goggles
        # Fins
        d.rectangle([18, 46, 23, 52], fill=(15, 25, 35, 255))
        d.polygon([(17, 52), (12, 56), (24, 56)], fill=(20, 110, 160, 255))
        d.rectangle([27, 46, 32, 52], fill=(15, 25, 35, 255))
        d.polygon([(26, 52), (21, 56), (33, 56)], fill=(20, 110, 160, 255))
        # Speargun
        d.rectangle([28, 28, 46, 32], fill=(50, 65, 80, 255))
        d.polygon([(46, 26), (52, 30), (46, 34)], fill=(180, 210, 230, 255)) # Spear tip

    for i in range(4):
        im = create_sprite(56, 60, lambda d, w, h, f=i: draw_scuba(d, w, h, f))
        im.save(f'{folder}/movement/walk_{i}.png')
        if i == 0: im.save(f'{folder}/scuba_commando.png')
    for i in range(4):
        def draw_death(d, w, h, f=i):
            d.ellipse([14, 18, 42, 46], fill=(20, 90, 150, int(255 * (1.0 - f*0.25))))
            d.ellipse([18, 22, 36, 40], fill=(80, 200, 255, int(220 * (1.0 - f*0.25))))
        create_sprite(56, 60, draw_death).save(f'{folder}/death/destroy_{i}.png')

    # 4. Torpedo Drone (58x44)
    folder2 = 'assets/enemies/torpedo_drone'
    ensure_dir(folder2)
    ensure_dir(f'{folder2}/movement')
    ensure_dir(f'{folder2}/death')
    
    def draw_torpedo_drone(d, w, h, frame=0):
        # Sleek hydrofoil body, twin glowing blue turbines, depth charge pod
        d.ellipse([14, 14, 44, 28], fill=(35, 55, 75, 255)) # Fuselage
        d.rectangle([22, 10, 36, 16], fill=(50, 80, 110, 255)) # Canopy
        d.ellipse([26, 11, 32, 15], fill=(70, 220, 255, 255)) # Sensor eye
        # Side propulsion pods
        d.rectangle([8, 16, 16, 26], fill=(25, 40, 60, 255))
        d.rectangle([42, 16, 50, 26], fill=(25, 40, 60, 255))
        # Turbine glow
        glow_c = (80, 220, 255, 255) if frame % 2 == 0 else (180, 245, 255, 255)
        d.ellipse([9, 18, 15, 24], fill=glow_c)
        d.ellipse([43, 18, 49, 24], fill=glow_c)
        # Depth charge attached underneath
        d.ellipse([24, 26, 34, 38], fill=(20, 30, 40, 255))
        d.ellipse([27, 29, 31, 35], fill=(255, 60, 50, 255))

    for i in range(4):
        im = create_sprite(58, 44, lambda d, w, h, f=i: draw_torpedo_drone(d, w, h, f))
        im.save(f'{folder2}/movement/walk_{i}.png')
        if i == 0: im.save(f'{folder2}/torpedo_drone.png')
    for i in range(4):
        def draw_death(d, w, h, f=i):
            d.ellipse([12, 10, 46, 34], fill=(50, 150, 220, int(255 * (1.0 - f*0.25))))
            d.ellipse([18, 14, 40, 30], fill=(255, 120, 50, int(220 * (1.0 - f*0.25))))
        create_sprite(58, 44, draw_death).save(f'{folder2}/death/destroy_{i}.png')

# -----------------------------------------------------------------------------
# STAGE 3: ACID SPITTER BEAST & CEILING STALKER LEAPER
# -----------------------------------------------------------------------------
def make_stage3():
    # 5. Acid Spitter Beast (56x52)
    folder = 'assets/enemies/acid_spitter'
    ensure_dir(folder)
    ensure_dir(f'{folder}/movement')
    ensure_dir(f'{folder}/death')
    
    def draw_spitter(d, w, h, frame=0):
        # Quadrupedal chitin beast with glowing green acid gullet
        d.ellipse([16, 20, 38, 38], fill=(60, 25, 50, 255)) # Carapace
        d.ellipse([12, 12, 26, 26], fill=(75, 30, 60, 255)) # Head/jaw
        d.polygon([(10, 16), (6, 22), (12, 20)], fill=(200, 240, 100, 255)) # Mandible
        # Swollen glowing acid sac
        g_rad = 10 if frame % 2 == 0 else 12
        d.ellipse([26, 14, 26 + g_rad*2, 14 + g_rad*2], fill=(140, 230, 40, 255))
        d.ellipse([28, 16, 28 + g_rad*1.5, 16 + g_rad*1.5], fill=(210, 255, 80, 255))
        # Legs
        d.line([(20, 34), (14, 46), (10, 48)], fill=(40, 18, 35, 255), width=3)
        d.line([(32, 34), (40, 46), (44, 48)], fill=(40, 18, 35, 255), width=3)

    for i in range(4):
        im = create_sprite(56, 52, lambda d, w, h, f=i: draw_spitter(d, w, h, f))
        im.save(f'{folder}/movement/walk_{i}.png')
        if i == 0: im.save(f'{folder}/acid_spitter.png')
    for i in range(4):
        def draw_death(d, w, h, f=i):
            d.ellipse([12, 14, 44, 44], fill=(120, 220, 40, int(255 * (1.0 - f*0.25))))
            d.ellipse([18, 18, 38, 38], fill=(80, 30, 60, int(220 * (1.0 - f*0.25))))
        create_sprite(56, 52, draw_death).save(f'{folder}/death/destroy_{i}.png')

    # 6. Ceiling Stalker (52x48)
    folder2 = 'assets/enemies/ceiling_stalker'
    ensure_dir(folder2)
    ensure_dir(f'{folder2}/movement')
    ensure_dir(f'{folder2}/death')
    
    def draw_stalker(d, w, h, frame=0):
        # Spidery multi-jointed leaper with mantis scythe claws
        d.ellipse([18, 16, 34, 30], fill=(85, 20, 45, 255)) # Core body
        d.ellipse([22, 18, 26, 22], fill=(255, 60, 100, 255)) # Multiple eyes
        d.ellipse([27, 18, 31, 22], fill=(255, 60, 100, 255))
        # Scythe claws
        claw_y = 38 if frame % 2 == 1 else 34
        d.line([(18, 20), (10, 26), (14, claw_y)], fill=(180, 30, 60, 255), width=3)
        d.line([(34, 20), (42, 26), (38, claw_y)], fill=(180, 30, 60, 255), width=3)
        # Upper ceiling hook legs
        d.line([(22, 16), (18, 8), (22, 6)], fill=(60, 15, 35, 255), width=2)
        d.line([(30, 16), (34, 8), (30, 6)], fill=(60, 15, 35, 255), width=2)

    for i in range(4):
        im = create_sprite(52, 48, lambda d, w, h, f=i: draw_stalker(d, w, h, f))
        im.save(f'{folder2}/movement/walk_{i}.png')
        if i == 0: im.save(f'{folder2}/ceiling_stalker.png')
    for i in range(4):
        def draw_death(d, w, h, f=i):
            d.ellipse([14, 12, 38, 36], fill=(160, 30, 60, int(255 * (1.0 - f*0.25))))
        create_sprite(52, 48, draw_death).save(f'{folder2}/death/destroy_{i}.png')

# -----------------------------------------------------------------------------
# STAGE 4: CRYO TROOPER & SNOW SLED RAIDER
# -----------------------------------------------------------------------------
def make_stage4():
    # 7. Cryo Mortar Trooper (52x58)
    folder = 'assets/enemies/cryo_trooper'
    ensure_dir(folder)
    ensure_dir(f'{folder}/movement')
    ensure_dir(f'{folder}/death')
    
    def draw_cryo(d, w, h, frame=0):
        # White arctic parka, frost cyan visor, shoulder cryo launcher
        d.rectangle([18, 22, 34, 46], fill=(215, 225, 235, 255)) # Parka torso
        d.ellipse([20, 10, 32, 22], fill=(200, 215, 225, 255)) # Parka hood
        d.rectangle([22, 14, 30, 18], fill=(60, 210, 255, 255)) # Visor
        # Legs in heavy snowboots
        d.rectangle([18, 46, 24, 54], fill=(120, 140, 155, 255))
        d.rectangle([28, 46, 34, 54], fill=(120, 140, 155, 255))
        # Shoulder Cryo Mortar Cannon
        d.rectangle([12, 16, 20, 34], fill=(80, 110, 130, 255))
        d.ellipse([13, 14, 19, 20], fill=(100, 230, 255, 255)) # Cryo core chamber
        d.polygon([(12, 16), (8, 12), (16, 12)], fill=(140, 170, 190, 255)) # Muzzle

    for i in range(4):
        im = create_sprite(52, 58, lambda d, w, h, f=i: draw_cryo(d, w, h, f))
        im.save(f'{folder}/movement/walk_{i}.png')
        if i == 0: im.save(f'{folder}/cryo_trooper.png')
    for i in range(4):
        def draw_death(d, w, h, f=i):
            d.ellipse([12, 14, 40, 44], fill=(120, 200, 240, int(255 * (1.0 - f*0.25))))
            d.polygon([(26, 10), (14, 40), (38, 40)], fill=(220, 245, 255, int(200 * (1.0 - f*0.25))))
        create_sprite(52, 58, draw_death).save(f'{folder}/death/destroy_{i}.png')

    # 8. Snow Sled Raider (72x48)
    folder2 = 'assets/enemies/sled_raider'
    ensure_dir(folder2)
    ensure_dir(f'{folder2}/movement')
    ensure_dir(f'{folder2}/death')
    
    def draw_sled(d, w, h, frame=0):
        # Fast snowmobile body with ski runners and forward cannons
        d.polygon([(10, 32), (60, 32), (54, 20), (22, 20)], fill=(50, 75, 95, 255)) # Chassis
        d.polygon([(46, 20), (52, 14), (58, 20)], fill=(70, 190, 230, 255)) # Windshield
        # Rider
        d.ellipse([30, 10, 40, 20], fill=(220, 230, 240, 255)) # Helmet
        d.rectangle([28, 18, 42, 28], fill=(60, 70, 80, 255)) # Rider coat
        # Ski runners underneath
        d.line([(8, 38), (58, 38), (64, 34)], fill=(180, 200, 215, 255), width=3)
        # Forward Twin Machine Guns
        d.rectangle([54, 26, 68, 29], fill=(30, 40, 50, 255))
        d.rectangle([54, 30, 68, 33], fill=(30, 40, 50, 255))

    for i in range(4):
        im = create_sprite(72, 48, lambda d, w, h, f=i: draw_sled(d, w, h, f))
        im.save(f'{folder2}/movement/walk_{i}.png')
        if i == 0: im.save(f'{folder2}/sled_raider.png')
    for i in range(4):
        def draw_death(d, w, h, f=i):
            d.ellipse([14, 12, 58, 36], fill=(70, 150, 200, int(255 * (1.0 - f*0.25))))
            d.ellipse([20, 16, 52, 32], fill=(255, 180, 50, int(220 * (1.0 - f*0.25))))
        create_sprite(72, 48, draw_death).save(f'{folder2}/death/destroy_{i}.png')

# -----------------------------------------------------------------------------
# STAGE 5: MOLTEN SLAG MECH & CONVEYOR SENTRY DROID
# -----------------------------------------------------------------------------
def make_stage5():
    # 9. Molten Slag Mech (68x68)
    folder = 'assets/enemies/slag_mech'
    ensure_dir(folder)
    ensure_dir(f'{folder}/movement')
    ensure_dir(f'{folder}/death')
    
    def draw_slag_mech(d, w, h, frame=0):
        # Heavy industrial walker, glowing orange furnace core, rivet claw
        d.rectangle([18, 16, 50, 44], fill=(45, 40, 42, 255)) # Heavy iron chassis
        d.ellipse([26, 22, 42, 38], fill=(255, 90, 20, 255)) # Furnace vat
        d.ellipse([29, 25, 39, 35], fill=(255, 220, 60, 255)) # Liquid molten core
        # Heavy hydraulic legs
        leg_step = 3 if frame % 2 == 1 else -3
        d.rectangle([18, 44, 28, 58 + leg_step], fill=(35, 30, 32, 255))
        d.rectangle([40, 44, 50, 58 - leg_step], fill=(35, 30, 32, 255))
        # Slag cannon arm
        d.rectangle([50, 24, 62, 34], fill=(60, 55, 58, 255))
        d.polygon([(62, 22), (66, 28), (62, 34)], fill=(255, 140, 30, 255)) # Heat nozzle

    for i in range(4):
        im = create_sprite(68, 68, lambda d, w, h, f=i: draw_slag_mech(d, w, h, f))
        im.save(f'{folder}/movement/walk_{i}.png')
        if i == 0: im.save(f'{folder}/slag_mech.png')
    for i in range(4):
        def draw_death(d, w, h, f=i):
            d.ellipse([14, 14, 54, 54], fill=(255, 100, 20, int(255 * (1.0 - f*0.25))))
            d.ellipse([20, 20, 48, 48], fill=(255, 240, 80, int(220 * (1.0 - f*0.25))))
        create_sprite(68, 68, draw_death).save(f'{folder}/death/destroy_{i}.png')

    # 10. Conveyor Sentry Droid (50x46)
    folder2 = 'assets/enemies/conveyor_droid'
    ensure_dir(folder2)
    ensure_dir(f'{folder2}/movement')
    ensure_dir(f'{folder2}/death')
    
    def draw_conveyor_droid(d, w, h, frame=0):
        # Rolling iron sphere droid with sweeping laser lens
        d.ellipse([12, 10, 38, 36], fill=(50, 45, 48, 255)) # Steel sphere
        d.rectangle([10, 20, 40, 26], fill=(30, 28, 30, 255)) # Armor belt
        # Glowing ruby optical aperture
        d.ellipse([20, 16, 30, 26], fill=(255, 30, 40, 255))
        d.ellipse([23, 19, 27, 23], fill=(255, 200, 200, 255))
        # Magnetic rail runners underneath
        d.rectangle([14, 36, 36, 40], fill=(80, 75, 78, 255))

    for i in range(4):
        im = create_sprite(50, 46, lambda d, w, h, f=i: draw_conveyor_droid(d, w, h, f))
        im.save(f'{folder2}/movement/walk_{i}.png')
        if i == 0: im.save(f'{folder2}/conveyor_droid.png')
    for i in range(4):
        def draw_death(d, w, h, f=i):
            d.ellipse([10, 8, 40, 38], fill=(255, 50, 30, int(255 * (1.0 - f*0.25))))
        create_sprite(50, 46, draw_death).save(f'{folder2}/death/destroy_{i}.png')

# -----------------------------------------------------------------------------
# STAGE 6: TESLA SHOCK TROOPER & PLASMA SPARK DRONE
# -----------------------------------------------------------------------------
def make_stage6():
    # 11. Tesla Shock Trooper (54x58)
    folder = 'assets/enemies/tesla_trooper'
    ensure_dir(folder)
    ensure_dir(f'{folder}/movement')
    ensure_dir(f'{folder}/death')
    
    def draw_tesla(d, w, h, frame=0):
        # Dielectric hazard suit, electric capacitor shield, spark baton
        d.rectangle([18, 22, 32, 44], fill=(30, 45, 65, 255)) # Insulated torso
        d.ellipse([20, 10, 30, 20], fill=(40, 60, 85, 255)) # Helmet
        d.rectangle([22, 13, 28, 17], fill=(80, 220, 255, 255)) # Blue visor
        # Legs
        d.rectangle([18, 44, 23, 54], fill=(20, 30, 45, 255))
        d.rectangle([27, 44, 32, 54], fill=(20, 30, 45, 255))
        # Electric Energy Shield in front
        d.rectangle([34, 16, 40, 48], fill=(25, 35, 50, 255))
        s_glow = (80, 220, 255, 255) if frame % 2 == 0 else (200, 245, 255, 255)
        d.line([(37, 18), (37, 46)], fill=s_glow, width=3)
        # Spark arcs around shield
        d.line([(32, 24), (42, 22), (36, 28)], fill=s_glow, width=2)
        d.line([(34, 36), (44, 38), (38, 42)], fill=s_glow, width=2)

    for i in range(4):
        im = create_sprite(54, 58, lambda d, w, h, f=i: draw_tesla(d, w, h, f))
        im.save(f'{folder}/movement/walk_{i}.png')
        if i == 0: im.save(f'{folder}/tesla_trooper.png')
    for i in range(4):
        def draw_death(d, w, h, f=i):
            d.ellipse([14, 14, 40, 44], fill=(60, 180, 255, int(255 * (1.0 - f*0.25))))
            d.ellipse([18, 18, 36, 40], fill=(240, 255, 255, int(220 * (1.0 - f*0.25))))
        create_sprite(54, 58, draw_death).save(f'{folder}/death/destroy_{i}.png')

    # 12. Plasma Spark Drone (48x48)
    folder2 = 'assets/enemies/spark_drone'
    ensure_dir(folder2)
    ensure_dir(f'{folder2}/movement')
    ensure_dir(f'{folder2}/death')
    
    def draw_spark_drone(d, w, h, frame=0):
        # Floating electromagnetic ring drone, bright plasma core
        d.ellipse([10, 10, 38, 38], fill=(25, 40, 60, 255)) # Outer stator ring
        d.ellipse([14, 14, 34, 34], fill=(15, 25, 40, 255)) # Inner hollow
        # Plasma Core in center
        p_color = (100, 230, 255, 255) if frame % 2 == 0 else (220, 250, 255, 255)
        d.ellipse([18, 18, 30, 30], fill=p_color)
        d.ellipse([21, 21, 27, 27], fill=(255, 255, 255, 255))
        # Electric discharge spikes
        d.line([(24, 6), (24, 12)], fill=p_color, width=2)
        d.line([(24, 36), (24, 42)], fill=p_color, width=2)
        d.line([(6, 24), (12, 24)], fill=p_color, width=2)
        d.line([(36, 24), (42, 24)], fill=p_color, width=2)

    for i in range(4):
        im = create_sprite(48, 48, lambda d, w, h, f=i: draw_spark_drone(d, w, h, f))
        im.save(f'{folder2}/movement/walk_{i}.png')
        if i == 0: im.save(f'{folder2}/spark_drone.png')
    for i in range(4):
        def draw_death(d, w, h, f=i):
            d.ellipse([8, 8, 40, 40], fill=(80, 200, 255, int(255 * (1.0 - f*0.25))))
        create_sprite(48, 48, draw_death).save(f'{folder2}/death/destroy_{i}.png')

# -----------------------------------------------------------------------------
# STAGE 7: JETPACK ELITE MARINE & GANTRY RAIL TURRET
# -----------------------------------------------------------------------------
def make_stage7():
    # 13. Jetpack Elite Marine (52x56)
    folder = 'assets/enemies/jetpack_marine'
    ensure_dir(folder)
    ensure_dir(f'{folder}/movement')
    ensure_dir(f'{folder}/death')
    
    def draw_jetpack(d, w, h, frame=0):
        # Aerospace carbon suit, twin rocket thrusters, dual SMGs
        d.rectangle([10, 20, 18, 36], fill=(40, 50, 65, 255)) # Left thruster
        d.rectangle([34, 20, 42, 36], fill=(40, 50, 65, 255)) # Right thruster
        # Thruster exhaust flame
        f_len = 8 if frame % 2 == 1 else 5
        d.polygon([(11, 36), (15, 36 + f_len), (17, 36)], fill=(255, 140, 30, 255))
        d.polygon([(35, 36), (39, 36 + f_len), (41, 36)], fill=(255, 140, 30, 255))
        # Torso & helmet
        d.rectangle([18, 18, 34, 40], fill=(25, 35, 48, 255))
        d.ellipse([20, 8, 32, 20], fill=(30, 42, 58, 255))
        d.rectangle([22, 12, 30, 16], fill=(255, 190, 40, 255)) # Gold visor
        # Hanging legs
        d.rectangle([20, 40, 25, 50], fill=(20, 28, 38, 255))
        d.rectangle([27, 40, 32, 50], fill=(20, 28, 38, 255))
        # Dual SMGs forward
        d.rectangle([28, 28, 46, 32], fill=(60, 75, 95, 255))

    for i in range(4):
        im = create_sprite(52, 56, lambda d, w, h, f=i: draw_jetpack(d, w, h, f))
        im.save(f'{folder}/movement/walk_{i}.png')
        if i == 0: im.save(f'{folder}/jetpack_marine.png')
    for i in range(4):
        def draw_death(d, w, h, f=i):
            d.ellipse([10, 10, 42, 46], fill=(255, 120, 40, int(255 * (1.0 - f*0.25))))
            d.ellipse([16, 16, 36, 40], fill=(255, 220, 80, int(220 * (1.0 - f*0.25))))
        create_sprite(52, 56, draw_death).save(f'{folder}/death/destroy_{i}.png')

    # 14. Gantry Rail Turret (54x48)
    folder2 = 'assets/enemies/rail_turret'
    ensure_dir(folder2)
    ensure_dir(f'{folder2}/movement')
    ensure_dir(f'{folder2}/death')
    
    def draw_rail_turret(d, w, h, frame=0):
        # Overhead rail clamp, suspended armored turret pod, particle beam barrel
        d.rectangle([12, 4, 42, 12], fill=(50, 60, 75, 255)) # Rail trolley
        d.rectangle([24, 12, 30, 20], fill=(35, 45, 58, 255)) # Suspension swivel
        # Pod ball
        d.ellipse([16, 18, 38, 38], fill=(30, 40, 52, 255))
        d.ellipse([21, 23, 33, 33], fill=(255, 40, 50, 255)) # Red laser lens
        d.ellipse([24, 26, 30, 30], fill=(255, 220, 220, 255))
        # Downward angled twin laser barrels
        d.rectangle([23, 36, 26, 44], fill=(65, 80, 100, 255))
        d.rectangle([28, 36, 31, 44], fill=(65, 80, 100, 255))

    for i in range(4):
        im = create_sprite(54, 48, lambda d, w, h, f=i: draw_rail_turret(d, w, h, f))
        im.save(f'{folder2}/movement/walk_{i}.png')
        if i == 0: im.save(f'{folder2}/rail_turret.png')
    for i in range(4):
        def draw_death(d, w, h, f=i):
            d.ellipse([12, 10, 42, 38], fill=(255, 60, 50, int(255 * (1.0 - f*0.25))))
        create_sprite(54, 48, draw_death).save(f'{folder2}/death/destroy_{i}.png')

# -----------------------------------------------------------------------------
# STAGE 8: BIO-TENTACLE WHIPPER & PSYCHIC FLOATER ORB
# -----------------------------------------------------------------------------
def make_stage8():
    # 15. Bio-Tentacle Whipper (48x64)
    folder = 'assets/enemies/tentacle_whipper'
    ensure_dir(folder)
    ensure_dir(f'{folder}/movement')
    ensure_dir(f'{folder}/death')
    
    def draw_tentacle(d, w, h, frame=0):
        # Organic muscular column, barbed suckers, needle-spitting maw
        d.ellipse([14, 44, 34, 60], fill=(70, 15, 35, 255)) # Root bulb
        # Curving whip trunk
        curve = 6 if frame % 2 == 1 else -4
        d.line([(24, 52), (24 + curve, 36), (24 - curve, 20), (24 + curve*1.5, 8)], fill=(150, 30, 70, 255), width=8)
        d.line([(24, 52), (24 + curve, 36), (24 - curve, 20), (24 + curve*1.5, 8)], fill=(210, 60, 110, 255), width=4)
        # Barbed tip maw
        d.ellipse([20 + int(curve*1.5), 4, 28 + int(curve*1.5), 14], fill=(255, 120, 160, 255))
        d.polygon([(18 + int(curve*1.5), 8), (14 + int(curve*1.5), 4), (18 + int(curve*1.5), 12)], fill=(255, 255, 240, 255))

    for i in range(4):
        im = create_sprite(48, 64, lambda d, w, h, f=i: draw_tentacle(d, w, h, f))
        im.save(f'{folder}/movement/walk_{i}.png')
        if i == 0: im.save(f'{folder}/tentacle_whipper.png')
    for i in range(4):
        def draw_death(d, w, h, f=i):
            d.ellipse([10, 20, 38, 48], fill=(160, 25, 60, int(255 * (1.0 - f*0.25))))
            d.ellipse([14, 24, 34, 44], fill=(220, 70, 120, int(220 * (1.0 - f*0.25))))
        create_sprite(48, 64, draw_death).save(f'{folder}/death/destroy_{i}.png')

    # 16. Psychic Floater Orb (54x54)
    folder2 = 'assets/enemies/psychic_orb'
    ensure_dir(folder2)
    ensure_dir(f'{folder2}/movement')
    ensure_dir(f'{folder2}/death')
    
    def draw_psychic_orb(d, w, h, frame=0):
        # Biomechanical ocular sphere with orbiting psychic crystals
        d.ellipse([16, 16, 38, 38], fill=(45, 18, 45, 255)) # Core sphere
        d.ellipse([21, 21, 33, 33], fill=(180, 40, 180, 255)) # Violet iris
        d.ellipse([24, 24, 30, 30], fill=(255, 210, 255, 255)) # Pupil
        # Orbiting psychic crystals
        angle_off = (frame * 45)
        d.polygon([(10, 24), (14, 20), (14, 28)], fill=(220, 80, 240, 255))
        d.polygon([(44, 24), (40, 20), (40, 28)], fill=(220, 80, 240, 255))
        d.polygon([(27, 8), (23, 12), (31, 12)], fill=(220, 80, 240, 255))
        d.polygon([(27, 46), (23, 42), (31, 42)], fill=(220, 80, 240, 255))

    for i in range(4):
        im = create_sprite(54, 54, lambda d, w, h, f=i: draw_psychic_orb(d, w, h, f))
        im.save(f'{folder2}/movement/walk_{i}.png')
        if i == 0: im.save(f'{folder2}/psychic_orb.png')
    for i in range(4):
        def draw_death(d, w, h, f=i):
            d.ellipse([10, 10, 44, 44], fill=(200, 60, 220, int(255 * (1.0 - f*0.25))))
            d.ellipse([16, 16, 38, 38], fill=(255, 180, 255, int(220 * (1.0 - f*0.25))))
        create_sprite(54, 54, draw_death).save(f'{folder2}/death/destroy_{i}.png')

if __name__ == '__main__':
    print('Generating Stage 1 sprites...')
    make_stage1()
    print('Generating Stage 2 sprites...')
    make_stage2()
    print('Generating Stage 3 sprites...')
    make_stage3()
    print('Generating Stage 4 sprites...')
    make_stage4()
    print('Generating Stage 5 sprites...')
    make_stage5()
    print('Generating Stage 6 sprites...')
    make_stage6()
    print('Generating Stage 7 sprites...')
    make_stage7()
    print('Generating Stage 8 sprites...')
    make_stage8()
    print('ALL 16 ENEMY SPRITE SETS GENERATED!')
