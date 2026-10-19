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
    plats = [
        (float(p[0]), float(p[1]), float(p[2]), float(p[3]))
        for p in re.findall(r'Rect2\(([\d\.]+),\s*([\d\.]+),\s*([\d\.]+),\s*([\d\.]+)\)', parts[1])
    ]
    print(f"\n=== STAGE {stage} ===")
    for idx, (px, py, pw, ph) in enumerate(plats):
        p_end = px + pw
        for gx, gy, gw, gh in grounds:
            g_end = gx + gw
            overlap_start = max(px, gx)
            overlap_end = min(p_end, g_end)
            if overlap_start < overlap_end:
                diff = gy - py
                if diff <= 0:
                    print(f"  [Plat {idx}] x={px}..{p_end}, y={py} INSIDE/BELOW ground x={gx}..{g_end}, gy={gy} (overlap {overlap_start}..{overlap_end}, diff={diff})")
                elif diff < 50:
                    print(f"  [Plat {idx}] x={px}..{p_end}, y={py} LOW CLEARANCE (diff={diff}) above ground x={gx}..{g_end}, gy={gy}")
