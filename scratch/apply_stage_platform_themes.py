import re

with open('scripts/level_maps.gd', 'r') as f:
    content = f.read()

# 1. Update PlatformType enum at the top of level_maps.gd
old_enum = """enum PlatformType {
	TURF,
	GIRDER,
	ROPE_BRIDGE,
	HIGH_PERCH,
	ICE_SLAB,
	LAVA_GRATE,
	ENERGY_BARRIER,
	TECH_CATWALK,
	BIO_RIB
}"""

new_enum = """enum PlatformType {
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
}"""

assert old_enum in content, "old_enum not found in level_maps.gd!"
content = content.replace(old_enum, new_enum)

# 2. Update Stage 2 (Waterfall Fortress)
# Replace stepping stones with PlatformType.WATERFALL_LEDGE variants ("crag", "ledge", "wide")
# and keep rope bridges with PlatformType.ROPE_BRIDGE

# In Stage 2:
# Sector 1
content = content.replace(
    '{"rect": Rect2(180.0, 360.0, 160.0, 16.0), "type": PlatformType.ROPE_BRIDGE},                           # Sniper 1 (240, 370)',
    '{"rect": Rect2(180.0, 360.0, 160.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "ledge"},    # Sniper 1 (240, 370)'
)
content = content.replace(
    '{"rect": Rect2(365.0, 400.0, 115.0, 16.0), "type": PlatformType.ROPE_BRIDGE},                           # NAVIGATE: Stepping bridge across Bluff Gap 1 (400-480)',
    '{"rect": Rect2(365.0, 400.0, 115.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "crag"},     # NAVIGATE: Stepping stone crag across Bluff Gap 1 (400-480)'
)
content = content.replace(
    '{"rect": Rect2(805.0, 320.0, 125.0, 16.0), "type": PlatformType.ROPE_BRIDGE},                           # NAVIGATE: Escarpment step across Gap 2 (840-930)',
    '{"rect": Rect2(805.0, 320.0, 125.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "crag"},     # NAVIGATE: Escarpment rock step across Gap 2 (840-930)'
)
content = content.replace(
    '{"rect": Rect2(1010.0, 200.0, 170.0, 16.0), "type": PlatformType.ROPE_BRIDGE},                          # Escarpment ascent bridge',
    '{"rect": Rect2(1010.0, 200.0, 170.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "wide"},    # Escarpment ascent stone shelf'
)

# Sector 2
content = content.replace(
    '{"rect": Rect2(1640.0, 130.0, 160.0, 16.0), "type": PlatformType.ROPE_BRIDGE},                          # Flanking cliff',
    '{"rect": Rect2(1640.0, 130.0, 160.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "ledge"},   # Flanking cliff rock shelf'
)
content = content.replace(
    '{"rect": Rect2(2320.0, 345.0, 135.0, 16.0), "type": PlatformType.ROPE_BRIDGE},                          # NAVIGATE: Bridge descending Gap (2320-2420)',
    '{"rect": Rect2(2320.0, 345.0, 135.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "crag"},    # NAVIGATE: Stepping stone descending Gap (2320-2420)'
)

# Sector 3
content = content.replace(
    '{"rect": Rect2(3285.0, 420.0, 145.0, 16.0), "type": PlatformType.ROPE_BRIDGE},                          # NAVIGATE: Stepping stone climbing out of 470 basin to 370 (3320-3430)',
    '{"rect": Rect2(3285.0, 420.0, 145.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "crag"},    # NAVIGATE: Stepping stone climbing out of 470 basin to 370 (3320-3430)'
)
content = content.replace(
    '{"rect": Rect2(3755.0, 320.0, 135.0, 16.0), "type": PlatformType.ROPE_BRIDGE},                          # NAVIGATE: Escalation step across Gap (3790-3890)',
    '{"rect": Rect2(3755.0, 320.0, 135.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "crag"},    # NAVIGATE: Escalation rock step across Gap (3790-3890)'
)

