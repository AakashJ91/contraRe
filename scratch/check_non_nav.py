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
    # find all platform lines with comments
    plat_lines = re.findall(r'(\{"rect":\s*Rect2\(([\d\.]+),\s*([\d\.]+),\s*([\d\.]+),\s*([\d\.]+)\)[^\n]+)', parts[1])
    
    print(f"\n================ STAGE {stage} PLATFORMS OVER GROUND ================")
    for idx, (raw, px_s, py_s, pw_s, ph_s) in enumerate(plat_lines):
        px, py, pw, ph = float(px_s), float(py_s), float(pw_s), float(ph_s)
        p_end = px + pw
        is_nav = "NAVIGATE:" in raw
        for gx, gy, gw, gh in grounds:
            g_end = gx + gw
            if max(px, gx) < min(p_end, g_end):
                diff = gy - py
                if not is_nav:
                    print(f"  [Plat {idx}] NON-NAV: px={px}..{p_end}, py={py}, over ground {gx}..{g_end} (gy={gy}), clearance={diff} | line: {raw.strip()[:65]}")
