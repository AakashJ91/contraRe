import os
import math
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
import numpy as np

def build_mini_boss_assets():
    base = Image.open('scratch/cut_mini.png').convert('RGBA')
    w, h = base.size
    
    out_dir = 'd:/GitHub/contraRe/assets/enemies/mini_boss_stage2'
    os.makedirs(f'{out_dir}/movement', exist_ok=True)
    os.makedirs(f'{out_dir}/death', exist_ok=True)
    
    # Save base texture
    base.save(f'{out_dir}/mini_boss_stage2.png')
    
    # -------------------------------------------------------------------------
    # WALK CYCLE (4 frames)
    # -------------------------------------------------------------------------
    # Separate upper body and legs to create high-quality articulated walk cycle
    # Hips line is around y = 460
    hip_y = 460
    
    upper = base.crop((0, 0, w, hip_y + 40))
    legs = base.crop((0, hip_y - 20, w, h))
    
    # Left leg (near leg, front) is roughly x: 200 - 550, y: hip_y to h
    # Right leg (far leg, back) is roughly x: 450 - 800, y: hip_y to h
    
    # We can create 4 dynamic stride frames with bobbing, leg shearing, knee flexion and foot planting
    for i in range(4):
        frame = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        
        # Upper body bob & forward lean
        # Frame 0: foot plant (bob down)
        # Frame 1: lift / leap pose (bob up, perfect for in-air!)
        # Frame 2: foot plant (bob down)
        # Frame 3: passing lift (bob up)
        bob_y = [4, -14, 4, -8][i]
        tilt = [1.2, -1.8, 1.0, -1.0][i]
        
        # Rotate & position upper body
        up_frame = upper.rotate(tilt, resample=Image.BICUBIC, center=(380, hip_y))
        
        # Leg transformation
        # We shear and scale the leg regions to simulate forward/backward stride and reverse-joint knee flexion
        l_img = legs.copy()
        l_arr = np.array(l_img)
        
        # Left leg (x < 500) and Right leg (x >= 500)
        # Stride offsets in x:
        # i=0: L leg forward (+18px), R leg back (-18px)
        # i=1: Legs tucked closer (mid air / passing)
        # i=2: L leg back (-18px), R leg forward (+18px)
        # i=3: Passing pose
        
        stride_l = [22, 6, -20, 4][i]
        stride_r = [-20, -4, 22, 8][i]
        flex_l = [0, -12, 0, -6][i]
        flex_r = [0, -6, 0, -12][i]
        
        # Split leg image into left and right halves
        mid_split = 480
        left_half = l_arr[:, :mid_split, :]
        right_half = l_arr[:, mid_split:, :]
        
        l_pil = Image.fromarray(left_half, 'RGBA')
        r_pil = Image.fromarray(right_half, 'RGBA')
        
        # Apply transformation
        # Paste right (back) leg first
        frame.paste(r_pil, (mid_split + stride_r, hip_y - 20 + flex_r + bob_y // 2), r_pil)
        # Paste upper body
        frame.paste(up_frame, (0, bob_y), up_frame)
        # Paste left (front) leg
        frame.paste(l_pil, (stride_l, hip_y - 20 + flex_l + bob_y // 2), l_pil)
        
        # Add jet thruster flame on frame 1 (air / leap frame)
        if i == 1:
            ov = Image.new('RGBA', (w, h), (0, 0, 0, 0))
            d = ImageDraw.Draw(ov)
            # Rear thrusters under hip and back shoulder
            j_x, j_y = 660, hip_y - 30
            d.polygon([(j_x, j_y), (j_x + 35, j_y + 15), (j_x + 8, j_y + 25)], fill=(255, 100, 20, 200))
            d.polygon([(j_x, j_y + 2), (j_x + 20, j_y + 12), (j_x + 5, j_y + 18)], fill=(255, 240, 100, 240))
            frame = Image.alpha_composite(frame, ov)
            
        frame.save(f'{out_dir}/movement/walk_{i}.png')
        print(f'Saved movement/walk_{i}.png')

    # -------------------------------------------------------------------------
    # DEATH SEQUENCE (4 frames)
    # -------------------------------------------------------------------------
    vx, vy = 373, 188 # Visor
    chest_x, chest_y = 440, 340
    pod_x, pod_y = 680, 160
    gun_x, gun_y = 120, 440
    
    for i in range(4):
        frame = base.copy()
        
        # Progressive desaturation and darkening
        enh = ImageEnhance.Color(frame)
        frame = enh.enhance(max(0.1, 1.0 - float(i) * 0.28))
        enh_b = ImageEnhance.Brightness(frame)
        frame = enh_b.enhance(max(0.35, 1.0 - float(i) * 0.20))
        
        ov = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(ov)
        
        if i == 0:
            # Frame 0: Visor blowout, chest spark blast, initial impact
            d.ellipse((vx - 25, vy - 20, vx + 25, vy + 20), fill=(255, 255, 200, 220))
            for k in range(8):
                ang = float(k) * (math.pi / 4.0)
                d.line([(vx, vy), (vx + math.cos(ang) * 55, vy + math.sin(ang) * 55)], fill=(255, 180, 40, 230), width=3)
            d.ellipse((chest_x - 30, chest_y - 30, chest_x + 30, chest_y + 30), fill=(255, 140, 20, 180))
            
        elif i == 1:
            # Frame 1: Shoulder rocket pod explodes, gatling barrel shattered
            d.ellipse((pod_x - 50, pod_y - 45, pod_x + 50, pod_y + 45), fill=(255, 100, 20, 220))
            d.ellipse((pod_x - 30, pod_y - 30, pod_x + 30, pod_y + 30), fill=(255, 240, 80, 240))
            d.ellipse((pod_x - 40, pod_y - 35, pod_x + 40, pod_y + 35), fill=(30, 30, 35, 200)) # black scorch
            # Gun shattered
            d.ellipse((gun_x - 20, gun_y - 30, gun_x + 60, gun_y + 30), fill=(255, 120, 30, 200))
            d.ellipse((gun_x, gun_y - 20, gun_x + 40, gun_y + 20), fill=(25, 25, 30, 240))
            # Smoke trail
            d.ellipse((chest_x - 35, chest_y - 50, chest_x + 35, chest_y + 20), fill=(40, 40, 45, 190))
            
        elif i == 2:
            # Frame 2: Legs buckling, heavily scorched hull, large fire and smoke
            d.ellipse((chest_x - 65, chest_y - 65, chest_x + 65, chest_y + 65), fill=(20, 20, 25, 240)) # core blown out
            d.ellipse((chest_x - 40, chest_y - 40, chest_x + 40, chest_y + 40), fill=(255, 80, 10, 190))
            # Billowing smoke columns
            for sm_x, sm_y in [(chest_x, chest_y - 90), (pod_x, pod_y - 60), (320, 300)]:
                for sm_r in [45, 32, 20]:
                    d.ellipse((sm_x - sm_r, sm_y - sm_r, sm_x + sm_r, sm_y + sm_r), fill=(30, 30, 35, 180))
            # Shrapnel embers
            for _ in range(20):
                rx = chest_x + int(np.random.uniform(-180, 180))
                ry = chest_y + int(np.random.uniform(-140, 140))
                d.ellipse((rx-3, ry-3, rx+3, ry+3), fill=(255, 160, 40, 210))
                
        elif i == 3:
            # Frame 3: Extinguished collapsed smoking scrap
            d.ellipse((chest_x - 70, chest_y - 70, chest_x + 70, chest_y + 70), fill=(15, 15, 18, 255))
            for sm_x, sm_y in [(chest_x, chest_y - 100), (pod_x, pod_y - 70)]:
                d.ellipse((sm_x - 50, sm_y - 50, sm_x + 50, sm_y + 50), fill=(20, 20, 24, 210))
                d.ellipse((sm_x - 30, sm_y - 80, sm_x + 30, sm_y - 20), fill=(30, 30, 35, 160))
            # Few dying embers
            for _ in range(8):
                rx = chest_x + int(np.random.uniform(-120, 120))
                ry = chest_y + int(np.random.uniform(-80, 80))
                d.ellipse((rx-2, ry-2, rx+2, ry+2), fill=(180, 60, 10, 140))
                
        frame = Image.alpha_composite(frame, ov)
        frame.save(f'{out_dir}/death/death_{i}.png')
        print(f'Saved death/death_{i}.png')

if __name__ == '__main__':
    build_mini_boss_assets()