# Sector 4
content = content.replace(
    '{"rect": Rect2(4620.0, 150.0, 160.0, 16.0), "type": PlatformType.ROPE_BRIDGE},                          # Suspension gantry',
    '{"rect": Rect2(4620.0, 150.0, 160.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "wide"},    # Torrent ridge stone terrace'
)
content = content.replace(
    '{"rect": Rect2(5280.0, 385.0, 115.0, 16.0), "type": PlatformType.ROPE_BRIDGE},                          # NAVIGATE: Terrace step into Mini-Boss Arena (5280-5360)',
    '{"rect": Rect2(5280.0, 385.0, 115.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "ledge"},   # NAVIGATE: Terrace rock step into Mini-Boss Arena (5280-5360)'
)

# Sector 6, 7 & 8
content = content.replace(
    '{"rect": Rect2(6735.0, 280.0, 145.0, 16.0), "type": PlatformType.ROPE_BRIDGE},                          # NAVIGATE: Stepped bridge climbing to 220 (6770-6880)',
    '{"rect": Rect2(6735.0, 280.0, 145.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "crag"},    # NAVIGATE: Stepped rock crag climbing to 220 (6770-6880)'
)
content = content.replace(
    '{"rect": Rect2(7745.0, 315.0, 135.0, 16.0), "type": PlatformType.ROPE_BRIDGE},                          # NAVIGATE: Bridge onto Citadel Ramparts (7780-7880)',
    '{"rect": Rect2(7745.0, 315.0, 135.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "ledge"},   # NAVIGATE: Slate ledge onto Citadel Ramparts (7780-7880)'
)
content = content.replace(
    '{"rect": Rect2(8280.0, 320.0, 135.0, 16.0), "type": PlatformType.ROPE_BRIDGE},                          # NAVIGATE: Rampart step (8280-8380)',
    '{"rect": Rect2(8280.0, 320.0, 135.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "crag"},    # NAVIGATE: Rampart rock step (8280-8380)'
)
content = content.replace(
    '{"rect": Rect2(8750.0, 400.0, 105.0, 16.0), "type": PlatformType.ROPE_BRIDGE},                          # NAVIGATE: Descent step to Boss Arena (8750-8820)',
    '{"rect": Rect2(8750.0, 400.0, 105.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "ledge"},   # NAVIGATE: Descent stone ledge to Boss Arena (8750-8820)'
)
content = content.replace(
    '{"rect": Rect2(9320.0, 210.0, 180.0, 16.0), "type": PlatformType.ROPE_BRIDGE}                           # Final Arena High Vantage Bridge',
    '{"rect": Rect2(9320.0, 210.0, 180.0, 16.0), "type": PlatformType.WATERFALL_LEDGE, "variant": "wide"}     # Final Arena High Vantage Stone Shelf'
)

# 3. Update Stage 3 (Alien Hive Bio-Cavern) with BIO_RIB variants
# Alternating carapace, shelf, wide, rib
bio_vars = ["carapace", "shelf", "wide", "rib"]
var_idx = 0

def replace_bio_stage3(match):
    global var_idx
    line = match.group(0)
    if 'variant' not in line:
        v = bio_vars[var_idx % len(bio_vars)]
        var_idx += 1
        return line.replace('"type": PlatformType.BIO_RIB}', f'"type": PlatformType.BIO_RIB, "variant": "{v}"}}').replace('"type": PlatformType.BIO_RIB, "is_drop"', f'"type": PlatformType.BIO_RIB, "variant": "{v}", "is_drop"')
    return line

# Split Stage 3 section
s3_start = content.find('3:\n\t\t\tdata["name"] = "ALIEN HIVE BIO-CAVERN"')
s4_start = content.find('4:\n\t\t\tdata["name"] = "SNOWFIELD TUNDRA"')
s3_block = content[s3_start:s4_start]
var_idx = 0
s3_new = re.sub(r'\{"rect":[^}]+"type": PlatformType\.BIO_RIB[^}]*\}', replace_bio_stage3, s3_block)
content = content[:s3_start] + s3_new + content[s4_start:]

