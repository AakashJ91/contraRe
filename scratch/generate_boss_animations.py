import os, sys, math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

def draw_pixel_fireball(target_img, cx, cy, radius, seed=0):
    np.random.seed(seed)
    draw = ImageDraw.Draw(target_img, 'RGBA')
    num_lobes = 14
    lobes = []
    for i in range(num_lobes):
        ang = (i / float(num_lobes)) * 2 * np.pi + np.random.uniform(-0.25, 0.25)
        dist = np.random.uniform(0.12, 0.55) * radius
        rad = np.random.uniform(0.38, 0.65) * radius
        lobes.append((cx + np.cos(ang) * dist, cy + np.sin(ang) * dist, rad))
        
    palette = [
        (35, 12, 8, 245),       # Charcoal crust
        (170, 30, 10, 255),     # Deep crimson flame
        (245, 110, 15, 255),    # Vivid burning orange
        (255, 205, 30, 255),    # Fiery golden amber
        (255, 255, 220, 255)    # Incandescent white core
    ]
    radii = [1.22, 1.0, 0.72, 0.44, 0.22]
    for col, factor in zip(palette, radii):
        for lx, ly, lr in lobes:
            r = lr * factor
            draw.ellipse([lx - r, ly - r, lx + r, ly + r], fill=col)
            
    # Pixel sparks / fire embers
    spark_col = palette[3]
    for _ in range(int(radius * 0.25)):
        ang = np.random.uniform(0, 2 * np.pi)
        dist = np.random.uniform(radius * 0.70, radius * 1.55)
        sx = cx + np.cos(ang) * dist
        sy = cy + np.sin(ang) * dist
        sz = np.random.choice([3, 4, 6])
        draw.rectangle([sx, sy, sx + sz, sy + sz], fill=spark_col)

def draw_pixel_smoke(target_img, cx, cy, radius, seed=0):
    np.random.seed(seed)
    draw = ImageDraw.Draw(target_img, 'RGBA')
    num_lobes = 12
    lobes = []
    for i in range(num_lobes):
        ang = (i / float(num_lobes)) * 2 * np.pi + np.random.uniform(-0.35, 0.35)
        dist = np.random.uniform(0.1, 0.6) * radius
        rad = np.random.uniform(0.35, 0.65) * radius
        lobes.append((cx + np.cos(ang) * dist, cy + np.sin(ang) * dist, rad))
    palette = [
        (22, 24, 30, 230),   # Dark charcoal
        (52, 56, 68, 240),   # Deep slate
        (88, 95, 110, 245),  # Mid ash
        (135, 145, 160, 250) # Highlight rim
    ]
    radii = [1.2, 1.0, 0.68, 0.32]
    for col, factor in zip(palette, radii):
        for lx, ly, lr in lobes:
            r = lr * factor
            draw.ellipse([lx - r, ly - r, lx + r, ly + r], fill=col)

def draw_shrapnel(draw, cx, cy, count, radius, seed=0):
    np.random.seed(seed)
    for _ in range(count):
        ang = np.random.uniform(0, 2 * np.pi)
        dist = np.random.uniform(radius * 0.4, radius * 1.40)
        px = cx + np.cos(ang) * dist
        py = cy + np.sin(ang) * dist
        w = np.random.randint(6, 18)
        h = np.random.randint(5, 14)
        draw.rectangle([px, py, px + w, py + h], fill=(35, 40, 48, 255), outline=(170, 180, 195, 255))
        # trailing burning spark
        draw.rectangle([px - 4, py - 4, px - 1, py - 1], fill=(255, 180, 30, 255))

def create_lightning_branch(draw, start, end, segments=7, max_offset=18, core_col=(255,255,255,255), glow_col=(0,230,255,160)):
    points = [start]
    dx = end[0] - start[0]
    dy = end[1] - start[1]
    dist = math.hypot(dx, dy)
    if dist < 1.0:
        return
    nx = -dy / dist
    ny = dx / dist
    
    for i in range(1, segments):
        t = i / float(segments)
        px = start[0] + dx * t
        py = start[1] + dy * t
        envelope = math.sin(t * math.pi)
        offset = np.random.uniform(-max_offset, max_offset) * envelope
        points.append((px + nx * offset, py + ny * offset))
    points.append(end)
    
    # Outer glow
    for i in range(len(points) - 1):
        draw.line([points[i], points[i+1]], fill=glow_col, width=5)
    # Bright inner core
    for i in range(len(points) - 1):
        draw.line([points[i], points[i+1]], fill=core_col, width=2)
        
    # Potential sub-branch
    if segments > 4 and np.random.random() < 0.6:
        b_idx = np.random.randint(1, segments - 2)
        b_start = points[b_idx]
        b_angle = math.atan2(dy, dx) + np.random.uniform(-0.8, 0.8)
        b_len = np.random.uniform(15, 35)
        b_end = (b_start[0] + math.cos(b_angle) * b_len, b_start[1] + math.sin(b_angle) * b_len)
        create_lightning_branch(draw, b_start, b_end, segments=3, max_offset=8, core_col=core_col, glow_col=glow_col)

