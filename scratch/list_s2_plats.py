import re

with open('scripts/level_maps.gd') as f:
    text = f.read()

pattern = r'\n\t\t2:\n(.*?)(?=\n\t\t3:)'
m = re.search(pattern, text, re.DOTALL)
st = m.group(1)
parts = st.split('data["platforms"]')
plat_lines = re.findall(r'(\{"rect":\s*Rect2\(([\d\.]+),\s*([\d\.]+),\s*([\d\.]+),\s*([\d\.]+)\)[^\n]+)', parts[1])

for idx, (raw, px, py, pw, ph) in enumerate(plat_lines):
    is_nav = "NAVIGATE:" in raw
    print(f"[{idx}] {'NAV' if is_nav else '   '}: Rect2({px}, {py}, {pw}, {ph}) | {raw.strip()[:65]}")