# 4. Update Stage 4 (Snowfield Tundra)
# ICE_SLAB variants: crag, wide, slab
ice_vars = ["crag", "wide", "slab"]
i_idx = 0
def replace_ice_stage4(match):
    global i_idx
    line = match.group(0)
    if 'PlatformType.ICE_SLAB' in line and 'variant' not in line:
        v = ice_vars[i_idx % len(ice_vars)]
        i_idx += 1
        return line.replace('"type": PlatformType.ICE_SLAB}', f'"type": PlatformType.ICE_SLAB, "variant": "{v}"}}').replace('"type": PlatformType.ICE_SLAB, "is_drop"', f'"type": PlatformType.ICE_SLAB, "variant": "{v}", "is_drop"')
    elif 'PlatformType.GIRDER' in line and 'variant' not in line:
        return line.replace('"type": PlatformType.GIRDER}', '"type": PlatformType.GIRDER, "variant": "tundra"}').replace('"type": PlatformType.GIRDER, "is_drop"', '"type": PlatformType.GIRDER, "variant": "tundra", "is_drop"')
    return line

s4_start = content.find('4:\n\t\t\tdata["name"] = "SNOWFIELD TUNDRA"')
s5_start = content.find('5:\n\t\t\tdata["name"] = "STEEL REFINERY"')
s4_block = content[s4_start:s5_start]
i_idx = 0
s4_new = re.sub(r'\{"rect":[^}]+PlatformType\.(ICE_SLAB|GIRDER)[^}]*\}', replace_ice_stage4, s4_block)
content = content[:s4_start] + s4_new + content[s5_start:]

# 5. Update Stage 5 (Steel Refinery)
# LAVA_GRATE variants: wide, slag_crag, grate
# GIRDER: refinery
lava_vars = ["wide", "slag_crag", "grate"]
l_idx = 0
def replace_lava_stage5(match):
    global l_idx
    line = match.group(0)
    if 'PlatformType.LAVA_GRATE' in line and 'variant' not in line:
        v = lava_vars[l_idx % len(lava_vars)]
        l_idx += 1
        return line.replace('"type": PlatformType.LAVA_GRATE}', f'"type": PlatformType.LAVA_GRATE, "variant": "{v}"}}').replace('"type": PlatformType.LAVA_GRATE, "is_drop"', f'"type": PlatformType.LAVA_GRATE, "variant": "{v}", "is_drop"')
    elif 'PlatformType.GIRDER' in line and 'variant' not in line:
        return line.replace('"type": PlatformType.GIRDER}', '"type": PlatformType.GIRDER, "variant": "refinery"}').replace('"type": PlatformType.GIRDER, "is_drop"', '"type": PlatformType.GIRDER, "variant": "refinery", "is_drop"')
    return line

s5_start = content.find('5:\n\t\t\tdata["name"] = "STEEL REFINERY"')
s6_start = content.find('6:\n\t\t\tdata["name"] = "ELECTRIC DYNAMO"')
s5_block = content[s5_start:s6_start]
l_idx = 0
s5_new = re.sub(r'\{"rect":[^}]+PlatformType\.(LAVA_GRATE|GIRDER)[^}]*\}', replace_lava_stage5, s5_block)
content = content[:s5_start] + s5_new + content[s6_start:]

# 6. Update Stage 6 (Electric Dynamo)
# ENERGY_BARRIER variants: wide, rail, barrier
# TECH_CATWALK: rail, catwalk
dynamo_vars = ["wide", "rail", "default"]
d_idx = 0
def replace_dynamo_stage6(match):
    global d_idx
    line = match.group(0)
    if 'PlatformType.ENERGY_BARRIER' in line and 'variant' not in line:
        v = dynamo_vars[d_idx % len(dynamo_vars)]
        d_idx += 1
        return line.replace('"type": PlatformType.ENERGY_BARRIER}', f'"type": PlatformType.ENERGY_BARRIER, "variant": "{v}"}}').replace('"type": PlatformType.ENERGY_BARRIER, "is_drop"', f'"type": PlatformType.ENERGY_BARRIER, "variant": "{v}", "is_drop"')
    elif 'PlatformType.TECH_CATWALK' in line and 'variant' not in line:
        v = "rail" if (d_idx % 2 == 1) else "default"
        d_idx += 1
        return line.replace('"type": PlatformType.TECH_CATWALK}', f'"type": PlatformType.TECH_CATWALK, "variant": "{v}"}}').replace('"type": PlatformType.TECH_CATWALK, "is_drop"', f'"type": PlatformType.TECH_CATWALK, "variant": "{v}", "is_drop"')
    return line

