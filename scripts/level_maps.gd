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
				Rect2(0.0, 440.0, 1000.0, 200.0),
				Rect2(1140.0, 440.0, 1050.0, 200.0),
				Rect2(2330.0, 440.0, 1100.0, 200.0),
				Rect2(3570.0, 440.0, 1150.0, 200.0),
				Rect2(4860.0, 440.0, 1200.0, 200.0),
				Rect2(6200.0, 440.0, 1200.0, 200.0),
				Rect2(7700.0, 440.0, 2100.0, 200.0)
			]
			data["platforms"] = [
				{"rect": Rect2(240.0, 360.0, 220.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(520.0, 280.0, 200.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(780.0, 350.0, 180.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(1280.0, 360.0, 240.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(1580.0, 280.0, 260.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(1880.0, 340.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2480.0, 360.0, 240.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(2780.0, 270.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3080.0, 350.0, 220.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(3700.0, 360.0, 260.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(4040.0, 280.0, 280.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4380.0, 340.0, 240.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(5020.0, 350.0, 260.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(5380.0, 270.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5720.0, 340.0, 240.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(6340.0, 360.0, 260.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(6680.0, 280.0, 280.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7020.0, 350.0, 260.0, 16.0), "type": PlatformType.TURF},
				# Cataract Chasm Crossing (7400 - 7700)
				{"rect": Rect2(7440.0, 330.0, 220.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				# Boss Arena Approach
				{"rect": Rect2(7850.0, 350.0, 260.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(8220.0, 270.0, 280.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(8580.0, 330.0, 240.0, 16.0), "type": PlatformType.ROPE_BRIDGE}
			]
		3:
			data["name"] = "ALIEN HIVE BIO-CAVERN"
			data["sector"] = "SECTOR 03 // SUBTERRANEAN HIVE"
			data["theme"] = "ORGANIC FLESH CAVERNS"
			data["diff"] = "HARD"
			data["boss"] = "GIGA BIO-HEART"
			data["hazard"] = "ORGANIC ACID PITS & CHITIN CHASM"
			data["intel"] = "Sub-surface breach into the organic nest. Slay the Chitin Behemoth at Sector 5, avoid falling into corrosive digestive fluids and rupture the throbbing bio-heart chamber."
			data["primary_color"] = Color(0.85, 0.25, 0.40)
			data["accent_color"] = Color(1.0, 0.60, 0.70)
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 950.0, 200.0),
				Rect2(1090.0, 440.0, 1000.0, 200.0),
				Rect2(2230.0, 440.0, 1050.0, 200.0),
				Rect2(3420.0, 440.0, 1100.0, 200.0),
				Rect2(4660.0, 440.0, 1150.0, 200.0),
				Rect2(5950.0, 440.0, 1200.0, 200.0),
				Rect2(7290.0, 440.0, 2510.0, 200.0)
			]
			data["platforms"] = [
				{"rect": Rect2(240.0, 360.0, 220.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(520.0, 280.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(800.0, 340.0, 200.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(1220.0, 360.0, 240.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(1520.0, 280.0, 260.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(1840.0, 340.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2360.0, 360.0, 240.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(2680.0, 270.0, 260.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(3000.0, 340.0, 240.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(3550.0, 360.0, 260.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(3880.0, 280.0, 280.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(4220.0, 340.0, 240.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4800.0, 360.0, 260.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(5150.0, 270.0, 260.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(5480.0, 340.0, 240.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(6100.0, 360.0, 260.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(6450.0, 280.0, 280.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(6800.0, 340.0, 240.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(7450.0, 360.0, 260.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(7820.0, 270.0, 280.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(8180.0, 340.0, 260.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(8560.0, 280.0, 240.0, 16.0), "type": PlatformType.HIGH_PERCH}
			]
		4:
			data["name"] = "SNOWFIELD TUNDRA"
			data["sector"] = "SECTOR 04 // FROSTBITE RIDGE"
			data["theme"] = "ARCTIC BLIZZARD & PERMAFROST"
			data["diff"] = "EXPERT"
			data["boss"] = "FROSTBITE SIEGE TANK"
			data["hazard"] = "SUB-ZERO GLACIAL CREVASSES"
			data["intel"] = "Traverse gale-force snowfields and icy steel gantries. Crush the Polar Siege Colossus at Sector 5, then demolish the entrenched heavy armored siege crawler guarding the mountain pass."
			data["primary_color"] = Color(0.40, 0.85, 1.0)
			data["accent_color"] = Color(0.85, 0.95, 1.0)
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 1050.0, 200.0),
				Rect2(1190.0, 440.0, 1100.0, 200.0),
				Rect2(2430.0, 440.0, 1150.0, 200.0),
				Rect2(3720.0, 440.0, 1200.0, 200.0),
				Rect2(5060.0, 440.0, 1200.0, 200.0),
				Rect2(6400.0, 440.0, 1250.0, 200.0),
				Rect2(7790.0, 440.0, 2010.0, 200.0)
			]
			data["platforms"] = [
				{"rect": Rect2(260.0, 360.0, 240.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(560.0, 280.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(840.0, 350.0, 220.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(1320.0, 360.0, 240.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1620.0, 280.0, 260.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(1960.0, 340.0, 240.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(2560.0, 360.0, 240.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(2880.0, 270.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3220.0, 340.0, 240.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(3860.0, 360.0, 260.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(4200.0, 270.0, 280.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(4560.0, 340.0, 260.0, 16.0), "type": PlatformType.ROPE_BRIDGE},
				{"rect": Rect2(5200.0, 360.0, 260.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(5540.0, 270.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5880.0, 340.0, 240.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(6540.0, 360.0, 260.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(6880.0, 280.0, 280.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7240.0, 340.0, 260.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(7940.0, 360.0, 260.0, 16.0), "type": PlatformType.ICE_SLAB},
				{"rect": Rect2(8300.0, 270.0, 280.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(8650.0, 340.0, 260.0, 16.0), "type": PlatformType.GIRDER}
			]
		5:
			data["name"] = "STEEL REFINERY"
			data["sector"] = "SECTOR 05 // VULCAN FOUNDRY"
			data["theme"] = "INDUSTRIAL SMELTING PLANT"
			data["diff"] = "EXPERT"
			data["boss"] = "MAGMA FORGE GOLEM"
			data["hazard"] = "MOLTEN LAVA POOLS & CHAIN GIRDERS"
			data["intel"] = "Infiltrate heavy metal foundry. Break the Vulcan Foundry Dreadnought at Sector 5, scale overhead cargo chains above superheated magma trenches and destroy the walking incinerator golem."
			data["primary_color"] = Color(1.0, 0.50, 0.15)
			data["accent_color"] = Color(1.0, 0.85, 0.20)
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 950.0, 200.0),
				Rect2(1090.0, 440.0, 1000.0, 200.0),
				Rect2(2230.0, 440.0, 1050.0, 200.0),
				Rect2(3420.0, 440.0, 1100.0, 200.0),
				Rect2(4660.0, 440.0, 1150.0, 200.0),
				Rect2(5950.0, 440.0, 1150.0, 200.0),
				Rect2(7240.0, 440.0, 2560.0, 200.0)
			]
			data["platforms"] = [
				{"rect": Rect2(240.0, 360.0, 220.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(500.0, 280.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(780.0, 340.0, 220.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(1220.0, 360.0, 240.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1520.0, 270.0, 260.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(1820.0, 340.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2360.0, 360.0, 240.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(2660.0, 270.0, 260.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(2960.0, 340.0, 240.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(3550.0, 360.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3880.0, 270.0, 280.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(4220.0, 340.0, 240.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(4800.0, 360.0, 260.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(5140.0, 270.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5480.0, 340.0, 240.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(6100.0, 360.0, 260.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(6440.0, 270.0, 280.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(6780.0, 340.0, 240.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(7400.0, 360.0, 260.0, 16.0), "type": PlatformType.LAVA_GRATE},
				{"rect": Rect2(7750.0, 270.0, 280.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(8120.0, 340.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(8520.0, 280.0, 260.0, 16.0), "type": PlatformType.LAVA_GRATE}
			]
		6:
			data["name"] = "ELECTRIC DYNAMO"
			data["sector"] = "SECTOR 06 // TESLA SUBSTATION"
			data["theme"] = "HIGH-VOLTAGE POWER GRID"
			data["diff"] = "EXPERT"
			data["boss"] = "THUNDER DYNAMO"
			data["hazard"] = "ARC DISCHARGE CHASM & CONDENSERS"
			data["intel"] = "Scale megavolt distribution towers and lightning coils. Neutralize the Tesla Storm Overlord at Sector 5, then short-circuit the Thunder Dynamo core generator."
			data["primary_color"] = Color(0.95, 0.85, 0.20)
			data["accent_color"] = Color(0.40, 0.90, 1.0)
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 1000.0, 200.0),
				Rect2(1140.0, 440.0, 1050.0, 200.0),
				Rect2(2330.0, 440.0, 1100.0, 200.0),
				Rect2(3570.0, 440.0, 1150.0, 200.0),
				Rect2(4860.0, 440.0, 1200.0, 200.0),
				Rect2(6200.0, 440.0, 1250.0, 200.0),
				Rect2(7590.0, 440.0, 2210.0, 200.0)
			]
			data["platforms"] = [
				{"rect": Rect2(260.0, 360.0, 240.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(540.0, 280.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(820.0, 340.0, 220.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(1260.0, 360.0, 240.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1560.0, 270.0, 260.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(1880.0, 340.0, 240.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2450.0, 360.0, 240.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(2780.0, 270.0, 260.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(3100.0, 340.0, 240.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3700.0, 360.0, 260.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(4050.0, 270.0, 280.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4400.0, 340.0, 240.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(5000.0, 360.0, 260.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(5350.0, 270.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5700.0, 340.0, 240.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(6340.0, 360.0, 260.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(6700.0, 270.0, 280.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(7060.0, 340.0, 240.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7750.0, 360.0, 260.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(8120.0, 270.0, 280.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(8500.0, 340.0, 260.0, 16.0), "type": PlatformType.ENERGY_BARRIER}
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
				Rect2(0.0, 440.0, 1100.0, 200.0),
				Rect2(1240.0, 440.0, 1150.0, 200.0),
				Rect2(2530.0, 440.0, 1200.0, 200.0),
				Rect2(3870.0, 440.0, 1200.0, 200.0),
				Rect2(5210.0, 440.0, 1250.0, 200.0),
				Rect2(6600.0, 440.0, 1250.0, 200.0),
				Rect2(7990.0, 440.0, 1810.0, 200.0)
			]
			data["platforms"] = [
				{"rect": Rect2(260.0, 360.0, 240.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(560.0, 280.0, 220.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(860.0, 340.0, 220.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(1360.0, 360.0, 260.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(1700.0, 270.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2040.0, 340.0, 240.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(2660.0, 360.0, 260.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(3000.0, 270.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(3340.0, 340.0, 240.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(4000.0, 360.0, 260.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(4350.0, 270.0, 280.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(4700.0, 340.0, 240.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(5340.0, 360.0, 260.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(5700.0, 270.0, 280.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(6060.0, 340.0, 240.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(6740.0, 360.0, 260.0, 16.0), "type": PlatformType.GIRDER},
				{"rect": Rect2(7100.0, 270.0, 280.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(7460.0, 340.0, 240.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(8150.0, 360.0, 260.0, 16.0), "type": PlatformType.TECH_CATWALK},
				{"rect": Rect2(8520.0, 270.0, 280.0, 16.0), "type": PlatformType.HIGH_PERCH}
			]
		8:
			data["name"] = "MOTHER BRAIN SANCTUM"
			data["sector"] = "SECTOR 08 // ALIEN CENTRAL CORE"
			data["theme"] = "LIVING PSYCHIC BIO-SANCTUM"
			data["diff"] = "APOCALYPSE"
			data["boss"] = "EMPEROR MOTHER BRAIN"
			data["hazard"] = "BIO-NEURAL ACID CHASMS"
			data["intel"] = "Final assault on the central neural hive. Purge the Psionic Hive Leviathan at Sector 5, penetrate defensive optic laser screens and eradicate the Emperor Mother Brain to save Earth!"
			data["primary_color"] = Color(1.0, 0.25, 0.35)
			data["accent_color"] = Color(0.95, 0.85, 0.20)
			data["ground_segments"] = [
				Rect2(0.0, 440.0, 1050.0, 200.0),
				Rect2(1190.0, 440.0, 1100.0, 200.0),
				Rect2(2430.0, 440.0, 1100.0, 200.0),
				Rect2(3670.0, 440.0, 1150.0, 200.0),
				Rect2(4960.0, 440.0, 1200.0, 200.0),
				Rect2(6300.0, 440.0, 1200.0, 200.0),
				Rect2(7640.0, 440.0, 2160.0, 200.0)
			]
			data["platforms"] = [
				{"rect": Rect2(240.0, 360.0, 220.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(520.0, 270.0, 220.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(800.0, 340.0, 220.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(1320.0, 360.0, 240.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(1620.0, 260.0, 240.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(1940.0, 340.0, 240.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(2560.0, 360.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(2880.0, 260.0, 260.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(3200.0, 340.0, 220.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(3800.0, 360.0, 260.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(4150.0, 260.0, 280.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(4500.0, 340.0, 240.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(5100.0, 360.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH},
				{"rect": Rect2(5450.0, 260.0, 280.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(5800.0, 340.0, 240.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(6440.0, 360.0, 260.0, 16.0), "type": PlatformType.TURF},
				{"rect": Rect2(6800.0, 260.0, 280.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(7160.0, 340.0, 240.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(7800.0, 360.0, 260.0, 16.0), "type": PlatformType.BIO_RIB},
				{"rect": Rect2(8180.0, 260.0, 280.0, 16.0), "type": PlatformType.ENERGY_BARRIER},
				{"rect": Rect2(8540.0, 340.0, 260.0, 16.0), "type": PlatformType.HIGH_PERCH}
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
			if pit_w > 0.0 and pit_w <= MAX_JUMP_GAP:
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
		
		# Glowing hazard drop indication in chasm
		var chasm_rect := Rect2(pit_start, ground_y + 2.0, pit_w, ground_thickness)
		canvas.draw_rect(chasm_rect, Color(0.02, 0.03, 0.05, 0.95))
		
		# Hazard marker stripes
		if pit_w > 8.0:
			var hazard_col := Color(acc_col.r, acc_col.g, acc_col.b, 0.45)
			var h_stripe_w := 3.0
			var num_stripes: int = int(pit_w / (h_stripe_w * 2.0))
			for s in range(num_stripes):
				var sx := pit_start + float(s) * (h_stripe_w * 2.0)
				canvas.draw_line(Vector2(sx, ground_y + 4.0), Vector2(sx + h_stripe_w, ground_y + ground_thickness - 2.0), hazard_col, 1.2)
	
	# Draw Ground Solid Elevation Strips
	for g in grounds:
		var gx: float = map_rect.position.x + g.position.x * scale_x
		var gw: float = g.size.x * scale_x
		var gr := Rect2(gx, ground_y, gw, ground_thickness)
		
		# Sub-surface foundation fill
		canvas.draw_rect(gr, Color(prim_col.r * 0.4, prim_col.g * 0.4, prim_col.b * 0.4, 0.95))
		# Top surface tactical highlight edge
		canvas.draw_rect(Rect2(gx, ground_y, gw, 2.5), prim_col)
		# Mechanical depth line
		canvas.draw_line(Vector2(gx, ground_y + 6.0), Vector2(gx + gw, ground_y + 6.0), Color(0.0, 0.0, 0.0, 0.4), 1.0)
	
	# 2. Tactical Elevation Platforms
	var plats: Array = m.get("platforms", [])
	for p in plats:
		var pr: Rect2 = p["rect"]
		var px: float = map_rect.position.x + pr.position.x * scale_x
		var pw: float = maxf(4.0, pr.size.x * scale_x)
		
		# Map world Y (180 to 440) to schematic height
		var rel_y: float = (pr.position.y - world_y_top) / world_y_range
		var py: float = map_rect.position.y + map_h * 0.16 + rel_y * (ground_y - (map_rect.position.y + map_h * 0.16))
		
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
			canvas.draw_line(Vector2(px + pw * 0.5, py), Vector2(px + pw * 0.5, minf(ground_y, py + 8.0)), Color(p_col.r, p_col.g, p_col.b, 0.4), 1.0)
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
		canvas.draw_string(font, Vector2(boss_x - 30.0, map_rect.end.y - 6.0), "8800m [CORE]", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1.0, 0.5, 0.5))
		canvas.draw_string(font, Vector2(map_rect.end.x - 68.0, map_rect.end.y - 6.0), "9800m [EXIT]", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.5, 0.7, 0.9))
