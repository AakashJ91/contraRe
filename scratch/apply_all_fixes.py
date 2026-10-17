import os
from PIL import Image, ImageDraw, ImageFilter, ImageChops

def add_arcade_borders_and_padding(im, pad=20, outline_color=(15, 18, 25, 255), taper_ends=False, cap_bottom=None, cap_top=None):
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

    if cap_bottom:
        mask = Image.new('L', (w, h), 255)
        draw = ImageDraw.Draw(mask)
        bot_h = cap_bottom
        for y in range(bot_h):
            py = h - 1 - y
            factor = y / float(bot_h)
            corner_cut = int((1.0 - factor) * 40)
            if corner_cut > 0:
                draw.line([(0, py), (corner_cut, py)], fill=0)
                draw.line([(w - 1 - corner_cut, py), (w - 1, py)], fill=0)
        orig_alpha = orig.split()[3]
        orig_alpha = ImageChops.multiply(orig_alpha, mask)
        orig.putalpha(orig_alpha)

    if cap_top:
        mask = Image.new('L', (w, h), 255)
        draw = ImageDraw.Draw(mask)
        top_h = cap_top
        for y in range(top_h):
            factor = y / float(top_h)
            corner_cut = int((1.0 - factor) * 35)
            if corner_cut > 0:
                draw.line([(0, y), (corner_cut, y)], fill=0)
                draw.line([(w - 1 - corner_cut, y), (w - 1, y)], fill=0)
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


def process_platforms():
    print('Processing platforms...')
    platforms = [
        'platform_ice_slab.png',
        'platform_energy_barrier.png',
        'platform_tech_catwalk.png',
        'platform_lava_grate.png',
        'platform_bio_rib.png'
    ]
    for p in platforms:
        path = os.path.join('assets/tiles', p)
        if os.path.exists(path):
            im = Image.open(path).convert('RGBA')
            res = add_arcade_borders_and_padding(im, pad=20, taper_ends=True)
            res.save(path)
            print(f'  Updated {p}: {im.size} -> {res.size}')


def process_boss_folder(folder_path, pad=20, outline_color=(15, 18, 25, 255), cap_bottom=None, cap_top=None):
    print(f'Processing {folder_path}...')
    for root, dirs, files in os.walk(folder_path):
        for f in files:
            if f.endswith('.png'):
                p = os.path.join(root, f)
                im = Image.open(p).convert('RGBA')
                res = add_arcade_borders_and_padding(im, pad=pad, outline_color=outline_color, cap_bottom=cap_bottom, cap_top=cap_top)
                res.save(p)
                print(f'  Updated {f}: {im.size} -> {res.size}')


