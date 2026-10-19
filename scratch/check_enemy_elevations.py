import re

with open('scripts/stage1.gd') as f:
    s1 = f.read()

with open('scripts/level_maps.gd') as f:
    lm = f.read()

# Parse ground segments for each stage
stage_grounds = {}
for st in range(1, 9):
    pattern = r'\n\t\t' + str(st) + r':\n(.*?)(?=\n\t\t\d:|\n\t# Platform rule|\n\treturn data)'
    m = re.search(pattern, lm, re.DOTALL)
    if m:
        parts = m.group(1).split('data["platforms"]')
        grounds = [
            (float(g[0]), float(g[1]), float(g[2]), float(g[3]))
            for g in re.findall(r'Rect2\(([\d\.]+),\s*([\d\.]+),\s*([\d\.]+),\s*([\d\.]+)\)', parts[0])
        ]
        stage_grounds[st] = grounds

# Parse static enemies in stage1.gd
# Between _setup_static_enemies() and the next function
setup_match = re.search(r'func _setup_static_enemies\(\) -> void:(.*?)(?=\nfunc )', s1, re.DOTALL)
if setup_match:
    setup_code = setup_match.group(1)
    stage_blocks = re.split(r'\n\t\t(\d):\s*#', setup_code)
    for i in range(1, len(stage_blocks), 2):
        st_id = int(stage_blocks[i])
        code = stage_blocks[i+1]
        grounds = stage_grounds.get(st_id, [])
        
        # find all Vector2(x, y)
        vecs = re.findall(r'Vector2\(([\d\.]+),\s*([\d\.]+)\)', code)
        bad_spawns = []
        for vx, vy in vecs:
            vx, vy = float(vx), float(vy)
            # Find ground at vx
            matching_g = None
            for gx, gy, gw, gh in grounds:
                if gx <= vx <= gx + gw:
                    matching_g = (gx, gy, gw, gh)
                    break
            if matching_g:
                diff = vy - matching_g[1]
                # Normally an enemy on ground should have vy near gy (e.g. gy - 5 to gy + 5)
                # If vy is far from gy (or inside ground by 50px or in air by 80px), report
                if diff > 15: # inside ground
                    bad_spawns.append((vx, vy, matching_g[1], f"INSIDE ground by {diff:.1f}px"))
                elif diff < -80: # high in air without platform?
                    bad_spawns.append((vx, vy, matching_g[1], f"HIGH in air by {-diff:.1f}px"))
        print(f"Stage {st_id} Static Enemies: {len(vecs)} total, {len(bad_spawns)} potential mismatches with ground")
        for b in bad_spawns[:5]:
            print(f"   at x={b[0]}, y={b[1]}, ground_y={b[2]}: {b[3]}")
