import re

def parse_level_maps(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    stage_blocks = re.split(r'\n\s*(\d):\s*\n', content)
    # stage_blocks[0] is preamble, then alternating stage_id and stage_text
    stages = {}
    for i in range(1, len(stage_blocks), 2):
        s_id = int(stage_blocks[i])
        s_text = stage_blocks[i+1]
        
        # parse ground segments: Rect2(x, y, w, h)
        grounds = []
        for match in re.finditer(r'Rect2\s*\(\s*([\d\.]+)\s*,\s*([\d\.]+)\s*,\s*([\d\.]+)\s*,\s*([\d\.]+)\s*\)', s_text):
            grounds.append([float(match.group(1)), float(match.group(2)), float(match.group(3)), float(match.group(4))])
        
        # separate ground segments from platform rects
        # ground segments are defined under data["ground_segments"] = [ ... ]
        gs_match = re.search(r'data\["ground_segments"\]\s*=\s*\[(.*?)\]', s_text, re.DOTALL)
        ground_list = []
        if gs_match:
            for gm in re.finditer(r'Rect2\s*\(\s*([\d\.]+)\s*,\s*([\d\.]+)\s*,\s*([\d\.]+)\s*,\s*([\d\.]+)\s*\)', gs_match.group(1)):
                ground_list.append([float(gm.group(1)), float(gm.group(2)), float(gm.group(3)), float(gm.group(4))])

        plat_match = re.search(r'data\["platforms"\]\s*=\s*\[(.*?)\]\s*(?:\n\t\t\d:|\n\t#|\Z)', s_text, re.DOTALL)
        plat_list = []
        if plat_match:
            for pm in re.finditer(r'Rect2\s*\(\s*([\d\.]+)\s*,\s*([\d\.]+)\s*,\s*([\d\.]+)\s*,\s*([\d\.]+)\s*\)', plat_match.group(1)):
                plat_list.append([float(pm.group(1)), float(pm.group(2)), float(pm.group(3)), float(pm.group(4))])

        stages[s_id] = {
            "grounds": ground_list,
            "platforms": plat_list
        }
    return stages

def validate():
    stages = parse_level_maps('d:/GitHub/contraRe/scripts/level_maps.gd')
    errors = 0
    warnings = 0
    for s_id, s_data in stages.items():
        grounds = s_data["grounds"]
        platforms = s_data["platforms"]
        print(f"\n=== STAGE {s_id} ===")
        print(f"Ground segments: {len(grounds)}, Platforms: {len(platforms)}")
        
        if len(grounds) == 0:
            print(f"ERROR: Stage {s_id} has no ground segments!")
            errors += 1
            continue
        
        # Check start and end
        if grounds[0][0] != 0.0:
            print(f"ERROR: Stage {s_id} does not start at 0.0 (starts at {grounds[0][0]})")
            errors += 1
        
        last_g = grounds[-1]
        last_end = last_g[0] + last_g[2]
        if last_end != 9800.0:
            print(f"ERROR: Stage {s_id} does not end at 9800.0 (ends at {last_end})")
            errors += 1
        
        if last_g[0] > 8800.0:
            print(f"ERROR: Stage {s_id} boss floor starts after 8800.0 ({last_g[0]})")
            errors += 1
            
        # Check pits
        for i in range(len(grounds) - 1):
            g1_end = grounds[i][0] + grounds[i][2]
            g2_start = grounds[i+1][0]
            gap = g2_start - g1_end
            if gap <= 0:
                print(f"ERROR: Negative or zero gap between seg {i} and {i+1}: {gap}")
                errors += 1
            else:
                # Rule: between the floor tiles if pit can cross by jump then dont add any platform above it
                # Jumpable pit <= 200px
                if gap <= 200.0:
                    for p_idx, p in enumerate(platforms):
                        p_l = p[0]
                        p_r = p[0] + p[2]
                        overlap_l = max(p_l, g1_end)
                        overlap_r = min(p_r, g2_start)
                        if overlap_r - overlap_l >= gap * 0.4:
                            print(f"ERROR Stage {s_id}: Jumpable pit [{g1_end}, {g2_start}] (gap={gap}) has platform {p_idx} [{p_l}, {p_r}] above it!")
                            errors += 1
                else:
                    print(f"  Note: Chasm between {g1_end} and {g2_start} (w={gap:.1f}px) requires platforms.")

    print(f"\n==========================================")
    print(f"VALIDATION COMPLETE: {errors} Errors, {warnings} Warnings.")
    assert errors == 0, f"{errors} errors found!"

if __name__ == '__main__':
    validate()
