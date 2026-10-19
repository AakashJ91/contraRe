import re

with open('scripts/level_maps.gd', 'r', encoding='utf-8') as f:
    text = f.read()

matches = re.findall(r'data\["name"\]\s*=\s*"([^"]+)".*?data\["ground_segments"\]\s*=\s*\[(.*?)\]\s+data\["platforms"\]', text, re.DOTALL)
for name, segs in matches:
    print(f'=== {name} ===')
    rects = re.findall(r'Rect2\(([0-9.]+),\s*([0-9.]+),\s*([0-9.]+),\s*([0-9.]+)\)', segs)
    y_vals = sorted(list(set(float(r[1]) for r in rects)))
    h_vals = sorted(list(set(float(r[3]) for r in rects)))
    print(f'  Count: {len(rects)}, Ys: {y_vals}, Heights: {h_vals}')
    for r in rects[:3]:
        print(f'    Rect2({r[0]}, {r[1]}, {r[2]}, {r[3]})')
