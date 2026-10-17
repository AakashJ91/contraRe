"""
Script to construct situation-based platforms for all 8 stages and update level_maps.gd.
"""

def generate_stage_platforms():
    stages = {}
    
    # -------------------------------------------------------------------------
    # STAGE 1: JUNGLE PERIMETER
    # -------------------------------------------------------------------------
    # Sector 1: [0, 1100] @ 440
    # Gap 1: 1100-1240
    # Sector 2: [1240, 2440] @ 440
    # Gap 2: 2440-2580
    # Sector 3: [2580, 3780] @ 440
    # Gap 3: 3780-3920
    # Sector 4: [3920, 5120] @ 440
    # Gap 4: 5120-5260
    # Sector 5: [5260, 6220] @ 440
    # Gap 5 (Abyss): 6220-7720
    # Sector 7-8: [7720, 9800] @ 440
    stages[1] = [
        # Sector 1: Beach Landing (0 - 1100)
        {"rect": "Rect2(240.0, 360.0, 180.0, 16.0)", "type": "PlatformType.TURF", "variant": '"wedge_left"'}, # Leading up to Powerup 1 (330, 358)
        {"rect": "Rect2(480.0, 280.0, 200.0, 16.0)", "type": "PlatformType.TURF", "variant": '"small"'},      # Lookout over beach patrol
        {"rect": "Rect2(780.0, 350.0, 190.0, 16.0)", "type": "PlatformType.TURF", "variant": '"default"'},    # Turret flank
        {"rect": "Rect2(1050.0, 370.0, 180.0, 16.0)", "type": "PlatformType.TURF", "variant": '"wedge_right"'}, # STEPPING BRIDGE 1: Navigates across River Gorge 1 (1100 - 1240) to Sector 2!
        
        # Sector 2: Outer Fortress Perimeter (1240 - 2440)
        {"rect": "Rect2(1460.0, 364.0, 180.0, 16.0)", "type": "PlatformType.TURF", "variant": '"default"'},   # Sniper 2 (1550, 364)
        {"rect": "Rect2(1620.0, 280.0, 190.0, 16.0)", "type": "PlatformType.GIRDER"},                          # High gantry directly under Powerup 2 (1700, 278)
        {"rect": "Rect2(1950.0, 220.0, 170.0, 16.0)", "type": "PlatformType.HIGH_PERCH"},                     # High perimeter beacon mast
        {"rect": "Rect2(2180.0, 320.0, 160.0, 16.0)", "type": "PlatformType.TURF", "variant": '"small"'},      # Bunker approach
        {"rect": "Rect2(2390.0, 370.0, 180.0, 16.0)", "type": "PlatformType.TURF", "variant": '"wedge_left"'}, # STEPPING BRIDGE 2: Navigates across Chasm 2 (2440 - 2580) to Sector 3!
        
        # Sector 3: Jungle Ravine & Catwalks (2580 - 3780)
        {"rect": "Rect2(2720.0, 344.0, 180.0, 16.0)", "type": "PlatformType.TURF", "variant": '"default"'},   # Sniper 4 (2800, 344)
        {"rect": "Rect2(2960.0, 260.0, 190.0, 16.0)", "type": "PlatformType.GIRDER"},                          # Gantry holding Powerup 3 (3050, 258)
        {"rect": "Rect2(3390.0, 204.0, 180.0, 16.0)", "type": "PlatformType.HIGH_PERCH"},                     # High Canopy Nest for Sniper 5 (3480, 204)
        {"rect": "Rect2(3580.0, 310.0, 160.0, 16.0)", "type": "PlatformType.TURF", "variant": '"thin"'},       # Descent towards ravine edge
        {"rect": "Rect2(3730.0, 365.0, 180.0, 16.0)", "type": "PlatformType.TURF", "variant": '"wedge_right"'}, # STEPPING BRIDGE 3: Navigates across Chasm 3 (3780 - 3920) to Sector 4!
        
        # Sector 4: Jungle Canopy & Riverbank (3920 - 5120)
        {"rect": "Rect2(4110.0, 354.0, 180.0, 16.0)", "type": "PlatformType.TURF", "variant": '"default"'},   # Sniper 6 (4200, 354)
        {"rect": "Rect2(4290.0, 270.0, 190.0, 16.0)", "type": "PlatformType.TURF", "variant": '"wide"'},      # Directly under Powerup 4 (4380, 268)
        {"rect": "Rect2(4660.0, 204.0, 180.0, 16.0)", "type": "PlatformType.HIGH_PERCH"},                     # High Canopy Nest for Sniper 7 (4750, 204)
        {"rect": "Rect2(4940.0, 320.0, 160.0, 16.0)", "type": "PlatformType.TURF", "variant": '"small"'},      # Trench approach
        {"rect": "Rect2(5070.0, 370.0, 180.0, 16.0)", "type": "PlatformType.TURF", "variant": '"wedge_left"'}, # STEPPING BRIDGE 4: Navigates across Trench 4 (5120 - 5260) to Sector 5 Battery!
        
        # Sector 5: Heavy Fortress Battery & Mini-Boss Arena (5260 - 6220)
        {"rect": "Rect2(5360.0, 354.0, 180.0, 16.0)", "type": "PlatformType.TURF", "variant": '"default"'},   # Sniper 8 (5450, 354)
        {"rect": "Rect2(5600.0, 270.0, 200.0, 16.0)", "type": "PlatformType.GIRDER"},                          # Gantry holding Powerup 5 (5700, 268)
        {"rect": "Rect2(5920.0, 220.0, 180.0, 16.0)", "type": "PlatformType.HIGH_PERCH"},                     # Mini-boss observation crane
        {"rect": "Rect2(6120.0, 340.0, 160.0, 16.0)", "type": "PlatformType.TURF", "variant": '"small"'},      # Runway to Abyss Leap
        
        # Sector 6: Post-Mini-Boss Falling Abyss (6220 - 7720) Pure Bottomless Chasm!
        {"rect": "Rect2(6260.0, 360.0, 130.0, 16.0)", "type": "PlatformType.TURF", "variant": '"thin"', "is_drop": "true", "drop_delay": "0.45", "respawn_time": "2.8"},
        # Level 1: High Skyway Route (y = 190 - 270)
        {"rect": "Rect2(6430.0, 270.0, 140.0, 16.0)", "type": "PlatformType.TURF", "variant": '"small"', "is_drop": "true", "drop_delay": "0.45", "respawn_time": "2.8"},
        {"rect": "Rect2(6610.0, 215.0, 140.0, 16.0)", "type": "PlatformType.TURF", "variant": '"thin"', "is_drop": "true", "drop_delay": "0.45", "respawn_time": "2.8"},
        {"rect": "Rect2(6800.0, 190.0, 150.0, 16.0)", "type": "PlatformType.TURF", "variant": '"wide"', "is_drop": "true", "drop_delay": "0.45", "respawn_time": "2.8"},
        {"rect": "Rect2(7000.0, 210.0, 140.0, 16.0)", "type": "PlatformType.TURF", "variant": '"small"', "is_drop": "true", "drop_delay": "0.45", "respawn_time": "2.8"},
        {"rect": "Rect2(7200.0, 250.0, 140.0, 16.0)", "type": "PlatformType.TURF", "variant": '"wedge_right"', "is_drop": "true", "drop_delay": "0.45", "respawn_time": "2.8"},
        {"rect": "Rect2(7400.0, 290.0, 130.0, 16.0)", "type": "PlatformType.TURF", "variant": '"thin"', "is_drop": "true", "drop_delay": "0.45", "respawn_time": "2.8"},
        # Level 2: Mid Terrace Route (y = 300 - 330)
        {"rect": "Rect2(6510.0, 330.0, 140.0, 16.0)", "type": "PlatformType.TURF", "variant": '"default"', "is_drop": "true", "drop_delay": "0.50", "respawn_time": "2.8"},
        {"rect": "Rect2(6710.0, 310.0, 140.0, 16.0)", "type": "PlatformType.TURF", "variant": '"wide"', "is_drop": "true", "drop_delay": "0.50", "respawn_time": "2.8"},
        {"rect": "Rect2(6910.0, 304.0, 140.0, 16.0)", "type": "PlatformType.TURF", "variant": '"default"', "is_drop": "true", "drop_delay": "0.50", "respawn_time": "2.8"}, # Holds Sniper 9 (6800-6910)
        {"rect": "Rect2(7110.0, 310.0, 140.0, 16.0)", "type": "PlatformType.TURF", "variant": '"wedge_left"', "is_drop": "true", "drop_delay": "0.50", "respawn_time": "2.8"},
        {"rect": "Rect2(7320.0, 330.0, 130.0, 16.0)", "type": "PlatformType.TURF", "variant": '"default"', "is_drop": "true", "drop_delay": "0.50", "respawn_time": "2.8"},
        # Level 3: Lower River Crag Route (y = 385 - 395)
        {"rect": "Rect2(6410.0, 395.0, 130.0, 16.0)", "type": "PlatformType.TURF", "variant": '"crag"', "is_drop": "true", "drop_delay": "0.55", "respawn_time": "2.8"},
        {"rect": "Rect2(6600.0, 390.0, 140.0, 16.0)", "type": "PlatformType.TURF", "variant": '"crag"', "is_drop": "true", "drop_delay": "0.55", "respawn_time": "2.8"},
        {"rect": "Rect2(6800.0, 390.0, 140.0, 16.0)", "type": "PlatformType.TURF", "variant": '"crag"', "is_drop": "true", "drop_delay": "0.55", "respawn_time": "2.8"},
        {"rect": "Rect2(7000.0, 395.0, 140.0, 16.0)", "type": "PlatformType.TURF", "variant": '"crag"', "is_drop": "true", "drop_delay": "0.55", "respawn_time": "2.8"},
        {"rect": "Rect2(7200.0, 390.0, 140.0, 16.0)", "type": "PlatformType.TURF", "variant": '"crag"', "is_drop": "true", "drop_delay": "0.55", "respawn_time": "2.8"},
        {"rect": "Rect2(7400.0, 390.0, 140.0, 16.0)", "type": "PlatformType.TURF", "variant": '"crag"', "is_drop": "true", "drop_delay": "0.55", "respawn_time": "2.8"},
        # Final Leap into Fortress Gate
        {"rect": "Rect2(7570.0, 360.0, 140.0, 16.0)", "type": "PlatformType.TURF", "variant": '"small"', "is_drop": "true", "drop_delay": "0.50", "respawn_time": "2.8"},
        
        # Sector 7 & 8: Fortress Approach & Boss Arena (7720 - 9800)
        {"rect": "Rect2(7910.0, 334.0, 180.0, 16.0)", "type": "PlatformType.TURF", "variant": '"wedge_left"'}, # Sniper 10 (8000, 334)
        {"rect": "Rect2(8110.0, 250.0, 180.0, 16.0)", "type": "PlatformType.GIRDER"},                          # Directly under Powerup 6 (8200, 248)
        {"rect": "Rect2(8460.0, 334.0, 180.0, 16.0)", "type": "PlatformType.TURF", "variant": '"wide"'},       # Sniper 11 (8550, 334)
        {"rect": "Rect2(8840.0, 330.0, 180.0, 16.0)", "type": "PlatformType.HIGH_PERCH"}                      # Fortress Core Gate Perch
    ]
    
    return stages

print("Stage 1 test generated successfully.")
