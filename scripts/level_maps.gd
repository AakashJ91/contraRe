class_name LevelMaps
extends RefCounted

# =============================================================================
# CONTRA RE - TACTICAL LEVEL MAP DATABASE & SCHEMATIC RENDERER
# =============================================================================

const LEVEL_MIN_X: float = 0.0
const LEVEL_MAX_X: float = 9800.0
const BOSS_TRIGGER_X: float = 8800.0

enum PlatformType {
	TURF,
	GIRDER,
	ROPE_BRIDGE,
	HIGH_PERCH,
	ICE_SLAB,
	LAVA_GRATE,
	ENERGY_BARRIER,
	TECH_CATWALK,
	BIO_RIB,
	WATERFALL_LEDGE
}

static func get_map_data(stage_id: int) -> Dictionary:
	var s_id := clampi(stage_id, 1, 8)
	var custom_path := "user://custom_levels/stage_%d.json" % s_id
	if FileAccess.file_exists(custom_path):
		var custom_data := load_custom_stage_data(custom_path, s_id)
		if not custom_data.is_empty():
			return custom_data
	return get_default_map_data(s_id)

static func load_custom_stage_data(file_path: String, stage_id: int) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}
	var json_str := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	if json.parse(json_str) != OK or not (json.data is Dictionary):
		return {}
	
	var data: Dictionary = json.data
	var def := get_default_map_data(stage_id)
	
	if data.has("ground_segments") and data["ground_segments"] is Array:
		var custom_g: Array[Rect2] = []
		for g in data["ground_segments"]:
			custom_g.append(Rect2(g["x"], g["y"], g["w"], g["h"]))
		def["ground_segments"] = custom_g
	
	if data.has("platforms") and data["platforms"] is Array:
		var custom_p: Array[Dictionary] = []
		for p in data["platforms"]:
			var p_dict: Dictionary = {
				"rect": Rect2(p["x"], p["y"], p["w"], p["h"]),
				"type": p.get("type", 0),
				"is_drop": p.get("is_drop", false),
				"variant": p.get("variant", "default")
			}
			if p.get("is_drop", false):
				p_dict["drop_delay"] = p.get("drop_delay", 0.45)
				p_dict["respawn_time"] = p.get("respawn_time", 2.8)
			custom_p.append(p_dict)
		def["platforms"] = custom_p
	
	if data.has("enemies"):
		def["custom_enemies"] = data["enemies"]
	if data.has("powerups"):
		def["custom_powerups"] = data["powerups"]
	if data.has("bg_props"):
		def["custom_bg_props"] = data["bg_props"]
	
	return def

static func has_custom_stage_data(stage_id: int) -> bool:
	return FileAccess.file_exists("user://custom_levels/stage_%d.json" % clampi(stage_id, 1, 8))

static func delete_custom_stage_data(stage_id: int) -> void:
	var path := "user://custom_levels/stage_%d.json" % clampi(stage_id, 1, 8)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

