import os
import re

enemies = [
    ("guerrilla_gunner", 1),
    ("flame_trooper", 1),
    ("scuba_commando", 2),
    ("torpedo_drone", 2),
    ("acid_spitter", 3),
    ("ceiling_stalker", 3),
    ("cryo_trooper", 4),
    ("sled_raider", 4),
    ("slag_mech", 5),
    ("conveyor_droid", 5),
    ("tesla_trooper", 6),
    ("spark_drone", 6),
    ("jetpack_marine", 7),
    ("rail_turret", 7),
    ("tentacle_whipper", 8),
    ("psychic_orb", 8)
]

errors = []
successes = []

# 1. Audit .tres files
for enemy_id, stage in enemies:
    tres_path = f"resources/enemies/{enemy_id}_data.tres"
    if not os.path.exists(tres_path):
        errors.append(f"Missing tres: {tres_path}")
    else:
        successes.append(f"Found tres: {tres_path}")

# 2. Audit .tscn files
for enemy_id, stage in enemies:
    tscn_path = f"scenes/enemy_{enemy_id}.tscn"
    if not os.path.exists(tscn_path):
        errors.append(f"Missing tscn: {tscn_path}")
    else:
        successes.append(f"Found tscn: {tscn_path}")

# 3. Audit scripts
for enemy_id, stage in enemies:
    gd_path = f"scripts/enemy_{enemy_id}.gd"
    if not os.path.exists(gd_path):
        errors.append(f"Missing script: {gd_path}")
    else:
        successes.append(f"Found script: {gd_path}")

# 4. Audit sprites
for enemy_id, stage in enemies:
    folder = f"assets/enemies/{enemy_id}"
    base_png = f"{folder}/{enemy_id}.png"
    if not os.path.exists(base_png):
        errors.append(f"Missing base sprite: {base_png}")
    for i in range(4):
        w_png = f"{folder}/movement/walk_{i}.png"
        d_png = f"{folder}/death/destroy_{i}.png"
        if not os.path.exists(w_png):
            errors.append(f"Missing walk frame: {w_png}")
        if not os.path.exists(d_png):
            errors.append(f"Missing death frame: {d_png}")

# 5. Audit stage1.gd integration
with open("scripts/stage1.gd", "r", encoding="utf-8") as f:
    stage1_code = f.read()

for enemy_id, stage in enemies:
    scene_var = f"{enemy_id}_scene"
    spawn_fn = f"_spawn_{enemy_id}s"
    if scene_var not in stage1_code:
        errors.append(f"Missing preload for {scene_var} in stage1.gd")
    if spawn_fn not in stage1_code:
        errors.append(f"Missing spawn method {spawn_fn} in stage1.gd")

print(f"Total successes: {len(successes)}")
if errors:
    print(f"FAILED with {len(errors)} errors:")
    for e in errors:
        print("  -", e)
else:
    print("ALL 16 ENEMIES AND INTEGRATIONS AUDITED PERFECTLY! 100% OK")
