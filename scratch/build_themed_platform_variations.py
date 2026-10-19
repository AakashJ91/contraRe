import os
import numpy as np
from PIL import Image, ImageFilter, ImageChops, ImageDraw, ImageEnhance

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

def widen_platform(im, target_w=1420):
    w, h = im.size
    if w >= target_w:
        return im
    
    left_cap = int(w * 0.30)
    right_cap = int(w * 0.30)
    mid_src_w = w - left_cap - right_cap
    
    needed_mid = target_w - left_cap - right_cap
    repeats = int(np.ceil(needed_mid / float(mid_src_w)))
    
    res = Image.new('RGBA', (target_w, h), (0, 0, 0, 0))
    # Paste left cap
    left_img = im.crop((0, 0, left_cap, h))
    res.paste(left_img, (0, 0))
    
    # Fill middle with repeated and crossfaded mid sections
    mid_img = im.crop((left_cap, 0, left_cap + mid_src_w, h))
    cur_x = left_cap
    for r in range(repeats):
        paste_w = min(mid_src_w, target_w - right_cap - cur_x)
        if paste_w <= 0:
            break
        chunk = mid_img.crop((0, 0, paste_w, h))
        res.paste(chunk, (cur_x, 0))
        cur_x += paste_w
        
    # Paste right cap
    right_img = im.crop((w - right_cap, 0, w, h))
    res.paste(right_img, (target_w - right_cap, 0))
    return res

