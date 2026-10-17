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
	BIO_RIB
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
				{"rect": Rect2(260.0, 370.0, 220.0, 16.0), "type": PlatformType.TURF, "variant": "default"},
				{"rect": Rect2(540.0, 280.0, 200.0, 16.0), "type": PlatformType.TURF, "variant": "small"},
				{"rect": Rect2(820.0, 360.0, 200.0, 16.0), "type": PlatformType.TURF, "variant": "default"},
				
				# Sector 2: Outer Fortress Perimeter (1240 - 2440)
				{"rect": Rect2(1360.0, 370.0, 240.0, 16.0), "type": PlatformType.TURF, "variant": "wedge_left"},
				{"rect": Rect2(1660.0, 290.0, 260.0, 16.0), "type": PlatformType.TURF, "variant": "wide"},
				{"rect": Rect2(1980.0, 215.0, 200.0, 16.0), "type": PlatformType.TURF, "variant": "thin"},
				{"rect": Rect2(2220.0, 310.0, 180.0, 16.0), "type": PlatformType.TURF, "variant": "small"},
				
				# Sector 3: Jungle Ravine & Catwalks (2580 - 3780)
				{"rect": Rect2(2700.0, 350.0, 240.0, 16.0), "type": PlatformType.TURF, "variant": "wedge_right"},
				{"rect": Rect2(3000.0, 270.0, 240.0, 16.0), "type": PlatformType.TURF, "variant": "default"},
				{"rect": Rect2(3300.0, 210.0, 200.0, 16.0), "type": PlatformType.TURF, "variant": "small"},
				{"rect": Rect2(3550.0, 310.0, 190.0, 16.0), "type": PlatformType.TURF, "variant": "thin"},
				
				# Sector 4: Jungle Canopy & Riverbank (3920 - 5120)
				{"rect": Rect2(4040.0, 360.0, 240.0, 16.0), "type": PlatformType.TURF, "variant": "wedge_left"},
				{"rect": Rect2(4340.0, 280.0, 260.0, 16.0), "type": PlatformType.TURF, "variant": "wide"},
				{"rect": Rect2(4660.0, 210.0, 200.0, 16.0), "type": PlatformType.TURF, "variant": "thin"},
				{"rect": Rect2(4920.0, 320.0, 180.0, 16.0), "type": PlatformType.TURF, "variant": "small"},
				
				# Sector 5: Heavy Fortress Battery & Mini-Boss Arena (5260 - 6220)
				{"rect": Rect2(5340.0, 360.0, 240.0, 16.0), "type": PlatformType.TURF, "variant": "wedge_left"},
				{"rect": Rect2(5640.0, 280.0, 280.0, 16.0), "type": PlatformType.TURF, "variant": "wide"},
				{"rect": Rect2(5960.0, 210.0, 200.0, 16.0), "type": PlatformType.TURF, "variant": "thin"},
				
				# =====================================================================
				# POST-MINI-BOSS FALLING PLATFORM SEQUENCE (6220 - 7720)
				# PURE BOTTOMLESS ABYSS - NO GROUND!
				# =====================================================================
				{"rect": Rect2(6260.0, 360.0, 130.0, 16.0), "type": PlatformType.TURF, "variant": "thin", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8},
				
				# LEVEL 1: High Skyway Route (y = 190 - 270)
				{"rect": Rect2(6430.0, 270.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "small", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8},
				{"rect": Rect2(6610.0, 215.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "thin", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8},
				{"rect": Rect2(6800.0, 190.0, 150.0, 16.0), "type": PlatformType.TURF, "variant": "wide", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8},
				{"rect": Rect2(7000.0, 210.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "small", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8},
				{"rect": Rect2(7200.0, 250.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "wedge_right", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8},
				{"rect": Rect2(7400.0, 290.0, 130.0, 16.0), "type": PlatformType.TURF, "variant": "thin", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8},
				
				# LEVEL 2: Mid Terrace Route (y = 300 - 330)
				{"rect": Rect2(6510.0, 330.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "default", "is_drop": true, "drop_delay": 0.50, "respawn_time": 2.8},
				{"rect": Rect2(6710.0, 310.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "wide", "is_drop": true, "drop_delay": 0.50, "respawn_time": 2.8},
				{"rect": Rect2(6910.0, 300.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "default", "is_drop": true, "drop_delay": 0.50, "respawn_time": 2.8},
				{"rect": Rect2(7110.0, 310.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "wedge_left", "is_drop": true, "drop_delay": 0.50, "respawn_time": 2.8},
				{"rect": Rect2(7320.0, 330.0, 130.0, 16.0), "type": PlatformType.TURF, "variant": "default", "is_drop": true, "drop_delay": 0.50, "respawn_time": 2.8},
				
				# LEVEL 3: Lower River Crag Route (y = 385 - 395)
				{"rect": Rect2(6410.0, 395.0, 130.0, 16.0), "type": PlatformType.TURF, "variant": "crag", "is_drop": true, "drop_delay": 0.55, "respawn_time": 2.8},
				{"rect": Rect2(6600.0, 390.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "crag", "is_drop": true, "drop_delay": 0.55, "respawn_time": 2.8},
				{"rect": Rect2(6800.0, 390.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "crag", "is_drop": true, "drop_delay": 0.55, "respawn_time": 2.8},
				{"rect": Rect2(7000.0, 395.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "crag", "is_drop": true, "drop_delay": 0.55, "respawn_time": 2.8},
				{"rect": Rect2(7200.0, 390.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "crag", "is_drop": true, "drop_delay": 0.55, "respawn_time": 2.8},
				{"rect": Rect2(7400.0, 390.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "crag", "is_drop": true, "drop_delay": 0.55, "respawn_time": 2.8},
				
				# Final Leap Threshold Platform into Fortress Gate
				{"rect": Rect2(7580.0, 350.0, 120.0, 16.0), "type": PlatformType.TURF, "variant": "small", "is_drop": true, "drop_delay": 0.50, "respawn_time": 2.8},
				
				# Sector 7 & 8: Fortress Approach & Boss Arena (7720 - 9800)
				{"rect": Rect2(7840.0, 340.0, 260.0, 16.0), "type": PlatformType.TURF, "variant": "wedge_left"},
				{"rect": Rect2(8160.0, 260.0, 260.0, 16.0), "type": PlatformType.TURF, "variant": "thin"},
				{"rect": Rect2(8500.0, 340.0, 220.0, 16.0), "type": PlatformType.TURF, "variant": "wide"},
				{"rect": Rect2(8900.0, 340.0, 180.0, 16.0), "type": PlatformType.TURF, "variant": "small"}
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
				# Sector 1: Drop Zone Shoreline & Bluff Escalation (0 - 1310)
				Rect2(0.0, 440.0, 400.0, 200.0),
				Rect2(480.0, 360.0, 360.0, 280.0),
				Rect2(930.0, 280.0, 380.0, 360.0),
				
				# Sector 2: Eagle's Pinnacle Summit & Gorge Descent (1400 - 2770)
				Rect2(1400.0, 200.0, 450.0, 440.0),
				Rect2(1950.0, 300.0, 370.0, 340.0),
				Rect2(2420.0, 390.0, 350.0, 250.0),
				
				# Sector 3: Sunken Cataract Basin & Rapid Escalation (2880 - 4290)
				Rect2(2880.0, 470.0, 440.0, 180.0),
				Rect2(3430.0, 370.0, 360.0, 270.0),
				Rect2(3890.0, 270.0, 400.0, 370.0),
				
				# Sector 4: High Torrent Ridge & Pre-Fortress Terrace (4390 - 5280)
				Rect2(4390.0, 210.0, 420.0, 430.0),
				Rect2(4920.0, 330.0, 360.0, 310.0),
				
				# Sector 5: Fortified Mini-Boss Arena (Aqua Assault Rig) (5360 - 6300)
				Rect2(5360.0, 440.0, 940.0, 200.0),
				
				# Sector 6: Granite Escalation, Cataract Spire & Falls Gorge (6410 - 7780)
				Rect2(6410.0, 340.0, 360.0, 300.0),
				Rect2(6880.0, 220.0, 420.0, 420.0),
				Rect2(7420.0, 350.0, 360.0, 290.0),
				
				# Sector 7 & 8: Citadel Ramparts & Hydro-Goliath Stronghold (7880 - 9820)
				Rect2(7880.0, 280.0, 400.0, 360.0),
				Rect2(8380.0, 360.0, 370.0, 280.0),
				Rect2(8820.0, 440.0, 1000.0, 200.0)
			]
			data["platforms"] = [
				# Sector 1: Cataract Foothills & Bluff Ascent (0 - 1310)
				{"rect": Rect2(180.0, 370.0, 160.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(300.0, 290.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(390.0, 400.0, 110.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(560.0, 270.0, 180.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(720.0, 200.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(830.0, 320.0, 120.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(1020.0, 200.0, 180.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(1180.0, 140.0, 140.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1300.0, 240.0, 120.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				
				# Sector 2: Pinnacle Summit & Gorge Descent (1400 - 2770)
				{"rect": Rect2(1480.0, 130.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1650.0, 150.0, 170.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(1830.0, 210.0, 150.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(1860.0, 260.0, 110.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(2020.0, 220.0, 180.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(2180.0, 150.0, 140.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2310.0, 330.0, 130.0, 16.0), "type": PlatformType.TURF},
				
				# Sector 3: Sunken Cataract Basin & Rapid Escalation (2880 - 4290)
				{"rect": Rect2(2500.0, 290.0, 180.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(2660.0, 210.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2760.0, 420.0, 130.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(2940.0, 390.0, 160.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(3060.0, 300.0, 170.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(3220.0, 220.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3310.0, 410.0, 130.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(3500.0, 290.0, 170.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(3660.0, 200.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3780.0, 310.0, 120.0, 16.0), "type": PlatformType.TURF},
				
				# Sector 4: Cascade Crag, Torrent Ridge & Approach (4390 - 5280)
				{"rect": Rect2(3980.0, 190.0, 180.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(4140.0, 130.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4280.0, 240.0, 120.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(4460.0, 140.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4640.0, 150.0, 160.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(4800.0, 260.0, 130.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(5000.0, 240.0, 170.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(5160.0, 300.0, 140.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5270.0, 370.0, 110.0, 16.0), "type": PlatformType.TURF},
				
				# Sector 5: Mini-Boss Arena Scaffoldings & Catwalks (5360 - 6300)
				{"rect": Rect2(5380.0, 340.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5580.0, 260.0, 220.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(5840.0, 320.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5680.0, 170.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(6100.0, 360.0, 160.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(6290.0, 380.0, 130.0, 16.0), "type": PlatformType.TURF},
				
				# Sector 6: Escalation Cliff, Cataract Spire & Falls Gorge (6410 - 7780)
				{"rect": Rect2(6480.0, 250.0, 180.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(6650.0, 180.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(6760.0, 270.0, 130.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(6950.0, 140.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7130.0, 150.0, 160.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(7290.0, 270.0, 140.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(7480.0, 260.0, 170.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(7640.0, 190.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7770.0, 310.0, 120.0, 16.0), "type": PlatformType.TURF},
				
				# Sector 7 & 8: Citadel Ramparts & Boss Stronghold (7880 - 9820)
				{"rect": Rect2(7950.0, 200.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(8130.0, 210.0, 160.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(8270.0, 310.0, 130.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(8460.0, 280.0, 170.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(8620.0, 200.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(8740.0, 380.0, 100.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(8880.0, 360.0, 180.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(9080.0, 270.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(9340.0, 210.0, 180.0, 16.0), "type": PlatformType.ROPE_BRIDGE}
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
				{"rect": Rect2(180.0, 360.0, 160.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(300.0, 280.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(380.0, 390.0, 110.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(560.0, 270.0, 180.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(710.0, 190.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(820.0, 310.0, 120.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(1020.0, 190.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(1180.0, 130.0, 140.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1290.0, 220.0, 120.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(1480.0, 120.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1660.0, 140.0, 170.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(1820.0, 200.0, 150.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(1840.0, 250.0, 110.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(2010.0, 220.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(2180.0, 140.0, 140.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2290.0, 340.0, 120.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(2480.0, 300.0, 180.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(2650.0, 220.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2730.0, 430.0, 130.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(2920.0, 390.0, 160.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(3060.0, 300.0, 170.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(3220.0, 220.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3280.0, 410.0, 130.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(3480.0, 280.0, 170.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(3650.0, 190.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3740.0, 310.0, 120.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(3950.0, 180.0, 180.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(4120.0, 120.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4240.0, 230.0, 120.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(4430.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4620.0, 140.0, 160.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(4770.0, 260.0, 130.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(4970.0, 240.0, 170.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(5140.0, 290.0, 140.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5250.0, 370.0, 110.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(5380.0, 340.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5580.0, 260.0, 220.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(5840.0, 320.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5680.0, 170.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(6100.0, 360.0, 160.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(6290.0, 380.0, 130.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(6480.0, 250.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(6650.0, 180.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(6760.0, 270.0, 130.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(6950.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7130.0, 140.0, 160.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(7280.0, 270.0, 140.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(7480.0, 260.0, 170.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(7640.0, 190.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7750.0, 310.0, 120.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(7930.0, 190.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(8120.0, 200.0, 160.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(8240.0, 310.0, 130.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(8440.0, 280.0, 170.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(8620.0, 200.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(8720.0, 380.0, 110.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(8880.0, 360.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(9080.0, 270.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(9340.0, 200.0, 180.0, 16.0), "type": PlatformType.BIO_RIB}
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
				{"rect": Rect2(180.0, 360.0, 160.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(300.0, 280.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(390.0, 400.0, 110.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(560.0, 270.0, 180.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(720.0, 190.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(830.0, 310.0, 120.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(1020.0, 190.0, 180.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(1190.0, 130.0, 140.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1310.0, 230.0, 120.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1490.0, 120.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1670.0, 140.0, 170.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(1840.0, 200.0, 150.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1860.0, 250.0, 110.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(2030.0, 220.0, 180.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(2200.0, 140.0, 140.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2320.0, 340.0, 120.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(2500.0, 300.0, 180.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(2670.0, 220.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2770.0, 430.0, 130.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(2940.0, 390.0, 160.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(3080.0, 300.0, 170.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(3240.0, 220.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3310.0, 410.0, 130.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(3500.0, 280.0, 170.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(3670.0, 190.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3770.0, 310.0, 120.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(3970.0, 180.0, 180.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(4150.0, 120.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4270.0, 230.0, 120.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(4460.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4650.0, 140.0, 160.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(4790.0, 260.0, 130.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(5000.0, 240.0, 170.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(5160.0, 290.0, 140.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5270.0, 370.0, 110.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(5380.0, 340.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5580.0, 260.0, 220.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(5840.0, 320.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5680.0, 170.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(6100.0, 360.0, 160.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(6290.0, 380.0, 130.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(6480.0, 250.0, 180.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(6650.0, 180.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(6760.0, 270.0, 130.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(6950.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7130.0, 140.0, 160.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(7280.0, 270.0, 140.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(7480.0, 260.0, 170.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(7640.0, 190.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7760.0, 310.0, 120.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(7940.0, 190.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(8130.0, 200.0, 160.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(8250.0, 310.0, 130.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(8450.0, 280.0, 170.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(8630.0, 200.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(8730.0, 380.0, 110.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(8890.0, 360.0, 180.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(9090.0, 270.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(9350.0, 200.0, 180.0, 16.0), "type": PlatformType.GIRDER}
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
				{"rect": Rect2(180.0, 360.0, 160.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(300.0, 280.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(380.0, 390.0, 110.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(550.0, 260.0, 180.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(710.0, 180.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(820.0, 300.0, 120.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1000.0, 180.0, 180.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(1170.0, 120.0, 140.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1290.0, 220.0, 120.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1470.0, 120.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1650.0, 140.0, 170.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(1810.0, 200.0, 150.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1830.0, 250.0, 110.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(2010.0, 220.0, 180.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(2180.0, 140.0, 140.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2290.0, 340.0, 120.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(2470.0, 300.0, 180.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(2640.0, 220.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2740.0, 430.0, 130.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(2920.0, 390.0, 160.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(3060.0, 300.0, 170.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(3220.0, 220.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3280.0, 410.0, 130.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(3480.0, 280.0, 170.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(3650.0, 190.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3740.0, 310.0, 120.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(3950.0, 180.0, 180.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(4120.0, 120.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4240.0, 230.0, 120.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(4430.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4620.0, 140.0, 160.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(4780.0, 260.0, 130.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(4980.0, 240.0, 170.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(5150.0, 290.0, 140.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5260.0, 370.0, 110.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(5380.0, 340.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5580.0, 260.0, 220.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(5840.0, 320.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5680.0, 170.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(6100.0, 360.0, 160.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(6290.0, 380.0, 130.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(6480.0, 250.0, 180.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(6650.0, 180.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(6760.0, 270.0, 130.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(6950.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7130.0, 140.0, 160.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(7280.0, 270.0, 140.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(7480.0, 260.0, 170.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(7640.0, 190.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7760.0, 310.0, 120.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(7940.0, 190.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(8130.0, 200.0, 160.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(8240.0, 310.0, 130.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(8440.0, 280.0, 170.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(8620.0, 200.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(8720.0, 380.0, 110.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(8880.0, 360.0, 180.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(9080.0, 270.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(9340.0, 200.0, 180.0, 16.0), "type": PlatformType.GIRDER}
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
				{"rect": Rect2(180.0, 360.0, 160.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(300.0, 280.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(390.0, 400.0, 110.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(560.0, 270.0, 180.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(710.0, 180.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(820.0, 310.0, 120.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(1010.0, 180.0, 180.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(1180.0, 120.0, 140.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1300.0, 220.0, 120.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1480.0, 120.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1660.0, 140.0, 170.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(1820.0, 200.0, 150.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1840.0, 250.0, 110.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(2020.0, 220.0, 180.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(2190.0, 140.0, 140.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2300.0, 340.0, 120.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(2480.0, 300.0, 180.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(2650.0, 220.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2750.0, 430.0, 130.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(2930.0, 390.0, 160.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(3070.0, 300.0, 170.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(3230.0, 220.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3300.0, 410.0, 130.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(3490.0, 280.0, 170.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(3660.0, 190.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3760.0, 310.0, 120.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(3960.0, 170.0, 180.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(4140.0, 120.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4260.0, 220.0, 120.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(4450.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4640.0, 140.0, 160.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(4780.0, 260.0, 130.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(4990.0, 240.0, 170.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(5160.0, 290.0, 140.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5270.0, 370.0, 110.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(5380.0, 340.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5580.0, 260.0, 220.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(5840.0, 320.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5680.0, 170.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(6100.0, 360.0, 160.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(6290.0, 380.0, 130.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(6490.0, 250.0, 180.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(6660.0, 180.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(6770.0, 270.0, 130.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(6960.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7140.0, 140.0, 160.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(7290.0, 270.0, 140.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(7490.0, 260.0, 170.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(7650.0, 190.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7770.0, 310.0, 120.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(7950.0, 190.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(8140.0, 200.0, 160.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(8260.0, 310.0, 130.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(8450.0, 280.0, 170.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(8630.0, 200.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(8730.0, 380.0, 110.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(8890.0, 360.0, 180.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(9090.0, 270.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(9350.0, 200.0, 180.0, 16.0), "type": PlatformType.GIRDER}
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
				{"rect": Rect2(180.0, 360.0, 160.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(300.0, 280.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(390.0, 400.0, 110.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(560.0, 270.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(710.0, 180.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(830.0, 310.0, 120.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1020.0, 180.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(1190.0, 120.0, 140.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1310.0, 220.0, 120.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1490.0, 120.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1670.0, 140.0, 170.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(1830.0, 200.0, 150.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1850.0, 250.0, 110.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(2030.0, 220.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(2200.0, 140.0, 140.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2310.0, 340.0, 120.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(2490.0, 300.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(2660.0, 220.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2760.0, 430.0, 130.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(2940.0, 390.0, 160.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(3080.0, 300.0, 170.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(3240.0, 220.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3310.0, 410.0, 130.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(3500.0, 280.0, 170.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(3670.0, 190.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3770.0, 310.0, 120.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(3970.0, 170.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(4150.0, 120.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4270.0, 220.0, 120.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(4460.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4650.0, 140.0, 160.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(4790.0, 260.0, 130.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(5000.0, 240.0, 170.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(5170.0, 290.0, 140.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5280.0, 370.0, 110.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(5380.0, 340.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5580.0, 260.0, 220.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(5840.0, 320.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5680.0, 170.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(6100.0, 360.0, 160.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(6290.0, 380.0, 130.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(6490.0, 250.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(6660.0, 180.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(6770.0, 270.0, 130.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(6960.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7140.0, 140.0, 160.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(7290.0, 270.0, 140.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(7490.0, 260.0, 170.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(7650.0, 190.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7770.0, 310.0, 120.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(7950.0, 190.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(8140.0, 200.0, 160.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(8260.0, 310.0, 130.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(8450.0, 280.0, 170.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(8630.0, 200.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(8730.0, 380.0, 110.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(8890.0, 360.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(9090.0, 270.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(9350.0, 200.0, 180.0, 16.0), "type": PlatformType.GIRDER}
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
				{"rect": Rect2(180.0, 360.0, 160.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(300.0, 280.0, 150.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(390.0, 400.0, 110.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(560.0, 270.0, 180.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(710.0, 180.0, 150.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(830.0, 310.0, 120.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(1020.0, 180.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(1190.0, 120.0, 140.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1310.0, 220.0, 120.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(1490.0, 120.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1670.0, 140.0, 170.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(1830.0, 200.0, 150.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(1850.0, 250.0, 110.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(2030.0, 220.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(2200.0, 140.0, 140.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2310.0, 340.0, 120.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(2490.0, 300.0, 180.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(2660.0, 220.0, 150.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(2760.0, 430.0, 130.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(2940.0, 390.0, 160.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(3080.0, 300.0, 170.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(3240.0, 220.0, 150.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(3310.0, 410.0, 130.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(3500.0, 280.0, 170.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(3670.0, 190.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3770.0, 310.0, 120.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(3970.0, 170.0, 180.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(4150.0, 120.0, 150.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(4270.0, 220.0, 120.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(4460.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4650.0, 140.0, 160.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(4790.0, 260.0, 130.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(5000.0, 240.0, 170.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(5170.0, 290.0, 140.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5280.0, 370.0, 110.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(5380.0, 340.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5580.0, 260.0, 220.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(5840.0, 320.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5680.0, 170.0, 160.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(6100.0, 360.0, 160.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(6290.0, 380.0, 130.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(6490.0, 250.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(6660.0, 180.0, 150.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(6770.0, 270.0, 130.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(6960.0, 130.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7140.0, 140.0, 160.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(7290.0, 270.0, 140.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(7490.0, 260.0, 170.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(7650.0, 190.0, 150.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(7770.0, 310.0, 120.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(7950.0, 190.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(8140.0, 200.0, 160.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(8260.0, 310.0, 130.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(8450.0, 280.0, 170.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(8630.0, 200.0, 150.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(8730.0, 380.0, 110.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(8890.0, 360.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(9090.0, 270.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(9350.0, 200.0, 180.0, 16.0), "type": PlatformType.ENERGY_BARRIER}
			]
	# Platform rule: If a pit between floor tiles can be crossed by jump, don't add any platform above it
	const MAX_JUMP_GAP: float = 200.0 # Player standard jump distance is ~170-202px
	var grounds: Array = data.get("ground_segments", [])
	var filtered_platforms: Array[Dictionary] = []
	for p in data.get("platforms", []):
		var pr: Rect2 = p.get("rect", Rect2())
		var is_above_jumpable_pit: bool = false
		for i in range(grounds.size() - 1):
			var pit_l: float = grounds[i].end.x
			var pit_r: float = grounds[i + 1].position.x
			var pit_w: float = pit_r - pit_l
			if pit_w > 0.0 and pit_w <= MAX_JUMP_GAP and absf(grounds[i].position.y - grounds[i + 1].position.y) < 15.0:
				var overlap_l: float = maxf(pr.position.x, pit_l)
				var overlap_r: float = minf(pr.end.x, pit_r)
				var overlap_w: float = overlap_r - overlap_l
				if overlap_w >= pit_w * 0.4:
					is_above_jumpable_pit = true
					break
		if not is_above_jumpable_pit:
			filtered_platforms.append(p)
	data["platforms"] = filtered_platforms

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