def generate_core_animations(base_img):
    os.makedirs('assets/enemies/boss_fortress/movement', exist_ok=True)
    cx, cy = 608, 485
    
    # In base_img, the glass chamber is x=510..705, y=385..580
    # To animate the plasma smoothly without destroying the metal frame:
    # We clear ONLY the inner core area (x=530..686, y=410..560) with a smooth radial dark-cyan glass gradient!
    
    for frame in range(4):
        np.random.seed(frame * 1337 + 42)
        img = base_img.copy()
        draw = ImageDraw.Draw(img, 'RGBA')
        
        # Soft-clear the inner plasma center while keeping the outer glass borders & metal casing
        for r in range(85, 0, -5):
            alpha = int(140 * (1.0 - (r / 85.0) ** 2))
            draw.ellipse([cx - r*1.1, cy - r, cx + r*1.1, cy + r], fill=(10, 32, 40, alpha))
            
        if frame == 0:
            # FRAME 0: Baseline humming core (calm, steady electric flow)
            core_r = 22
            # Plasma aura
            draw.ellipse([cx - core_r*1.8, cy - core_r*1.8, cx + core_r*1.8, cy + core_r*1.8], fill=(0, 200, 220, 80))
            draw.ellipse([cx - core_r, cy - core_r, cx + core_r, cy + core_r], fill=(0, 245, 215, 210))
            draw.ellipse([cx - 9, cy - 9, cx + 9, cy + 9], fill=(235, 255, 255, 255))
            
            # 4 calm diagonal lightning tendrils
            targets = [(535, 420), (680, 420), (535, 550), (680, 550)]
            for tx, ty in targets:
                create_lightning_branch(draw, (cx, cy), (tx, ty), segments=5, max_offset=12)
                draw.ellipse([tx - 4, ty - 4, tx + 4, ty + 4], fill=(180, 255, 255, 220))
                
        elif frame == 1:
            # FRAME 1: Energy Surge (expanding plasma + pulse shockwave)
            core_r = 32
            # Cyan shockwave ring
            draw.ellipse([cx - 68, cy - 68, cx + 68, cy + 68], outline=(0, 245, 255, 140), width=3)
            # Plasma core
            draw.ellipse([cx - core_r*1.7, cy - core_r*1.7, cx + core_r*1.7, cy + core_r*1.7], fill=(0, 215, 245, 100))
            draw.ellipse([cx - core_r, cy - core_r, cx + core_r, cy + core_r], fill=(30, 255, 230, 230))
            draw.ellipse([cx - 13, cy - 13, cx + 13, cy + 13], fill=(255, 255, 255, 255))
            
            # 6 energetic arcs striking glass chamber nodes
            targets = [(520, 435), (695, 435), (520, 535), (695, 535), (608, 412), (608, 558)]
            for tx, ty in targets:
                create_lightning_branch(draw, (cx, cy), (tx, ty), segments=6, max_offset=16)
                draw.ellipse([tx - 6, ty - 6, tx + 6, ty + 6], fill=(220, 255, 255, 255))
                
            # Specular light highlight on glass
            draw.line([512, 405, 524, 565], fill=(255, 255, 255, 110), width=3)
            
        elif frame == 2:
            # FRAME 2: Maximum Critical Discharge (Incandescent bloom + heavy branching)
            core_r = 44
            # Blinding white-cyan plasma flare
            draw.ellipse([cx - core_r*2.1, cy - core_r*2.1, cx + core_r*2.1, cy + core_r*2.1], fill=(0, 190, 255, 90))
            draw.ellipse([cx - core_r*1.4, cy - core_r*1.4, cx + core_r*1.4, cy + core_r*1.4], fill=(50, 240, 255, 190))
            draw.ellipse([cx - core_r, cy - core_r, cx + core_r, cy + core_r], fill=(170, 255, 255, 240))
            draw.ellipse([cx - 18, cy - 18, cx + 18, cy + 18], fill=(255, 255, 255, 255))
            
            # 8 dense branching lightning trees
            targets = [
                (522, 415), (694, 415), (512, 485), (704, 485),
                (522, 555), (694, 555), (608, 404), (608, 566)
            ]
            for tx, ty in targets:
                create_lightning_branch(draw, (cx, cy), (tx, ty), segments=7, max_offset=20)
                draw.ellipse([tx - 7, ty - 7, tx + 7, ty + 7], fill=(255, 255, 255, 255))
                
            # Ambient reflections on glass and armor
            draw.line([512, 400, 524, 570], fill=(255, 255, 255, 150), width=4)
            draw.line([528, 410, 538, 560], fill=(255, 255, 255, 70), width=2)
            # Glowing conduit wires
            draw.line([525, 608, 690, 608], fill=(0, 255, 220, 210), width=3)
            
        elif frame == 3:
            # FRAME 3: Electromagnetic Vortex Recharge
            core_r = 20
            # Swirling orbital electric ring
            orbit_r = 42
            draw.arc([cx - orbit_r, cy - orbit_r, cx + orbit_r, cy + orbit_r], start=0, end=360, fill=(0, 230, 255, 190), width=3)
            # Orbiting energy nodes
            for a_deg in [45, 165, 285]:
                rad = math.radians(a_deg)
                ox = cx + math.cos(rad) * orbit_r
                oy = cy + math.sin(rad) * orbit_r
                draw.ellipse([ox - 5, oy - 5, ox + 5, oy + 5], fill=(225, 255, 255, 255))
                create_lightning_branch(draw, (cx, cy), (ox, oy), segments=4, max_offset=10)
                
            # Concentrated core
            draw.ellipse([cx - core_r*1.5, cy - core_r*1.5, cx + core_r*1.5, cy + core_r*1.5], fill=(0, 165, 245, 95))
            draw.ellipse([cx - core_r, cy - core_r, cx + core_r, cy + core_r], fill=(0, 245, 255, 215))
            draw.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=(255, 255, 255, 255))
            # Vertical cathode/anode discharge beam
            create_lightning_branch(draw, (cx, 408), (cx, 562), segments=6, max_offset=12)

        out_path = f'assets/enemies/boss_fortress/movement/core_{frame}.png'
        img.save(out_path)
        print(f'Saved movement frame: {out_path}')

