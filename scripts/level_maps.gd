class_name LevelMaps
extends RefCounted

# =============================================================================
# CONTRA RE - TACTICAL LEVEL MAP DATABASE & SCHEMATIC RENDERER
# =============================================================================

const LEVEL_MIN_X: float = 0.0
const LEVEL_MAX_X: float = 6700.0
const BOSS_TRIGGER_X: float = 5800.0

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
			data["intel"] = "Infiltrate perimeter via coastline sandbars. Leap across river chasms using floating turf ledges and eliminate outer fortress turrets."
			data["primary_color"] = Color(0.25, 0.75, 0.35)
			data["accent_color"] = Color(0.95, 0.85, 0.20)
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 820.0, 200.0),       # Sector 1: Landing Beach (0 - 820)
				Rect2(960.0, 440.0, 860.0, 200.0),     # Sector 2: Outer Fortress Perimeter (960 - 1820)
				Rect2(1960.0, 440.0, 900.0, 200.0),    # Sector 3: Jungle Ravine & Catwalks (1960 - 2860)
				Rect2(3000.0, 440.0, 880.0, 200.0),    # Sector 4: Heavy Fortress Battery & Mini-Boss Arena (3000 - 3880)
				# SECTOR 5 IS A PURE BOTTOMLESS ABYSS (3880 - 5140): NO GROUND!
				Rect2(5140.0, 440.0, 1560.0, 200.0)    # Sector 6 & 7: Fortress Approach & Boss Arena (5140 - 6700)
			]
			data["platforms"] = [
				# Sector 1: Landing Beach (0 - 820)
				{"rect": Rect2(240.0, 370.0, 200.0, 16.0), "type": PlatformType.TURF, "variant": "default"},
				{"rect": Rect2(460.0, 280.0, 180.0, 16.0), "type": PlatformType.TURF, "variant": "small"},
				# Chasm 1 (820 - 960): River Gorge Chasm Turf Crag
				{"rect": Rect2(800.0, 340.0, 200.0, 16.0), "type": PlatformType.TURF, "variant": "crag"},
				
				# Sector 2: Outer Fortress Perimeter (960 - 1820)
				{"rect": Rect2(1060.0, 370.0, 240.0, 16.0), "type": PlatformType.TURF, "variant": "wedge_left"},
				{"rect": Rect2(1240.0, 295.0, 260.0, 16.0), "type": PlatformType.TURF, "variant": "wide"},
				{"rect": Rect2(1460.0, 225.0, 180.0, 16.0), "type": PlatformType.TURF, "variant": "thin"},
				# Chasm 2 (1820 - 1960): Deep River Canyon
				{"rect": Rect2(1800.0, 330.0, 200.0, 16.0), "type": PlatformType.TURF, "variant": "crag"},
				
				# Sector 3: Jungle Ravine & Catwalks (1960 - 2860)
				{"rect": Rect2(2060.0, 350.0, 240.0, 16.0), "type": PlatformType.TURF, "variant": "wedge_right"},
				{"rect": Rect2(2300.0, 275.0, 240.0, 16.0), "type": PlatformType.TURF, "variant": "default"},
				{"rect": Rect2(2520.0, 210.0, 200.0, 16.0), "type": PlatformType.TURF, "variant": "small"},
				# Chasm 3 (2860 - 3000): River Crossing
				{"rect": Rect2(2840.0, 340.0, 200.0, 16.0), "type": PlatformType.TURF, "variant": "crag"},
				
				# Sector 4: Heavy Fortress Battery & Mini-Boss Arena (3000 - 3880)
				{"rect": Rect2(3100.0, 360.0, 260.0, 16.0), "type": PlatformType.TURF, "variant": "wedge_left"},
				{"rect": Rect2(3340.0, 285.0, 300.0, 16.0), "type": PlatformType.TURF, "variant": "wide"},
				{"rect": Rect2(3660.0, 210.0, 180.0, 16.0), "type": PlatformType.TURF, "variant": "thin"},
				
				# =====================================================================
				# POST-MINI-BOSS FALLING PLATFORM SEQUENCE (3880 - 5140)
				# PURE BOTTOMLESS ABYSS - NO GROUND!
				# Player must hop across slowly descending platforms to reach the Fortress Gate!
				# =====================================================================
				
				# Abyss Threshold Stepping Stone
				{"rect": Rect2(3910.0, 360.0, 130.0, 16.0), "type": PlatformType.TURF, "variant": "thin", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8},
				
				# LEVEL 1: High Skyway Route (y = 190 - 270)
				{"rect": Rect2(4070.0, 270.0, 130.0, 16.0), "type": PlatformType.TURF, "variant": "small", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8},
				{"rect": Rect2(4240.0, 215.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "thin", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8},
				{"rect": Rect2(4410.0, 190.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "wide", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8},
				{"rect": Rect2(4590.0, 210.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "small", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8},
				{"rect": Rect2(4760.0, 250.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "wedge_right", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8},
				{"rect": Rect2(4930.0, 290.0, 130.0, 16.0), "type": PlatformType.TURF, "variant": "thin", "is_drop": true, "drop_delay": 0.45, "respawn_time": 2.8},
				
				# LEVEL 2: Mid Terrace Route (y = 300 - 330)
				{"rect": Rect2(4150.0, 330.0, 130.0, 16.0), "type": PlatformType.TURF, "variant": "default", "is_drop": true, "drop_delay": 0.50, "respawn_time": 2.8},
				{"rect": Rect2(4330.0, 310.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "wide", "is_drop": true, "drop_delay": 0.50, "respawn_time": 2.8},
				{"rect": Rect2(4510.0, 300.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "default", "is_drop": true, "drop_delay": 0.50, "respawn_time": 2.8},
				{"rect": Rect2(4690.0, 310.0, 140.0, 16.0), "type": PlatformType.TURF, "variant": "wedge_left", "is_drop": true, "drop_delay": 0.50, "respawn_time": 2.8},
				{"rect": Rect2(4870.0, 330.0, 130.0, 16.0), "type": PlatformType.TURF, "variant": "default", "is_drop": true, "drop_delay": 0.50, "respawn_time": 2.8},
				
				# LEVEL 3: Lower River Crag Route (y = 385 - 395)
				{"rect": Rect2(4050.0, 395.0, 130.0, 16.0), "type": PlatformType.TURF, "variant": "crag", "is_drop": true, "drop_delay": 0.55, "respawn_time": 2.8},
				{"rect": Rect2(4230.0, 390.0, 130.0, 16.0), "type": PlatformType.TURF, "variant": "crag", "is_drop": true, "drop_delay": 0.55, "respawn_time": 2.8},
				{"rect": Rect2(4410.0, 390.0, 130.0, 16.0), "type": PlatformType.TURF, "variant": "crag", "is_drop": true, "drop_delay": 0.55, "respawn_time": 2.8},
				{"rect": Rect2(4590.0, 395.0, 130.0, 16.0), "type": PlatformType.TURF, "variant": "crag", "is_drop": true, "drop_delay": 0.55, "respawn_time": 2.8},
				{"rect": Rect2(4770.0, 390.0, 130.0, 16.0), "type": PlatformType.TURF, "variant": "crag", "is_drop": true, "drop_delay": 0.55, "respawn_time": 2.8},
				{"rect": Rect2(4950.0, 390.0, 130.0, 16.0), "type": PlatformType.TURF, "variant": "crag", "is_drop": true, "drop_delay": 0.55, "respawn_time": 2.8},
				
				# Final Leap Threshold Platform into Fortress Gate
				{"rect": Rect2(5050.0, 360.0, 120.0, 16.0), "type": PlatformType.TURF, "variant": "small", "is_drop": true, "drop_delay": 0.50, "respawn_time": 2.8},
				
				# Sector 6 & 7: Fortress Approach & Boss Arena (5140 - 6700)
				{"rect": Rect2(5220.0, 340.0, 260.0, 16.0), "type": PlatformType.TURF, "variant": "wedge_left"},
				{"rect": Rect2(5460.0, 260.0, 240.0, 16.0), "type": PlatformType.TURF, "variant": "thin"},
				{"rect": Rect2(5900.0, 340.0, 280.0, 16.0), "type": PlatformType.TURF, "variant": "wide"},
				{"rect": Rect2(6200.0, 270.0, 240.0, 16.0), "type": PlatformType.TURF, "variant": "small"}
			]
		2:
			data["name"] = "WATERFALL FORTRESS"
			data["sector"] = "SECTOR 02 // CATARACT CHASM"
			data["theme"] = "TORRENTIAL CLIFFSIDE"
			data["diff"] = "HARD"
			data["boss"] = "HYDRO-GOLIATH MECH"
			data["hazard"] = "RUSHING WATERFALLS & CLIFF PITS"
			data["intel"] = "Ascend vertical granite escarpments over raging torrents. Leap across cataract chasms using high thermal updrafts while dodging sniper fire."
			data["primary_color"] = Color(0.20, 0.65, 0.95)
			data["accent_color"] = Color(0.60, 0.90, 1.0)
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 750.0, 200.0),
				Rect2(900.0, 440.0, 750.0, 200.0),
				Rect2(1800.0, 440.0, 750.0, 200.0),
				Rect2(2700.0, 440.0, 850.0, 200.0),
				Rect2(3700.0, 440.0, 850.0, 200.0),
				Rect2(4750.0, 440.0, 1950.0, 200.0)
			]
			data["platforms"] = [
				{"rect": Rect2(200.0, 360.0, 220.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(380.0, 280.0, 200.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1050.0, 360.0, 220.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(1280.0, 290.0, 240.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(1950.0, 350.0, 240.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(2200.0, 270.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2850.0, 360.0, 260.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(3150.0, 280.0, 280.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(3850.0, 350.0, 240.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(4150.0, 270.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4950.0, 360.0, 260.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(5250.0, 280.0, 280.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5550.0, 330.0, 240.0, 16.0), "type": PlatformType.ROPE_BRIDGE}
			]
		3:
			data["name"] = "ALIEN HIVE BIO-CAVERN"
			data["sector"] = "SECTOR 03 // SUBTERRANEAN HIVE"
			data["theme"] = "ORGANIC FLESH CAVERNS"
			data["diff"] = "HARD"
			data["boss"] = "GIGA BIO-HEART"
			data["hazard"] = "ORGANIC ACID PITS & CHITIN CHASM"
			data["intel"] = "Sub-surface breach into the organic nest. Avoid falling into corrosive digestive fluids and rupture the throbbing bio-heart chamber."
			data["primary_color"] = Color(0.85, 0.25, 0.40)
			data["accent_color"] = Color(1.0, 0.60, 0.70)
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 720.0, 200.0),
				Rect2(840.0, 440.0, 740.0, 200.0),
				Rect2(1700.0, 440.0, 740.0, 200.0),
				Rect2(2580.0, 440.0, 820.0, 200.0),
				Rect2(3550.0, 440.0, 850.0, 200.0),
				Rect2(4550.0, 440.0, 950.0, 200.0),
				Rect2(5650.0, 440.0, 1050.0, 200.0)
			]
			data["platforms"] = [
				{"rect": Rect2(220.0, 360.0, 200.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(400.0, 280.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(690.0, 330.0, 230.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(980.0, 360.0, 220.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(1200.0, 290.0, 240.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(1520.0, 330.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1850.0, 360.0, 240.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(2120.0, 270.0, 240.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(2420.0, 330.0, 240.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(2750.0, 360.0, 260.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(3050.0, 280.0, 280.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(3400.0, 330.0, 240.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3750.0, 360.0, 260.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(4100.0, 270.0, 260.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(4400.0, 330.0, 240.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(4750.0, 360.0, 260.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(5100.0, 280.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5480.0, 330.0, 240.0, 16.0), "type": PlatformType.BIO_RIB}
			]
		4:
			data["name"] = "SNOWFIELD TUNDRA"
			data["sector"] = "SECTOR 04 // FROSTBITE RIDGE"
			data["theme"] = "ARCTIC BLIZZARD & PERMAFROST"
			data["diff"] = "EXPERT"
			data["boss"] = "FROSTBITE SIEGE TANK"
			data["hazard"] = "SUB-ZERO GLACIAL CREVASSES"
			data["intel"] = "Traverse gale-force snowfields and icy steel gantries. Demolish the entrenched heavy armored siege crawler guarding the mountain pass."
			data["primary_color"] = Color(0.40, 0.85, 1.0)
			data["accent_color"] = Color(0.85, 0.95, 1.0)
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 780.0, 200.0),
				Rect2(920.0, 440.0, 800.0, 200.0),
				Rect2(1860.0, 440.0, 800.0, 200.0),
				Rect2(2800.0, 440.0, 880.0, 200.0),
				Rect2(3840.0, 440.0, 860.0, 200.0),
				Rect2(4850.0, 440.0, 1850.0, 200.0)
			]
			data["platforms"] = [
				{"rect": Rect2(240.0, 360.0, 220.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(450.0, 280.0, 200.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(760.0, 330.0, 240.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(1080.0, 360.0, 240.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1320.0, 280.0, 260.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(1680.0, 330.0, 260.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(2020.0, 360.0, 240.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(2300.0, 270.0, 240.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2640.0, 330.0, 240.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(2980.0, 360.0, 260.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(3300.0, 270.0, 260.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(3660.0, 330.0, 260.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(4000.0, 360.0, 260.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(4300.0, 270.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4660.0, 330.0, 260.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(5040.0, 350.0, 280.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(5380.0, 270.0, 260.0, 16.0), "type": PlatformType.ICE_SLAB}
			]
		5:
			data["name"] = "STEEL REFINERY"
			data["sector"] = "SECTOR 05 // VULCAN FOUNDRY"
			data["theme"] = "INDUSTRIAL SMELTING PLANT"
			data["diff"] = "EXPERT"
			data["boss"] = "MAGMA FORGE GOLEM"
			data["hazard"] = "MOLTEN LAVA POOLS & CHAIN GIRDERS"
			data["intel"] = "Infiltrate heavy metal foundry. Scale overhead cargo chains above superheated magma trenches and destroy the walking incinerator golem."
			data["primary_color"] = Color(1.0, 0.50, 0.15)
			data["accent_color"] = Color(1.0, 0.85, 0.20)
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 680.0, 200.0),
				Rect2(780.0, 440.0, 700.0, 200.0),
				Rect2(1580.0, 440.0, 700.0, 200.0),
				Rect2(2380.0, 440.0, 800.0, 200.0),
				Rect2(3280.0, 440.0, 800.0, 200.0),
				Rect2(4180.0, 440.0, 800.0, 200.0),
				Rect2(5080.0, 440.0, 700.0, 200.0),
				Rect2(5880.0, 440.0, 820.0, 200.0)
			]
			data["platforms"] = [
				{"rect": Rect2(200.0, 360.0, 220.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(420.0, 280.0, 200.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(650.0, 330.0, 220.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(920.0, 350.0, 240.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1200.0, 270.0, 260.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(1450.0, 330.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1740.0, 350.0, 240.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(2000.0, 270.0, 240.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(2250.0, 330.0, 220.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(2520.0, 350.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2850.0, 270.0, 260.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(3150.0, 330.0, 220.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(3450.0, 350.0, 260.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(3750.0, 270.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4050.0, 330.0, 220.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(4350.0, 350.0, 260.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(4700.0, 270.0, 260.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(4980.0, 330.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5300.0, 350.0, 260.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(5650.0, 270.0, 240.0, 16.0), "type": PlatformType.GIRDER}
			]
		6:
			data["name"] = "ELECTRIC DYNAMO"
			data["sector"] = "SECTOR 06 // TESLA SUBSTATION"
			data["theme"] = "HIGH-VOLTAGE POWER GRID"
			data["diff"] = "EXPERT"
			data["boss"] = "THUNDER DYNAMO"
			data["hazard"] = "ARC DISCHARGE CHASM & CONDENSERS"
			data["intel"] = "Scale megavolt distribution towers and lightning coils. High static conductivity across all steel scaffolding. Short-circuit the core generator."
			data["primary_color"] = Color(0.95, 0.85, 0.20)
			data["accent_color"] = Color(0.40, 0.90, 1.0)
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 740.0, 200.0),
				Rect2(860.0, 440.0, 740.0, 200.0),
				Rect2(1720.0, 440.0, 760.0, 200.0),
				Rect2(2600.0, 440.0, 850.0, 200.0),
				Rect2(3600.0, 440.0, 850.0, 200.0),
				Rect2(4600.0, 440.0, 900.0, 200.0),
				Rect2(5650.0, 440.0, 1050.0, 200.0)
			]
			data["platforms"] = [
				{"rect": Rect2(220.0, 360.0, 220.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(440.0, 280.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(720.0, 330.0, 220.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(1000.0, 350.0, 240.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1260.0, 270.0, 260.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(1580.0, 330.0, 240.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1880.0, 350.0, 260.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(2180.0, 270.0, 260.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(2480.0, 330.0, 220.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(2800.0, 350.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3100.0, 270.0, 280.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(3480.0, 330.0, 220.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(3800.0, 350.0, 260.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(4150.0, 270.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4480.0, 330.0, 220.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(4800.0, 350.0, 260.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(5200.0, 270.0, 260.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(5520.0, 330.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH}
			]
		7:
			data["name"] = "ALIEN AEROSPACE HANGAR"
			data["sector"] = "SECTOR 07 // ORBITAL STARPORT"
			data["theme"] = "SPACE LAUNCH BAYS"
			data["diff"] = "NIGHTMARE"
			data["boss"] = "VANGUARD STAR CRUISER"
			data["hazard"] = "VACUUM EXHAUST DUCTS & TURRETS"
			data["intel"] = "Infiltrate orbital launch deck. Navigate heavy hydraulic gantries across high-altitude docking trenches and bring down the alien command cruiser."
			data["primary_color"] = Color(0.70, 0.45, 0.95)
			data["accent_color"] = Color(0.35, 0.85, 1.0)
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 820.0, 200.0),
				Rect2(960.0, 440.0, 840.0, 200.0),
				Rect2(1950.0, 440.0, 850.0, 200.0),
				Rect2(2960.0, 440.0, 940.0, 200.0),
				Rect2(4080.0, 440.0, 920.0, 200.0),
				Rect2(5180.0, 440.0, 1520.0, 200.0)
			]
			data["platforms"] = [
				{"rect": Rect2(250.0, 360.0, 240.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(480.0, 280.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(820.0, 330.0, 220.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(1100.0, 360.0, 260.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1400.0, 270.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(1800.0, 330.0, 240.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(2120.0, 350.0, 260.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(2450.0, 270.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2800.0, 330.0, 240.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(3150.0, 350.0, 280.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(3500.0, 270.0, 280.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3920.0, 330.0, 240.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(4250.0, 350.0, 280.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(4650.0, 270.0, 280.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5020.0, 330.0, 240.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(5380.0, 350.0, 280.0, 16.0), "type": PlatformType.GIRDER}
			]
		8:
			data["name"] = "MOTHER BRAIN SANCTUM"
			data["sector"] = "SECTOR 08 // ALIEN CENTRAL CORE"
			data["theme"] = "LIVING PSYCHIC BIO-SANCTUM"
			data["diff"] = "APOCALYPSE"
			data["boss"] = "EMPEROR MOTHER BRAIN"
			data["hazard"] = "BIO-NEURAL ACID CHASMS"
			data["intel"] = "Final assault on the central neural hive. Penetrate defensive optic laser screens and eradicate the Emperor Mother Brain to save Earth!"
			data["primary_color"] = Color(1.0, 0.25, 0.35)
			data["accent_color"] = Color(0.95, 0.85, 0.20)
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 700.0, 200.0),
				Rect2(820.0, 440.0, 700.0, 200.0),
				Rect2(1640.0, 440.0, 760.0, 200.0),
				Rect2(2520.0, 440.0, 830.0, 200.0),
				Rect2(3500.0, 440.0, 850.0, 200.0),
				Rect2(4500.0, 440.0, 900.0, 200.0),
				Rect2(5550.0, 440.0, 1150.0, 200.0)
			]
			data["platforms"] = [
				{"rect": Rect2(200.0, 360.0, 220.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(400.0, 270.0, 220.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(680.0, 330.0, 220.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(950.0, 350.0, 240.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(1220.0, 260.0, 240.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(1500.0, 330.0, 240.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(1800.0, 350.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2100.0, 260.0, 260.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(2400.0, 330.0, 220.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(2720.0, 350.0, 260.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(3050.0, 260.0, 280.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(3380.0, 330.0, 220.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(3700.0, 350.0, 280.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4050.0, 260.0, 280.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(4380.0, 330.0, 220.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(4700.0, 350.0, 280.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(5100.0, 260.0, 280.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(5420.0, 330.0, 220.0, 16.0), "type": PlatformType.BIO_RIB}
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
	var world_y_top: float = 180.0
	var world_y_bottom: float = 460.0
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
	var ground_y: float = map_rect.position.y + map_h * 0.76
	var ground_thickness: float = maxf(4.0, map_h * 0.18)
	
	# Draw Chasms (Abyss / Hazards between ground chunks)
	var grounds: Array = m.get("ground_segments", [])
	for i in range(grounds.size() - 1):
		var g1: Rect2 = grounds[i]
		var g2: Rect2 = grounds[i + 1]
		var pit_start: float = map_rect.position.x + g1.end.x * scale_x
		var pit_end: float = map_rect.position.x + g2.position.x * scale_x
		var pit_w: float = pit_end - pit_start
		var chasm_rect := Rect2(pit_start, ground_y - 2.0, pit_w, ground_thickness + 4.0)
		
		# Hazard specific color in chasms
		var hazard_col := Color(0.02, 0.03, 0.05)
		if stage_id == 5: # Lava
			hazard_col = Color(0.95, 0.35, 0.05, 0.85)
		elif stage_id == 6: # Electric
			hazard_col = Color(0.25, 0.80, 1.0, 0.85)
		elif stage_id == 3 or stage_id == 8: # Acid
			hazard_col = Color(0.85, 0.15, 0.35, 0.85)
		elif stage_id == 4: # Blizzard Ice
			hazard_col = Color(0.50, 0.80, 1.0, 0.85)
		
		canvas.draw_rect(chasm_rect, hazard_col)
		# Hazard exclamation line
		if is_schematic and pit_w > 8.0:
			canvas.draw_line(Vector2(pit_start + pit_w * 0.5, ground_y - 4.0), Vector2(pit_start + pit_w * 0.5, ground_y + ground_thickness), Color(1.0, 0.25, 0.25, 0.9), 1.2)
	
	# 2. Solid Ground Segments
	for g_item in grounds:
		var g: Rect2 = g_item
		var gx: float = map_rect.position.x + g.position.x * scale_x
		var gw: float = g.size.x * scale_x
		var g_rect := Rect2(gx, ground_y, gw, ground_thickness)
		
		# Terrain block
		var col_body := Color(prim_col.r * 0.45, prim_col.g * 0.45, prim_col.b * 0.45)
		canvas.draw_rect(g_rect, col_body)
		# Top illuminated terrain ridge line
		canvas.draw_line(Vector2(gx, ground_y), Vector2(gx + gw, ground_y), prim_col, 2.0)
	
	# 3. Elevated Platforms (Tiered Architecture)
	var plats: Array = m.get("platforms", [])
	for p_item in plats:
		var p: Dictionary = p_item
		var pr: Rect2 = p["rect"]
		var px: float = map_rect.position.x + pr.position.x * scale_x
		var pw: float = maxf(3.0, pr.size.x * scale_x)
		var rel_y: float = clampf((pr.position.y - world_y_top) / world_y_range, 0.1, 0.9)
		var py: float = map_rect.position.y + rel_y * (map_h * 0.72)
		
		var p_col := acc_col
		var p_type: int = p["type"]
		if p_type == PlatformType.HIGH_PERCH:
			p_col = Color(0.35, 0.85, 1.0)
		elif p_type == PlatformType.ROPE_BRIDGE:
			p_col = Color(0.95, 0.65, 0.30)
		elif p_type == PlatformType.ICE_SLAB:
			p_col = Color(0.70, 0.95, 1.0)
		elif p_type == PlatformType.LAVA_GRATE:
			p_col = Color(1.0, 0.50, 0.10)
		elif p_type == PlatformType.ENERGY_BARRIER:
			p_col = Color(0.25, 0.85, 1.0)
		elif p_type == PlatformType.TECH_CATWALK:
			p_col = Color(0.95, 0.80, 0.25)
		elif p_type == PlatformType.BIO_RIB:
			p_col = Color(0.95, 0.30, 0.60)
		
		canvas.draw_line(Vector2(px, py), Vector2(px + pw, py), p_col, 2.0)
		# Mini vertical support stanchion or schematic motif
		if is_schematic:
			canvas.draw_line(Vector2(px + pw * 0.5, py), Vector2(px + pw * 0.5, minf(ground_y, py + 8.0)), Color(p_col.r, p_col.g, p_col.b, 0.4), 1.0)
			if p_type == PlatformType.ICE_SLAB:
				canvas.draw_circle(Vector2(px + pw * 0.3, py + 3.0), 1.0, Color.WHITE)
				canvas.draw_circle(Vector2(px + pw * 0.7, py + 3.0), 1.0, Color.WHITE)
			elif p_type == PlatformType.LAVA_GRATE:
				canvas.draw_circle(Vector2(px + pw * 0.5, py + 2.0), 1.5, Color(1.0, 0.35, 0.05))
			elif p_type == PlatformType.ENERGY_BARRIER:
				canvas.draw_line(Vector2(px + 4.0, py - 2.0), Vector2(px + pw - 4.0, py - 2.0), Color(0.8, 1.0, 1.0, 0.7), 1.0)
	
	# 4. Boss Stronghold Zone at 5800m
	var boss_x: float = map_rect.position.x + BOSS_TRIGGER_X * scale_x
	var boss_marker_rect := Rect2(boss_x - 3.0, map_rect.position.y + 4.0, 6.0, map_h - 8.0)
	var pulse: float = 0.75 + 0.25 * sin(anim_time * 6.0)
	canvas.draw_rect(boss_marker_rect, Color(1.0, 0.25, 0.25, 0.35 * pulse))
	canvas.draw_line(Vector2(boss_x, map_rect.position.y + 4.0), Vector2(boss_x, map_rect.end.y - 4.0), Color(1.0, 0.30, 0.30, pulse), 1.5)
	
	# Boss Target Icon
	var boss_icon_y := ground_y - 12.0
	canvas.draw_circle(Vector2(boss_x, boss_icon_y), 5.0, Color(1.0, 0.20, 0.20))
	canvas.draw_circle(Vector2(boss_x, boss_icon_y), 2.5, Color.WHITE)
	
	# 5. Player Commando Position Beacon (When in-game)
	if player_x >= 0.0:
		var p_norm_x := clampf(player_x, 0.0, LEVEL_MAX_X)
		var p_screen_x := map_rect.position.x + p_norm_x * scale_x
		var p_beacon_y := ground_y - 10.0
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
		canvas.draw_string(font, Vector2(boss_x - 30.0, map_rect.end.y - 6.0), "5800m [CORE]", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1.0, 0.5, 0.5))
		canvas.draw_string(font, Vector2(map_rect.end.x - 68.0, map_rect.end.y - 6.0), "6700m [EXIT]", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.5, 0.7, 0.9))
