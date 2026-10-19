import os
from PIL import Image
import numpy as np

player_dir = "assets/player"

# -------------------------------------------------------------------------
# STEP 0: EXTRACT ORIGINAL ANGLED-DOWN TORSO FIRST!
# -------------------------------------------------------------------------
print("Reading original angled-down torso from player_run_0.png...")
r0_orig = Image.open(f"{player_dir}/player_run_0.png").convert("RGBA")
# Intact angled-down upper body is at (35, 8, 215, 118)
r0_upper = r0_orig.crop((35, 8, 215, 118))

# Flash from run_fire_0 rotated at -26 degrees
rf0 = Image.open(f"{player_dir}/player_run_fire_0.png").convert("RGBA")
flash_crop = rf0.crop((200, 30, 240, 75))
rotated_flash = flash_crop.rotate(-26, resample=Image.Resampling.BICUBIC, expand=True)

# -------------------------------------------------------------------------
# 1. GENERATE DIAGONAL-DOWN (LOWER RIGHT) RUN FRAMES:
#    player_run_down_0..3.png & player_run_fire_down_0..3.png
# -------------------------------------------------------------------------
print("Generating diagonal-down run frames (player_run_down_0..3 & fire)...")
for i in range(4):
    rf = Image.open(f"{player_dir}/player_run_fire_{i}.png").convert("RGBA")
    rf_arr = np.array(rf)
    
    # Take legs from rf (y >= 118)
    down_arr = np.zeros_like(rf_arr)
    down_arr[118:, :, :] = rf_arr[118:, :, :]
    
    # Clean stray artifact dots from legs
    down_arr[130:170, 165:185, :] = 0
    
    down_im = Image.fromarray(down_arr)
    down_im.paste(r0_upper, (35, 8), r0_upper)
    down_im.save(f"{player_dir}/player_run_down_{i}.png")
    print(f"  Saved {player_dir}/player_run_down_{i}.png")
    
    # Fire version
    down_fire = down_im.copy()
    down_fire.paste(rotated_flash, (187, 88), rotated_flash)
    down_fire.save(f"{player_dir}/player_run_fire_down_{i}.png")
    print(f"  Saved {player_dir}/player_run_fire_down_{i}.png")

# -------------------------------------------------------------------------
# 2. GENERATE CLEAN HORIZONTAL RUN FRAMES: player_run_0..3.png
# -------------------------------------------------------------------------
print("Generating clean horizontal run frames (player_run_0..3.png)...")
for i in range(4):
    rf = Image.open(f"{player_dir}/player_run_fire_{i}.png").convert("RGBA")
    arr = np.array(rf)
    
    # Erase flame at x >= 202
    arr[:, 202:, :] = 0
    # Clean up sparks above/below barrel
    arr[40:53, 195:202, :] = 0
    arr[60:75, 195:202, :] = 0
    # Clean metallic barrel tip at x=201
    arr[53:60, 201, :] = [22, 22, 26, 255]
    
    # Clean any stray single pixels
    stray_mask = (arr[:, :, 3] > 0) & (arr[:, :, 3] < 200)
    arr[stray_mask, 3] = 0
    
    out = Image.fromarray(arr)
    out.save(f"{player_dir}/player_run_{i}.png")
    print(f"  Saved {player_dir}/player_run_{i}.png")

# -------------------------------------------------------------------------
# 3. GENERATE DIAGONAL-UP RUN FRAMES (WITHOUT FLASH): player_run_up_0..3.png
# -------------------------------------------------------------------------
print("Generating clean diagonal-up run frames (player_run_up_0..3.png)...")
for i in range(4):
    rfu = Image.open(f"{player_dir}/player_run_fire_up_{i}.png").convert("RGBA")
    arr = np.array(rfu)
    
    # Clean flash particles around barrel tip (x >= 200, y <= 35)
    flash_mask = (arr[:, :, 0] > 190) & (arr[:, :, 1] > 110) & (arr[:, :, 2] < 90)
    arr[flash_mask] = 0
    
    out = Image.fromarray(arr)
    out.save(f"{player_dir}/player_run_up_{i}.png")
    print(f"  Saved {player_dir}/player_run_up_{i}.png")

# -------------------------------------------------------------------------
# 4. GENERATE STANDING LOWER-RIGHT (DIAGONAL DOWN):
#    player_aim_diag_down.png & player_fire_diag_down.png
# -------------------------------------------------------------------------
print("Generating standing diagonal-down sprites...")
aim = Image.open(f"{player_dir}/player_aim.png").convert("RGBA")

# Crop gun from aim
gun = aim.crop((50, 38, 192, 85))
rot_gun = gun.rotate(-28, resample=Image.Resampling.BICUBIC, center=(35, 27), expand=True)

# Erase original gun from aim
aim_arr = np.array(aim)
aim_arr[34:68, 70:192, :] = 0
base = Image.fromarray(aim_arr)

# Paste rotated gun
rot_x = 50 - (rot_gun.width - gun.width) // 2
rot_y = 38 - (rot_gun.height - gun.height) // 2
base.paste(rot_gun, (rot_x, rot_y), rot_gun)

# Clean any artifacts and paste face/head on top
head_crop = aim.crop((45, 12, 95, 48))
base.paste(head_crop, (45, 12), head_crop)

base.save(f"{player_dir}/player_aim_diag_down.png")
print(f"  Saved {player_dir}/player_aim_diag_down.png")

# Fire version
base_fire = base.copy()
# In rotated aim, barrel tip is at (180, 95)
base_fire.paste(rotated_flash, (168, 81), rotated_flash)
base_fire.save(f"{player_dir}/player_fire_diag_down.png")
print(f"  Saved {player_dir}/player_fire_diag_down.png")

print("\n--- ALL PLAYER SPRITES GENERATED SUCCESSFULLY ---")
