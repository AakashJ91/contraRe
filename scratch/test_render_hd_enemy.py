import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops

def create_arcade_outline(im, pad=8, outline_color=(15, 18, 25, 255)):
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

# Let's test generating a high-detail Guerrilla Gunner
def test_guerrilla():
    # 96x104 canvas
    w, h = 96, 104
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    
    # Color palette
    c_camo_dark = (38, 52, 26, 255)
    c_camo_mid = (65, 88, 44, 255)
    c_camo_light = (98, 128, 68, 255)
    c_camo_tan = (130, 110, 75, 255)
    c_skin_shadow = (145, 85, 60, 255)
    c_skin_mid = (210, 140, 105, 255)
    c_skin_high = (245, 185, 150, 255)
    c_red_dark = (140, 25, 25, 255)
    c_red_mid = (215, 40, 35, 255)
    c_red_high = (255, 95, 80, 255)
    c_metal_black = (18, 22, 28, 255)
    c_metal_dark = (38, 44, 54, 255)
    c_metal_mid = (70, 80, 96, 255)
    c_metal_high = (140, 155, 180, 255)
    c_boot_dark = (22, 24, 26, 255)
    c_boot_mid = (45, 48, 52, 255)
    
    # 1. Trailing bandana cloth
    d.polygon([(30, 28), (14, 34), (18, 44), (32, 34)], fill=c_red_dark)
    d.polygon([(30, 30), (16, 36), (20, 42), (32, 34)], fill=c_red_mid)
    
    # 2. Back leg & Boot
    d.rectangle([34, 62, 46, 88], fill=c_camo_dark)
    # Camo patches
    d.rectangle([36, 68, 44, 76], fill=c_camo_mid)
    d.rectangle([38, 80, 46, 86], fill=c_camo_tan)
    # Boot
    d.polygon([(32, 88), (48, 88), (52, 98), (30, 98)], fill=c_boot_dark)
    d.rectangle([32, 90, 46, 94], fill=c_boot_mid)
    
    # 3. Front leg & Boot
    d.rectangle([48, 64, 62, 90], fill=c_camo_mid)
    d.rectangle([50, 68, 58, 78], fill=c_camo_light)
    d.rectangle([52, 72, 60, 84], fill=c_camo_dark)
    d.rectangle([50, 82, 56, 88], fill=c_camo_tan)
    # Knee pad
    d.rectangle([48, 72, 58, 80], fill=(28, 30, 32, 255))
    d.rectangle([50, 74, 56, 78], fill=(60, 65, 70, 255))
    # Front boot
    d.polygon([(46, 90), (66, 90), (72, 100), (44, 100)], fill=c_boot_dark)
    d.rectangle([(46, 92), (64, 96)], fill=c_boot_mid)
    d.rectangle([(62, 94), (70, 98)], fill=c_metal_mid) # Steel toe
    
    # 4. Torso & Tactical Vest
    d.rectangle([36, 36, 62, 66], fill=c_camo_dark)
    d.polygon([(38, 36), (60, 36), (58, 64), (36, 64)], fill=c_camo_mid)
    # Camo pattern on vest
    d.polygon([(40, 40), (52, 38), (48, 50), (42, 48)], fill=c_camo_light)
    d.polygon([(46, 52), (58, 50), (56, 62), (48, 60)], fill=c_camo_tan)
    d.polygon([(38, 52), (44, 50), (42, 60), (36, 58)], fill=c_camo_dark)
    # Ammo pouches
    d.rectangle([40, 56, 48, 66], fill=(30, 25, 20, 255))
    d.rectangle([42, 58, 46, 64], fill=(70, 60, 48, 255))
    d.rectangle([50, 56, 58, 66], fill=(30, 25, 20, 255))
    d.rectangle([52, 58, 56, 64], fill=(70, 60, 48, 255))
    
    # 5. Head, Face & Bandana
    d.rectangle([40, 18, 56, 36], fill=c_skin_mid)
    # Jaw shadow
    d.rectangle([40, 30, 54, 36], fill=c_skin_shadow)
    # Face highlight
    d.rectangle([46, 22, 54, 28], fill=c_skin_high)
    # Camo war paint stripes on cheek
    d.line([(44, 28), (52, 30)], fill=c_camo_dark, width=2)
    # Eye & brow
    d.rectangle([48, 22, 54, 24], fill=(20, 15, 12, 255)) # Brow
    d.rectangle([50, 24, 54, 26], fill=(255, 255, 255, 255)) # Eye sclera
    d.point((52, 25), fill=(40, 90, 140, 255)) # Blue iris
    # Bandana around head
    d.rectangle([38, 16, 58, 22], fill=c_red_dark)
    d.rectangle([40, 16, 58, 20], fill=c_red_mid)
    d.line([(42, 17), (56, 17)], fill=c_red_high, width=1)
    # Spiky commando hair
    d.polygon([(38, 16), (36, 10), (44, 14)], fill=(40, 30, 20, 255))
    d.polygon([(42, 14), (46, 8), (50, 14)], fill=(50, 38, 25, 255))
    d.polygon([(48, 14), (54, 10), (58, 16)], fill=(35, 25, 18, 255))
    
    # 6. Arms & Tactical Assault Rifle
    # Back arm holding barrel grip
    d.rectangle([58, 42, 70, 50], fill=c_skin_shadow)
    d.rectangle([68, 40, 76, 48], fill=(35, 38, 42, 255)) # Glove
    
    # Heavy Assault Rifle Body
    d.rectangle([44, 44, 88, 52], fill=c_metal_black)
    d.rectangle([46, 45, 86, 50], fill=c_metal_dark)
    d.line([(48, 46), (84, 46)], fill=c_metal_mid, width=2)
    d.line([(52, 46), (80, 46)], fill=c_metal_high, width=1)
    # Rifle Stock
    d.polygon([(36, 44), (46, 44), (46, 52), (32, 54)], fill=(75, 45, 28, 255))
    d.rectangle([34, 46, 44, 50], fill=(110, 68, 42, 255))
    # Curved Banana Magazine
    d.polygon([(56, 52), (64, 52), (60, 68), (54, 66)], fill=c_metal_black)
    d.polygon([(57, 53), (63, 53), (59, 66), (55, 65)], fill=c_metal_dark)
    # Barrel & Muzzle Flash Suppressor
    d.rectangle([86, 46, 92, 50], fill=c_metal_black)
    d.rectangle([88, 45, 92, 51], fill=c_metal_mid)
    # Red laser sight module
    d.rectangle([64, 40, 76, 44], fill=c_metal_black)
    d.point((76, 42), fill=(255, 30, 20, 255)) # Laser lens
    
    # Front Arm holding trigger grip
    d.rectangle([42, 38, 52, 48], fill=c_skin_mid)
    d.rectangle([44, 40, 50, 46], fill=c_skin_high)
    d.rectangle([48, 46, 56, 54], fill=(35, 38, 42, 255)) # Glove
    
    outline = create_arcade_outline(im, pad=10)
    out_path = 'scratch/test_guerrilla_gunner_hd.png'
    outline.save(out_path)
    print(f'Saved {out_path} size: {outline.size}')

test_guerrilla()
