class_name LevelMaps
extends RefCounted

# =============================================================================
# CONTRA RE - TACTICAL LEVEL MAP DATABASE & SCHEMATIC RENDERER
# =============================================================================

# Old editor saves remain available in Contra Maker but do not mask a new campaign.
const CAMPAIGN_REVISION: int = 2
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

static func parse_platform_type(val: Variant) -> int:
	if val is int:
		return val
	if val is float:
		return int(val)
	if val is String:
		var s: String = str(val).strip_edges().to_lower()
		match s:
			"0", "turf", "default":
				return PlatformType.TURF
			"1", "girder":
				return PlatformType.GIRDER
			"2", "bridge", "rope_bridge":
				return PlatformType.ROPE_BRIDGE
			"3", "perch", "high_perch":
				return PlatformType.HIGH_PERCH
			"4", "ice", "ice_slab":
				return PlatformType.ICE_SLAB
			"5", "lava", "lava_grate":
				return PlatformType.LAVA_GRATE
			"6", "energy", "energy_barrier":
				return PlatformType.ENERGY_BARRIER
			"7", "tech", "platform_tech", "catwalk", "tech_catwalk":
				return PlatformType.TECH_CATWALK
			"8", "bio", "bio_rib":
				return PlatformType.BIO_RIB
			"9", "waterfall", "waterfall_ledge", "ledge":
				return PlatformType.WATERFALL_LEDGE
	return 0

