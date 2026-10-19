import os
from PIL import Image, ImageOps, ImageFilter
import numpy as np

def build_tundra_assets():
    mid_src_path = r"C:\Users\aakas\.gemini\antigravity-ide\brain\c9a7cee5-f785-4615-8d4c-c35c3c314791\ground_tundra_v2_1792253555509.jpg"
    edge_src_path = r"C:\Users\aakas\.gemini\antigravity-ide\brain\c9a7cee5-f785-4615-8d4c-c35c3c314791\ground_tundra_edge_left_1792253776819.jpg"
    
    out_mid_path = r"d:\GitHub\contraRe\assets\tiles\ground_tundra.png"
    out_edge_l_path = r"d:\GitHub\contraRe\assets\tiles\ground_tundra_edge_left.png"
    out_edge_r_path = r"d:\GitHub\contraRe\assets\tiles\ground_tundra_edge_right.png"
    
    print("Loading source images...")
    im_mid = Image.open(mid_src_path).convert("RGB")
    im_edge = Image.open(edge_src_path).convert("RGB")
    
    w_m, h_m = im_mid.size
    
    # 1. Process ground_tundra.png
    print("Processing ground_tundra.png...")
    # Crop from y=135 to get pure pristine snow top
    crop_top = 135
    cropped_mid = im_mid.crop((0, crop_top, w_m, h_m))
    
    # Make seamlessly tileable horizontally via overlap blending
    arr_m = np.array(cropped_mid).astype(float)
    h_c, w_c, _ = arr_m.shape
    overlap = 120
    
    for x in range(overlap):
        t = (1.0 - np.cos(np.pi * x / float(overlap))) * 0.5
        arr_m[:, x] = arr_m[:, x] * t + arr_m[:, w_c - overlap + x] * (1.0 - t)
        
    arr_seamless = arr_m[:, :w_c - overlap]
    im_seamless = Image.fromarray(np.clip(arr_seamless, 0, 255).astype(np.uint8))
    
    target_w = 1024
    target_h = 580
    im_mid_final = im_seamless.resize((target_w, target_h), Image.Resampling.LANCZOS).convert("RGBA")
    
    im_mid_final.save(out_mid_path)
    print(f"Saved {out_mid_path} (size: {im_mid_final.size})")

    # 2. Process ground_tundra_edge_left.png
    print("Processing ground_tundra_edge_left.png...")
    w_e, h_e = im_edge.size
    
    # Crop from y=135 to match snow level
    cropped_edge = im_edge.crop((0, crop_top, w_e, h_e))
    arr_e = np.array(cropped_edge)
    h_ec, w_ec, _ = arr_e.shape
    
    # Segment cliff face vs white background outside
    # White background is r > 248, g > 248, b > 248
    alpha_edge = np.zeros((h_ec, w_ec), dtype=np.uint8)
    for y in range(h_ec):
        cliff_x = 0
        for x in range(w_ec):
            r, g, b = arr_e[y, x]
            is_white = (r > 248 and g > 248 and b > 248)
            if not is_white:
                cliff_x = x
                break
        
        for x in range(w_ec):
            if x < cliff_x - 1:
                alpha_edge[y, x] = 0
            elif x <= cliff_x + 1:
                alpha_edge[y, x] = 140
            else:
                alpha_edge[y, x] = 255

    # Gaussian blur the alpha mask slightly for crisp anti-aliased edge
    alpha_img = Image.fromarray(alpha_edge).filter(ImageFilter.GaussianBlur(radius=0.5))
    
    rgba_e = np.zeros((h_ec, w_ec, 4), dtype=np.uint8)
    rgba_e[:, :, :3] = arr_e
    rgba_e[:, :, 3] = np.array(alpha_img)
    
    im_edge_rgba = Image.fromarray(rgba_e)
    target_edge_w = 470
    target_edge_h = 580
    im_edge_resized = im_edge_rgba.resize((target_edge_w, target_edge_h), Image.Resampling.LANCZOS)
    
    # Ensure right connection edge is fully opaque
    arr_ef = np.array(im_edge_resized)
    arr_ef[:, -30:, 3] = 255
    im_edge_final = Image.fromarray(arr_ef)
    im_edge_final.save(out_edge_l_path)
    print(f"Saved {out_edge_l_path} (size: {im_edge_final.size})")

    # 3. Process ground_tundra_edge_right.png
    print("Processing ground_tundra_edge_right.png...")
    im_edge_r = ImageOps.mirror(im_edge_final)
    im_edge_r.save(out_edge_r_path)
    print(f"Saved {out_edge_r_path} (size: {im_edge_r.size})")

if __name__ == "__main__":
    build_tundra_assets()
