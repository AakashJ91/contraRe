import re

with open('scripts/level_maps.gd') as f:
    text = f.read()

for stage in range(1, 9):
    pattern = r'\n\t\t' + str(stage) + r':\n(.*?)(?=\n\t\t\d:|\n\t# Platform rule)'
    m = re.search(pattern, text, re.DOTALL)
    if not m:
        continue
    st = m.group(1)
    parts = st.split('data["platforms"]')
    grounds = re.findall(r'Rect2\(([\d\.]+),\s*([\d\.]+),\s*([\d\.]+),\s*([\d\.]+)\)', parts[0])
    plats = re.findall(r'Rect2\(([\d\.]+),\s*([\d\.]+),\s*([\d\.]+),\s*([\d\.]+)\)', parts[1])
    g_ys = [float(g[1]) for g in grounds]
    p_ys = [float(p[1]) for p in plats]
    print(f"Stage {stage}:")
    print(f"  Ground count: {len(g_ys)}, y min/max/distinct: {min(g_ys)}/{max(g_ys)}/{sorted(set(g_ys))}")
    print(f"  Plat count: {len(p_ys)}, y min/max: {min(p_ys)}/{max(p_ys)}")
