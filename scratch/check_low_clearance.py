import re

with open('scripts/level_maps.gd') as f:
    text = f.read()

for stage in [2, 3, 4, 5, 8]:
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
    # Check Plat 28
    plats[28] = (plats[28][0], 240.0, plats[28][2], plats[28][3])
    for idx, (px, py, pw, ph) in enumerate(plats):
        raw = plat_lines[idx][0]
        if "NAVIGATE:" in raw:
            continue
        p_end = px + pw
        for gx, gy, gw, gh in grounds:
            g_end = gx + gw
            if max(px, gx) < min(p_end, g_end):
                diff = gy - py
                if 0 < diff < 55:
                    print(f"Stage {stage} Plat {idx} diff={diff}: x={px}..{p_end}, y={py} over {gx}..{g_end} (gy={gy}) | {raw.strip()[:60]}")