s6_start = content.find('6:\n\t\t\tdata["name"] = "ELECTRIC DYNAMO"')
s7_start = content.find('7:\n\t\t\tdata["name"] = "ALIEN AEROSPACE HANGAR"')
s6_block = content[s6_start:s7_start]
d_idx = 0
s6_new = re.sub(r'\{"rect":[^}]+PlatformType\.(ENERGY_BARRIER|TECH_CATWALK)[^}]*\}', replace_dynamo_stage6, s6_block)
content = content[:s6_start] + s6_new + content[s7_start:]

# 7. Update Stage 7 (Alien Aerospace Hangar)
# TECH_CATWALK: deck, default
# GIRDER: hangar
h_idx = 0
def replace_hangar_stage7(match):
    global h_idx
    line = match.group(0)
    if 'PlatformType.TECH_CATWALK' in line and 'variant' not in line:
        v = "deck" if (h_idx % 2 == 1) else "default"
        h_idx += 1
        return line.replace('"type": PlatformType.TECH_CATWALK}', f'"type": PlatformType.TECH_CATWALK, "variant": "{v}"}}').replace('"type": PlatformType.TECH_CATWALK, "is_drop"', f'"type": PlatformType.TECH_CATWALK, "variant": "{v}", "is_drop"')
    elif 'PlatformType.GIRDER' in line and 'variant' not in line:
        return line.replace('"type": PlatformType.GIRDER}', '"type": PlatformType.GIRDER, "variant": "hangar"}').replace('"type": PlatformType.GIRDER, "is_drop"', '"type": PlatformType.GIRDER, "variant": "hangar", "is_drop"')
    return line

s7_start = content.find('7:\n\t\t\tdata["name"] = "ALIEN AEROSPACE HANGAR"')
s8_start = content.find('8:\n\t\t\tdata["name"] = "MOTHER BRAIN SANCTUM"')
s7_block = content[s7_start:s8_start]
h_idx = 0
s7_new = re.sub(r'\{"rect":[^}]+PlatformType\.(TECH_CATWALK|GIRDER)[^}]*\}', replace_hangar_stage7, s7_block)
content = content[:s7_start] + s7_new + content[s8_start:]

# 8. Update Stage 8 (Mother Brain Sanctum)
# BIO_RIB: synapse, carapace, wide
# ENERGY_BARRIER: psychic
syn_vars = ["synapse", "carapace", "wide"]
syn_idx = 0
def replace_sanctum_stage8(match):
    global syn_idx
    line = match.group(0)
    if 'PlatformType.BIO_RIB' in line and 'variant' not in line:
        v = syn_vars[syn_idx % len(syn_vars)]
        syn_idx += 1
        return line.replace('"type": PlatformType.BIO_RIB}', f'"type": PlatformType.BIO_RIB, "variant": "{v}"}}').replace('"type": PlatformType.BIO_RIB, "is_drop"', f'"type": PlatformType.BIO_RIB, "variant": "{v}", "is_drop"')
    elif 'PlatformType.ENERGY_BARRIER' in line and 'variant' not in line:
        return line.replace('"type": PlatformType.ENERGY_BARRIER}', '"type": PlatformType.ENERGY_BARRIER, "variant": "psychic"}').replace('"type": PlatformType.ENERGY_BARRIER, "is_drop"', '"type": PlatformType.ENERGY_BARRIER, "variant": "psychic", "is_drop"')
    return line

s8_start = content.find('8:\n\t\t\tdata["name"] = "MOTHER BRAIN SANCTUM"')
s8_end = content.find('\n\tstatic func', s8_start)
if s8_end == -1:
    s8_end = len(content)
s8_block = content[s8_start:s8_end]
syn_idx = 0
s8_new = re.sub(r'\{"rect":[^}]+PlatformType\.(BIO_RIB|ENERGY_BARRIER)[^}]*\}', replace_sanctum_stage8, s8_block)
content = content[:s8_start] + s8_new + content[s8_end:]

with open('scripts/level_maps.gd', 'w') as f:
    f.write(content)

print("level_maps.gd updated successfully with all matching theme platforms and variations!")
