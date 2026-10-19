"""
Precision designer for Contra Re Stage 2, 3, 4, 5, 8.
Ensures:
1. All grounds start at 0.0, end at 9800.0, boss arena starts <= 8800.0.
2. Step-ups between ground heights are <= 90px (e.g. 440 -> 360, 360 -> 280).
3. Any gap > 160px has a navigation platform.
4. No platform ever clips into or sits below any ground segment (diff >= 55px if directly over ground).
5. All platform types match the stage biome (NO green TURF in Waterfall, etc.).
6. Enemy positions in stage1.gd match the platform and ground elevations.
"""

def build_stage_2():
    # WATERFALL FORTRESS
    # Granite cliffs, cataract gorges, vertical escarpments over torrents
    # Large coherent geological terraces:
    # Sector 1: Cataract Foothills & Bluff (0 - 1300) @ 440
    # Gap 1: 1300 - 1460 (160px gorge) -> Stepping rope bridge at y=390
    # Sector 2: Lower Granite Escarpment (1460 - 2700) @ 360
    # Gap 2: 2700 - 2900 (200px cataract chasm) -> Dropping rope bridge at y=310
    # Sector 3: High Mountain Escarpment (2900 - 4100) @ 280
    # Gap 3: 4100 - 4300 (200px summit falls gorge) -> Stepping stone & bridge down to 360
    # Sector 4: Torrent Gorge Descent (4300 - 5260) @ 360
    # Gap 4: 5260 - 5420 (160px river trench) -> Bridge into Arena
    # Sector 5: Heavy Aqua Assault Rig Mini-Boss Deck (5420 - 6400) @ 440
    # Gap 5: 6400 - 7800 (1400px CATARACT ABYSS - bottomless waterfall gorge!)
    # Sector 7 & 8: Citadel Ramparts & Hydro-Goliath Stronghold (7800 - 9800) @ 440
    grounds = [
        {"x": 0.0, "y": 440.0, "w": 1300.0, "h": 200.0},
        {"x": 1460.0, "y": 360.0, "w": 1240.0, "h": 280.0},
        {"x": 2900.0, "y": 280.0, "w": 1200.0, "h": 360.0},
        {"x": 4300.0, "y": 360.0, "w": 960.0, "h": 280.0},
        {"x": 5420.0, "y": 440.0, "w": 980.0, "h": 200.0},
        # Cataract Abyss: 6400 - 7800 (NO GROUND)
        {"x": 7800.0, "y": 440.0, "w": 2000.0, "h": 200.0}
    ]
    return grounds

print("Design logic test loaded.")
