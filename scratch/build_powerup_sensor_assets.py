import os
import math
from PIL import Image, ImageDraw

os.makedirs('assets/powerups/sensor', exist_ok=True)

# Generate a 6-frame 40x48 pixel art animation of the Contra Defense Sensor Pod
# Color palette:
# - Dark Gunmetal / Titanium Armor: (28, 32, 42), (45, 52, 68), (70, 82, 105), (105, 120, 150)
# - Metal Highlights & Bevels: (160, 180, 210), (220, 235, 255)
# - Caution / Warning stripes & Rivets: (240, 180, 40), (180, 120, 20)
# - Radiant Optic Plasma Core:
#   Halo: (255, 60, 30, alpha)
#   Mid: (255, 140, 40)
#   Hot Core: (255, 240, 180), (255, 255, 255)

W, H = 40, 48

frames = []

for frame_idx in range(6):
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    t = frame_idx / 6.0
    # Pulse cycle for energy: peaks around frame 2 and 3
    pulse = math.sin(t * math.pi)
    
    # Base Mount / Mounting Brackets attached to wall/ground (bottom Y: 36..47)
    # Beveled heavy pedestal base
    draw.polygon([(6, 46), (33, 46), (31, 38), (8, 38)], fill=(32, 36, 48, 255), outline=(18, 22, 30, 255))
    draw.line([(8, 38), (31, 38)], fill=(90, 105, 130, 255), width=1) # top rim highlight
    draw.line([(7, 44), (32, 44)], fill=(50, 58, 75, 255), width=1)
    
    # Rivets on mounting base
    draw.point((10, 42), fill=(160, 180, 210, 255))
    draw.point((11, 42), fill=(30, 35, 45, 255))
    draw.point((29, 42), fill=(160, 180, 210, 255))
    draw.point((30, 42), fill=(30, 35, 45, 255))
    
    # Main Hexagonal Cyber-Armored Pod Housing (Y: 6..38, X: 6..33)
    hull_pts = [
        (13, 6), (26, 6),
        (33, 14), (33, 32),
        (26, 38), (13, 38),
        (6, 32), (6, 14)
    ]
    draw.polygon(hull_pts, fill=(40, 48, 62, 255), outline=(18, 22, 30, 255))
    
    # Hull panel shading / metallic bevels
    draw.polygon([(14, 7), (25, 7), (31, 14), (31, 31), (25, 37), (14, 37), (8, 31), (8, 14)], fill=(52, 62, 80, 255))
    
    # Upper specular metallic highlight
    draw.line([(14, 8), (25, 8)], fill=(150, 175, 210, 255), width=1)
    draw.line([(9, 14), (14, 8)], fill=(120, 145, 180, 255), width=1)
    draw.line([(30, 14), (25, 8)], fill=(140, 165, 200, 255), width=1)
    
    # Side ventilation cooling grilles
    for vy in [16, 20, 24, 28]:
        draw.line([(9, vy), (11, vy)], fill=(20, 24, 32, 255), width=1)
        draw.line([(28, vy), (30, vy)], fill=(20, 24, 32, 255), width=1)
    
    # Hazard warning markers on top corners
    draw.point((13, 9), fill=(240, 190, 40, 255))
    draw.point((26, 9), fill=(240, 190, 40, 255))
    
    # Central Optic Scanner Chamber (Circular / Elliptical housing, center (19.5, 21.5))
    cx, cy = 19.5, 21.5
    outer_r = 9.0
    draw.ellipse([cx - outer_r, cy - outer_r, cx + outer_r, cy + outer_r], fill=(22, 26, 34, 255), outline=(14, 18, 24, 255))
    draw.arc([cx - outer_r, cy - outer_r, cx + outer_r, cy + outer_r], 0, 360, fill=(80, 95, 120, 255), width=1)
    
    # Protective Mechanical Iris / Aperture Shutters
    # Opening distance varies by frame
    # Frame 0: closed (slit = 1px)
    # Frame 1: opening (slit = 3px)
    # Frame 2: wide open (slit = 6px)
    # Frame 3: maximum flare (slit = 7px)
    # Frame 4: closing (slit = 4px)
    # Frame 5: nearly closed (slit = 2px)
    aperture_openings = [1.5, 3.5, 6.5, 7.5, 4.5, 2.5]
    ap_w = aperture_openings[frame_idx]
    
    # Plasma Glow behind aperture
    glow_alpha = int(90 + 150 * pulse)
    glow_r = outer_r - 1.5
    
    # Draw soft radial energy glow
    for gr in range(int(glow_r), 0, -1):
        ratio = gr / glow_r
        col_r = 255
        col_g = int(40 + 180 * (1.0 - ratio))
        col_b = int(20 + 120 * (1.0 - ratio) * (1.0 - ratio))
        draw.ellipse([cx - gr, cy - gr, cx + gr, gr + cy], fill=(col_r, col_g, col_b, int(glow_alpha * (1.0 - ratio * 0.7))))
    
    # Radiant Optic Eye Core
    core_w = ap_w
    core_h = 3.5 + 2.5 * pulse
    draw.ellipse([cx - core_w, cy - core_h, cx + core_w, cy + core_h], fill=(255, 120, 30, 255))
    draw.ellipse([cx - core_w * 0.6, cy - core_h * 0.55, cx + core_w * 0.6, cy + core_h * 0.55], fill=(255, 240, 160, 255))
    draw.ellipse([cx - core_w * 0.25, cy - core_h * 0.25, cx + core_w * 0.25, cy + core_h * 0.25], fill=(255, 255, 255, 255))
    
    # Horizontal Optical Scan Line / Laser Tracker Sweep
    scan_y = cy + math.sin(t * math.pi * 2.0) * 3.0
    scan_span = 8.0 + 4.0 * pulse
    draw.line([(cx - scan_span, scan_y), (cx + scan_span, scan_y)], fill=(255, 220, 150, int(180 + 75 * pulse)), width=1)
    
    # Iris Blades (top and bottom dark metal plates framing the aperture)
    iris_top_h = outer_r - ap_w * 0.6
    if iris_top_h > 1.0:
        draw.chord([cx - outer_r + 1, cy - outer_r + 1, cx + outer_r - 1, cy + outer_r - 1], 190, 350, fill=(35, 42, 54, 255))
        draw.chord([cx - outer_r + 1, cy - outer_r + 1, cx + outer_r - 1, cy + outer_r - 1], 10, 170, fill=(35, 42, 54, 255))
        draw.line([(cx - outer_r + 2, cy - ap_w * 0.5), (cx + outer_r - 2, cy - ap_w * 0.5)], fill=(75, 88, 110, 255), width=1)
        draw.line([(cx - outer_r + 2, cy + ap_w * 0.5), (cx + outer_r - 2, cy + ap_w * 0.5)], fill=(75, 88, 110, 255), width=1)
    
    # Status Alert Beacon on top dome (Y: 2..5, X: 18..21)
    beacon_glow = (frame_idx % 2 == 0) or (frame_idx in [2, 3])
    beacon_col = (255, 60, 40, 255) if beacon_glow else (120, 30, 20, 255)
    draw.rectangle([18, 2, 21, 5], fill=beacon_col, outline=(18, 22, 30, 255))
    if beacon_glow:
        draw.point((19, 3), fill=(255, 220, 220, 255))
        # subtle light halo
        draw.point((17, 3), fill=(255, 80, 50, 120))
        draw.point((22, 3), fill=(255, 80, 50, 120))
        draw.point((19, 1), fill=(255, 80, 50, 120))
    
    # Save individual frame
    frame_path = f'assets/powerups/sensor/sensor_frame_{frame_idx}.png'
    img.save(frame_path)
    frames.append(img)
    print(f'Saved {frame_path}')

# Also save master powerup_sensor.png as the high-res frame 2 (peak glow)
frames[2].save('assets/powerups/powerup_sensor.png')
print('Updated assets/powerups/powerup_sensor.png')

# Save animated GIF preview to scratch
frames[0].save('scratch/powerup_sensor_anim.gif', save_all=True, append_images=frames[1:], duration=140, loop=0)
print('Saved scratch/powerup_sensor_anim.gif')
