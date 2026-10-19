import re

s2_replacements = {
    2: (365.0, 400.0, 115.0, 16.0),
    5: (805.0, 320.0, 125.0, 16.0),
    8: (1275.0, 240.0, 125.0, 16.0),
    11: (1850.0, 250.0, 135.0, 16.0),
    13: (2320.0, 345.0, 135.0, 16.0),
    15: (2770.0, 430.0, 145.0, 16.0),
    18: (3285.0, 420.0, 145.0, 16.0),
    20: (3755.0, 320.0, 135.0, 16.0),
    22: (4255.0, 240.0, 135.0, 16.0),
    25: (4810.0, 270.0, 145.0, 16.0),
    27: (5280.0, 385.0, 115.0, 16.0),
    31: (6265.0, 390.0, 145.0, 16.0),
    33: (6735.0, 280.0, 145.0, 16.0),
    35: (7300.0, 285.0, 155.0, 16.0),
    37: (7745.0, 315.0, 135.0, 16.0),
    40: (8280.0, 320.0, 135.0, 16.0),
    42: (8750.0, 400.0, 105.0, 16.0),
}

with open('scripts/level_maps.gd') as f:
    text = f.read()

pattern = r'\n\t\t2:\n(.*?)(?=\n\t\t3:)'
m = re.search(pattern, text, re.DOTALL)
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

# Apply mock replacements
for idx, new_p in s2_replacements.items():
    plats[idx] = new_p

print("Verifying Stage 2 with exact indices:")
issues = []
for idx, (px, py, pw, ph) in enumerate(plats):
    p_end = px + pw
    for gx, gy, gw, gh in grounds:
        g_end = gx + gw
        if max(px, gx) < min(p_end, g_end):
            diff = gy - py
            if diff <= 0:
                issues.append(f"Plat {idx} x={px}..{p_end}, y={py} INSIDE ground x={gx}..{g_end}, gy={gy}")

print(f"Total inside/below ground issues: {len(issues)}")
for i in issues:
    print("  ", i)