def process_hydro_goliath():
    print('Processing boss_hydro_goliath...')
    folder = 'assets/enemies/boss_hydro_goliath'
    base_path = os.path.join(folder, 'boss_hydro_goliath.png')
    base_orig = Image.open(base_path).convert('RGBA')
    w, h = base_orig.size
    
    # Generate red version and superheated (hg) version directly on base_orig
    red_orig = base_orig.copy()
    red_pix = red_orig.load()
    hg_orig = base_orig.copy()
    hg_pix = hg_orig.load()
    
    for y in range(h):
        for x in range(w):
            dx = x - 451
            dy = y - 458
            dist = (dx*dx + dy*dy) ** 0.5
            if dist < 65:
                r, g, b, a = base_orig.getpixel((x, y))
                if a > 40 and (b > r or (b > 120 and g > 120)):
                    lum = int(0.299*r + 0.587*g + 0.114*b)
                    falloff = max(0.0, 1.0 - (dist / 60.0))
                    new_r = min(255, int(lum * 1.4 + 40 * falloff))
                    new_g = int(lum * 0.25 * (1.0 - falloff * 0.5))
                    new_b = int(lum * 0.25 * (1.0 - falloff * 0.5))
                    red_pix[x, y] = (new_r, new_g, new_b, a)
                    
                    if dist < 22:
                        hg_pix[x, y] = (255, 255, min(255, int(180 + 75 * (1.0 - dist/22.0))), a)
                    elif dist < 42:
                        f = (dist - 22.0) / 20.0
                        sr = 255
                        sg = int(240 * (1.0 - f * 0.6))
                        sb = int(40 * (1.0 - f))
                        hg_pix[x, y] = (sr, sg, sb, a)
                    else:
                        f = (dist - 42.0) / 23.0
                        sr = int(255 * (1.0 - f * 0.3))
                        sg = int(80 * (1.0 - f))
                        sb = 10
                        hg_pix[x, y] = (sr, sg, sb, a)
                        
    # Now pad and add retro outline to base, red, and hg with identical dimensions
    pad = 20
    base_res = add_arcade_borders_and_padding(base_orig, pad=pad)
    base_res.save(base_path)
    
    red_res = add_arcade_borders_and_padding(red_orig, pad=pad)
    red_res.save(os.path.join(folder, 'boss_hydro_goliath_red.png'))
    
    hg_res = add_arcade_borders_and_padding(hg_orig, pad=pad)
    hg_res.save(os.path.join(folder, 'hg.png'))
    print(f'  Saved base, red, hg at matching size: {base_res.size}')
    
    # Process walk, idle, death frames with same padding
    for sub in ['movement', 'death', 'idle']:
        sub_dir = os.path.join(folder, sub)
        if os.path.exists(sub_dir):
            for f in os.listdir(sub_dir):
                if f.endswith('.png'):
                    p = os.path.join(sub_dir, f)
                    im = Image.open(p).convert('RGBA')
                    res = add_arcade_borders_and_padding(im, pad=pad)
                    res.save(p)
                    print(f'  Updated {sub}/{f}: {im.size} -> {res.size}')


def process_hazards():
    print('Processing hazards...')
    h_dir = 'assets/enemies/hazards'
    if os.path.exists(h_dir):
        for f in os.listdir(h_dir):
            if f.endswith('.png'):
                p = os.path.join(h_dir, f)
                im = Image.open(p).convert('RGBA')
                res = add_arcade_borders_and_padding(im, pad=16, outline_color=(25, 12, 18, 255))
                res.save(p)
                print(f'  Updated hazard {f}: {im.size} -> {res.size}')


def process_mini_boss_stage2():
    print('Processing mini_boss_stage2...')
    mb_dir = 'assets/enemies/mini_boss_stage2'
    if os.path.exists(mb_dir):
        for root, dirs, files in os.walk(mb_dir):
            for f in files:
                if f.endswith('.png'):
                    p = os.path.join(root, f)
                    im = Image.open(p).convert('RGBA')
                    res = add_arcade_borders_and_padding(im, pad=16, outline_color=(15, 20, 28, 255))
                    res.save(p)
                    print(f'  Updated mini_boss_stage2 {f}: {im.size} -> {res.size}')


if __name__ == '__main__':
    process_platforms()
    process_hydro_goliath()
    process_boss_folder('assets/enemies/boss_magma_forge', pad=20, outline_color=(15, 12, 18, 255), cap_bottom=20, cap_top=15)
    process_boss_folder('assets/enemies/boss_mother_brain', pad=20, outline_color=(20, 20, 30, 255), cap_bottom=25)
    process_boss_folder('assets/enemies/boss_bio_heart', pad=20, outline_color=(25, 12, 18, 255), cap_bottom=25)
    process_boss_folder('assets/enemies/boss_star_cruiser', pad=20, outline_color=(15, 20, 28, 255))
    process_boss_folder('assets/enemies/boss_thunder_dynamo', pad=20, outline_color=(12, 18, 25, 255))
    process_boss_folder('assets/enemies/boss_siege_tank', pad=20, outline_color=(15, 22, 26, 255))
    process_hazards()
    process_mini_boss_stage2()
    print('ALL BORDER AND PADDING PROCESSING COMPLETE!')
