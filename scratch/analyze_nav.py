import re

with open('scripts/level_maps.gd') as f:
    text = f.read()

def analyze_stage_nav(stage):
    pattern = r'\n\t\t' + str(stage) + r':\n(.*?)(?=\n\t\t\d:|\n\t# Platform rule|\n\treturn data)'
    m = re.search(pattern, text, re.DOTALL)
    if not m:
        return
    st = m.group(1)
    parts = st.split('data["platforms"]')
    grounds = [
        (float(g[0]), float(g[1]), float(g[2]), float(g[3]))
        for g in re.findall(r'Rect2\(([\d\.]+),\s*([\d\.]+),\s*([\d\.]+),\s*([\d\.]+)\)', parts[0])
    ]
    plat_lines = re.findall(r'(\{"rect":\s*Rect2\(([\d\.]+),\s*([\d\.]+),\s*([\d\.]+),\s*([\d\.]+)\)[^\n]+)', parts[1])
    
    print(f"\n==================== STAGE {stage} NAV BRIDGES ====================")
    nav_idx = 0
    for idx, (raw, px_s, py_s, pw_s, ph_s) in enumerate(plat_lines):
        if "NAVIGATE:" in raw:
            px, py, pw, ph = float(px_s), float(py_s), float(pw_s), float(ph_s)
            g1 = grounds[nav_idx]
            g2 = grounds[nav_idx + 1]
            x1 = g1[0] + g1[2]
            x2 = g2[0]
            y1 = g1[1]
            y2 = g2[1]
            gap_w = x2 - x1
            is_asc = y1 > y2
            mid_y = (y1 + y2) / 2.0
            
            # calculate perfect rect
            # for ASC: lower on left (y1), higher on right (y2)
            # platform is at mid_y, which is ABOVE y1, but BELOW y2.
            # So platform can extend left of x1, but MUST end <= x2.
            # Let's give it width = gap_w + 35, ending at x2:
            # start = x2 - (gap_w + 35) = x1 - 35, end = x2.
            
            # for DESC: higher on left (y1), lower on right (y2)
            # platform is at mid_y, which is BELOW y1, but ABOVE y2.
            # So platform MUST start >= x1, and can extend right of x2.
            # Let's give it width = gap_w + 35, starting at x1:
            # start = x1, end = x1 + gap_w + 35 = x2 + 35.
            
            if is_asc:
                p_w = gap_w + 35.0
                ideal_x = x2 - p_w # which is x1 - 35.0
            else:
                p_w = gap_w + 35.0
                ideal_x = x1
            
            print(f"Gap {nav_idx} [{x1}..{x2}] (y={y1}->{y2}, {'ASC' if is_asc else 'DESC'}) mid_y={mid_y}:")
            print(f"  Old Plat {idx}: x={px}..{px+pw}, y={py} | {raw.strip()[:60]}")
            print(f"  Ideal Plat:   x={ideal_x}..{ideal_x+p_w}, y={mid_y}")
            nav_idx += 1

for st in [2, 3, 4, 5, 8]:
    analyze_stage_nav(st)
