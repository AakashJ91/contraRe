import re

with open('scripts/level_maps.gd') as f:
    text = f.read()

def parse_stages():
    stages = {}
    for stage in range(1, 9):
        pattern = r'\n\t\t' + str(stage) + r':\n(.*?)(?=\n\t\t\d:|\n\t# Platform rule|\n\treturn data)'
        m = re.search(pattern, text, re.DOTALL)
        if not m:
            continue
        st = m.group(1)
        parts = st.split('data["platforms"]')
        grounds = [
            (float(g[0]), float(g[1]), float(g[2]), float(g[3]))
            for g in re.findall(r'Rect2\(([\d\.]+),\s*([\d\.]+),\s*([\d\.]+),\s*([\d\.]+)\)', parts[0])
        ]
        plats = [
            (float(p[0]), float(p[1]), float(p[2]), float(p[3]))
            for p in re.findall(r'Rect2\(([\d\.]+),\s*([\d\.]+),\s*([\d\.]+),\s*([\d\.]+)\)', parts[1])
        ]
        stages[stage] = (grounds, plats)
    return stages

stages = parse_stages()

for stage, (grounds, plats) in stages.items():
    print(f"\n=== STAGE {stage} ===")
    # Check for each platform: what ground is directly below/around it?
    # Or is a platform below the ground? Or inside the ground?
    inconsistencies = []
    for px, py, pw, ph in plats:
        # Find overlapping ground in x
        p_end = px + pw
        overlapping_grounds = []
        for gx, gy, gw, gh in grounds:
            g_end = gx + gw
            if max(px, gx) < min(p_end, g_end):
                overlapping_grounds.append((gx, gy, gw, gh))
        
        if not overlapping_grounds:
            # Platform is over a gap / chasm
            pass
        else:
            for gx, gy, gw, gh in overlapping_grounds:
                diff = gy - py # ground y minus plat y. If positive, plat is above ground. If negative, plat is below ground!
                if diff <= 0:
                    inconsistencies.append(f"Plat at x={px}..{p_end}, y={py} is BELOW/INSIDE ground at x={gx}..{gx+gw}, gy={gy} (diff={diff})")
                elif diff < 30:
                    inconsistencies.append(f"Plat at x={px}..{p_end}, y={py} is TOO CLOSE to ground at gy={gy} (diff={diff})")
    
    print(f"Total platforms: {len(plats)}, over-ground issues: {len(inconsistencies)}")
    for inc in inconsistencies[:10]:
        print("  ", inc)
