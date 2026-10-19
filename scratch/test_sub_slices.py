from PIL import Image

def test_sub_slice(name, sub_ratio, test_filename):
    im = Image.open(f'assets/tiles/ground_{name}.png')
    gw, gh = im.size
    scale_g = 0.35
    target_h = 460.0 # simulated tall elevated pillar (e.g. from y=200 down to 640)
    
    dst_h = gh * scale_g
    sub_src_y = gh * sub_ratio
    sub_src_h = gh - sub_src_y
    sub_dst_h = sub_src_h * scale_g
    
    out_h = int(target_h)
    out_w = int(250)
    out_im = Image.new('RGBA', (out_w, out_h))
    
    # 1. Top primary slice
    top_slice = im.crop((0, 0, int(out_w / scale_g), int(min(gh, target_h / scale_g))))
    top_slice_scaled = top_slice.resize((out_w, int(top_slice.height * scale_g)), Image.Resampling.NEAREST)
    out_im.paste(top_slice_scaled, (0, 0))
    
    # 2. Subterranean repeat
    cur_y = int(dst_h)
    sub_crop = im.crop((0, int(sub_src_y), int(out_w / scale_g), gh))
    sub_scaled = sub_crop.resize((out_w, int(sub_crop.height * scale_g)), Image.Resampling.NEAREST)
    while cur_y < out_h:
        h_left = out_h - cur_y
        if h_left < sub_scaled.height:
            part = sub_scaled.crop((0, 0, out_w, h_left))
            out_im.paste(part, (0, cur_y))
            cur_y += h_left
        else:
            out_im.paste(sub_scaled, (0, cur_y))
            cur_y += sub_scaled.height
            
    out_im.save(test_filename)
    print(f"Saved {test_filename} with sub_ratio={sub_ratio}")

test_sub_slice('refinery', 0.48, 'scratch/test_sub_refinery_clean.png')
test_sub_slice('hive', 0.52, 'scratch/test_sub_hive_clean.png')
test_sub_slice('tundra', 0.38, 'scratch/test_sub_tundra_clean.png')
test_sub_slice('waterfall', 0.40, 'scratch/test_sub_waterfall_clean.png')