def build_all_tiles():
    tiles_dir = "assets/tiles"
    
    # 1. platform_waterfall_wide.png
    print("Building platform_waterfall_wide.png...")
    wf_crag = Image.open(os.path.join(tiles_dir, "platform_waterfall_crag.png")).convert('RGBA')
    wf_wide = widen_platform(wf_crag, target_w=1400)
    wf_wide.save(os.path.join(tiles_dir, "platform_waterfall_wide.png"))
    print("  Saved platform_waterfall_wide.png", wf_wide.size)
    
    # 2. platform_bio_wide.png
    print("Building platform_bio_wide.png...")
    bio_car = Image.open(os.path.join(tiles_dir, "platform_bio_carapace.png")).convert('RGBA')
    bio_wide = widen_platform(bio_car, target_w=1380)
    bio_wide.save(os.path.join(tiles_dir, "platform_bio_wide.png"))
    print("  Saved platform_bio_wide.png", bio_wide.size)
    
    # 3. platform_bio_shelf.png (fleshy biomass shelf with tendrils)
    print("Building platform_bio_shelf.png...")
    g_hive = Image.open(os.path.join(tiles_dir, "ground_hive.png")).convert('RGBA')
    # Sample upper organic band
    w_gh, h_gh = g_hive.size
    shelf_w = 1180
    shelf_h = 320
    # Tile ground_hive horizontally to reach shelf_w
    gh_tiled = Image.new('RGBA', (shelf_w, 280), (0, 0, 0, 0))
    for tx in range(0, shelf_w, w_gh):
        gh_tiled.paste(g_hive.crop((0, 0, min(w_gh, shelf_w - tx), 280)), (tx, 0))
    
    # Create organic arched cutout with hanging fleshy roots
    arr_shelf = np.array(gh_tiled)
    alpha = np.zeros((280, shelf_w), dtype=np.uint8)
    for x in range(shelf_w):
        fx = (x - shelf_w * 0.5) / (shelf_w * 0.5) # -1 to 1
        # Arch height from bottom
        arch = (1.0 - fx * fx) * 110.0 + 80.0
        # Add fleshy undulations
        arch += np.sin(x * 0.04) * 14.0 + np.sin(x * 0.1) * 8.0
        max_y = int(np.clip(arch, 30, 260))
        alpha[0:max_y, x] = 255
        # Soft edge
        if max_y < 278:
            alpha[max_y:max_y+3, x] = 120
            
    # Add hanging roots/tendrils below arch
    for r in range(16):
        rx = int(120 + r * 60 + np.sin(r * 2.5) * 20)
        rlen = int(25 + (r % 5) * 8 + np.cos(r) * 10)
        r_start_y = int(np.clip((1.0 - ((rx - shelf_w * 0.5) / (shelf_w * 0.5))**2) * 110.0 + 75.0, 30, 250))
        for dy in range(rlen):
            cy = r_start_y + dy
            if cy < 278 and 0 <= rx < shelf_w:
                thick = max(1, int(3 - dy * 0.08))
                for tx in range(rx - thick, rx + thick + 1):
                    if 0 <= tx < shelf_w:
                        alpha[cy, tx] = max(alpha[cy, tx], int(240 - dy * 5))
                        # Color tendril with deep purple/crimson
                        arr_shelf[cy, tx, :3] = [135, 25, 55]

    arr_shelf[:, :, 3] = alpha
    im_shelf = Image.fromarray(arr_shelf)
    final_shelf = add_arcade_borders_and_padding(im_shelf, pad=18, taper_ends=True)
    final_shelf.save(os.path.join(tiles_dir, "platform_bio_shelf.png"))
    print("  Saved platform_bio_shelf.png", final_shelf.size)

    # 4. platform_ice_shelf_wide.png
    print("Building platform_ice_shelf_wide.png...")
    ice_slab = Image.open(os.path.join(tiles_dir, "platform_ice_slab.png")).convert('RGBA')
    ice_wide = widen_platform(ice_slab, target_w=1420)
    ice_wide.save(os.path.join(tiles_dir, "platform_ice_shelf_wide.png"))
    print("  Saved platform_ice_shelf_wide.png", ice_wide.size)

    # 5. platform_tundra_girder.png (frosted heavy industrial steel girder)
    print("Building platform_tundra_girder.png...")
    girder = Image.open(os.path.join(tiles_dir, "platform_girder.png")).convert('RGBA')
    gw, gh = girder.size
    arr_g = np.array(girder).astype(float)
    # Cool down color palette to arctic blue/steel
    # Multiply R:0.75, G:0.88, B:1.15
    arr_g[:, :, 0] = np.clip(arr_g[:, :, 0] * 0.72 + 15, 0, 255)
    arr_g[:, :, 1] = np.clip(arr_g[:, :, 1] * 0.85 + 25, 0, 255)
    arr_g[:, :, 2] = np.clip(arr_g[:, :, 2] * 1.15 + 40, 0, 255)
    
    # Add thick white snow cap on top surface
    alpha_g = arr_g[:, :, 3]
    for x in range(gw):
        # find top surface pixel
        col = np.where(alpha_g[:, x] > 100)[0]
        if len(col) > 0:
            top_y = col[0]
            snow_depth = int(12 + np.sin(x * 0.05) * 4 + np.sin(x * 0.15) * 2)
            for sy in range(top_y, min(gh, top_y + snow_depth)):
                if alpha_g[sy, x] > 50:
                    blend = 1.0 - (sy - top_y) / float(snow_depth)
                    arr_g[sy, x, 0] = arr_g[sy, x, 0] * (1.0 - blend) + 235 * blend
                    arr_g[sy, x, 1] = arr_g[sy, x, 1] * (1.0 - blend) + 245 * blend
                    arr_g[sy, x, 2] = arr_g[sy, x, 2] * (1.0 - blend) + 255 * blend

    # Add sharp icicles along bottom edge
    for x in range(20, gw - 20, 28):
        icicle_len = int(15 + np.sin(x * 0.4) * 8 + (x % 7) * 3)
        bot_col = np.where(alpha_g[:, x] > 100)[0]
        if len(bot_col) > 0:
            bot_y = bot_col[-1]
            for dy in range(icicle_len):
                iy = bot_y + dy
                if iy < gh:
                    thick = max(1, int(3 - dy * 0.15))
                    for tx in range(x - thick, x + thick + 1):
                        if 0 <= tx < gw:
                            arr_g[iy, tx, :3] = [190, 230, 255]
                            arr_g[iy, tx, 3] = max(arr_g[iy, tx, 3], int(230 - dy * 8))

    im_tg = Image.fromarray(arr_g.astype(np.uint8))
    im_tg.save(os.path.join(tiles_dir, "platform_tundra_girder.png"))
    print("  Saved platform_tundra_girder.png", im_tg.size)

    # 6. platform_lava_grate_wide.png
    print("Building platform_lava_grate_wide.png...")
    lava_grate = Image.open(os.path.join(tiles_dir, "platform_lava_grate.png")).convert('RGBA')
    lava_wide = widen_platform(lava_grate, target_w=1420)
    lava_wide.save(os.path.join(tiles_dir, "platform_lava_grate_wide.png"))
    print("  Saved platform_lava_grate_wide.png", lava_wide.size)

    # 7. platform_refinery_girder.png (superheated foundry girder)
    print("Building platform_refinery_girder.png...")
    girder = Image.open(os.path.join(tiles_dir, "platform_girder.png")).convert('RGBA')
    arr_rg = np.array(girder).astype(float)
    # Warm scorched palette
    arr_rg[:, :, 0] = np.clip(arr_rg[:, :, 0] * 1.35 + 25, 0, 255)
    arr_rg[:, :, 1] = np.clip(arr_rg[:, :, 1] * 0.82 + 10, 0, 255)
    arr_rg[:, :, 2] = np.clip(arr_rg[:, :, 2] * 0.55, 0, 255)
    
    # Add molten orange heat seam running horizontally along central truss
    gh_rg, gw_rg = arr_rg.shape[:2]
    for y in range(int(gh_rg * 0.35), int(gh_rg * 0.65)):
        for x in range(gw_rg):
            if arr_rg[y, x, 3] > 120:
                dist = abs(y - int(gh_rg * 0.50)) / (gh_rg * 0.15)
                if dist < 1.0:
                    heat = (1.0 - dist) * (0.6 + 0.4 * np.sin(x * 0.08))
                    arr_rg[y, x, 0] = arr_rg[y, x, 0] * (1.0 - heat) + 255 * heat
                    arr_rg[y, x, 1] = arr_rg[y, x, 1] * (1.0 - heat) + 150 * heat
                    arr_rg[y, x, 2] = arr_rg[y, x, 2] * (1.0 - heat) + 20 * heat

    im_rg = Image.fromarray(arr_rg.astype(np.uint8))
    im_rg.save(os.path.join(tiles_dir, "platform_refinery_girder.png"))
    print("  Saved platform_refinery_girder.png", im_rg.size)

    # 8. platform_slag_crag.png (hardened volcanic basalt shelf with magma veins)
    print("Building platform_slag_crag.png...")
    g_ref = Image.open(os.path.join(tiles_dir, "ground_refinery.png")).convert('RGBA')
    w_gr, h_gr = g_ref.size
    slag_w = 1200
    slag_h = 320
    tiled_ref = Image.new('RGBA', (slag_w, slag_h), (0, 0, 0, 0))
    for tx in range(0, slag_w, w_gr):
        tiled_ref.paste(g_ref.crop((0, 0, min(w_gr, slag_w - tx), slag_h)), (tx, 0))
        
    arr_slag = np.array(tiled_ref).astype(float)
    # Darken and add incandescent magma contrast
    arr_slag[:, :, 0] = np.clip(arr_slag[:, :, 0] * 1.25, 0, 255)
    arr_slag[:, :, 1] = np.clip(arr_slag[:, :, 1] * 0.85, 0, 255)
    arr_slag[:, :, 2] = np.clip(arr_slag[:, :, 2] * 0.65, 0, 255)
    
    alpha_s = np.zeros((slag_h, slag_w), dtype=np.uint8)
    for x in range(slag_w):
        fx = (x - slag_w * 0.5) / (slag_w * 0.5)
        arch = (1.0 - fx * fx) * 140.0 + 80.0
        arch += np.sin(x * 0.05) * 18.0 + np.sin(x * 0.12) * 10.0
        max_y = int(np.clip(arch, 30, slag_h - 10))
        alpha_s[0:max_y, x] = 255
        
    arr_slag[:, :, 3] = alpha_s
    im_slag = Image.fromarray(arr_slag.astype(np.uint8))
    final_slag = add_arcade_borders_and_padding(im_slag, pad=18, taper_ends=True)
    final_slag.save(os.path.join(tiles_dir, "platform_slag_crag.png"))
    print("  Saved platform_slag_crag.png", final_slag.size)

    # 9. platform_energy_barrier_wide.png
    print("Building platform_energy_barrier_wide.png...")
    bar = Image.open(os.path.join(tiles_dir, "platform_energy_barrier.png")).convert('RGBA')
    bar_wide = widen_platform(bar, target_w=1440)
    bar_wide.save(os.path.join(tiles_dir, "platform_energy_barrier_wide.png"))
    print("  Saved platform_energy_barrier_wide.png", bar_wide.size)

    # 10. platform_dynamo_rail.png (dielectric ceramic capacitor rail with glowing coils)
    print("Building platform_dynamo_rail.png...")
    catwalk = Image.open(os.path.join(tiles_dir, "platform_tech_catwalk.png")).convert('RGBA')
    cw_w, cw_h = catwalk.size
    arr_dr = np.array(catwalk).astype(float)
    # Electric cyan and yellow voltage glow
    arr_dr[:, :, 0] = np.clip(arr_dr[:, :, 0] * 0.70 + 10, 0, 255)
    arr_dr[:, :, 1] = np.clip(arr_dr[:, :, 1] * 1.10 + 30, 0, 255)
    arr_dr[:, :, 2] = np.clip(arr_dr[:, :, 2] * 1.45 + 60, 0, 255)
    
    # Add glowing insulator coils every 48 pixels
    for x in range(30, cw_w - 30, 48):
        for y in range(int(cw_h * 0.25), int(cw_h * 0.75)):
            if arr_dr[y, x, 3] > 150:
                for dx in range(-4, 5):
                    cx = x + dx
                    if 0 <= cx < cw_w and arr_dr[y, cx, 3] > 100:
                        arr_dr[y, cx, 0] = 255
                        arr_dr[y, cx, 1] = 220
                        arr_dr[y, cx, 2] = 40
                        
    im_dr = Image.fromarray(arr_dr.astype(np.uint8))
    im_dr.save(os.path.join(tiles_dir, "platform_dynamo_rail.png"))
    print("  Saved platform_dynamo_rail.png", im_dr.size)

    # 11. platform_hangar_deck.png (titanium flight deck with yellow hazard markings)
    print("Building platform_hangar_deck.png...")
    g_hng = Image.open(os.path.join(tiles_dir, "ground_hangar.png")).convert('RGBA')
    catwalk = Image.open(os.path.join(tiles_dir, "platform_tech_catwalk.png")).convert('RGBA')
    arr_hd = np.array(catwalk).astype(float)
    h_w, h_h = catwalk.size
    # Aerospace navy titanium grade
    arr_hd[:, :, 0] = np.clip(arr_hd[:, :, 0] * 0.82 + 15, 0, 255)
    arr_hd[:, :, 1] = np.clip(arr_hd[:, :, 1] * 0.88 + 18, 0, 255)
    arr_hd[:, :, 2] = np.clip(arr_hd[:, :, 2] * 1.15 + 35, 0, 255)
    
    # Paint yellow/black diagonal hazard stripes across the top 14px
    for x in range(h_w):
        is_yellow = ((x // 14) % 2 == 0)
        top_y_idx = np.where(arr_hd[:, x, 3] > 100)[0]
        if len(top_y_idx) > 0:
            ty = top_y_idx[0]
            for sy in range(ty, min(h_h, ty + 12)):
                if arr_hd[sy, x, 3] > 50:
                    if is_yellow:
                        arr_hd[sy, x, 0] = 240
                        arr_hd[sy, x, 1] = 200
                        arr_hd[sy, x, 2] = 20
                    else:
                        arr_hd[sy, x, 0] = 25
                        arr_hd[sy, x, 1] = 28
                        arr_hd[sy, x, 2] = 35

    im_hd = Image.fromarray(arr_hd.astype(np.uint8))
    im_hd.save(os.path.join(tiles_dir, "platform_hangar_deck.png"))
    print("  Saved platform_hangar_deck.png", im_hd.size)

    # 12. platform_hangar_girder.png (aerospace titanium truss)
    print("Building platform_hangar_girder.png...")
    girder = Image.open(os.path.join(tiles_dir, "platform_girder.png")).convert('RGBA')
    arr_hg = np.array(girder).astype(float)
    # Gunmetal / navy aerospace titanium
    arr_hg[:, :, 0] = np.clip(arr_hg[:, :, 0] * 0.78 + 12, 0, 255)
    arr_hg[:, :, 1] = np.clip(arr_hg[:, :, 1] * 0.84 + 16, 0, 255)
    arr_hg[:, :, 2] = np.clip(arr_hg[:, :, 2] * 1.20 + 32, 0, 255)
    
    # Cyan status LED beacons along truss nodes
    gh_h, gw_h = arr_hg.shape[:2]
    for x in range(40, gw_h - 40, 64):
        mid_y = int(gh_h * 0.48)
        for dy in range(-3, 4):
            for dx in range(-3, 4):
                if dx*dx + dy*dy <= 9:
                    arr_hg[mid_y + dy, x + dx, 0] = 40
                    arr_hg[mid_y + dy, x + dx, 1] = 220
                    arr_hg[mid_y + dy, x + dx, 2] = 255
                    arr_hg[mid_y + dy, x + dx, 3] = 255

    im_hg = Image.fromarray(arr_hg.astype(np.uint8))
    im_hg.save(os.path.join(tiles_dir, "platform_hangar_girder.png"))
    print("  Saved platform_hangar_girder.png", im_hg.size)

    # 13. platform_psychic_synapse.png (neural synapse platform with glowing magenta/violet axons)
    print("Building platform_psychic_synapse.png...")
    bio_car = Image.open(os.path.join(tiles_dir, "platform_bio_carapace.png")).convert('RGBA')
    arr_ps = np.array(bio_car).astype(float)
    # Transform to deep cosmic purple and electric magenta
    arr_ps[:, :, 0] = np.clip(arr_ps[:, :, 0] * 1.15 + 30, 0, 255)
    arr_ps[:, :, 1] = np.clip(arr_ps[:, :, 1] * 0.45, 0, 255)
    arr_ps[:, :, 2] = np.clip(arr_ps[:, :, 2] * 1.45 + 50, 0, 255)
    
    # Add vibrant neural synaptic discharge nodes
    ps_h, ps_w = arr_ps.shape[:2]
    for x in range(30, ps_w - 30, 50):
        ny = int(ps_h * 0.35 + np.sin(x * 0.1) * 12)
        if arr_ps[ny, x, 3] > 120:
            for dy in range(-4, 5):
                for dx in range(-4, 5):
                    if dx*dx + dy*dy <= 16:
                        arr_ps[ny + dy, x + dx, 0] = 255
                        arr_ps[ny + dy, x + dx, 1] = 80
                        arr_ps[ny + dy, x + dx, 2] = 240
                        
    im_ps = Image.fromarray(arr_ps.astype(np.uint8))
    im_ps.save(os.path.join(tiles_dir, "platform_psychic_synapse.png"))
    print("  Saved platform_psychic_synapse.png", im_ps.size)

    # 14. platform_psychic_barrier.png (prismatic psionic forcefield)
    print("Building platform_psychic_barrier.png...")
    bar = Image.open(os.path.join(tiles_dir, "platform_energy_barrier.png")).convert('RGBA')
    arr_pb = np.array(bar).astype(float)
    # Convert cyan (high G, high B) to magenta/violet psionic forcefield
    # Swap G and R, boost B
    orig_r = arr_pb[:, :, 0].copy()
    orig_g = arr_pb[:, :, 1].copy()
    orig_b = arr_pb[:, :, 2].copy()
    arr_pb[:, :, 0] = np.clip(orig_g * 1.1 + orig_r * 0.5, 0, 255)
    arr_pb[:, :, 1] = np.clip(orig_r * 0.3 + orig_g * 0.2, 0, 255)
    arr_pb[:, :, 2] = np.clip(orig_b * 1.15 + 40, 0, 255)
    
    im_pb = Image.fromarray(arr_pb.astype(np.uint8))
    im_pb.save(os.path.join(tiles_dir, "platform_psychic_barrier.png"))
    print("  Saved platform_psychic_barrier.png", im_pb.size)

    print("\nAll themed platform variations built successfully!")

if __name__ == "__main__":
    build_all_tiles()
