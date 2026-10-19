import os
from PIL import Image, ImageOps, ImageFilter
import numpy as np

def build():
    mid_src_path = r"C:\Users\aakas\.gemini\antigravity-ide\brain\c9a7cee5-f785-4615-8d4c-c35c3c314791\ground_tundra_v2_1792253555509.jpg"
    jungle_edge_l_path = r"d:\GitHub\contraRe\assets\tiles\ground_edge_left.png"
    
    out_mid_path = r"d:\GitHub\contraRe\assets\tiles\ground_tundra.png"
    out_edge_l_path = r"d:\GitHub\contraRe\assets\tiles\ground_tundra_edge_left.png"
    out_edge_r_path = r"d:\GitHub\contraRe\assets\tiles\ground_tundra_edge_right.png"
    
    # 1. Master mid tile: ground_tundra.png
    print("1. Building master ground_tundra.png...")
    im_raw = Image.open(mid_src_path).convert("RGB")
    w_raw, h_raw = im_raw.size
    
    # Crop from y=135 downwards (pristine snow top, zero checkerboard)
    crop_top = 135
    im_cropped = im_raw.crop((0, crop_top, w_raw, h_raw))
    
    # Seamless horizontal wrap blend across 120 pixels
    arr_c = np.array(im_cropped).astype(float)
    h_c, w_c, _ = arr_c.shape
    overlap = 120
    
    for x in range(overlap):
        t = (1.0 - np.cos(np.pi * x / float(overlap))) * 0.5
        arr_c[:, x] = arr_c[:, x] * t + arr_c[:, w_c - overlap + x] * (1.0 - t)
        
    arr_seamless = arr_c[:, :w_c - overlap]
    im_seamless = Image.fromarray(np.clip(arr_seamless, 0, 255).astype(np.uint8))
    
    target_w = 1024
    target_h = 580
    im_mid = im_seamless.resize((target_w, target_h), Image.Resampling.LANCZOS).convert("RGBA")
    
    # Add subtle snow highlights and clean top edge (first 3 pixels have smooth alpha fade so it anti-aliases against any background)
    arr_mid = np.array(im_mid)
    arr_mid[0, :, 3] = (arr_mid[0, :, 3].astype(float) * 0.3).astype(np.uint8)
    arr_mid[1, :, 3] = (arr_mid[1, :, 3].astype(float) * 0.7).astype(np.uint8)
    
    im_mid_final = Image.fromarray(arr_mid)
    im_mid_final.save(out_mid_path)
    print(f"Saved {out_mid_path} (size: {im_mid_final.size})")

    # 2. Left Edge: ground_tundra_edge_left.png
    print("2. Building ground_tundra_edge_left.png...")
    # Base is taken directly from the left side of im_mid_final!
    edge_w = 470
    edge_h = 580
    
    # im_mid_final is 1024x580. Take the first 470 columns
    arr_edge_l = arr_mid[:, :edge_w].copy()
    
    # Get organic cliff silhouette mask from jungle_edge_l_path
    im_jungle_edge = Image.open(jungle_edge_l_path).convert("RGBA")
    im_j_resized = im_jungle_edge.resize((edge_w, edge_h), Image.Resampling.LANCZOS)
    arr_j = np.array(im_j_resized)
    j_alpha = arr_j[:, :, 3].astype(float) / 255.0 # 0.0 to 1.0
    
    # Apply cliff silhouette to left 180 pixels
    # For x >= 180, alpha is strictly 1.0 (unmodified ground_tundra pixels!)
    # For x < 180, alpha follows the organic cliff silhouette
    for x in range(edge_w):
        if x < 180:
            blend_factor = x / 180.0
            # Blend between cliff silhouette and full opacity
            mask_val = j_alpha[:, x] * (1.0 - blend_factor) + blend_factor
            arr_edge_l[:, x, 3] = (arr_edge_l[:, x, 3].astype(float) * mask_val).clip(0, 255).astype(np.uint8)
        else:
            arr_edge_l[:, x, 3] = arr_mid[:, x, 3]
            
    # Add frosty icicles along the cliff lip (x < 110, y between 10 and 120)
    # Give the cliff overhang a crisp snow-capped rim lighting
    for y in range(edge_h):
        for x in range(min(140, edge_w)):
            a = arr_edge_l[y, x, 3]
            # Near the silhouette boundary
            if 30 < a < 240 and y < 140:
                # Add icy frost highlight
                arr_edge_l[y, x, 0] = min(255, int(arr_edge_l[y, x, 0] * 0.7 + 220 * 0.3))
                arr_edge_l[y, x, 1] = min(255, int(arr_edge_l[y, x, 1] * 0.7 + 245 * 0.3))
                arr_edge_l[y, x, 2] = min(255, int(arr_edge_l[y, x, 2] * 0.7 + 255 * 0.3))

    # CRITICAL: For x >= 200, ensure 100% BIT-FOR-BIT EXACT MATCH with arr_mid!
    # Because _draw_unskewed_edge_tile samples around x = 274, this guarantees ZERO seam!
    arr_edge_l[:, 200:, :] = arr_mid[:, 200:edge_w, :]

    im_edge_l = Image.fromarray(arr_edge_l)
    im_edge_l.save(out_edge_l_path)
    print(f"Saved {out_edge_l_path} (size: {im_edge_l.size})")

    # 3. Right Edge: ground_tundra_edge_right.png
    print("3. Building ground_tundra_edge_right.png...")
    # For the right edge, Godot samples from x = 470 - 274.3 = 195.7 to 470.0.
    # At x = 195.7, it meets the mid ground tile!
    # At x = 470.0, it is the right cliff drop-off into the chasm!
    # So we take the rightmost 470 columns of arr_mid as the base!
    arr_edge_r = arr_mid[:, target_w - edge_w:].copy()
    
    # Horizontally mirror the cliff silhouette mask so it drops off on the right
    j_alpha_r = np.fliplr(j_alpha)
    
    # Apply cliff silhouette to right 180 pixels (x >= edge_w - 180)
    for x in range(edge_w):
        if x >= edge_w - 180:
            dist_from_right = (edge_w - 1 - x) / 180.0
            mask_val = j_alpha_r[:, x] * (1.0 - dist_from_right) + dist_from_right
            arr_edge_r[:, x, 3] = (arr_edge_r[:, x, 3].astype(float) * mask_val).clip(0, 255).astype(np.uint8)
        else:
            arr_edge_r[:, x, 3] = arr_mid[:, target_w - edge_w + x, 3]

    # Frost rim along right cliff lip
    for y in range(edge_h):
        for x in range(max(0, edge_w - 140), edge_w):
            a = arr_edge_r[y, x, 3]
            if 30 < a < 240 and y < 140:
                arr_edge_r[y, x, 0] = min(255, int(arr_edge_r[y, x, 0] * 0.7 + 220 * 0.3))
                arr_edge_r[y, x, 1] = min(255, int(arr_edge_r[y, x, 1] * 0.7 + 245 * 0.3))
                arr_edge_r[y, x, 2] = min(255, int(arr_edge_r[y, x, 2] * 0.7 + 255 * 0.3))

    # CRITICAL: For x <= edge_w - 200 (x <= 270), ensure 100% BIT-FOR-BIT EXACT MATCH with arr_mid!
    # Since Godot samples starting at x = 195.7, this guarantees ZERO seam at the junction!
    arr_edge_r[:, :edge_w - 200, :] = arr_mid[:, target_w - edge_w : target_w - 200, :]

    im_edge_r = Image.fromarray(arr_edge_r)
    im_edge_r.save(out_edge_r_path)
    print(f"Saved {out_edge_r_path} (size: {im_edge_r.size})")

if __name__ == "__main__":
    build()
