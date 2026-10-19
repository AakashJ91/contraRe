import re

with open('scripts/level_maps.gd') as f:
    text = f.read()

for stage in [3, 4, 5, 8]:
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
    plat_lines = re.findall(r'(\{"rect":\s*Rect2\(([\d\.]+),\s*([\d\.]+),\s*([\d\.]+),\s*([\d\.]+)\)[^\n]+)', parts[1])
    plats = [
        (float(p[0]), float(p[1]), float(p[2]), float(p[3]))
        for p in re.findall(r'Rect2\(([\d\.]+),\s*([\d\.]+),\s*([\d\.]+),\s*([\d\.]+)\)', parts[1])
    ]
    
    # Calculate replacements for NAV indices: [2, 5, 8, 11, 13, 15, 19, 22, 24, 27, 29, 32, 34, 36, 38, 40, 42]
    nav_indices = [2, 5, 8, 11, 13, 15, 19, 22, 24, 27, 29, 32, 34, 36, 38, 40, 42]
    for gap_idx, p_idx in enumerate(nav_indices):
        g1 = grounds[gap_idx]
        g2 = grounds[gap_idx + 1]
        x1 = g1[0] + g1[2]
        x2 = g2[0]
        y1 = g1[1]
        y2 = g2[1]
        gap_w = x2 - x1
        is_asc = y1 > y2
        mid_y = (y1 + y2) / 2.0
        p_w = gap_w + 35.0
        if is_asc:
            ideal_x = x2 - p_w
        else:
            ideal_x = x1
        plats[p_idx] = (ideal_x, mid_y, p_w, 16.0)

    # Check Plat 28 clearance
    # Plat 28 is at px=5120..5280, py=290. Raising to 240.
    plats[28] = (plats[28][0], 240.0, plats[28][2], plats[28][3])

    issues = []
    for idx, (px, py, pw, ph) in enumerate(plats):
        p_end = px + pw
        for gx, gy, gw, gh in grounds:
            g_end = gx + gw
            if max(px, gx) < min(p_end, g_end):
                diff = gy - py
                if diff <= 0:
                    issues.append(f"Plat {idx} x={px}..{p_end}, y={py} INSIDE ground x={gx}..{g_end}, gy={gy}")

    print(f"Stage {stage}: Total inside/below ground issues: {len(issues)}")
    for i in issues:
        print("  ", i)
