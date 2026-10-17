import re

def parse_rects(text):
    pattern = r'Rect2\(\s*([\d\.]+)\s*,\s*([\d\.]+)\s*,\s*([\d\.]+)\s*,\s*([\d\.]+)\s*\)'
    return [(float(m[0]), float(m[1]), float(m[2]), float(m[3])) for m in re.findall(pattern, text)]

with open('scripts/level_maps.gd', 'r', encoding='utf-8') as f:
    maps_code = f.read()

stages = {}
stage_blocks = re.split(r'\n\s*(\d):\s*\n', maps_code)
for i in range(1, len(stage_blocks), 2):
    s_num = int(stage_blocks[i])
    s_text = stage_blocks[i+1]
    g_match = re.search(r'data\["ground_segments"\]\s*=\s*\[(.*?)\]', s_text, re.DOTALL)
    p_match = re.search(r'data\["platforms"\]\s*=\s*\[(.*?)\]', s_text, re.DOTALL)
    grounds = parse_rects(g_match.group(1)) if g_match else []
    plats = parse_rects(p_match.group(1)) if p_match else []
    stages[s_num] = {'ground': grounds, 'platforms': plats}
    print(f'Stage {s_num}: {len(grounds)} grounds, {len(plats)} platforms')

# Now check enemy positions in stage1.gd
with open('scripts/stage1.gd', 'r', encoding='utf-8') as f:
    stage1_code = f.read()

setup_match = re.search(r'func _setup_static_enemies\(\) -> void:(.*?)\nfunc _is_over_ground', stage1_code, re.DOTALL)
if setup_match:
    setup_code = setup_match.group(1)
    s_blocks = re.split(r'\n\s*(\d):\s*#', setup_code)
    for i in range(1, len(s_blocks), 2):
        s_num = int(s_blocks[i])
        s_text = s_blocks[i+1]
        
        # Find all spawns
        # _spawn_...( [ Vector2(...) ... ] )
        # or sensors with dict
        v_pattern = r'Vector2\(\s*([\d\.]+)\s*,\s*([\d\.]+)\s*\)'
        # Let's inspect each spawn call
        calls = re.findall(r'(_spawn_\w+)\(\s*\[(.*?)\]\s*\)', s_text, re.DOTALL)
        
        stage_grounds = stages.get(s_num, {}).get('ground', [])
        stage_plats = stages.get(s_num, {}).get('platforms', [])
        
        print(f'\n=== STAGE {s_num} ENEMY POSITION AUDIT ===')
        floating_count = 0
        total_count = 0
        
        for func_name, args_text in calls:
            vecs = re.findall(v_pattern, args_text)
            for vx_str, vy_str in vecs:
                x, y = float(vx_str), float(vy_str)
                total_count += 1
                
                # Check if x is over ground or platform
                # Find all surfaces at x:
                surfaces = []
                for gx, gy, gw, gh in stage_grounds:
                    if gx <= x <= (gx + gw):
                        surfaces.append(('ground', gy))
                for px, py, pw, ph in stage_plats:
                    if px <= x <= (px + pw):
                        surfaces.append(('platform', py))
                        
                if not surfaces:
                    print(f'  [CHASM AIR] {func_name} at ({x}, {y}) - NO ground or platform at x={x}!')
                    floating_count += 1
                else:
                    # Find closest surface
                    min_diff = min(abs(y - sy) for _, sy in surfaces)
                    best_surface = min(surfaces, key=lambda s: abs(y - s[1]))
                    # If y is more than 30px away from the surface, it is floating or sunk!
                    if min_diff > 25.0:
                        print(f'  [FLOATING AIR] {func_name} at ({x}, {y}) - closest {best_surface[0]} is at y={best_surface[1]} (gap: {y - best_surface[1]:.1f}px)')
                        floating_count += 1
        print(f'Stage {s_num}: {floating_count}/{total_count} enemies floating in air!')
