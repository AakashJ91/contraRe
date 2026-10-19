import os
import numpy as np
from PIL import Image, ImageFilter, ImageChops, ImageDraw

def add_arcade_borders_and_padding(im, pad=20, outline_color=(15, 18, 25, 255), taper_ends=False):
    w, h = im.size
    orig = im.copy()
    
    if taper_ends:
        mask = Image.new('L', (w, h), 255)
        draw = ImageDraw.Draw(mask)
        cap_w = 24
        for x in range(cap_w):
            factor = x / float(cap_w)
            cut_h = int((1.0 - factor) * (h * 0.35))
            if cut_h > 0:
                draw.line([(x, 0), (x, cut_h)], fill=0)
                draw.line([(x, h - cut_h), (x, h - 1)], fill=0)
                
            rx = w - 1 - x
            if cut_h > 0:
                draw.line([(rx, 0), (rx, cut_h)], fill=0)
                draw.line([(rx, h - cut_h), (rx, h - 1)], fill=0)
        
        orig_alpha = orig.split()[3]
        orig_alpha = ImageChops.multiply(orig_alpha, mask)
        orig.putalpha(orig_alpha)

    new_w = w + pad * 2
    new_h = h + pad * 2
    padded = Image.new('RGBA', (new_w, new_h), (0, 0, 0, 0))
    padded.paste(orig, (pad, pad))
    
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

def cutout_black_bg(rgb_img, low_thresh=18, high_thresh=35):
    arr = np.array(rgb_img).astype(float)
    # Brightness per pixel
    brightness = arr.max(axis=-1)
    
    # Smooth alpha ramp
    alpha = np.zeros_like(brightness)
    mask_high = brightness >= high_thresh
    mask_ramp = (brightness >= low_thresh) & (brightness < high_thresh)
    
    alpha[mask_high] = 255.0
    alpha[mask_ramp] = (brightness[mask_ramp] - low_thresh) / float(high_thresh - low_thresh) * 255.0
    
    alpha_img = Image.fromarray(alpha.astype(np.uint8))
    # Smooth edges slightly to remove single-pixel specks
    alpha_img = alpha_img.filter(ImageFilter.MedianFilter(3))
    
    res = rgb_img.convert('RGBA')
    res.putalpha(alpha_img)
    
    # Crop to non-transparent bbox
    bbox = res.getbbox()
    if bbox:
        # Add a tiny 4px margin if possible
        x0 = max(0, bbox[0] - 4)
        y0 = max(0, bbox[1] - 4)
        x1 = min(res.width, bbox[2] + 4)
        y1 = min(res.height, bbox[3] + 4)
        res = res.crop((x0, y0, x1, y1))
        
    return res

def process_all():
    brain_dir = r"C:\Users\aakas\.gemini\antigravity-ide\brain\df5786b2-9934-40af-824b-d23a66b01c79"
    targets = [
        ("waterfall_rock_crag_1792256323172.jpg", "platform_waterfall_crag.png"),
        ("waterfall_platform_test_1792256285314.jpg", "platform_waterfall_ledge.png"),
        ("bio_carapace_platform_1792256339515.jpg", "platform_bio_carapace.png"),
        ("ice_crag_platform_1792256359977.jpg", "platform_ice_crag.png"),
    ]
    
    for src_name, dst_name in targets:
        src_path = os.path.join(brain_dir, src_name)
        dst_path = os.path.join("assets/tiles", dst_name)
        if not os.path.exists(src_path):
            print(f"File not found: {src_path}")
            continue
        
        im = Image.open(src_path).convert('RGB')
        cutout = cutout_black_bg(im)
        final_tile = add_arcade_borders_and_padding(cutout, pad=18, taper_ends=True)
        final_tile.save(dst_path)
        print(f"Created {dst_name} ({final_tile.size}) from {src_name}")

if __name__ == "__main__":
    process_all()