static func get_default_map_data(stage_id: int) -> Dictionary:
	var s_id := clampi(stage_id, 1, 8)
	var data := {
		"id": s_id,
		"name": "",
		"sector": "",
		"theme": "",
		"diff": "",
		"boss": "",
		"hazard": "",
		"intel": "",
		"primary_color": Color.WHITE,
		"accent_color": Color.WHITE,
		"ground_segments": [] as Array[Rect2],
		"platforms": [] as Array[Dictionary],
	}
	
	match s_id:
		1:
			data["name"] = "JUNGLE PERIMETER"
			data["sector"] = "SECTOR 01 // GALUGA COAST"
			data["theme"] = "TROPICAL CANOPY & RIVERBANK"
			data["diff"] = "NORMAL"
			data["boss"] = "WALL DEFENSE CORE"
			data["hazard"] = "RIVER CHASMS & JUNGLE TURF CRAGS"
			data["intel"] = "Infiltrate perimeter via coastline sandbars. Destroy the Titan Goliath mech at Sector 5, leap across river chasms using floating turf ledges and eliminate outer fortress turrets."
			data["primary_color"] = Color(0.25, 0.75, 0.35)
			data["accent_color"] = Color(0.95, 0.85, 0.20)
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 1100.0, 200.0),      # Sector 1: Landing Beach (0 - 1100)
				Rect2(1240.0, 440.0, 1200.0, 200.0),    # Sector 2: Outer Fortress Perimeter (1240 - 2440)
				Rect2(2580.0, 440.0, 1200.0, 200.0),    # Sector 3: Jungle Ravine & Catwalks (2580 - 3780)
				Rect2(3920.0, 440.0, 1200.0, 200.0),    # Sector 4: Jungle Canopy & Riverbank (3920 - 5120)
				Rect2(5260.0, 440.0, 960.0, 200.0),     # Sector 5: Heavy Fortress Battery & Mini-Boss Arena (5260 - 6220)
				# SECTOR 6 IS A PURE BOTTOMLESS ABYSS (6220 - 7720): NO GROUND!
				Rect2(7720.0, 440.0, 2080.0, 200.0)     # Sector 7 & 8: Fortress Approach & Boss Arena (7720 - 9800)
			]
			data["platforms"] = [
				# Sector 1: Landing Beach (0 - 1100)
				{"rect": Rect2(240.0, 360.0, 180.0, 16.0), "type": PlatformType.TURF, "variant": "wedge_left"}, # Perch for Powerup 1 (330, 358)
				{"rect": Rect2(480.0, 280.0, 200.0, 16.0), "type": PlatformType.TURF, "variant": "small"},      # Lookout overlooking beach
				{"rect": Rect2(780.0, 350.0, 190.0, 16.0), "type": PlatformType.TURF, "variant": "default"},    # Flanking ledge
				{"rect": Rect2(1050.0, 370.0, 180.0, 16.0), "type": PlatformType.TURF, "variant": "wedge_right"}, # NAVIGATE: Bridge across River Gorge 1 (1100-1240) to Sector 2
				
				# Sector 2: Outer Fortress Perimeter (1240 - 2440)
				{"rect": Rect2(1460.0, 364.0, 180.0, 16.0), "type": PlatformType.TURF, "variant": "default"},   # Sniper 2 (1550, 364)
				{"rect": Rect2(1620.0, 280.0, 180.0, 16.0), "type": PlatformType.GIRDER},                          # High Gantry under Powerup 2 (1700, 278)
				{"rect": Rect2(1950.0, 215.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                     # High perimeter beacon mast
				{"rect": Rect2(2180.0, 320.0, 160.0, 16.0), "type": PlatformType.TURF, "variant": "small"},      # Bunker approach
				{"rect": Rect2(2390.0, 370.0, 180.0, 16.0), "type": PlatformType.TURF, "variant": "wedge_left"}, # NAVIGATE: Bridge across Chasm 2 (2440-2580) to Sector 3
				
				# Sector 3: Jungle Ravine & Catwalks (2580 - 3780)
				{"rect": Rect2(2720.0, 344.0, 180.0, 16.0), "type": PlatformType.TURF, "variant": "default"},   # Sniper 4 (2800, 344)
				{"rect": Rect2(2960.0, 260.0, 190.0, 16.0), "type": PlatformType.GIRDER},                          # Gantry holding Powerup 3 (3050, 258)
				{"rect": Rect2(3390.0, 204.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},                     # High Canopy Nest for Sniper 5 (3480, 204)
				{"rect": Rect2(3580.0, 310.0, 160.0, 16.0), "type": PlatformType.TURF, "variant": "thin"},       # Descent toward ravine
				{"rect": Rect2(3730.0, 365.0, 180.0, 16.0), "type": PlatformType.TURF, "variant": "wedge_right"}, # NAVIGATE: Bridge across Chasm 3 (3780-3920) to Sector 4
				
				# Sector 4: Jungle Canopy & Riverbank (3920 - 5120)
				{"rect": Rect2(4110.0, 354.0, 180.0, 16.0), "type": PlatformType.TURF, "variant": "default"},   # Sniper 6 (4200, 354)
				{"rect": Rect2(4290.0, 270.0, 190.0, 16.0), "type": PlatformType.TURF, "variant": "wide"},      # Directly under Powerup 4 (4380, 268)
				{"rect": Rect2(4660.0, 204.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},                     # High Canopy Nest for Sniper 7 (4750, 204)
				{"rect": Rect2(4940.0, 320.0, 160.0, 16.0), "type": PlatformType.TURF, "variant": "small"},      # Trench approach
				{"rect": Rect2(5070.0, 370.0, 180.0, 16.0), "type": PlatformType.TURF, "variant": "wedge_left"}, # NAVIGATE: Bridge across Trench 4 (5120-5260) to Sector 5
				
				# Sector 5: Heavy Fortress Battery & Mini-Boss Arena (5260 - 6220)
				{"rect": Rect2(5360.0, 354.0, 180.0, 16.0), "type": PlatformType.TURF, "variant": "default"},   # Sniper 8 (5450, 354)
				{"rect": Rect2(5600.0, 270.0, 200.0, 16.0), "type": PlatformType.GIRDER},                          # Gantry holding Powerup 5 (5700, 268)
				{"rect": Rect2(5920.0, 215.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},                     # Mini-boss observation crane
				{"rect": Rect2(6120.0, 340.0, 160.0, 16.0), "type": PlatformType.TURF, "variant": "small"},      # Runway to Abyss Leap
				
				# Sector 6: Post-Mini-Boss Falling Abyss (6220 - 7720) Pure Bottomless Chasm!
				{"rect": Rect2(6260.0, 360.0, 130.0, 16.0), "type": PlatformType.TURF, "variant": "thin", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8},
				# Level 1: High Skyway Route (y = 190 - 270)
				{"rect": Rect2(6430.0, 270.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "small", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8},
				{"rect": Rect2(6610.0, 215.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "thin", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8},
				{"rect": Rect2(6800.0, 190.0, 150.0, 16.0), "type": PlatformType.TURF, "variant": "wide", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8},
				{"rect": Rect2(7000.0, 210.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "small", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8},
				{"rect": Rect2(7200.0, 250.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "wedge_right", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8},
				{"rect": Rect2(7400.0, 290.0, 130.0, 16.0), "type": PlatformType.TURF, "variant": "thin", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8},
				# Level 2: Mid Terrace Route (y = 300 - 330)
				{"rect": Rect2(6510.0, 330.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "default", "is_drop": true, "drop_delay": 0.50, "respawn_time": 2.8},
				{"rect": Rect2(6710.0, 310.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "wide", "is_drop": true, "drop_delay": 0.50, "respawn_time": 2.8},
				{"rect": Rect2(6910.0, 304.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "default", "is_drop": true, "drop_delay": 0.50, "respawn_time": 2.8}, # Holds Sniper 9
				{"rect": Rect2(7110.0, 310.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "wedge_left", "is_drop": true, "drop_delay": 0.50, "respawn_time": 2.8},
				{"rect": Rect2(7320.0, 330.0, 130.0, 16.0), "type": PlatformType.TURF, "variant": "default", "is_drop": true, "drop_delay": 0.50, "respawn_time": 2.8},
				# Level 3: Lower River Crag Route (y = 385 - 395)
				{"rect": Rect2(6410.0, 395.0, 130.0, 16.0), "type": PlatformType.TURF, "variant": "crag", "is_drop": true, "drop_delay": 0.55, "respawn_time": 2.8},
				{"rect": Rect2(6600.0, 390.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "crag", "is_drop": true, "drop_delay": 0.55, "respawn_time": 2.8},
				{"rect": Rect2(6800.0, 390.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "crag", "is_drop": true, "drop_delay": 0.55, "respawn_time": 2.8},
				{"rect": Rect2(7000.0, 395.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "crag", "is_drop": true, "drop_delay": 0.55, "respawn_time": 2.8},
				{"rect": Rect2(7200.0, 390.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "crag", "is_drop": true, "drop_delay": 0.55, "respawn_time": 2.8},
				{"rect": Rect2(7400.0, 390.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "crag", "is_drop": true, "drop_delay": 0.55, "respawn_time": 2.8},
				# Final Leap into Fortress Gate
				{"rect": Rect2(7570.0, 360.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "small", "is_drop": true, "drop_delay": 0.50, "respawn_time": 2.8},
				
				# Sector 7 & 8: Fortress Approach & Boss Arena (7720 - 9800)
				{"rect": Rect2(7910.0, 334.0, 180.0, 16.0), "type": PlatformType.TURF, "variant": "wedge_left"}, # Sniper 10 (8000, 334)
				{"rect": Rect2(8110.0, 250.0, 180.0, 16.0), "type": PlatformType.GIRDER},                          # Directly under Powerup 6 (8200, 248)
				{"rect": Rect2(8460.0, 334.0, 180.0, 16.0), "type": PlatformType.TURF, "variant": "wide"},       # Sniper 11 (8550, 334)
				{"rect": Rect2(8840.0, 330.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH}                      # Fortress Core Gate Perch
			]
		2:
			data["name"] = "WATERFALL FORTRESS"
			data["sector"] = "SECTOR 02 // CATARACT CHASM"
			data["theme"] = "TORRENTIAL CLIFFSIDE"
			data["diff"] = "HARD"
			data["boss"] = "HYDRO-GOLIATH MECH"
			data["hazard"] = "RUSHING WATERFALLS & CLIFF PITS"
			data["intel"] = "Ascend vertical granite escarpments over raging torrents. Destroy the Aqua Assault Rig at Sector 5, traverse cataract chasms and bring down the Hydro-Goliath Mech."
			data["primary_color"] = Color(0.20, 0.65, 0.95)
			data["accent_color"] = Color(0.60, 0.90, 1.0)
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 400.0, 200.0),
				Rect2(480.0, 360.0, 360.0, 280.0),
				Rect2(930.0, 280.0, 380.0, 360.0),
				Rect2(1400.0, 200.0, 450.0, 440.0),
				Rect2(1950.0, 300.0, 370.0, 340.0),
				Rect2(2420.0, 390.0, 350.0, 250.0),
				Rect2(2880.0, 470.0, 440.0, 180.0),
				Rect2(3430.0, 370.0, 360.0, 270.0),
				Rect2(3890.0, 270.0, 400.0, 370.0),
				Rect2(4390.0, 210.0, 420.0, 430.0),
				Rect2(4920.0, 330.0, 360.0, 310.0),
				Rect2(5360.0, 440.0, 940.0, 200.0),
				Rect2(6410.0, 340.0, 360.0, 300.0),
				Rect2(6880.0, 220.0, 420.0, 420.0),
				Rect2(7420.0, 350.0, 360.0, 290.0),
				Rect2(7880.0, 280.0, 400.0, 360.0),
				Rect2(8380.0, 360.0, 370.0, 280.0),
				Rect2(8820.0, 440.0, 1000.0, 200.0)
			]
			data["platforms"] = [
				# Sector 1: Cataract Foothills & Bluff Ascent (0 - 1310)
				{"rect": Rect2(180.0, 360.0, 160.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "ledge"},    # Sniper 1 (240, 370)
				{"rect": Rect2(230.0, 290.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                            # Powerup 1 (300, 290) & Sniper 2
				{"rect": Rect2(365.0, 400.0, 115.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "crag"},     # NAVIGATE: Stepping stone crag across Bluff Gap 1 (400-480)
				{"rect": Rect2(560.0, 270.0, 180.0, 16.0), "type": PlatformType.ROPE_BRIDGE},                           # Hanging gorge catwalk
				{"rect": Rect2(650.0, 200.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                            # Sniper 3 (720, 200)
				{"rect": Rect2(805.0, 320.0, 125.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "crag"},     # NAVIGATE: Escarpment rock step across Gap 2 (840-930)
				{"rect": Rect2(1010.0, 200.0, 170.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "wide"},    # Escarpment ascent stone shelf
				{"rect": Rect2(1110.0, 140.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 4 (1180, 140)
				{"rect": Rect2(1275.0, 240.0, 125.0, 16.0), "type": PlatformType.ROPE_BRIDGE},                          # NAVIGATE: Bridge across Gorge to Summit (1310-1400)
				
				# Sector 2: Pinnacle Summit & Gorge Descent (1400 - 2770)
				{"rect": Rect2(1410.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Summit Perch: Powerup 2 (1480, 130) & Sniper 5
				{"rect": Rect2(1640.0, 130.0, 160.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "ledge"},   # Flanking cliff rock shelf
				{"rect": Rect2(1850.0, 250.0, 135.0, 16.0), "type": PlatformType.ROPE_BRIDGE},                          # NAVIGATE: Stepped bridge descending Summit Gap (1850-1950)
				{"rect": Rect2(2100.0, 150.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # High look out for Sniper 6 (2180, 150)
				{"rect": Rect2(2320.0, 345.0, 135.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "crag"},    # NAVIGATE: Stepping stone descending Gap (2320-2420)
				{"rect": Rect2(2580.0, 210.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 7 (2660, 210)
				{"rect": Rect2(2770.0, 430.0, 145.0, 16.0), "type": PlatformType.ROPE_BRIDGE, "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8}, # NAVIGATE: Dropping rope bridge into deep basin (2770-2880)
				
				# Sector 3: Sunken Cataract Basin & Rapid Escalation (2880 - 4290)
				{"rect": Rect2(2980.0, 300.0, 170.0, 16.0), "type": PlatformType.ROPE_BRIDGE},                          # High Basin Skyway: Powerup 3 (3060, 300)
				{"rect": Rect2(3140.0, 220.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 8 (3220, 220)
				{"rect": Rect2(3285.0, 420.0, 145.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "crag"},    # NAVIGATE: Stepping stone climbing out of 470 basin to 370 (3320-3430)
				{"rect": Rect2(3580.0, 200.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 9 (3660, 200)
				{"rect": Rect2(3755.0, 320.0, 135.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "crag"},    # NAVIGATE: Escalation rock step across Gap (3790-3890)
				{"rect": Rect2(4060.0, 130.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # High Waterfall Spire Sniper 10 (4140, 130)
				{"rect": Rect2(4255.0, 240.0, 135.0, 16.0), "type": PlatformType.ROPE_BRIDGE},                          # NAVIGATE: Bridge onto High Torrent Ridge (4290-4390)
				
				# Sector 4: Torrent Ridge & Approach (4390 - 5280)
				{"rect": Rect2(4390.0, 140.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Ridge Lookout: Powerup 4 (4460, 140) & Sniper 11
				{"rect": Rect2(4620.0, 150.0, 160.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "wide"},    # Torrent ridge stone terrace
				{"rect": Rect2(4810.0, 270.0, 145.0, 16.0), "type": PlatformType.ROPE_BRIDGE},                          # NAVIGATE: Stepping bridge down from 210 to 330 (4810-4920)
				{"rect": Rect2(4930.0, 240.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 12 (5000, 240)
				{"rect": Rect2(5280.0, 385.0, 115.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "ledge"},   # NAVIGATE: Terrace rock step into Mini-Boss Arena (5280-5360)
				
				# Sector 5: Mini-Boss Arena Scaffoldings & Catwalks (5360 - 6300)
				{"rect": Rect2(5500.0, 260.0, 200.0, 16.0), "type": PlatformType.ROPE_BRIDGE},                          # High fighting gantry: Powerup 5 (5580, 260)
				{"rect": Rect2(5600.0, 170.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 13 (5680, 170)
				{"rect": Rect2(5840.0, 320.0, 180.0, 16.0), "type": PlatformType.GIRDER},                               # Defense rig girder
				{"rect": Rect2(6265.0, 390.0, 145.0, 16.0), "type": PlatformType.ROPE_BRIDGE, "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8}, # NAVIGATE: Bridge exiting arena (6300-6410)
				
				# Sector 6: Escalation Cliff, Cataract Spire & Falls Gorge (6410 - 7780)
				{"rect": Rect2(6570.0, 180.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Cataract Spire Sniper 14 (6650, 180)
				{"rect": Rect2(6735.0, 280.0, 145.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "crag"},    # NAVIGATE: Stepped rock crag climbing to 220 (6770-6880)
				{"rect": Rect2(6870.0, 140.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Spire Summit: Powerup 6 (6950, 140) & Sniper 15
				{"rect": Rect2(7300.0, 285.0, 155.0, 16.0), "type": PlatformType.ROPE_BRIDGE},                          # NAVIGATE: Stepped bridge descending Gorge (7300-7420)
				{"rect": Rect2(7560.0, 190.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 16 (7640, 190)
				{"rect": Rect2(7745.0, 315.0, 135.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "ledge"},   # NAVIGATE: Slate ledge onto Citadel Ramparts (7780-7880)
				
				# Sector 7 & 8: Citadel Ramparts & Boss Stronghold (7880 - 9820)
				{"rect": Rect2(7870.0, 200.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 17 (7950, 200)
				{"rect": Rect2(8050.0, 210.0, 170.0, 16.0), "type": PlatformType.ROPE_BRIDGE},                          # Powerup 7 (8130, 210)
				{"rect": Rect2(8280.0, 320.0, 135.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "crag"},    # NAVIGATE: Rampart rock step (8280-8380)
				{"rect": Rect2(8540.0, 200.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 18 (8620, 200)
				{"rect": Rect2(8750.0, 400.0, 105.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "ledge"},   # NAVIGATE: Descent stone ledge to Boss Arena (8750-8820)
				{"rect": Rect2(9000.0, 270.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Hydro-Goliath Lookout: Sniper 19 (9080, 270)
				{"rect": Rect2(9320.0, 210.0, 180.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "wide"}     # Final Arena High Vantage Stone Shelf
			]
		3:
			data["name"] = "ALIEN HIVE BIO-CAVERN"
			data["sector"] = "SECTOR 03 // SUBTERRANEAN HIVE"
			data["theme"] = "ORGANIC FLESH CAVERNS"
			data["diff"] = "HARD"
			data["boss"] = "GIGA BIO-HEART"
			data["hazard"] = "ORGANIC ACID PITS & CHITIN CHASM"
			data["intel"] = "Sub-surface breach into the organic nest. Slay the Chitin Behemoth at Sector 5, navigate undulating visceral chambers and rupture the throbbing bio-heart chamber."
			data["primary_color"] = Color(0.85, 0.25, 0.40)
			data["accent_color"] = Color(1.0, 0.60, 0.70)
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 390.0, 200.0),
				Rect2(470.0, 350.0, 360.0, 290.0),
				Rect2(910.0, 260.0, 400.0, 380.0),
				Rect2(1390.0, 200.0, 440.0, 440.0),
				Rect2(1920.0, 300.0, 370.0, 340.0),
				Rect2(2380.0, 390.0, 360.0, 250.0),
				Rect2(2840.0, 470.0, 440.0, 180.0),
				Rect2(3380.0, 360.0, 370.0, 280.0),
				Rect2(3840.0, 260.0, 410.0, 380.0),
				Rect2(4340.0, 200.0, 440.0, 440.0),
				Rect2(4870.0, 320.0, 390.0, 320.0),
				Rect2(5350.0, 440.0, 950.0, 200.0),
				Rect2(6400.0, 330.0, 370.0, 310.0),
				Rect2(6860.0, 220.0, 430.0, 420.0),
				Rect2(7380.0, 330.0, 370.0, 310.0),
				Rect2(7840.0, 270.0, 410.0, 370.0),
				Rect2(8340.0, 360.0, 380.0, 280.0),
				Rect2(8810.0, 440.0, 1010.0, 200.0)
			]
			data["platforms"] = [
				# Sector 1: Organic Cavern Entry & Acid Pit Escalation (0 - 1390)
				{"rect": Rect2(160.0, 360.0, 160.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "carapace"},
				{"rect": Rect2(280.0, 280.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                            # Powerup 1 (360, 280) & Bio-Sniper 1
				{"rect": Rect2(355.0, 395.0, 115.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "shelf", "is_drop": true, "drop_delay": 0.40, "respawn_time": 2.8}, # NAVIGATE: Drop rib across Acid Pit 1 (390-470)
				{"rect": Rect2(550.0, 270.0, 170.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "wide"},
				{"rect": Rect2(680.0, 190.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                            # Sniper 2 (760, 190) above egg sac
				{"rect": Rect2(795.0, 305.0, 115.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "rib"},                               # NAVIGATE: Stepping rib climbing to 260 across Gap 2 (830-910)
				{"rect": Rect2(1010.0, 190.0, 170.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "carapace"},
				{"rect": Rect2(1160.0, 130.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 3 (1240, 130) on chitin spire
				{"rect": Rect2(1275.0, 230.0, 115.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "shelf"},                              # NAVIGATE: Rib onto High Chamber (1310-1390)
				
				# Sector 2: Spore Chamber Summit & Visceral Descent (1390 - 2840)
				{"rect": Rect2(1470.0, 120.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Spore Summit: Powerup 2 (1550, 120) & Sniper 4
				{"rect": Rect2(1650.0, 140.0, 160.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "wide"},
				{"rect": Rect2(1830.0, 250.0, 125.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "rib", "is_drop": true, "drop_delay": 0.40, "respawn_time": 2.8}, # NAVIGATE: Fleshy drop rib descending (1830-1920)
				{"rect": Rect2(2160.0, 140.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # High bio-stalk Sniper 5 (2240, 140)
				{"rect": Rect2(2290.0, 345.0, 125.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "carapace"},                              # NAVIGATE: Stepped rib descending (2290-2380)
				{"rect": Rect2(2640.0, 220.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 6 (2720, 220)
				{"rect": Rect2(2740.0, 430.0, 135.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "shelf", "is_drop": true, "drop_delay": 0.40, "respawn_time": 2.8}, # NAVIGATE: Dropping rib into Deep Acid Trench (2740-2840)
				
				# Sector 3: Sunken Acid Basin & Organic Escalation (2840 - 4340)
				# High Bio-Bypass route across 470 acid ground
				{"rect": Rect2(2920.0, 380.0, 160.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "wide"},                              # Bypass rib level 1
				{"rect": Rect2(3060.0, 290.0, 170.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "rib"},                              # Bypass rib level 2
				{"rect": Rect2(3200.0, 220.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Powerup 3 (3280, 220) & Sniper 7
				{"rect": Rect2(3245.0, 415.0, 135.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "carapace"},                              # NAVIGATE: Stepping rib climbing out of 470 pit (3280-3380)
				{"rect": Rect2(3480.0, 280.0, 160.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "shelf"},
				{"rect": Rect2(3630.0, 190.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 8 (3710, 190)
				{"rect": Rect2(3715.0, 310.0, 125.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "wide", "is_drop": true, "drop_delay": 0.40, "respawn_time": 2.8}, # NAVIGATE: Drop rib climbing to 260 (3750-3840)
				{"rect": Rect2(4100.0, 120.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Bio-Sniper 9 (4180, 120)
				{"rect": Rect2(4215.0, 230.0, 125.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "rib"},                              # NAVIGATE: Rib onto Upper Hive Nest (4250-4340)
				
				# Sector 4: Upper Hive Nest & Approach (4340 - 5350)
				{"rect": Rect2(4420.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Upper Nest Perch: Powerup 4 (4500, 130) & Sniper 10
				{"rect": Rect2(4620.0, 140.0, 160.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "carapace"},
				{"rect": Rect2(4780.0, 260.0, 125.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "shelf", "is_drop": true, "drop_delay": 0.40, "respawn_time": 2.8}, # NAVIGATE: Drop rib descending (4780-4870)
				{"rect": Rect2(5120.0, 240.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 11 (5200, 240)
				{"rect": Rect2(5260.0, 380.0, 125.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "wide"},                              # NAVIGATE: Threshold rib into Chitin Behemoth Arena (5260-5350)
				
				# Sector 5: Chitin Behemoth Mini-Boss Arena (5350 - 6400)
				{"rect": Rect2(5580.0, 260.0, 200.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "rib"},                              # Overhead spine platform: Sniper 12 (5680, 260)
				{"rect": Rect2(5760.0, 340.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Powerup 5 support perch (5840, 440)
				{"rect": Rect2(6265.0, 385.0, 135.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "carapace", "is_drop": true, "drop_delay": 0.40, "respawn_time": 2.8}, # NAVIGATE: Bio-rib exiting arena (6300-6400)
				
				# Sector 6: Undulating Organ Chambers & Spores (6400 - 7840)
				{"rect": Rect2(6630.0, 180.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 13 (6710, 180)
				{"rect": Rect2(6735.0, 275.0, 125.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "shelf"},                              # NAVIGATE: Stepped rib climbing to 220 (6760-6860)
				{"rect": Rect2(6930.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # High Organ Spire: Powerup 6 (7010, 130) & Sniper 14
				{"rect": Rect2(7290.0, 275.0, 125.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "wide", "is_drop": true, "drop_delay": 0.40, "respawn_time": 2.8}, # NAVIGATE: Dropping rib over acid gap (7280-7380)
				{"rect": Rect2(7620.0, 190.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 15 (7700, 190)
				{"rect": Rect2(7715.0, 300.0, 125.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "rib"},                              # NAVIGATE: Spine onto Bio-Heart ramparts (7750-7840)
				
				# Sector 7 & 8: Giga Bio-Heart Approaches & Core (7840 - 9820)
				{"rect": Rect2(7930.0, 200.0, 170.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "carapace"},
				{"rect": Rect2(8250.0, 315.0, 125.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "shelf"},                              # NAVIGATE: Rampart step (8240-8340)
				{"rect": Rect2(8600.0, 200.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Final Powerup 7 Perch (8680, 200) & Bio-Sniper 16
				{"rect": Rect2(8720.0, 400.0, 125.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "wide", "is_drop": true, "drop_delay": 0.40, "respawn_time": 2.8}, # NAVIGATE: Dropping spine into Bio-Heart Core (8720-8810)
				{"rect": Rect2(9080.0, 270.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Living Heart Observation Stalk
				{"rect": Rect2(9340.0, 200.0, 180.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "rib"}                               # Pulsating Chamber Arch
			]
		4:
			data["name"] = "SNOWFIELD TUNDRA"
			data["sector"] = "SECTOR 04 // FROSTBITE RIDGE"
			data["theme"] = "ARCTIC BLIZZARD & PERMAFROST"
			data["diff"] = "EXPERT"
			data["boss"] = "FROSTBITE SIEGE TANK"
			data["hazard"] = "SUB-ZERO GLACIAL CREVASSES"
			data["intel"] = "Traverse gale-force snowfield peaks and icy steel gantries. Crush the Polar Siege Colossus at Sector 5, scale glacial seracs and demolish the entrenched heavy siege crawler."
			data["primary_color"] = Color(0.40, 0.85, 1.0)
			data["accent_color"] = Color(0.85, 0.95, 1.0)
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 390.0, 200.0),
				Rect2(470.0, 350.0, 370.0, 290.0),
				Rect2(920.0, 260.0, 400.0, 380.0),
				Rect2(1410.0, 200.0, 450.0, 440.0),
				Rect2(1950.0, 290.0, 370.0, 350.0),
				Rect2(2410.0, 390.0, 370.0, 250.0),
				Rect2(2870.0, 470.0, 440.0, 180.0),
				Rect2(3410.0, 370.0, 370.0, 270.0),
				Rect2(3870.0, 260.0, 410.0, 380.0),
				Rect2(4370.0, 200.0, 430.0, 440.0),
				Rect2(4890.0, 320.0, 380.0, 320.0),
				Rect2(5360.0, 440.0, 940.0, 200.0),
				Rect2(6400.0, 330.0, 370.0, 310.0),
				Rect2(6860.0, 220.0, 430.0, 420.0),
				Rect2(7380.0, 330.0, 370.0, 310.0),
				Rect2(7850.0, 280.0, 410.0, 360.0),
				Rect2(8350.0, 360.0, 380.0, 280.0),
				Rect2(8820.0, 440.0, 1000.0, 200.0)
			]
			data["platforms"] = [
				# Sector 1: Arctic Shore & Glacial Crevasse Escalation (0 - 1410)
				{"rect": Rect2(180.0, 360.0, 160.0, 16.0), "type": PlatformType.ICE_SLAB, "variant": "crag"},
				{"rect": Rect2(280.0, 280.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                            # Powerup 1 (360, 280) & Cryo-Sniper 1
				{"rect": Rect2(355.0, 395.0, 115.0, 16.0), "type": PlatformType.ICE_SLAB, "variant": "wide", "is_drop": true, "drop_delay": 0.35, "respawn_time": 2.8}, # NAVIGATE: Fragile ice slab across Crevasse 1 (390-470)
				{"rect": Rect2(560.0, 270.0, 170.0, 16.0), "type": PlatformType.GIRDER, "variant": "tundra"},                                # Frozen steel gantry
				{"rect": Rect2(680.0, 190.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                            # Sniper 2 (760, 190) on weather mast
				{"rect": Rect2(805.0, 305.0, 115.0, 16.0), "type": PlatformType.GIRDER, "variant": "tundra"},                                 # NAVIGATE: Steel girder bridging step to 260 (840-920)
				{"rect": Rect2(1020.0, 190.0, 170.0, 16.0), "type": PlatformType.ICE_SLAB, "variant": "slab"},
				{"rect": Rect2(1160.0, 130.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 3 (1240, 130) on alpine lookout
				{"rect": Rect2(1285.0, 230.0, 125.0, 16.0), "type": PlatformType.ICE_SLAB, "variant": "crag"},                              # NAVIGATE: Ice slab onto Serac Summit (1320-1410)
				
				# Sector 2: Glacier Peak Summit & Icy Ravine Descent (1410 - 2870)
				{"rect": Rect2(1470.0, 120.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Summit Perch: Powerup 2 (1550, 120) & Sniper 4
				{"rect": Rect2(1670.0, 140.0, 160.0, 16.0), "type": PlatformType.GIRDER, "variant": "tundra"},                                # Crane beam over serac
				{"rect": Rect2(1860.0, 245.0, 125.0, 16.0), "type": PlatformType.ICE_SLAB, "variant": "wide", "is_drop": true, "drop_delay": 0.35, "respawn_time": 2.8}, # NAVIGATE: Crumbling ice slab descending (1860-1950)
				{"rect": Rect2(2160.0, 140.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Alpine outpost Sniper 5 (2240, 140)
				{"rect": Rect2(2320.0, 340.0, 125.0, 16.0), "type": PlatformType.GIRDER, "variant": "tundra"},                                # NAVIGATE: Girder descending (2320-2410)
				{"rect": Rect2(2640.0, 220.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 6 (2720, 220)
				{"rect": Rect2(2780.0, 430.0, 125.0, 16.0), "type": PlatformType.ICE_SLAB, "variant": "slab", "is_drop": true, "drop_delay": 0.35, "respawn_time": 2.8}, # NAVIGATE: Dropping ice shelf into Frost Valley (2780-2870)
				
				# Sector 3: Sunken Frost Valley & Blizzard Escalation (2870 - 4370)
				{"rect": Rect2(2940.0, 390.0, 160.0, 16.0), "type": PlatformType.ICE_SLAB, "variant": "crag"},
				{"rect": Rect2(3080.0, 300.0, 170.0, 16.0), "type": PlatformType.GIRDER, "variant": "tundra"},                                # Valley skyway
				{"rect": Rect2(3200.0, 220.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Powerup 3 (3280, 220) & Sniper 7
				{"rect": Rect2(3275.0, 420.0, 135.0, 16.0), "type": PlatformType.GIRDER, "variant": "tundra"},                                # NAVIGATE: Girder climbing out of 470 valley (3310-3410)
				{"rect": Rect2(3500.0, 280.0, 160.0, 16.0), "type": PlatformType.ICE_SLAB, "variant": "wide"},
				{"rect": Rect2(3630.0, 190.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 8 (3710, 190)
				{"rect": Rect2(3745.0, 315.0, 125.0, 16.0), "type": PlatformType.ICE_SLAB, "variant": "slab", "is_drop": true, "drop_delay": 0.35, "respawn_time": 2.8}, # NAVIGATE: Shattering ice step climbing to 260 (3780-3870)
				{"rect": Rect2(4100.0, 120.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 9 (4180, 120)
				{"rect": Rect2(4245.0, 230.0, 125.0, 16.0), "type": PlatformType.GIRDER, "variant": "tundra"},                                # NAVIGATE: Heavy girder onto Upper Glacier (4280-4370)
				
				# Sector 4: Upper Glacial Ridge & Approach (4370 - 5360)
				{"rect": Rect2(4420.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Upper Glacier: Powerup 4 (4500, 130) & Sniper 10
				{"rect": Rect2(4640.0, 140.0, 160.0, 16.0), "type": PlatformType.ICE_SLAB, "variant": "crag"},
				{"rect": Rect2(4800.0, 260.0, 125.0, 16.0), "type": PlatformType.ICE_SLAB, "variant": "wide", "is_drop": true, "drop_delay": 0.35, "respawn_time": 2.8}, # NAVIGATE: Drop slab descending (4800-4890)
				{"rect": Rect2(5120.0, 240.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 11 (5200, 240)
				{"rect": Rect2(5270.0, 380.0, 125.0, 16.0), "type": PlatformType.GIRDER, "variant": "tundra"},                                # NAVIGATE: Threshold girder into Colossus Arena (5270-5360)
				
				# Sector 5: Polar Siege Colossus Arena (5360 - 6400)
				{"rect": Rect2(5580.0, 260.0, 200.0, 16.0), "type": PlatformType.GIRDER, "variant": "tundra"},                                # Combat gantry: Sniper 12 (5680, 260)
				{"rect": Rect2(5760.0, 340.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Powerup 5 support (5840, 440)
				{"rect": Rect2(6265.0, 385.0, 135.0, 16.0), "type": PlatformType.ICE_SLAB, "variant": "slab", "is_drop": true, "drop_delay": 0.35, "respawn_time": 2.8}, # NAVIGATE: Shattering exit shelf (6300-6400)
				
				# Sector 6: Permafrost Pinnacles & Crevasse Gap (6400 - 7850)
				{"rect": Rect2(6630.0, 180.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 13 (6710, 180)
				{"rect": Rect2(6735.0, 275.0, 125.0, 16.0), "type": PlatformType.GIRDER, "variant": "tundra"},                                # NAVIGATE: Girder climbing to 220 (6770-6860)
				{"rect": Rect2(6930.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # High Glacier Spire: Powerup 6 (7010, 130) & Sniper 14
				{"rect": Rect2(7290.0, 275.0, 125.0, 16.0), "type": PlatformType.ICE_SLAB, "variant": "crag", "is_drop": true, "drop_delay": 0.35, "respawn_time": 2.8}, # NAVIGATE: Fragile shelf descending crevasse (7290-7380)
				{"rect": Rect2(7620.0, 190.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 15 (7700, 190)
				{"rect": Rect2(7750.0, 305.0, 100.0, 16.0), "type": PlatformType.GIRDER, "variant": "tundra"},                                # NAVIGATE: Bridge onto Frost Ramparts (7750-7850)
				
				# Sector 7 & 8: Frost Ramparts & Siege Tank Core (7850 - 9820)
				{"rect": Rect2(7940.0, 190.0, 170.0, 16.0), "type": PlatformType.ICE_SLAB, "variant": "wide"},
				{"rect": Rect2(8260.0, 320.0, 125.0, 16.0), "type": PlatformType.GIRDER, "variant": "tundra"},                                # NAVIGATE: Rampart step (8260-8350)
				{"rect": Rect2(8600.0, 200.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Powerup 7 Perch (8680, 200) & Sniper 16
				{"rect": Rect2(8730.0, 400.0, 125.0, 16.0), "type": PlatformType.ICE_SLAB, "variant": "slab", "is_drop": true, "drop_delay": 0.35, "respawn_time": 2.8}, # NAVIGATE: Cracking ice shelf into Tank Arena (8730-8820)
				{"rect": Rect2(9080.0, 270.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Tank Observation Mast
				{"rect": Rect2(9340.0, 200.0, 180.0, 16.0), "type": PlatformType.GIRDER, "variant": "tundra"}                                # Final Artillery Scaffolding
			]
		5:
			data["name"] = "STEEL REFINERY"
			data["sector"] = "SECTOR 05 // VULCAN FOUNDRY"
			data["theme"] = "INDUSTRIAL SMELTING PLANT"
			data["diff"] = "EXPERT"
			data["boss"] = "MAGMA FORGE GOLEM"
			data["hazard"] = "MOLTEN LAVA POOLS & CHAIN GIRDERS"
			data["intel"] = "Infiltrate heavy metal foundry. Break the Vulcan Foundry Dreadnought at Sector 5, scale overhead cargo chains and blast decks above superheated magma trenches, then destroy the incinerator golem."
			data["primary_color"] = Color(1.0, 0.50, 0.15)
			data["accent_color"] = Color(1.0, 0.85, 0.20)
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 380.0, 200.0),
				Rect2(460.0, 340.0, 370.0, 300.0),
				Rect2(910.0, 250.0, 390.0, 390.0),
				Rect2(1390.0, 190.0, 440.0, 450.0),
				Rect2(1920.0, 300.0, 370.0, 340.0),
				Rect2(2380.0, 390.0, 360.0, 250.0),
				Rect2(2840.0, 470.0, 440.0, 180.0),
				Rect2(3380.0, 360.0, 370.0, 280.0),
				Rect2(3840.0, 260.0, 410.0, 380.0),
				Rect2(4340.0, 210.0, 440.0, 430.0),
				Rect2(4880.0, 320.0, 380.0, 320.0),
				Rect2(5350.0, 440.0, 950.0, 200.0),
				Rect2(6400.0, 330.0, 360.0, 310.0),
				Rect2(6860.0, 220.0, 420.0, 420.0),
				Rect2(7380.0, 330.0, 370.0, 310.0),
				Rect2(7850.0, 280.0, 400.0, 360.0),
				Rect2(8340.0, 360.0, 390.0, 280.0),
				Rect2(8810.0, 440.0, 1010.0, 200.0)
			]
			data["platforms"] = [
				# Sector 1: Smelter Intake & Slag Trench Escalation (0 - 1390)
				{"rect": Rect2(180.0, 360.0, 160.0, 16.0), "type": PlatformType.LAVA_GRATE, "variant": "wide"},
				{"rect": Rect2(280.0, 280.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                            # Powerup 1 (360, 280) & Foundry Sniper 1
				{"rect": Rect2(345.0, 390.0, 115.0, 16.0), "type": PlatformType.LAVA_GRATE, "variant": "slag_crag", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8}, # NAVIGATE: Collapsing lava grate over molten ditch (380-460)
				{"rect": Rect2(550.0, 260.0, 170.0, 16.0), "type": PlatformType.GIRDER, "variant": "refinery"},                                # Heavy hoist girder
				{"rect": Rect2(680.0, 180.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                            # Sniper 2 (760, 180) on crane post
				{"rect": Rect2(795.0, 295.0, 115.0, 16.0), "type": PlatformType.LAVA_GRATE, "variant": "grate"},                             # NAVIGATE: Grate climbing to 250 (830-910)
				{"rect": Rect2(1000.0, 180.0, 170.0, 16.0), "type": PlatformType.GIRDER, "variant": "refinery"},
				{"rect": Rect2(1160.0, 120.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 3 (1240, 120) on furnace balcony
				{"rect": Rect2(1265.0, 220.0, 125.0, 16.0), "type": PlatformType.LAVA_GRATE, "variant": "wide"},                             # NAVIGATE: Lava grate onto Crucible Peak (1300-1390)
				
				# Sector 2: Crucible Summit & Molten Chute Descent (1390 - 2840)
				{"rect": Rect2(1470.0, 120.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Crucible Balcony: Powerup 2 (1550, 120) & Sniper 4
				{"rect": Rect2(1650.0, 120.0, 160.0, 16.0), "type": PlatformType.GIRDER, "variant": "refinery"},                                # Crane track
				{"rect": Rect2(1830.0, 245.0, 125.0, 16.0), "type": PlatformType.LAVA_GRATE, "variant": "slag_crag", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8}, # NAVIGATE: Drop grate descending (1830-1920)
				{"rect": Rect2(2160.0, 140.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Overhead furnace crane Sniper 5 (2240, 140)
				{"rect": Rect2(2290.0, 345.0, 125.0, 16.0), "type": PlatformType.GIRDER, "variant": "refinery"},                                # NAVIGATE: Girder descending (2290-2380)
				{"rect": Rect2(2640.0, 220.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 6 (2720, 220)
				{"rect": Rect2(2740.0, 430.0, 135.0, 16.0), "type": PlatformType.LAVA_GRATE, "variant": "grate", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8}, # NAVIGATE: Dropping grate into Smelting Vat (2740-2840)
				
				# Sector 3: Smelting Vat & Foundry Escalation (2840 - 4340)
				{"rect": Rect2(2920.0, 380.0, 160.0, 16.0), "type": PlatformType.LAVA_GRATE, "variant": "wide"},
				{"rect": Rect2(3060.0, 290.0, 170.0, 16.0), "type": PlatformType.GIRDER, "variant": "refinery"},                                # Overhead conveyor bypass
				{"rect": Rect2(3200.0, 220.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Powerup 3 (3280, 220) & Sniper 7
				{"rect": Rect2(3245.0, 415.0, 135.0, 16.0), "type": PlatformType.LAVA_GRATE, "variant": "slag_crag"},                             # NAVIGATE: Grate climbing out of 470 vat (3280-3380)
				{"rect": Rect2(3480.0, 280.0, 160.0, 16.0), "type": PlatformType.GIRDER, "variant": "refinery"},
				{"rect": Rect2(3630.0, 190.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 8 (3710, 190)
				{"rect": Rect2(3715.0, 310.0, 125.0, 16.0), "type": PlatformType.LAVA_GRATE, "variant": "grate", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8}, # NAVIGATE: Overheating grate climbing to 260 (3750-3840)
				{"rect": Rect2(4100.0, 120.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 9 (4180, 120)
				{"rect": Rect2(4250.0, 235.0, 90.0, 16.0), "type": PlatformType.GIRDER, "variant": "refinery"},                                # NAVIGATE: Crane track onto Upper Smelter (4250-4340)
				
				# Sector 4: Upper Smelter Deck & Approach (4340 - 5350)
				{"rect": Rect2(4420.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Upper Deck: Powerup 4 (4500, 130) & Sniper 10
				{"rect": Rect2(4620.0, 140.0, 160.0, 16.0), "type": PlatformType.LAVA_GRATE, "variant": "wide"},
				{"rect": Rect2(4780.0, 265.0, 135.0, 16.0), "type": PlatformType.GIRDER, "variant": "refinery", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8}, # NAVIGATE: Drop girder descending (4780-4880)
				{"rect": Rect2(5120.0, 240.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 11 (5200, 240)
				{"rect": Rect2(5260.0, 380.0, 125.0, 16.0), "type": PlatformType.LAVA_GRATE, "variant": "slag_crag"},                             # NAVIGATE: Threshold grate into Dreadnought Arena (5260-5350)
				
				# Sector 5: Vulcan Foundry Dreadnought Arena (5350 - 6400)
				{"rect": Rect2(5580.0, 260.0, 200.0, 16.0), "type": PlatformType.GIRDER, "variant": "refinery"},                                # Conveyor gantry: Sniper 12 (5680, 260)
				{"rect": Rect2(5760.0, 340.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Powerup 5 support perch (5840, 440)
				{"rect": Rect2(6265.0, 385.0, 135.0, 16.0), "type": PlatformType.LAVA_GRATE, "variant": "grate", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8}, # NAVIGATE: Grate exiting arena (6300-6400)
				
				# Sector 6: Foundry Girders & Lava Chasm (6400 - 7850)
				{"rect": Rect2(6630.0, 180.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 13 (6710, 180)
				{"rect": Rect2(6725.0, 275.0, 135.0, 16.0), "type": PlatformType.GIRDER, "variant": "refinery"},                                # NAVIGATE: Girder climbing to 220 (6760-6860)
				{"rect": Rect2(6930.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Furnace Tower: Powerup 6 (7010, 130) & Sniper 14
				{"rect": Rect2(7280.0, 275.0, 135.0, 16.0), "type": PlatformType.LAVA_GRATE, "variant": "wide", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8}, # NAVIGATE: Drop grate over lava pool (7280-7380)
				{"rect": Rect2(7620.0, 190.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 15 (7700, 190)
				{"rect": Rect2(7750.0, 305.0, 100.0, 16.0), "type": PlatformType.GIRDER, "variant": "refinery"},                                # NAVIGATE: Gantry onto Forge Ramparts (7750-7850)
				
				# Sector 7 & 8: Forge Ramparts & Magma Golem Core (7850 - 9820)
				{"rect": Rect2(7940.0, 190.0, 170.0, 16.0), "type": PlatformType.LAVA_GRATE, "variant": "slag_crag"},
				{"rect": Rect2(8250.0, 320.0, 125.0, 16.0), "type": PlatformType.GIRDER, "variant": "refinery"},                                # NAVIGATE: Rampart step (8250-8340)
				{"rect": Rect2(8600.0, 200.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Powerup 7 Perch (8680, 200) & Sniper 16
				{"rect": Rect2(8730.0, 400.0, 115.0, 16.0), "type": PlatformType.LAVA_GRATE, "variant": "grate", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8}, # NAVIGATE: Dropping grate into Golem Arena (8730-8810)
				{"rect": Rect2(9080.0, 270.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Furnace Observation Crane
				{"rect": Rect2(9340.0, 200.0, 180.0, 16.0), "type": PlatformType.GIRDER, "variant": "refinery"}                                # Final Molten Iron Deck
			]
		6:
			data["name"] = "ELECTRIC DYNAMO"
			data["sector"] = "SECTOR 06 // TESLA SUBSTATION"
			data["theme"] = "HIGH-VOLTAGE POWER GRID"
			data["diff"] = "EXPERT"
			data["boss"] = "THUNDER DYNAMO"
			data["hazard"] = "ARC DISCHARGE CHASM & CONDENSERS"
			data["intel"] = "Scale megavolt distribution towers, dielectric capacitor terraces and lightning coils. Neutralize the Tesla Storm Overlord at Sector 5, then short-circuit the Thunder Dynamo core generator."
			data["primary_color"] = Color(0.95, 0.85, 0.20)
			data["accent_color"] = Color(0.40, 0.90, 1.0)
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 390.0, 200.0),
				Rect2(470.0, 350.0, 360.0, 290.0),
				Rect2(910.0, 260.0, 400.0, 380.0),
				Rect2(1400.0, 200.0, 440.0, 440.0),
				Rect2(1930.0, 290.0, 370.0, 350.0),
				Rect2(2390.0, 390.0, 370.0, 250.0),
				Rect2(2860.0, 470.0, 440.0, 180.0),
				Rect2(3400.0, 370.0, 370.0, 270.0),
				Rect2(3860.0, 250.0, 410.0, 390.0),
				Rect2(4360.0, 200.0, 430.0, 440.0),
				Rect2(4890.0, 320.0, 380.0, 320.0),
				Rect2(5360.0, 440.0, 940.0, 200.0),
				Rect2(6410.0, 330.0, 360.0, 310.0),
				Rect2(6870.0, 220.0, 420.0, 420.0),
				Rect2(7390.0, 330.0, 370.0, 310.0),
				Rect2(7860.0, 270.0, 400.0, 370.0),
				Rect2(8350.0, 360.0, 390.0, 280.0),
				Rect2(8820.0, 440.0, 1000.0, 200.0)
			]
			data["platforms"] = [
				# Sector 1: Pylon Substation & High-Voltage Arc Escalation (0 - 1400)
				{"rect": Rect2(180.0, 360.0, 160.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "wide"},
				{"rect": Rect2(280.0, 280.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                            # Powerup 1 (360, 280) & Tesla-Sniper 1
				{"rect": Rect2(370.0, 395.0, 140.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "rail", "is_drop": true, "drop_delay": 0.40, "respawn_time": 2.8}, # NAVIGATE: Overcharged barrier across Arc Gap 1 (390-470)
				{"rect": Rect2(560.0, 270.0, 170.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "default"},                          # Insulated gantry
				{"rect": Rect2(680.0, 180.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                            # Sniper 2 (760, 180) on pylon mast
				{"rect": Rect2(820.0, 305.0, 140.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "wide"},                        # NAVIGATE: Energy shield climbing to 260 (830-910)
				{"rect": Rect2(1010.0, 180.0, 170.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "default"},
				{"rect": Rect2(1160.0, 120.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 3 (1240, 120) on capacitor tower
				{"rect": Rect2(1290.0, 230.0, 140.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "default"},                        # NAVIGATE: Barrier onto Transformer Summit (1310-1400)
				
				# Sector 2: Megavolt Transformer Summit & Discharge Chute (1400 - 2860)
				{"rect": Rect2(1470.0, 120.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Summit Perch: Powerup 2 (1550, 120) & Sniper 4
				{"rect": Rect2(1660.0, 140.0, 160.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "default"},                         # Dielectric gantry
				{"rect": Rect2(1820.0, 245.0, 140.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "rail", "is_drop": true, "drop_delay": 0.40, "respawn_time": 2.8}, # NAVIGATE: Fluctuating barrier descending (1840-1930)
				{"rect": Rect2(2160.0, 140.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # High transmission deck Sniper 5 (2240, 140)
				{"rect": Rect2(2290.0, 340.0, 140.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "default"},                         # NAVIGATE: Catwalk descending (2300-2390)
				{"rect": Rect2(2640.0, 220.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 6 (2720, 220)
				{"rect": Rect2(2750.0, 430.0, 150.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "wide", "is_drop": true, "drop_delay": 0.40, "respawn_time": 2.8}, # NAVIGATE: Dropping forcefield into Condenser Pit (2760-2860)
				
				# Sector 3: Condenser Pit & Grid Escalation (2860 - 4360)
				{"rect": Rect2(2930.0, 390.0, 160.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "default"},
				{"rect": Rect2(3070.0, 300.0, 170.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "default"},                        # High voltage skyway
				{"rect": Rect2(3200.0, 220.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Powerup 3 (3280, 220) & Sniper 7
				{"rect": Rect2(3290.0, 420.0, 140.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "default"},                         # NAVIGATE: Gantry climbing out of 470 pit (3300-3400)
				{"rect": Rect2(3490.0, 280.0, 160.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "rail"},
				{"rect": Rect2(3630.0, 190.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 8 (3710, 190)
				{"rect": Rect2(3750.0, 310.0, 140.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "default", "is_drop": true, "drop_delay": 0.40, "respawn_time": 2.8}, # NAVIGATE: Flickering barrier climbing to 250 (3770-3860)
				{"rect": Rect2(4100.0, 120.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 9 (4180, 120)
				{"rect": Rect2(4250.0, 225.0, 140.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "rail"},                         # NAVIGATE: Catwalk onto Upper Transformer Deck (4270-4360)
				
				# Sector 4: Upper Power Grid & Approach (4360 - 5360)
				{"rect": Rect2(4420.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Upper Deck: Powerup 4 (4500, 130) & Sniper 10
				{"rect": Rect2(4640.0, 140.0, 160.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "rail"},
				{"rect": Rect2(4770.0, 260.0, 140.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "rail", "is_drop": true, "drop_delay": 0.40, "respawn_time": 2.8}, # NAVIGATE: Drop catwalk descending (4790-4890)
				{"rect": Rect2(5120.0, 290.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 11 (5200, 290)
				{"rect": Rect2(5250.0, 380.0, 140.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "wide"},                        # NAVIGATE: Threshold shield into Tesla Storm Arena (5270-5360)
				
				# Sector 5: Tesla Storm Overlord Arena (5360 - 6410)
				{"rect": Rect2(5580.0, 260.0, 200.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "rail"},                        # Electric fighting bridge: Sniper 12 (5680, 260)
				{"rect": Rect2(5760.0, 340.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Powerup 5 support (5840, 440)
				{"rect": Rect2(6290.0, 385.0, 150.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "default", "is_drop": true, "drop_delay": 0.40, "respawn_time": 2.8}, # NAVIGATE: Barrier exiting arena (6300-6410)
				
				# Sector 6: Dielectric Towers & Arc Discharge Abyss (6410 - 7860)
				{"rect": Rect2(6630.0, 180.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 13 (6710, 180)
				{"rect": Rect2(6750.0, 275.0, 150.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "rail"},                         # NAVIGATE: Catwalk climbing to 220 (6770-6870)
				{"rect": Rect2(6930.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Dielectric Spire: Powerup 6 (7010, 130) & Sniper 14
				{"rect": Rect2(7270.0, 275.0, 150.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "rail", "is_drop": true, "drop_delay": 0.40, "respawn_time": 2.8}, # NAVIGATE: Drop shield over arc abyss (7290-7390)
				{"rect": Rect2(7620.0, 190.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 15 (7700, 190)
				{"rect": Rect2(7750.0, 300.0, 140.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "rail"},                         # NAVIGATE: Catwalk onto Substation Ramparts (7760-7860)
				
				# Sector 7 & 8: Dynamo Substation Ramparts & Thunder Dynamo (7860 - 9820)
				{"rect": Rect2(7940.0, 190.0, 170.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "wide"},
				{"rect": Rect2(8230.0, 315.0, 140.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "rail"},                         # NAVIGATE: Rampart step (8260-8350)
				{"rect": Rect2(8600.0, 200.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Powerup 7 Perch (8680, 200) & Sniper 16
				{"rect": Rect2(8710.0, 400.0, 140.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "default", "is_drop": true, "drop_delay": 0.40, "respawn_time": 2.8}, # NAVIGATE: Dropping barrier into Dynamo Core (8740-8820)
				{"rect": Rect2(9090.0, 270.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Dynamo Observation Mast
				{"rect": Rect2(9350.0, 200.0, 180.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "wide"}                        # High Voltage Electrode Shield
			]
		7:
			data["name"] = "ALIEN AEROSPACE HANGAR"
			data["sector"] = "SECTOR 07 // ORBITAL STARPORT"
			data["theme"] = "SPACE LAUNCH BAYS"
			data["diff"] = "NIGHTMARE"
			data["boss"] = "VANGUARD STAR CRUISER"
			data["hazard"] = "VACUUM EXHAUST DUCTS & TURRETS"
			data["intel"] = "Infiltrate orbital launch deck. Defeat the Orbital Strike Vanguard at Sector 5, navigate heavy hydraulic gantries across high-altitude docking trenches and bring down the alien command cruiser."
			data["primary_color"] = Color(0.70, 0.45, 0.95)
			data["accent_color"] = Color(0.35, 0.85, 1.0)
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 390.0, 200.0),
				Rect2(470.0, 350.0, 370.0, 290.0),
				Rect2(920.0, 260.0, 400.0, 380.0),
				Rect2(1410.0, 200.0, 440.0, 440.0),
				Rect2(1940.0, 300.0, 370.0, 340.0),
				Rect2(2400.0, 390.0, 370.0, 250.0),
				Rect2(2870.0, 470.0, 440.0, 180.0),
				Rect2(3410.0, 360.0, 370.0, 280.0),
				Rect2(3870.0, 250.0, 410.0, 390.0),
				Rect2(4370.0, 200.0, 430.0, 440.0),
				Rect2(4900.0, 320.0, 380.0, 320.0),
				Rect2(5360.0, 440.0, 940.0, 200.0),
				Rect2(6410.0, 330.0, 360.0, 310.0),
				Rect2(6870.0, 220.0, 420.0, 420.0),
				Rect2(7390.0, 330.0, 370.0, 310.0),
				Rect2(7860.0, 280.0, 400.0, 360.0),
				Rect2(8350.0, 360.0, 390.0, 280.0),
				Rect2(8820.0, 440.0, 1000.0, 200.0)
			]
			data["platforms"] = [
				# Sector 1: Launch Pad Foothills & Exhaust Trench Escalation (0 - 1410)
				{"rect": Rect2(180.0, 360.0, 160.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "default"},
				{"rect": Rect2(280.0, 280.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                            # Powerup 1 (360, 280) & Orbital Sniper 1
				{"rect": Rect2(370.0, 395.0, 140.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "deck", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8}, # NAVIGATE: Retracting gantry across Trench 1 (390-470)
				{"rect": Rect2(560.0, 270.0, 170.0, 16.0), "type": PlatformType.GIRDER, "variant": "hangar"},                                # Heavy hydraulic crane truss
				{"rect": Rect2(680.0, 180.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                            # Sniper 2 (760, 180) on docking mast
				{"rect": Rect2(820.0, 305.0, 140.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "default"},                         # NAVIGATE: Catwalk climbing to 260 (840-920)
				{"rect": Rect2(1020.0, 180.0, 170.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "deck"},
				{"rect": Rect2(1160.0, 120.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 3 (1240, 120) on flight deck tower
				{"rect": Rect2(1290.0, 230.0, 140.0, 16.0), "type": PlatformType.GIRDER, "variant": "hangar"},                                # NAVIGATE: Truss onto Gantry Summit (1320-1410)
				
				# Sector 2: Shuttle Gantry Summit & Launch Duct Descent (1410 - 2870)
				{"rect": Rect2(1470.0, 120.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Gantry Summit: Powerup 2 (1550, 120) & Sniper 4
				{"rect": Rect2(1670.0, 140.0, 160.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "default"},                         # Shuttle guidance rail
				{"rect": Rect2(1830.0, 250.0, 140.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "deck", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8}, # NAVIGATE: Drop catwalk descending (1850-1940)
				{"rect": Rect2(2170.0, 140.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Overhead docking crane Sniper 5 (2240, 140)
				{"rect": Rect2(2300.0, 345.0, 140.0, 16.0), "type": PlatformType.GIRDER, "variant": "hangar"},                                # NAVIGATE: Crane girder descending (2310-2400)
				{"rect": Rect2(2640.0, 220.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 6 (2720, 220)
				{"rect": Rect2(2760.0, 430.0, 150.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "default", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8}, # NAVIGATE: Dropping catwalk into Launch Pit (2770-2870)
				
				# Sector 3: Launch Pit & Service Bay Escalation (2870 - 4370)
				{"rect": Rect2(2940.0, 390.0, 160.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "deck"},
				{"rect": Rect2(3080.0, 300.0, 170.0, 16.0), "type": PlatformType.GIRDER, "variant": "hangar"},                                # Cargo bay skyway
				{"rect": Rect2(3200.0, 220.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Powerup 3 (3280, 220) & Sniper 7
				{"rect": Rect2(3290.0, 415.0, 140.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "default"},                         # NAVIGATE: Catwalk climbing out of 470 pit (3310-3410)
				{"rect": Rect2(3500.0, 280.0, 160.0, 16.0), "type": PlatformType.GIRDER, "variant": "hangar"},
				{"rect": Rect2(3630.0, 190.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 8 (3710, 190)
				{"rect": Rect2(3760.0, 305.0, 140.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "deck", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8}, # NAVIGATE: Retracting gate climbing to 250 (3780-3870)
				{"rect": Rect2(4100.0, 120.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 9 (4180, 120)
				{"rect": Rect2(4250.0, 225.0, 140.0, 16.0), "type": PlatformType.GIRDER, "variant": "hangar"},                                # NAVIGATE: Gantry onto Upper Docking Deck (4280-4370)
				
				# Sector 4: Upper Flight Deck & Approach (4370 - 5360)
				{"rect": Rect2(4420.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Flight Control Perch: Powerup 4 (4500, 130) & Sniper 10
				{"rect": Rect2(4650.0, 140.0, 160.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "default"},
				{"rect": Rect2(4780.0, 260.0, 140.0, 16.0), "type": PlatformType.GIRDER, "variant": "hangar", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8}, # NAVIGATE: Drop girder descending (4800-4900)
				{"rect": Rect2(5120.0, 290.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 11 (5200, 290)
				{"rect": Rect2(5250.0, 380.0, 140.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "deck"},                         # NAVIGATE: Threshold catwalk into Vanguard Arena (5280-5360)
				
				# Sector 5: Orbital Strike Vanguard Arena (5360 - 6410)
				{"rect": Rect2(5580.0, 260.0, 200.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "default"},                         # High launch bay bridge: Sniper 12 (5680, 260)
				{"rect": Rect2(5760.0, 340.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Powerup 5 support (5840, 440)
				{"rect": Rect2(6290.0, 385.0, 150.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "deck", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8}, # NAVIGATE: Catwalk exiting arena (6300-6410)
				
				# Sector 6: Aerospace Gantries & Exhaust Duct Void (6410 - 7860)
				{"rect": Rect2(6630.0, 180.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 13 (6710, 180)
				{"rect": Rect2(6750.0, 275.0, 150.0, 16.0), "type": PlatformType.GIRDER, "variant": "hangar"},                                # NAVIGATE: Crane truss climbing to 220 (6770-6870)
				{"rect": Rect2(6930.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Starport Tower: Powerup 6 (7010, 130) & Sniper 14
				{"rect": Rect2(7270.0, 275.0, 150.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "default", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8}, # NAVIGATE: Drop catwalk over vacuum duct (7290-7390)
				{"rect": Rect2(7620.0, 190.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Sniper 15 (7700, 190)
				{"rect": Rect2(7750.0, 305.0, 140.0, 16.0), "type": PlatformType.GIRDER, "variant": "hangar"},                                # NAVIGATE: Gantry onto Cruiser Ramparts (7760-7860)
				
				# Sector 7 & 8: Vanguard Star Cruiser Launch Deck (7860 - 9820)
				{"rect": Rect2(7950.0, 190.0, 170.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "deck"},
				{"rect": Rect2(8230.0, 320.0, 140.0, 16.0), "type": PlatformType.GIRDER, "variant": "hangar"},                                # NAVIGATE: Launch deck step (8260-8350)
				{"rect": Rect2(8600.0, 200.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Final Powerup 7 Perch (8680, 200) & Sniper 16
				{"rect": Rect2(8710.0, 400.0, 140.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "default", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8}, # NAVIGATE: Dropping launch gate into Star Cruiser Bay (8740-8820)
				{"rect": Rect2(9090.0, 270.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Star Cruiser Guidance Mast
				{"rect": Rect2(9350.0, 200.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK, "variant": "deck"}                          # Orbital Command Gantry
			]
		8:
			data["name"] = "MOTHER BRAIN SANCTUM"
			data["sector"] = "SECTOR 08 // ALIEN CENTRAL CORE"
			data["theme"] = "LIVING PSYCHIC BIO-SANCTUM"
			data["diff"] = "APOCALYPSE"
			data["boss"] = "EMPEROR MOTHER BRAIN"
			data["hazard"] = "BIO-NEURAL ACID CHASMS"
			data["intel"] = "Final assault on the central neural hive. Purge the Psionic Hive Leviathan at Sector 5, scale bio-synapse towers, penetrate defensive optic laser screens and eradicate the Emperor Mother Brain!"
			data["primary_color"] = Color(1.0, 0.25, 0.35)
			data["accent_color"] = Color(0.95, 0.85, 0.20)
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 390.0, 200.0),
				Rect2(470.0, 350.0, 370.0, 290.0),
				Rect2(920.0, 260.0, 400.0, 380.0),
				Rect2(1410.0, 200.0, 440.0, 440.0),
				Rect2(1940.0, 290.0, 370.0, 350.0),
				Rect2(2400.0, 390.0, 370.0, 250.0),
				Rect2(2870.0, 470.0, 440.0, 180.0),
				Rect2(3410.0, 370.0, 370.0, 270.0),
				Rect2(3870.0, 250.0, 410.0, 390.0),
				Rect2(4370.0, 200.0, 430.0, 440.0),
				Rect2(4900.0, 320.0, 380.0, 320.0),
				Rect2(5360.0, 440.0, 940.0, 200.0),
				Rect2(6410.0, 330.0, 360.0, 310.0),
				Rect2(6870.0, 220.0, 420.0, 420.0),
				Rect2(7390.0, 330.0, 370.0, 310.0),
				Rect2(7860.0, 270.0, 400.0, 370.0),
				Rect2(8350.0, 360.0, 390.0, 280.0),
				Rect2(8820.0, 440.0, 1000.0, 200.0)
			]
			data["platforms"] = [
				# Sector 1: Living Cortex Breach & Neural Chasm Escalation (0 - 1410)
				{"rect": Rect2(180.0, 360.0, 160.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "synapse"},
				{"rect": Rect2(280.0, 280.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                            # Powerup 1 (360, 280) & Bio-Eye 1
				{"rect": Rect2(355.0, 395.0, 115.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "carapace", "is_drop": true, "drop_delay": 0.35, "respawn_time": 2.8}, # NAVIGATE: Dissolving synapse rib over Neural Chasm 1 (390-470)
				{"rect": Rect2(560.0, 270.0, 170.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "psychic"},                        # Psionic force barrier
				{"rect": Rect2(680.0, 180.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                            # Bio-Eye 2 (760, 180) on nerve stalk
				{"rect": Rect2(805.0, 305.0, 115.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "wide"},                               # NAVIGATE: Spinal rib climbing to 260 (840-920)
				{"rect": Rect2(1020.0, 180.0, 170.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "synapse"},
				{"rect": Rect2(1160.0, 120.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Bio-Eye 3 (1240, 120) on synaptic pillar
				{"rect": Rect2(1285.0, 230.0, 125.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "psychic"},                        # NAVIGATE: Psionic barrier onto Synapse Summit (1320-1410)
				
				# Sector 2: Synapse Summit & Neural Acid Fall Descent (1410 - 2870)
				{"rect": Rect2(1470.0, 120.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Synapse Summit: Powerup 2 (1550, 120) & Bio-Eye 4
				{"rect": Rect2(1670.0, 140.0, 160.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "carapace"},                               # Spinal arch
				{"rect": Rect2(1850.0, 245.0, 125.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "wide", "is_drop": true, "drop_delay": 0.35, "respawn_time": 2.8}, # NAVIGATE: Dying synapse rib descending (1850-1940)
				{"rect": Rect2(2170.0, 140.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Psionic nerve stalk Bio-Eye 5 (2240, 140)
				{"rect": Rect2(2310.0, 340.0, 125.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "psychic"},                        # NAVIGATE: Psionic shield descending (2310-2400)
				{"rect": Rect2(2640.0, 220.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Bio-Eye 6 (2720, 220)
				{"rect": Rect2(2770.0, 430.0, 135.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "synapse", "is_drop": true, "drop_delay": 0.35, "respawn_time": 2.8}, # NAVIGATE: Dropping spine into Neural Fluid Abyss (2770-2870)
				
				# Sector 3: Neural Fluid Basin & Synaptic Escalation (2870 - 4370)
				{"rect": Rect2(2940.0, 390.0, 160.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "carapace"},
				{"rect": Rect2(3080.0, 300.0, 170.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "psychic"},                        # Psionic bypass gantry
				{"rect": Rect2(3200.0, 220.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Powerup 3 (3280, 220) & Bio-Eye 7
				{"rect": Rect2(3275.0, 420.0, 135.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "wide"},                               # NAVIGATE: Spinal rib climbing out of 470 basin (3310-3410)
				{"rect": Rect2(3500.0, 280.0, 160.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "psychic"},
				{"rect": Rect2(3630.0, 190.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Bio-Eye 8 (3710, 190)
				{"rect": Rect2(3745.0, 310.0, 125.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "synapse", "is_drop": true, "drop_delay": 0.35, "respawn_time": 2.8}, # NAVIGATE: Dissolving synapse climbing to 250 (3780-3870)
				{"rect": Rect2(4100.0, 120.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Bio-Eye 9 (4180, 120)
				{"rect": Rect2(4280.0, 225.0, 90.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "psychic"},                        # NAVIGATE: Psionic barrier onto Upper Cortex (4280-4370)
				
				# Sector 4: Upper Cortex Sanctum & Approach (4370 - 5360)
				{"rect": Rect2(4420.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Cortex Peak: Powerup 4 (4500, 130) & Bio-Eye 10
				{"rect": Rect2(4650.0, 140.0, 160.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "carapace"},
				{"rect": Rect2(4800.0, 260.0, 135.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "wide", "is_drop": true, "drop_delay": 0.35, "respawn_time": 2.8}, # NAVIGATE: Drop rib descending (4800-4900)
				{"rect": Rect2(5120.0, 240.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Bio-Eye 11 (5200, 240)
				{"rect": Rect2(5280.0, 380.0, 115.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "psychic"},                        # NAVIGATE: Threshold barrier into Leviathan Arena (5280-5360)
				
				# Sector 5: Psionic Hive Leviathan Arena (5360 - 6410)
				{"rect": Rect2(5580.0, 260.0, 200.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "synapse"},                               # Living spine fighting deck: Bio-Eye 12 (5680, 260)
				{"rect": Rect2(5760.0, 340.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Powerup 5 support (5840, 440)
				{"rect": Rect2(6265.0, 385.0, 145.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "carapace", "is_drop": true, "drop_delay": 0.35, "respawn_time": 2.8}, # NAVIGATE: Spine exiting arena (6300-6410)
				
				# Sector 6: Neural Synapse Columns & Acid Abyss (6410 - 7860)
				{"rect": Rect2(6630.0, 180.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Bio-Eye 13 (6710, 180)
				{"rect": Rect2(6735.0, 275.0, 135.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "wide"},                               # NAVIGATE: Spinal column climbing to 220 (6770-6870)
				{"rect": Rect2(6930.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Optic Nerve Spire: Powerup 6 (7010, 130) & Bio-Eye 14
				{"rect": Rect2(7290.0, 275.0, 135.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "psychic", "is_drop": true, "drop_delay": 0.35, "respawn_time": 2.8}, # NAVIGATE: Collapsing psionic shield over abyss (7290-7390)
				{"rect": Rect2(7620.0, 190.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Bio-Eye 15 (7700, 190)
				{"rect": Rect2(7725.0, 300.0, 135.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "synapse"},                               # NAVIGATE: Spine onto Mother Brain Sanctum Ramparts (7760-7860)
				
				# Sector 7 & 8: Central Core Ramparts & Emperor Mother Brain Chamber (7860 - 9820)
				{"rect": Rect2(7950.0, 190.0, 170.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "psychic"},
				{"rect": Rect2(8260.0, 315.0, 125.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "carapace"},                               # NAVIGATE: Cortex rampart step (8260-8350)
				{"rect": Rect2(8600.0, 200.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Apocalypse Weapon Perch (8680, 200) & Bio-Eye 16
				{"rect": Rect2(8740.0, 400.0, 115.0, 16.0), "type": PlatformType.BIO_RIB, "variant": "wide", "is_drop": true, "drop_delay": 0.35, "respawn_time": 2.8}, # NAVIGATE: Dropping nerve stalk into Mother Brain Chamber (8740-8820)
				{"rect": Rect2(9090.0, 270.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},                           # Central Psychic Nerve Core
				{"rect": Rect2(9350.0, 200.0, 180.0, 16.0), "type": PlatformType.ENERGY_BARRIER, "variant": "psychic"}                        # Final Emperor Shield Barrier
			]

	return data

# =============================================================================
# PROCEDURAL LEVEL MAP TACTICAL SCHEMATIC DRAWING
# =============================================================================
static func draw_level_map(canvas: CanvasItem, stage_id: int, map_rect: Rect2, player_x: float = -1.0, is_schematic: bool = false, anim_time: float = 0.0) -> void:
	var m := get_map_data(stage_id)
	var prim_col: Color = m["primary_color"]
	var acc_col: Color = m["accent_color"]
	
	# Background tactical plate
	canvas.draw_rect(map_rect, Color(0.04, 0.06, 0.10, 0.95))
	
	# Coordinate Mapping
	var map_w := map_rect.size.x
	var map_h := map_rect.size.y
	var scale_x: float = map_w / LEVEL_MAX_X
	var world_y_top: float = 120.0
	var world_y_bottom: float = 480.0
	var world_y_range: float = world_y_bottom - world_y_top
	
	# Tactical Grid Overlay (in schematic mode)
	if is_schematic:
		var grid_cols := 8
		for c in range(grid_cols + 1):
			var gx := map_rect.position.x + float(c) * (map_w / float(grid_cols))
			canvas.draw_line(Vector2(gx, map_rect.position.y), Vector2(gx, map_rect.end.y), Color(0.20, 0.35, 0.50, 0.22), 1.0)
		for r in range(4):
			var gy := map_rect.position.y + float(r + 1) * (map_h / 4.0)
			canvas.draw_line(Vector2(map_rect.position.x, gy), Vector2(map_rect.end.x, gy), Color(0.20, 0.35, 0.50, 0.22), 1.0)
	
	# 1. Base Ground Elevation Level
	var ground_y_base: float = map_rect.position.y + map_h * 0.76
	var ground_thickness: float = maxf(4.0, map_h * 0.18)
	
	# Draw Chasms (Abyss / Hazards between ground chunks)
	var grounds: Array = m.get("ground_segments", [])
	for i in range(grounds.size() - 1):
		var g1: Rect2 = grounds[i]
		var g2: Rect2 = grounds[i + 1]
		var pit_start: float = map_rect.position.x + g1.end.x * scale_x
		var pit_end: float = map_rect.position.x + g2.position.x * scale_x
		var pit_w: float = pit_end - pit_start
		
		var rel_y1 := clampf((g1.position.y - world_y_top) / world_y_range, 0.0, 1.0)
		var rel_y2 := clampf((g2.position.y - world_y_top) / world_y_range, 0.0, 1.0)
		var pit_top_y := minf(
			map_rect.position.y + map_h * 0.20 + rel_y1 * (ground_y_base - (map_rect.position.y + map_h * 0.20)),
			map_rect.position.y + map_h * 0.20 + rel_y2 * (ground_y_base - (map_rect.position.y + map_h * 0.20))
		)
		var chasm_rect := Rect2(pit_start, pit_top_y + 2.0, pit_w, (map_rect.position.y + map_h) - pit_top_y - 2.0)
		canvas.draw_rect(chasm_rect, Color(0.02, 0.03, 0.05, 0.95))
		
		# Hazard marker stripes
		if pit_w > 8.0:
			var hazard_col := Color(acc_col.r, acc_col.g, acc_col.b, 0.45)
			var h_stripe_w := 3.0
			var num_stripes: int = int(pit_w / (h_stripe_w * 2.0))
			for s in range(num_stripes):
				var sx := pit_start + float(s) * (h_stripe_w * 2.0)
				canvas.draw_line(Vector2(sx, pit_top_y + 4.0), Vector2(sx + h_stripe_w, map_rect.end.y - 2.0), hazard_col, 1.2)
	
	# Draw Ground Solid Elevation Strips
	for g in grounds:
		var gx: float = map_rect.position.x + g.position.x * scale_x
		var gw: float = g.size.x * scale_x
		var rel_gy := clampf((g.position.y - world_y_top) / world_y_range, 0.0, 1.0)
		var seg_y: float = map_rect.position.y + map_h * 0.20 + rel_gy * (ground_y_base - (map_rect.position.y + map_h * 0.20))
		var seg_h: float = maxf(ground_thickness, (map_rect.position.y + map_h) - seg_y)
		var gr := Rect2(gx, seg_y, gw, seg_h)
		
		# Sub-surface foundation fill
		canvas.draw_rect(gr, Color(prim_col.r * 0.4, prim_col.g * 0.4, prim_col.b * 0.4, 0.95))
		# Top surface tactical highlight edge
		canvas.draw_rect(Rect2(gx, seg_y, gw, 2.5), prim_col)
		# Mechanical depth line
		canvas.draw_line(Vector2(gx, seg_y + 6.0), Vector2(gx + gw, seg_y + 6.0), Color(0.0, 0.0, 0.0, 0.4), 1.0)
	
	# 2. Tactical Elevation Platforms
	var plats: Array = m.get("platforms", [])
	for p in plats:
		var pr: Rect2 = p["rect"]
		var px: float = map_rect.position.x + pr.position.x * scale_x
		var pw: float = maxf(4.0, pr.size.x * scale_x)
		
		# Map world Y (120 to 480) to schematic height
		var rel_y: float = clampf((pr.position.y - world_y_top) / world_y_range, 0.0, 1.0)
		var py: float = map_rect.position.y + map_h * 0.16 + rel_y * (ground_y_base - (map_rect.position.y + map_h * 0.16))
		
		var p_type: int = p["type"]
		var p_col: Color = prim_col
		var is_drop: bool = p.get("is_drop", false)
		
		match p_type:
			PlatformType.TURF: p_col = prim_col
			PlatformType.GIRDER: p_col = Color(0.90, 0.75, 0.30)
			PlatformType.ROPE_BRIDGE: p_col = Color(0.80, 0.55, 0.30)
			PlatformType.HIGH_PERCH: p_col = Color(0.95, 0.95, 0.95)
			PlatformType.ICE_SLAB: p_col = Color(0.50, 0.85, 1.0)
			PlatformType.LAVA_GRATE: p_col = Color(1.0, 0.40, 0.15)
			PlatformType.ENERGY_BARRIER: p_col = Color(0.30, 0.90, 1.0)
			PlatformType.TECH_CATWALK: p_col = Color(0.70, 0.50, 0.95)
			PlatformType.BIO_RIB: p_col = Color(0.95, 0.35, 0.60)
		
		if is_drop:
			p_col = Color(1.0, 0.4, 0.4)
		
		# Platform schematic pill
		var plat_rect := Rect2(px, py - 1.5, pw, 3.0)
		canvas.draw_rect(plat_rect, p_col)
		
		# Mini vertical support stanchion or schematic motif
		if is_schematic:
			canvas.draw_line(Vector2(px + pw * 0.5, py), Vector2(px + pw * 0.5, minf(ground_y_base, py + 8.0)), Color(p_col.r, p_col.g, p_col.b, 0.4), 1.0)
			if p_type == PlatformType.ICE_SLAB:
				canvas.draw_circle(Vector2(px + pw * 0.3, py + 3.0), 1.0, Color.WHITE)
				canvas.draw_circle(Vector2(px + pw * 0.7, py + 3.0), 1.0, Color.WHITE)
			elif p_type == PlatformType.LAVA_GRATE:
				canvas.draw_circle(Vector2(px + pw * 0.5, py + 2.0), 1.5, Color(1.0, 0.35, 0.05))
			elif p_type == PlatformType.ENERGY_BARRIER:
				canvas.draw_line(Vector2(px + 4.0, py - 2.0), Vector2(px + pw - 4.0, py - 2.0), Color(0.8, 1.0, 1.0, 0.7), 1.0)
	
	# 4. Boss Stronghold Zone at 8800m
	var boss_x: float = map_rect.position.x + BOSS_TRIGGER_X * scale_x
	var boss_marker_rect := Rect2(boss_x - 3.0, map_rect.position.y + 4.0, 6.0, map_h - 8.0)
	var pulse: float = 0.75 + 0.25 * sin(anim_time * 6.0)
	canvas.draw_rect(boss_marker_rect, Color(1.0, 0.25, 0.25, 0.35 * pulse))
	canvas.draw_line(Vector2(boss_x, map_rect.position.y + 4.0), Vector2(boss_x, map_rect.end.y - 4.0), Color(1.0, 0.30, 0.30, pulse), 1.5)
	
	# Boss Target Icon
	var boss_icon_y := ground_y_base - 12.0
	canvas.draw_circle(Vector2(boss_x, boss_icon_y), 5.0, Color(1.0, 0.20, 0.20))
	canvas.draw_circle(Vector2(boss_x, boss_icon_y), 2.5, Color.WHITE)
	
	# 5. Player Commando Position Beacon (When in-game)
	if player_x >= 0.0:
		var p_norm_x := clampf(player_x, 0.0, LEVEL_MAX_X)
		var p_screen_x := map_rect.position.x + p_norm_x * scale_x
		var p_beacon_y := ground_y_base - 10.0
		var p_pulse := 0.6 + 0.4 * sin(anim_time * 9.0)
		
		# Glowing radar beacon rings
		canvas.draw_circle(Vector2(p_screen_x, p_beacon_y), 8.0 * p_pulse, Color(0.20, 0.95, 0.40, 0.30))
		canvas.draw_circle(Vector2(p_screen_x, p_beacon_y), 4.0, Color(0.25, 1.0, 0.45))
		canvas.draw_circle(Vector2(p_screen_x, p_beacon_y), 1.8, Color.WHITE)
		# Vertical tracking guideline
		canvas.draw_line(Vector2(p_screen_x, map_rect.position.y), Vector2(p_screen_x, map_rect.end.y), Color(0.25, 1.0, 0.45, 0.5), 1.0)
	
	# Border frame and corner tech ticks
	var border_col := prim_col if is_schematic else Color(0.25, 0.35, 0.48, 0.75)
	canvas.draw_rect(map_rect, border_col, false, 1.2)
	
	var c_len := 6.0
	canvas.draw_line(map_rect.position, map_rect.position + Vector2(c_len, 0.0), Color.WHITE, 1.5)
	canvas.draw_line(map_rect.position, map_rect.position + Vector2(0.0, c_len), Color.WHITE, 1.5)
	canvas.draw_line(map_rect.end, map_rect.end - Vector2(c_len, 0.0), Color.WHITE, 1.5)
	canvas.draw_line(map_rect.end, map_rect.end - Vector2(0.0, c_len), Color.WHITE, 1.5)
	
	# Schematic Telemetry Labels
	if is_schematic:
		var font := ThemeDB.fallback_font
		canvas.draw_string(font, map_rect.position + Vector2(8.0, 16.0), "TERRAIN PROFILE // " + m["sector"], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.85, 0.95, 1.0))
		canvas.draw_string(font, map_rect.position + Vector2(8.0, 30.0), "HAZARDS: " + m["hazard"], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.45, 0.45))
		canvas.draw_string(font, Vector2(boss_x - 44.0, map_rect.position.y + 16.0), "BOSS CORE ►", HORIZONTAL_ALIGNMENT_RIGHT, -1, 9, Color(1.0, 0.35, 0.35))
		canvas.draw_string(font, map_rect.position + Vector2(8.0, map_h - 6.0), "0m [DROP ZONE]", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.5, 0.7, 0.9))
		canvas.draw_string(font, Vector2(boss_x - 30.0, map_rect.end.y - 6.0), "8800m [CORE]", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1.0, 0.5, 0.5))
		canvas.draw_string(font, Vector2(map_rect.end.x - 68.0, map_rect.end.y - 6.0), "9800m [EXIT]", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.5, 0.7, 0.9))