def generate_death_animations(base_img):
    os.makedirs('assets/enemies/boss_fortress/death', exist_ok=True)
    cx, cy = 608, 485
    
    # 4 Death Destruction Frames using authentic arcade pixel fireballs & smoke
    for frame in range(4):
        np.random.seed(frame * 999 + 77)
        img = base_img.copy()
        draw = ImageDraw.Draw(img, 'RGBA')
        
        if frame == 0:
            # FRAME 0: Containment Overload & Glass Shatter
            # Rupture flash at core
            for r in range(95, 10, -12):
                alpha = int(240 * (1.0 - r / 95.0))
                draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(220, 255, 255, alpha))
            draw.ellipse([cx - 24, cy - 24, cx + 24, cy + 24], fill=(255, 255, 255, 255))
            
            # Electric fire branching across the entire fortress facade
            shatter_targets = [
                (240, 110), (840, 110), (370, 310), (800, 310),
                (120, 630), (500, 750), (720, 750), (450, 250), (760, 250)
            ]
            for tx, ty in shatter_targets:
                create_lightning_branch(draw, (cx, cy), (tx, ty), segments=8, max_offset=26,
                                        core_col=(255, 255, 255, 255), glow_col=(255, 185, 0, 200))
                draw.ellipse([tx - 8, ty - 8, tx + 8, ty + 8], fill=(255, 240, 120, 255))
                
            # Spiderweb fracture lines radiating through the glass
            for _ in range(14):
                ang = np.random.uniform(0, 2 * np.pi)
                flen = np.random.uniform(45, 105)
                fx = cx + np.cos(ang) * flen
                fy = cy + np.sin(ang) * flen
                draw.line([(cx, cy), (fx, fy)], fill=(255, 255, 255, 230), width=2)
                draw.line([(fx - 5, fy - 5), (fx + 5, fy + 5)], fill=(255, 255, 255, 180), width=1)
                
        elif frame == 1:
            # FRAME 1: Secondary Explosive Detonations
            # Internal breaches using multi-lobed pixel fireballs
            draw_pixel_fireball(img, cx, cy, radius=85, seed=101)
            draw_pixel_fireball(img, 370, 335, radius=62, seed=102)
            draw_pixel_fireball(img, 830, 95, radius=56, seed=103)
            draw_pixel_fireball(img, 140, 630, radius=50, seed=104)
            draw_pixel_fireball(img, 560, 240, radius=46, seed=105)
            
            draw = ImageDraw.Draw(img, 'RGBA')
            draw_shrapnel(draw, cx, cy, count=30, radius=160, seed=106)
            draw_pixel_smoke(img, 360, 260, radius=42, seed=107)
            draw_pixel_smoke(img, 820, 45, radius=38, seed=108)
            
        elif frame == 2:
            # FRAME 2: Catastrophic Cascading Firestorm
            # Massive central explosion engulfed by multi-tiered arcade fireballs
            draw_pixel_fireball(img, cx, cy - 25, radius=165, seed=201)
            draw_pixel_fireball(img, 330, 220, radius=105, seed=202)
            draw_pixel_fireball(img, 850, 130, radius=98, seed=203)
            draw_pixel_fireball(img, 160, 610, radius=88, seed=204)
            draw_pixel_fireball(img, 780, 520, radius=82, seed=205)
            
            draw = ImageDraw.Draw(img, 'RGBA')
            draw_shrapnel(draw, cx, cy, count=55, radius=240, seed=206)
            draw_pixel_smoke(img, cx, cy - 130, radius=95, seed=207)
            draw_pixel_smoke(img, 450, 110, radius=75, seed=208)
            draw_pixel_smoke(img, 750, 80, radius=70, seed=209)
            
        elif frame == 3:
            # FRAME 3: Charred, Demolished Ruin
            arr = np.array(img)
            # Scorched / charred darkening on the whole fortress
            gray_hull = arr[:, :, :3].astype(float) * 0.45
            arr[:, :, :3] = gray_hull.astype(np.uint8)
            img = Image.fromarray(arr, 'RGBA')
            draw = ImageDraw.Draw(img, 'RGBA')
            
            # Blown-out crater cavity at the core
            crater_pts = [
                (485, 375), (610, 360), (730, 380),
                (745, 480), (725, 595), (605, 610),
                (480, 590), (470, 480)
            ]
            draw.polygon(crater_pts, fill=(10, 8, 12, 255))
            draw.polygon(crater_pts, outline=(40, 30, 35, 255), width=4)
            
            # Glowing cherry-red and molten slag pools in the crater bottom
            for _ in range(16):
                sx = np.random.uniform(505, 705)
                sy = np.random.uniform(485, 585)
                sr = np.random.uniform(7, 22)
                draw.ellipse([sx - sr, sy - sr*0.6, sx + sr, sy + sr*0.6], fill=(225, 65, 10, 230))
                draw.ellipse([sx - sr*0.5, sy - sr*0.3, sx + sr*0.5, sy + sr*0.3], fill=(255, 195, 45, 255))
                
            # Severed smoking cannon stumps
            draw.ellipse([250 - 22, 110 - 15, 250 + 22, 110 + 15], fill=(15, 12, 16, 255))
            draw.line([245, 110, 232, 138], fill=(200, 120, 30, 255), width=3)
            draw.ellipse([830 - 22, 90 - 15, 830 + 22, 90 + 15], fill=(15, 12, 16, 255))
            draw.line([835, 90, 848, 122], fill=(200, 120, 30, 255), width=3)
            draw.ellipse([120 - 26, 630 - 16, 120 + 26, 630 + 16], fill=(15, 12, 16, 255))
            
            # 3 massive rising columns of thick billowing pixel smoke
            draw_pixel_smoke(img, cx, 360, radius=90, seed=301)
            draw_pixel_smoke(img, cx - 25, 240, radius=110, seed=302)
            draw_pixel_smoke(img, cx + 15, 120, radius=125, seed=303)
            draw_pixel_smoke(img, 250, 50, radius=65, seed=304)
            draw_pixel_smoke(img, 830, 30, radius=65, seed=305)
            
            # Floating fire embers rising through smoke
            draw = ImageDraw.Draw(img, 'RGBA')
            for _ in range(30):
                ex = np.random.uniform(cx - 120, cx + 120)
                ey = np.random.uniform(80, 480)
                es = np.random.choice([3, 4, 6])
                draw.rectangle([ex, ey, ex + es, ey + es], fill=(255, 130, 20, 240))
                
        out_path = f'assets/enemies/boss_fortress/death/destroy_{frame}.png'
        img.save(out_path)
        print(f'Saved death frame: {out_path}')

if __name__ == '__main__':
    base = Image.open('assets/enemies/boss_fortress/boss_fortress.png')
    generate_core_animations(base)
    generate_death_animations(base)
    print('All boss fortress animation frames successfully generated!')
