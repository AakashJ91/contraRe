import os

enemies = [
    {
        "id": "guerrilla_gunner",
        "uid": "uid://cguerrillagunner001",
        "name": "Guerrilla Gunner",
        "hp": 2.0, "speed": 90.0, "score": 200, "contact": 1.0,
        "w": 54.0, "h": 56.0, "atk_min": 1.8, "atk_max": 3.0
    },
    {
        "id": "flame_trooper",
        "uid": "uid://cflametrooper001",
        "name": "Flame Trooper",
        "hp": 4.5, "speed": 65.0, "score": 300, "contact": 1.5,
        "w": 68.0, "h": 64.0, "atk_min": 2.0, "atk_max": 3.5
    },
    {
        "id": "scuba_commando",
        "uid": "uid://cscubacommando001",
        "name": "Scuba Commando",
        "hp": 2.5, "speed": 75.0, "score": 250, "contact": 1.0,
        "w": 54.0, "h": 56.0, "atk_min": 1.5, "atk_max": 2.8
    },
    {
        "id": "torpedo_drone",
        "uid": "uid://ctorpedodrone001",
        "name": "Torpedo Drone",
        "hp": 3.0, "speed": 85.0, "score": 250, "contact": 1.0,
        "w": 56.0, "h": 52.0, "atk_min": 2.0, "atk_max": 3.2
    },
    {
        "id": "acid_spitter",
        "uid": "uid://cacidspitter001",
        "name": "Acid Spitter",
        "hp": 4.0, "speed": 70.0, "score": 350, "contact": 1.5,
        "w": 62.0, "h": 56.0, "atk_min": 2.2, "atk_max": 3.6
    },
    {
        "id": "ceiling_stalker",
        "uid": "uid://cceilingstalker001",
        "name": "Ceiling Stalker",
        "hp": 2.5, "speed": 110.0, "score": 300, "contact": 1.0,
        "w": 54.0, "h": 52.0, "atk_min": 1.2, "atk_max": 2.4
    },
    {
        "id": "cryo_trooper",
        "uid": "uid://ccryotrooper001",
        "name": "Cryo Trooper",
        "hp": 4.5, "speed": 60.0, "score": 350, "contact": 1.0,
        "w": 58.0, "h": 60.0, "atk_min": 2.5, "atk_max": 4.0
    },
    {
        "id": "sled_raider",
        "uid": "uid://csledraider001",
        "name": "Sled Raider",
        "hp": 5.0, "speed": 190.0, "score": 400, "contact": 2.0,
        "w": 68.0, "h": 52.0, "atk_min": 1.5, "atk_max": 2.5
    },
    {
        "id": "slag_mech",
        "uid": "uid://cslagmech001",
        "name": "Slag Loader Mech",
        "hp": 7.0, "speed": 50.0, "score": 500, "contact": 2.0,
        "w": 72.0, "h": 72.0, "atk_min": 2.5, "atk_max": 4.0
    },
    {
        "id": "conveyor_droid",
        "uid": "uid://cconveyordroid001",
        "name": "Conveyor Sentry Droid",
        "hp": 3.5, "speed": 80.0, "score": 300, "contact": 1.0,
        "w": 52.0, "h": 52.0, "atk_min": 2.0, "atk_max": 3.5
    },
    {
        "id": "tesla_trooper",
        "uid": "uid://cteslatrooper001",
        "name": "Tesla Shock Trooper",
        "hp": 5.0, "speed": 65.0, "score": 450, "contact": 1.5,
        "w": 58.0, "h": 62.0, "atk_min": 2.2, "atk_max": 3.8
    },
    {
        "id": "spark_drone",
        "uid": "uid://csparkdrone001",
        "name": "Spark Arc Drone",
        "hp": 3.0, "speed": 95.0, "score": 350, "contact": 1.0,
        "w": 54.0, "h": 54.0, "atk_min": 1.8, "atk_max": 3.0
    },
    {
        "id": "jetpack_marine",
        "uid": "uid://cjetpackmarine001",
        "name": "Aerospace Jetpack Marine",
        "hp": 4.5, "speed": 115.0, "score": 450, "contact": 1.5,
        "w": 56.0, "h": 60.0, "atk_min": 1.6, "atk_max": 3.0
    },
    {
        "id": "rail_turret",
        "uid": "uid://crailturret001",
        "name": "Ceiling Rail Turret",
        "hp": 6.0, "speed": 60.0, "score": 500, "contact": 1.5,
        "w": 60.0, "h": 56.0, "atk_min": 2.4, "atk_max": 3.8
    },
    {
        "id": "tentacle_whipper",
        "uid": "uid://ctentaclewhipper001",
        "name": "Sanctum Tentacle Whipper",
        "hp": 5.5, "speed": 0.0, "score": 450, "contact": 2.0,
        "w": 60.0, "h": 68.0, "atk_min": 1.5, "atk_max": 2.8
    },
    {
        "id": "psychic_orb",
        "uid": "uid://cpsychicorb001",
        "name": "Bio-Psychic Ocular Orb",
        "hp": 6.0, "speed": 75.0, "score": 600, "contact": 1.5,
        "w": 60.0, "h": 60.0, "atk_min": 2.0, "atk_max": 3.5
    }
]

out_dir = "resources/enemies"
os.makedirs(out_dir, exist_ok=True)

for e in enemies:
    filename = f"{out_dir}/{e['id']}_data.tres"
    content = f"""[gd_resource type="Resource" script_class="EnemyData" load_steps=3 format=3 uid="{e['uid']}"]

[ext_resource type="Script" path="res://scripts/enemy_data.gd" id="1_data"]
[ext_resource type="Texture2D" path="res://assets/enemies/{e['id']}/{e['id']}.png" id="2_tex"]

[resource]
script = ExtResource("1_data")
enemy_name = "{e['name']}"
max_health = {e['hp']}
move_speed = {e['speed']}
score_reward = {e['score']}
contact_damage = {e['contact']}
sprite_texture = ExtResource("2_tex")
sprite_size = Vector2({e['w']}, {e['h']})
attack_interval_min = {e['atk_min']}
attack_interval_max = {e['atk_max']}
"""
    with open(filename, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Generated {filename}")
