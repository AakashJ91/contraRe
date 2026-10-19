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
    plat_lines = re.findall(r'(\{"rect":\s*Rect2\(([\d\.]+),\s*([\d\.]+),\s*([\d\.]+),\s*([\d\.]+)\)[^\n]+)', parts[1])
    nav_indices = [idx for idx, (raw, px, py, pw, ph) in enumerate(plat_lines) if "NAVIGATE:" in raw]
    print(f"Stage {stage} total plats: {len(plat_lines)}, NAV indices: {nav_indices}")
