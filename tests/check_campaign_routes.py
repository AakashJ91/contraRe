"""Static ballistic traversal check for all eight authored Godot maps.
Uses the player's 180 px/s speed, -450 jump, 950 gravity, and 32px body.
This supplements engine playtesting; it does not emulate enemy combat.
"""
from pathlib import Path
import re
from collections import deque

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / 'scripts/level_maps.gd').read_text(encoding='utf-8')
source = source.split('match s_id:')[1].split('\n\treturn data')[0]
stages = {}
for match in re.finditer(r'\n\t\t([1-8]):(.*?)(?=\n\t\t[1-8]:|\Z)', source, re.S):
    sid, text = int(match[1]), match[2]
    grounds = [tuple(map(float, m.split(","))) for m in re.findall(r'^\s*Rect2\((.*?)\)', text, re.M)]
    platforms = []
    for rect, kind, extra in re.findall(r'"rect": Rect2\((.*?)\), "type": PlatformType\.(\w+)([^\n]*)', text):
        platforms.append((*map(float, rect.split(',')), kind, '"is_drop": true' in extra, '"is_lift": true' in extra))
    assert all(p[4] != 'ROPE_BRIDGE' for p in platforms), sid
    assert any(x <= 5320 < x+w and y == 440 for x,y,w,h in grounds), (sid, 'mini-boss floor')
    assert any(x <= 8800 and x+w >= 9800 and y == 440 for x,y,w,h in grounds), (sid, 'boss floor')
    stages[sid] = (grounds, platforms)


def graph_for(grounds, platforms, allow_dynamic=False):
    # The main-route check excludes falling ledges and lifts.
    # The optional-reward check also considers their authored resting positions.
    surfaces = [(*g, True) for g in grounds] + [(*p[:4], False) for p in platforms if (allow_dynamic or not p[5]) and (allow_dynamic or not p[6])]
    graph = [set() for _ in surfaces]
    dt = 1/120
    for i, (sx, sy, sw, sh, solid) in enumerate(surfaces):
        starts = [sx+12 + n*24 for n in range(max(1, int((sw-24)/24)+1))] + [sx+sw-12]
        for start in starts:
            for vx in (0, 180):
                x, feet, vy = start, sy, -450.0
                for _ in range(170):
                    old_feet = feet
                    vy += 950*dt
                    x += vx*dt
                    feet += vy*dt
                    # Capsule approximated by a conservative 16x32 rectangle.
                    hits = [(y,j) for j,(bx,y,w,h,solid) in enumerate(surfaces)
                            if vy>0 and old_feet <= y+0.01 and feet >= y and x>=bx+10 and x<=bx+w-10]
                    if hits:
                        _,j = min(hits)
                        if i != j:
                            graph[i].add(j)
                        break
                    if any(x+7 > gx and x-7 < gx+gw and feet > gy+0.5 and feet-31 < gy+gh for gx,gy,gw,gh in grounds):
                        break
                    if feet>640:
                        break
    seen={0};queue=deque([0])
    while queue:
        for j in graph[queue.popleft()]:
            if j not in seen: seen.add(j);queue.append(j)
    return surfaces, seen

results={}
for sid,(grounds,platforms) in stages.items():
    surfaces, seen = graph_for(grounds, platforms)
    # Every ground chunk must have a forward-only route from the spawn.
    missing = [grounds[i] for i in range(len(grounds)) if i not in seen]
    assert not missing, (sid, 'unreachable ground', missing)
    results[sid]=(surfaces,seen)
    print('Stage %d: all %d ground sections reachable; %d/%d fixed surfaces reachable; no bridges' % (sid,len(grounds),len(seen),len(surfaces)))

# Weapon sensors should be on reachable surfaces. Approximate the game's surface snap.
runtime=(ROOT/'scripts/stage1.gd').read_text(encoding='utf-8')
runtime=runtime.split('func _setup_static_enemies()')[1].split('func _find_valid_surface_at')[0]
for match in re.finditer(r'\n\t\t([1-8]):(.*?)(?=\n\t\t[1-8]:|\Z)',runtime,re.S):
    sid=int(match[1]);surfaces,seen=graph_for(*stages[sid], allow_dynamic=True)
    for x,y in re.findall(r'"pos": Vector2\(([\d.]+), ([\d.]+)\)',match[2]):
        x,y=float(x),float(y)
        possible=[(abs(sy-y),i) for i,(sx,sy,w,h,solid) in enumerate(surfaces) if sx+12<=x<=sx+w-12]
        if possible:
            _,i=min(possible)
            assert i in seen, (sid,'weapon route unreachable',x,y,surfaces[i])
print('All weapon-support routes reachable, including optional collapsing and lift routes.')

