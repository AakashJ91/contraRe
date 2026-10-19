import re

with open('scripts/level_maps.gd') as f:
    text = f.read()

def solve_stage(stage):
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
    
    # print gaps
    print(f"\n=================== STAGE {stage} GAPS & BRIDGES ===================")
    for i in range(len(grounds) - 1):
        g1 = grounds[i]
        g2 = grounds[i+1]
        x1 = g1[0] + g1[2] # g1 end x
        x2 = g2[0]        # g2 start x
        y1 = g1[1]        # g1 y
        y2 = g2[1]        # g2 y
        gap_w = x2 - x1
        is_asc = y1 > y2
        mid_y = (y1 + y2) / 2.0
        print(f"Gap {i}: [{x1} .. {x2}] (w={gap_w}), y: {y1} -> {y2} ({'ASC' if is_asc else 'DESC'}), mid_y={mid_y}")

solve_stage(2)
solve_stage(3)
solve_stage(4)
solve_stage(5)
solve_stage(8)