static func get_map_data(stage_id: int, include_legacy_custom: bool = false) -> Dictionary:
	var s_id := clampi(stage_id, 1, 8)
	var custom_path := "user://custom_levels/stage_%d.json" % s_id
	if FileAccess.file_exists(custom_path):
		var custom_data := load_custom_stage_data(custom_path, s_id)
		if not custom_data.is_empty():
			if include_legacy_custom or int(custom_data.get("campaign_revision", 0)) >= CAMPAIGN_REVISION:
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
	def["campaign_revision"] = int(data.get("campaign_revision", 0))
	
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
				"type": parse_platform_type(p.get("type", 0)),
				"is_drop": p.get("is_drop", false),
				"is_lift": p.get("is_lift", false),
				"lift_amplitude": p.get("lift_amplitude", 36.0),
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
			data["intel"] = "Secure the beach supply cache, flank the outpost via its gantries, and cross the canopy ledges. Defeat Titan Goliath, choose the river stepping stones or the faster upper route, then rearm for the fortress assault."
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
				{"rect": Rect2(240.0, 360.0, 180.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(480.0, 280.0, 200.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(780.0, 350.0, 190.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(1050.0, 370.0, 180.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(1460.0, 364.0, 180.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(1620.0, 280.0, 180.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1820.0, 250.0, 120.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1950.0, 215.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2180.0, 320.0, 160.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(2390.0, 370.0, 180.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(2720.0, 344.0, 180.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(2960.0, 260.0, 190.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(3190.0, 240.0, 140.0, 16.0), "type": PlatformType.TURF, "is_drop": true, "drop_delay": 0.85, "respawn_time": 2.8},
				{"rect": Rect2(3390.0, 204.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3580.0, 310.0, 160.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(3730.0, 365.0, 180.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(4110.0, 354.0, 180.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(4290.0, 270.0, 190.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(4500.0, 240.0, 140.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(4660.0, 204.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4940.0, 320.0, 160.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(5070.0, 370.0, 180.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(5360.0, 354.0, 180.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(5600.0, 270.0, 200.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(5820.0, 245.0, 100.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(5920.0, 215.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(6120.0, 340.0, 160.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(6290.0, 365.0, 150.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(6480.0, 310.0, 150.0, 16.0), "type": PlatformType.TURF, "is_drop": true, "drop_delay": 0.65, "respawn_time": 2.8},
				{"rect": Rect2(6680.0, 250.0, 170.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(6910.0, 220.0, 150.0, 16.0), "type": PlatformType.TURF, "is_drop": true, "drop_delay": 0.65, "respawn_time": 2.8},
				{"rect": Rect2(7110.0, 250.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7340.0, 290.0, 150.0, 16.0), "type": PlatformType.TURF, "is_drop": true, "drop_delay": 0.65, "respawn_time": 2.8},
				{"rect": Rect2(7540.0, 350.0, 160.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(6480.0, 410.0, 150.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(6690.0, 390.0, 170.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(6910.0, 400.0, 160.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(7120.0, 390.0, 170.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(7340.0, 410.0, 150.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(7770.0, 365.0, 120.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(7910.0, 334.0, 180.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(8110.0, 250.0, 180.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(8320.0, 285.0, 120.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(8460.0, 334.0, 180.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(8680.0, 380.0, 140.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(8840.0, 330.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
			]
		2:
			data["name"] = "WATERFALL FORTRESS"
			data["sector"] = "SECTOR 02 // CATARACT CHASM"
			data["theme"] = "TORRENTIAL CLIFFSIDE"
			data["diff"] = "HARD"
			data["boss"] = "HYDRO-GOLIATH MECH"
			data["hazard"] = "RUSHING WATERFALLS & CLIFF PITS"
			data["intel"] = "Climb the foothill terraces, descend into the torrent basin, and take the upper rock shelves for supplies. Defeat the Aqua Assault Rig, regroup at the riverbank, then scale the three cataract spires to the citadel."
			data["primary_color"] = Color(0.20, 0.65, 0.95)
			data["accent_color"] = Color(0.60, 0.90, 1.0)
			# Authored terrain: approach, route choice, battery, recovery, final assault.
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 620.0, 200.0),
				Rect2(700.0, 360.0, 420.0, 280.0),
				Rect2(1200.0, 280.0, 460.0, 360.0),
				Rect2(1740.0, 200.0, 520.0, 440.0),
				Rect2(2360.0, 300.0, 520.0, 340.0),
				Rect2(3000.0, 440.0, 500.0, 200.0),
				Rect2(3620.0, 360.0, 400.0, 280.0),
				Rect2(4140.0, 280.0, 380.0, 360.0),
				Rect2(4640.0, 350.0, 520.0, 290.0),
				Rect2(5260.0, 440.0, 1040.0, 200.0),
				Rect2(6420.0, 360.0, 360.0, 280.0),
				Rect2(6900.0, 280.0, 360.0, 360.0),
				Rect2(7400.0, 200.0, 380.0, 440.0),
				Rect2(7900.0, 320.0, 420.0, 320.0),
				Rect2(8440.0, 440.0, 1360.0, 200.0),
			]
			data["platforms"] = [
				{"rect": Rect2(220.0, 360.0, 180.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(420.0, 290.0, 170.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(596.0, 400.0, 128.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(800.0, 280.0, 160.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(1096.0, 320.0, 128.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(1310.0, 200.0, 180.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(1636.0, 240.0, 128.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(1810.0, 130.0, 190.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2236.0, 250.0, 148.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(2420.0, 230.0, 170.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(2856.0, 370.0, 168.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(3070.0, 360.0, 180.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(3260.0, 280.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3476.0, 400.0, 168.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(3690.0, 280.0, 180.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(3996.0, 320.0, 168.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(4220.0, 200.0, 180.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(4496.0, 315.0, 168.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(4750.0, 270.0, 180.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(5136.0, 395.0, 148.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(5430.0, 360.0, 180.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(5630.0, 280.0, 190.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5990.0, 355.0, 180.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(6276.0, 400.0, 168.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(6490.0, 280.0, 180.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(6756.0, 320.0, 168.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(6970.0, 200.0, 180.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(7236.0, 240.0, 188.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(7470.0, 120.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7756.0, 260.0, 168.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(7980.0, 240.0, 180.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(8296.0, 380.0, 168.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(8500.0, 360.0, 180.0, 16.0), "type": PlatformType.WATERFALL_LEDGE},
				{"rect": Rect2(8700.0, 280.0, 170.0, 16.0), "type": PlatformType.HIGH_PERCH},
			]
		3:
			data["name"] = "ALIEN HIVE BIO-CAVERN"
			data["sector"] = "SECTOR 03 // SUBTERRANEAN HIVE"
			data["theme"] = "ORGANIC FLESH CAVERNS"
			data["diff"] = "HARD"
			data["boss"] = "GIGA BIO-HEART"
			data["hazard"] = "ORGANIC ACID PITS & CHITIN CHASM"
			data["intel"] = "Breach the low hive tunnels or climb the rib shelves to flank the spore chambers. Learn unstable tissue over solid ground, defeat the Chitin Behemoth, and cross the upper organ route before attacking the bio-heart."
			data["primary_color"] = Color(0.85, 0.25, 0.40)
			data["accent_color"] = Color(1.0, 0.60, 0.70)
			# Authored terrain: approach, route choice, battery, recovery, final assault.
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 980.0, 200.0),
				Rect2(1100.0, 390.0, 660.0, 250.0),
				Rect2(1880.0, 470.0, 640.0, 170.0),
				Rect2(2640.0, 410.0, 680.0, 230.0),
				Rect2(3440.0, 330.0, 720.0, 310.0),
				Rect2(4280.0, 400.0, 880.0, 240.0),
				Rect2(5260.0, 440.0, 1040.0, 200.0),
				Rect2(6420.0, 410.0, 600.0, 230.0),
				Rect2(7140.0, 340.0, 520.0, 300.0),
				Rect2(7800.0, 410.0, 840.0, 230.0),
				Rect2(8760.0, 440.0, 1040.0, 200.0),
			]
			data["platforms"] = [
				{"rect": Rect2(240.0, 360.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(440.0, 280.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(956.0, 415.0, 168.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(1180.0, 310.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(1380.0, 230.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(1580.0, 165.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1736.0, 430.0, 168.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(1950.0, 390.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(2150.0, 310.0, 180.0, 16.0), "type": PlatformType.BIO_RIB, "is_drop": true, "drop_delay": 0.8, "respawn_time": 2.8},
				{"rect": Rect2(2350.0, 230.0, 170.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(2496.0, 440.0, 168.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(2710.0, 330.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(2910.0, 250.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(3110.0, 185.0, 160.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3296.0, 370.0, 168.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(3520.0, 250.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(3720.0, 180.0, 180.0, 16.0), "type": PlatformType.BIO_RIB, "is_drop": true, "drop_delay": 0.8, "respawn_time": 2.8},
				{"rect": Rect2(3920.0, 180.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(4136.0, 365.0, 168.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(4370.0, 320.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(4570.0, 240.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5136.0, 420.0, 148.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(5440.0, 360.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(5650.0, 280.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(6276.0, 425.0, 168.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(6530.0, 330.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(6750.0, 250.0, 180.0, 16.0), "type": PlatformType.BIO_RIB, "is_drop": true, "drop_delay": 0.8, "respawn_time": 2.8},
				{"rect": Rect2(6996.0, 375.0, 168.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(7220.0, 260.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(7420.0, 185.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7636.0, 375.0, 188.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(7900.0, 330.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(8100.0, 250.0, 180.0, 16.0), "type": PlatformType.BIO_RIB, "is_drop": true, "drop_delay": 0.8, "respawn_time": 2.8},
				{"rect": Rect2(8310.0, 250.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(8500.0, 330.0, 140.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(8616.0, 425.0, 168.0, 16.0), "type": PlatformType.BIO_RIB},
			]
		4:
			data["name"] = "SNOWFIELD TUNDRA"
			data["sector"] = "SECTOR 04 // FROSTBITE RIDGE"
			data["theme"] = "ARCTIC BLIZZARD & PERMAFROST"
			data["diff"] = "EXPERT"
			data["boss"] = "FROSTBITE SIEGE TANK"
			data["hazard"] = "SUB-ZERO GLACIAL CREVASSES"
			data["intel"] = "Build momentum across broad snowfields, brake on steel resting decks, and climb above the icicle ambushes. Defeat the Polar Siege Colossus, cross the broken glacier shelves, and assault the siege tank."
			data["primary_color"] = Color(0.40, 0.85, 1.0)
			data["accent_color"] = Color(0.85, 0.95, 1.0)
			# Authored terrain: approach, route choice, battery, recovery, final assault.
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 960.0, 200.0),
				Rect2(1080.0, 410.0, 680.0, 230.0),
				Rect2(1920.0, 350.0, 680.0, 290.0),
				Rect2(2760.0, 450.0, 660.0, 190.0),
				Rect2(3580.0, 380.0, 620.0, 260.0),
				Rect2(4360.0, 420.0, 800.0, 220.0),
				Rect2(5260.0, 440.0, 1040.0, 200.0),
				Rect2(6460.0, 400.0, 660.0, 240.0),
				Rect2(7280.0, 340.0, 520.0, 300.0),
				Rect2(7960.0, 410.0, 680.0, 230.0),
				Rect2(8760.0, 440.0, 1040.0, 200.0),
			]
			data["platforms"] = [
				{"rect": Rect2(250.0, 360.0, 220.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(500.0, 280.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(936.0, 425.0, 168.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1170.0, 330.0, 220.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(1430.0, 250.0, 220.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1736.0, 380.0, 208.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(2040.0, 270.0, 230.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(2300.0, 200.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2576.0, 400.0, 208.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(2850.0, 370.0, 230.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(3110.0, 290.0, 230.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(3396.0, 415.0, 208.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(3660.0, 300.0, 220.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(3920.0, 220.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4176.0, 400.0, 208.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(4440.0, 340.0, 240.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(4720.0, 260.0, 220.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(5136.0, 430.0, 148.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(5440.0, 360.0, 220.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(5680.0, 280.0, 200.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(6276.0, 420.0, 208.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(6530.0, 320.0, 230.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(6790.0, 240.0, 230.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(7096.0, 370.0, 208.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(7360.0, 260.0, 240.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(7610.0, 190.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7776.0, 375.0, 208.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(8040.0, 330.0, 230.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(8310.0, 250.0, 220.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(8616.0, 425.0, 168.0, 16.0), "type": PlatformType.GIRDER},
			]
		5:
			data["name"] = "STEEL REFINERY"
			data["sector"] = "SECTOR 05 // VULCAN FOUNDRY"
			data["theme"] = "INDUSTRIAL SMELTING PLANT"
			data["diff"] = "EXPERT"
			data["boss"] = "MAGMA FORGE GOLEM"
			data["hazard"] = "MOLTEN LAVA POOLS & CHAIN GIRDERS"
			data["intel"] = "Advance through alternating production decks and molten trenches. Use fixed girders to wait out vent eruptions or ride the upper conveyor route for supplies. Break the foundry dreadnought, rearm, then climb the furnace gantries."
			data["primary_color"] = Color(1.0, 0.50, 0.15)
			data["accent_color"] = Color(1.0, 0.85, 0.20)
			# Authored terrain: approach, route choice, battery, recovery, final assault.
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 980.0, 200.0),
				Rect2(1120.0, 380.0, 700.0, 260.0),
				Rect2(1980.0, 440.0, 700.0, 200.0),
				Rect2(2840.0, 380.0, 660.0, 260.0),
				Rect2(3660.0, 440.0, 720.0, 200.0),
				Rect2(4540.0, 360.0, 620.0, 280.0),
				Rect2(5260.0, 440.0, 1040.0, 200.0),
				Rect2(6460.0, 420.0, 720.0, 220.0),
				Rect2(7340.0, 340.0, 580.0, 300.0),
				Rect2(8080.0, 400.0, 560.0, 240.0),
				Rect2(8760.0, 440.0, 1040.0, 200.0),
			]
			data["platforms"] = [
				{"rect": Rect2(240.0, 360.0, 180.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(440.0, 280.0, 180.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(956.0, 410.0, 188.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1220.0, 300.0, 200.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1450.0, 220.0, 190.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1796.0, 410.0, 208.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(2070.0, 360.0, 200.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(2300.0, 280.0, 200.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(2656.0, 410.0, 208.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(2910.0, 300.0, 200.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(3140.0, 220.0, 200.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3476.0, 410.0, 208.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(3750.0, 360.0, 200.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(3980.0, 280.0, 200.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(4356.0, 400.0, 208.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(4610.0, 280.0, 200.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(4840.0, 210.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5136.0, 400.0, 148.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(5430.0, 360.0, 190.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(5650.0, 280.0, 200.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(6276.0, 430.0, 208.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(6550.0, 340.0, 200.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(6780.0, 260.0, 200.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(7156.0, 380.0, 208.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(7410.0, 260.0, 190.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(7630.0, 185.0, 200.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7896.0, 370.0, 208.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(8180.0, 320.0, 190.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(8400.0, 240.0, 180.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(8616.0, 420.0, 168.0, 16.0), "type": PlatformType.GIRDER},
			]
		6:
			data["name"] = "ELECTRIC DYNAMO"
			data["sector"] = "SECTOR 06 // TESLA SUBSTATION"
			data["theme"] = "HIGH-VOLTAGE POWER GRID"
			data["diff"] = "EXPERT"
			data["boss"] = "THUNDER DYNAMO"
			data["hazard"] = "ARC DISCHARGE CHASM & CONDENSERS"
			data["intel"] = "Study the first surge platform from a safe capacitor deck. Choose the grounded combat lane or timed upper circuit, destroy the Tesla Storm Overlord, and traverse the final charged towers to the dynamo."
			data["primary_color"] = Color(0.95, 0.85, 0.20)
			data["accent_color"] = Color(0.40, 0.90, 1.0)
			# Authored terrain: approach, route choice, battery, recovery, final assault.
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 900.0, 200.0),
				Rect2(1040.0, 380.0, 680.0, 260.0),
				Rect2(1860.0, 320.0, 580.0, 320.0),
				Rect2(2580.0, 420.0, 680.0, 220.0),
				Rect2(3400.0, 350.0, 660.0, 290.0),
				Rect2(4200.0, 300.0, 560.0, 340.0),
				Rect2(4900.0, 380.0, 260.0, 260.0),
				Rect2(5260.0, 440.0, 1040.0, 200.0),
				Rect2(6440.0, 380.0, 640.0, 260.0),
				Rect2(7220.0, 300.0, 640.0, 340.0),
				Rect2(8000.0, 380.0, 640.0, 260.0),
				Rect2(8760.0, 440.0, 1040.0, 200.0),
			]
			data["platforms"] = [
				{"rect": Rect2(230.0, 360.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(430.0, 280.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(876.0, 410.0, 188.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(1120.0, 300.0, 180.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(1320.0, 220.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(1510.0, 220.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1696.0, 350.0, 188.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(1930.0, 240.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(2130.0, 165.0, 180.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(2416.0, 370.0, 188.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(2670.0, 340.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(2870.0, 260.0, 180.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(3070.0, 200.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3236.0, 385.0, 188.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(3480.0, 270.0, 180.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(3680.0, 190.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(4036.0, 325.0, 188.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(4270.0, 220.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(4470.0, 145.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4736.0, 340.0, 188.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(5136.0, 410.0, 148.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(5440.0, 360.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(5650.0, 280.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(6276.0, 410.0, 188.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(6510.0, 300.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(6710.0, 220.0, 180.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(7056.0, 340.0, 188.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(7300.0, 220.0, 180.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(7500.0, 150.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7836.0, 340.0, 188.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(8090.0, 300.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(8290.0, 220.0, 180.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(8616.0, 410.0, 168.0, 16.0), "type": PlatformType.TECH_CATWALK},
			]
		7:
			data["name"] = "ALIEN AEROSPACE HANGAR"
			data["sector"] = "SECTOR 07 // ORBITAL STARPORT"
			data["theme"] = "SPACE LAUNCH BAYS"
			data["diff"] = "NIGHTMARE"
			data["boss"] = "VANGUARD STAR CRUISER"
			data["hazard"] = "VACUUM EXHAUST DUCTS & TURRETS"
			data["intel"] = "Clear the cargo bays, choose fixed gantries or optional hydraulic lifts, and evade security tripwires from the upper route. Defeat the Orbital Strike Vanguard, regroup at the service dock, and storm the launch deck."
			data["primary_color"] = Color(0.70, 0.45, 0.95)
			data["accent_color"] = Color(0.35, 0.85, 1.0)
			# Authored terrain: approach, route choice, battery, recovery, final assault.
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 1180.0, 200.0),
				Rect2(1340.0, 370.0, 780.0, 270.0),
				Rect2(2280.0, 440.0, 800.0, 200.0),
				Rect2(3240.0, 360.0, 780.0, 280.0),
				Rect2(4180.0, 410.0, 980.0, 230.0),
				Rect2(5260.0, 440.0, 1040.0, 200.0),
				Rect2(6480.0, 400.0, 740.0, 240.0),
				Rect2(7380.0, 320.0, 580.0, 320.0),
				Rect2(8120.0, 390.0, 520.0, 250.0),
				Rect2(8780.0, 440.0, 1020.0, 200.0),
			]
			data["platforms"] = [
				{"rect": Rect2(250.0, 360.0, 190.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(470.0, 280.0, 190.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(710.0, 280.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK, "is_lift": true, "lift_amplitude": 36.0},
				{"rect": Rect2(1156.0, 405.0, 208.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1420.0, 290.0, 190.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1630.0, 210.0, 190.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1860.0, 210.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(2096.0, 405.0, 208.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(2370.0, 360.0, 200.0, 16.0), "type": PlatformType.TECH_CATWALK, "is_lift": true, "lift_amplitude": 36.0},
				{"rect": Rect2(2610.0, 280.0, 200.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(2850.0, 210.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3056.0, 400.0, 208.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(3320.0, 280.0, 190.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(3530.0, 200.0, 190.0, 16.0), "type": PlatformType.TECH_CATWALK, "is_lift": true, "lift_amplitude": 36.0},
				{"rect": Rect2(3760.0, 200.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(3996.0, 385.0, 208.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(4270.0, 330.0, 190.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(4480.0, 250.0, 190.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(4700.0, 180.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5136.0, 425.0, 148.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(5440.0, 360.0, 190.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(5660.0, 280.0, 190.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(6276.0, 420.0, 228.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(6570.0, 320.0, 190.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(6780.0, 240.0, 190.0, 16.0), "type": PlatformType.TECH_CATWALK, "is_lift": true, "lift_amplitude": 36.0},
				{"rect": Rect2(7010.0, 240.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(7196.0, 360.0, 208.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(7460.0, 240.0, 190.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(7670.0, 165.0, 190.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7936.0, 355.0, 208.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(8200.0, 310.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK, "is_lift": true, "lift_amplitude": 36.0},
				{"rect": Rect2(8410.0, 230.0, 180.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(8616.0, 415.0, 188.0, 16.0), "type": PlatformType.GIRDER},
			]
		8:
			data["name"] = "MOTHER BRAIN SANCTUM"
			data["sector"] = "SECTOR 08 // ALIEN CENTRAL CORE"
			data["theme"] = "LIVING PSYCHIC BIO-SANCTUM"
			data["diff"] = "APOCALYPSE"
			data["boss"] = "EMPEROR MOTHER BRAIN"
			data["hazard"] = "BIO-NEURAL ACID CHASMS"
			data["intel"] = "Breach the neural gate, flank the sentry chambers via rib shelves, and cross unstable synapse ledges. Defeat the Psionic Hive Leviathan, rearm in the outer chamber, and push through the final layered defenses to Mother Brain."
			data["primary_color"] = Color(1.0, 0.25, 0.35)
			data["accent_color"] = Color(0.95, 0.85, 0.20)
			# Authored terrain: approach, route choice, battery, recovery, final assault.
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 860.0, 200.0),
				Rect2(1000.0, 370.0, 680.0, 270.0),
				Rect2(1820.0, 430.0, 700.0, 210.0),
				Rect2(2660.0, 340.0, 700.0, 300.0),
				Rect2(3500.0, 420.0, 760.0, 220.0),
				Rect2(4400.0, 330.0, 760.0, 310.0),
				Rect2(5260.0, 440.0, 1040.0, 200.0),
				Rect2(6440.0, 380.0, 660.0, 260.0),
				Rect2(7240.0, 320.0, 540.0, 320.0),
				Rect2(7920.0, 400.0, 720.0, 240.0),
				Rect2(8780.0, 440.0, 1020.0, 200.0),
			]
			data["platforms"] = [
				{"rect": Rect2(230.0, 360.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(430.0, 280.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(836.0, 405.0, 188.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(1070.0, 290.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(1270.0, 210.0, 180.0, 16.0), "type": PlatformType.BIO_RIB, "is_drop": true, "drop_delay": 0.8, "respawn_time": 2.8},
				{"rect": Rect2(1470.0, 160.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1656.0, 400.0, 188.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(1900.0, 350.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(2100.0, 270.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(2300.0, 200.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2496.0, 385.0, 188.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(2740.0, 260.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(2940.0, 180.0, 180.0, 16.0), "type": PlatformType.BIO_RIB, "is_drop": true, "drop_delay": 0.8, "respawn_time": 2.8},
				{"rect": Rect2(3140.0, 180.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3336.0, 380.0, 188.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(3580.0, 340.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(3780.0, 260.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(3980.0, 190.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4236.0, 375.0, 188.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(4480.0, 250.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(4680.0, 175.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5136.0, 385.0, 148.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(5440.0, 360.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(5650.0, 280.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(6276.0, 410.0, 188.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(6530.0, 300.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(6730.0, 225.0, 180.0, 16.0), "type": PlatformType.BIO_RIB, "is_drop": true, "drop_delay": 0.8, "respawn_time": 2.8},
				{"rect": Rect2(7076.0, 350.0, 188.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(7330.0, 240.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(7530.0, 165.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7756.0, 360.0, 188.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(8010.0, 320.0, 180.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(8210.0, 240.0, 180.0, 16.0), "type": PlatformType.BIO_RIB, "is_drop": true, "drop_delay": 0.8, "respawn_time": 2.8},
				{"rect": Rect2(8420.0, 240.0, 180.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(8616.0, 420.0, 188.0, 16.0), "type": PlatformType.BIO_RIB},
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
		
		var p_type: int = parse_platform_type(p.get("type", 0))
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
			PlatformType.WATERFALL_LEDGE: p_col = Color(0.40, 0.80, 0.90)
		
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
