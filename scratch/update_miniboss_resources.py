import os

minibosses = [
    {
        "stage": 1,
        "name": "Titan Goliath Mech",
        "uid": "uid://otenhfmc7h7e",
        "tex_path": "res://assets/enemies/mini_boss/mini_boss_mech.png",
        "health": 28.0,
        "speed": 65.0,
        "score": 6000,
        "w": 108, "h": 135,
        "min_att": 1.4, "max_att": 3.2,
        "patterns": '["quad_gatling", "cluster_grenade", "tremor_slam", "suppression_barrage"]',
        "spec_cd": 4.5,
        "enrage": 0.5
    },
    {
        "stage": 2,
        "name": "Aqua Assault Rig",
        "uid": "uid://dc1tvmb5x2e4o",
        "tex_path": "res://assets/enemies/mini_boss_stage2/mini_boss_stage2.png",
        "health": 32.0,
        "speed": 60.0,
        "score": 8000,
        "w": 110, "h": 138,
        "min_att": 1.3, "max_att": 2.8,
        "patterns": '["harpoon_skewer", "depth_charge", "hydro_cutter", "water_torpedo"]',
        "spec_cd": 4.2,
        "enrage": 0.5
    },
    {
        "stage": 3,
        "name": "Chitin Behemoth",
        "uid": "uid://cminiboss_stg3_001",
        "tex_path": "res://assets/enemies/mini_boss_stage3/mini_boss_stage3.png",
        "health": 36.0,
        "speed": 58.0,
        "score": 9000,
        "w": 120, "h": 135,
        "min_att": 1.2, "max_att": 2.6,
        "patterns": '["spore_needle", "acid_glob", "chitin_spine_nova", "acid_spray_sweep"]',
        "spec_cd": 4.0,
        "enrage": 0.5
    },
    {
        "stage": 4,
        "name": "Polar Siege Colossus",
        "uid": "uid://cminiboss_stg4_001",
        "tex_path": "res://assets/enemies/mini_boss_stage4/mini_boss_stage4.png",
        "health": 40.0,
        "speed": 52.0,
        "score": 10000,
        "w": 114, "h": 136,
        "min_att": 1.2, "max_att": 2.5,
        "patterns": '["subzero_beam", "ice_mortar", "frost_flurry", "avalanche_slam"]',
        "spec_cd": 3.8,
        "enrage": 0.5
    },
    {
        "stage": 5,
        "name": "Vulcan Dreadnought",
        "uid": "uid://cminiboss_stg5_001",
        "tex_path": "res://assets/enemies/mini_boss_stage5/mini_boss_stage5.png",
        "health": 44.0,
        "speed": 50.0,
        "score": 11000,
        "w": 118, "h": 138,
        "min_att": 1.1, "max_att": 2.4,
        "patterns": '["rivet_burst", "slag_wave", "fire_wheel", "magma_bombardment"]',
        "spec_cd": 3.6,
        "enrage": 0.5
    },
    {
        "stage": 6,
        "name": "Tesla Overlord",
        "uid": "uid://cminiboss_stg6_001",
        "tex_path": "res://assets/enemies/mini_boss_stage6/mini_boss_stage6.png",
        "health": 46.0,
        "speed": 54.0,
        "score": 12000,
        "w": 115, "h": 140,
        "min_att": 1.0, "max_att": 2.2,
        "patterns": '["spark_crossfire", "ball_lightning", "lightning_strike", "emp_nova"]',
        "spec_cd": 3.5,
        "enrage": 0.5
    },
    {
        "stage": 7,
        "name": "Orbital Vanguard",
        "uid": "uid://cminiboss_stg7_001",
        "tex_path": "res://assets/enemies/mini_boss_stage7/mini_boss_stage7.png",
        "health": 50.0,
        "speed": 64.0,
        "score": 14000,
        "w": 122, "h": 136,
        "min_att": 0.9, "max_att": 2.0,
        "patterns": '["particle_beam", "homing_missile", "laser_sweep", "plasma_drone"]',
        "spec_cd": 3.2,
        "enrage": 0.5
    },
    {
        "stage": 8,
        "name": "Psionic Leviathan",
        "uid": "uid://cminiboss_stg8_001",
        "tex_path": "res://assets/enemies/mini_boss_stage8/mini_boss_stage8.png",
        "health": 54.0,
        "speed": 56.0,
        "score": 16000,
        "w": 124, "h": 142,
        "min_att": 0.8, "max_att": 1.8,
        "patterns": '["telekinetic_dart", "psychic_ring", "void_orb", "mind_pillar"]',
        "spec_cd": 3.0,
        "enrage": 0.5
    }
]

for mb in minibosses:
    s = mb["stage"]
    content = f'''[gd_resource type="Resource" script_class="EnemyData" format=3 uid="{mb['uid']}"]

[ext_resource type="Script" path="res://scripts/enemy_data.gd" id="1_data"]
[ext_resource type="Texture2D" path="{mb['tex_path']}" id="2_tex"]

[resource]
script = ExtResource("1_data")
enemy_name = "{mb['name']}"
max_health = {mb['health']:.1f}
move_speed = {mb['speed']:.1f}
score_reward = {mb['score']}
contact_damage = 2.0
sprite_texture = ExtResource("2_tex")
sprite_size = Vector2({mb['w']}, {mb['h']})
attack_interval_min = {mb['min_att']:.1f}
attack_interval_max = {mb['max_att']:.1f}
attack_patterns = {mb['patterns']}
special_attack_cooldown = {mb['spec_cd']:.1f}
enrage_health_threshold = {mb['enrage']:.1f}
'''
    path = f'resources/enemies/mini_boss_stage{s}_data.tres'
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'Generated {path}')
