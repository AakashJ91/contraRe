import numpy as np
from PIL import Image, ImageDraw

def create_barrel_spin_frames():
    base_im = Image.open("assets/enemies/boss_fortress/boss_fortress.png").convert("RGBA")
    
    # -------------------------------------------------------------------------
    # 1. MIDDLE-LEFT GUN
    # Box in full image: (0, 480, 135, 565)
    # Rotor center in image: x_tip ~ 0, y_center ~ 534
    # Radius ~ 16 px, 6 barrels
    # -------------------------------------------------------------------------
    mid_barrel_crop = base_im.crop((0, 480, 135, 565))
    w_m, h_m = mid_barrel_crop.size
    y_center_m = 534 - 480 # ~ 54
    
    frames_mid = []
    for step in range(4):
        theta = step * (np.pi / 3.0 / 4.0) # 0, 15, 30, 45 deg
        f = mid_barrel_crop.copy()
        draw = ImageDraw.Draw(f)
        
        # We modify the barrel segments (x=24 to 56 and x=66 to 110)
        # and the front muzzle holes (x=0 to 24)
        # Compute barrel positions for 6 barrels
        R = 15.0
        r_b = 4.2
        
        # Draw barrels back-to-front
        barrels = []
        for k in range(6):
            phi = theta + k * (2.0 * np.pi / 6.0)
            yb = y_center_m + R * np.sin(phi)
            zb = R * np.cos(phi)
            barrels.append((zb, yb, phi))
        barrels.sort(key=lambda b: b[0]) # draw deepest first
        
        # For x segments: [24..56] and [66..110]
        # We clear the interior barrel pipe areas and draw the shaded cylinders
        for x_start, x_end in [(26, 56), (68, 110)]:
            # Clear interior
            for b in barrels:
                zb, yb, phi = b
                # brightness / specularity based on depth and angle
                # zb in [-R, R] -> normalized depth [0..1]
                depth_norm = (zb + R) / (2.0 * R)
                
                # Colors based on steel palette
                # highlight, mid, shadow
                c_high = (int(160 + 60 * depth_norm), int(175 + 65 * depth_norm), int(190 + 65 * depth_norm), 255)
                c_mid  = (int(70 + 40 * depth_norm), int(80 + 45 * depth_norm), int(95 + 50 * depth_norm), 255)
                c_dark = (int(25 + 20 * depth_norm), int(30 + 25 * depth_norm), int(38 + 30 * depth_norm), 255)
                c_line = (14, 18, 22, 255)
                
                y_top = int(round(yb - r_b))
                y_bot = int(round(yb + r_b))
                
                # Dark boundary outline
                draw.line([(x_start, y_top), (x_end, y_top)], fill=c_line, width=1)
                draw.line([(x_start, y_bot), (x_end, y_bot)], fill=c_line, width=1)
                
                # Shaded body
                y_hi = int(round(yb - r_b * 0.4))
                y_mid = int(round(yb + r_b * 0.2))
                if y_hi > y_top:
                    draw.rectangle([x_start, y_top + 1, x_end, y_hi], fill=c_high)
                if y_mid > y_hi:
                    draw.rectangle([x_start, y_hi + 1, x_end, y_mid], fill=c_mid)
                if y_bot - 1 >= y_mid:
                    draw.rectangle([x_start, y_mid + 1, x_end, y_bot - 1], fill=c_dark)
        
        # Front muzzle tips (x=0 to 24)
        for b in barrels:
            zb, yb, phi = b
            if zb > -5: # only draw visible front muzzles
                y_top = int(round(yb - r_b))
                y_bot = int(round(yb + r_b))
                # muzzle outer ring
                draw.rectangle([6, y_top, 22, y_bot], fill=(45, 52, 60, 255), outline=(15, 18, 22, 255))
                draw.line([(6, y_top + 1), (22, y_top + 1)], fill=(130, 145, 160, 255))
                # muzzle orifice (dark hole)
                draw.rectangle([0, y_top + 1, 5, y_bot - 1], fill=(10, 12, 14, 255), outline=(5, 6, 8, 255))
        
        frames_mid.append(f)
    
    # Save animated gif to inspect
    frames_mid[0].save("scratch/mid_gun_spin.gif", save_all=True, append_images=frames_mid[1:], duration=100, loop=0)
    print("Saved scratch/mid_gun_spin.gif")

if __name__ == "__main__":
    create_barrel_spin_frames()
