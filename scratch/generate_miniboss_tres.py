import os

minibosses = [
    {
        "stage": 3,
        "name": "Chitin Behemoth",
        "uid": "uid://cminiboss_stg3_001",
        "health": 34.0,
        "speed": 58.0,
        "score": 9000,
        "w": 120, "h": 135,
        "min_att": 1.4, "max_att": 2.8
    },
    {
        "stage": 4,
        "name": "Polar Siege Colossus",
        "uid": "uid://cminiboss_stg4_001",
        "health": 36.0,
        "speed": 52.0,
        "score": 10000,
        "w": 114, "h": 136,
        "min_att": 1.3, "max_att": 2.6
    },
    {
        "stage": 5,
        "name": "Vulcan Dreadnought",
        "uid": "uid://cminiboss_stg5_001",
        "health": 40.0,
        "speed": 50.0,
        "score": 11000,
        "w": 118, "h": 138,
        "min_att": 1.2, "max_att": 2.5
    },
    {
        "stage": 6,
        "name": "Tesla Overlord",
        "uid": "uid://cminiboss_stg6_001",
        "health": 42.0,
        "speed": 54.0,
        "score": 12000,
        "w": 115, "h": 140,
        "min_att": 1.1, "max_att": 2.4
    },
    {
        "stage": 7,
        "name": "Orbital Vanguard",
        "uid": "uid://cminiboss_stg7_001",
        "health": 46.0,
        "speed": 64.0,
        "score": 14000,
        "w": 122, "h": 136,
        "min_att": 1.0, "max_att": 2.2
    },
    {
        "stage": 8,
        "name": "Psionic Leviathan",
        "uid": "uid://cminiboss_stg8_001",
        "health": 50.0,
        "speed": 56.0,
        "score": 16000,
        "w": 124, "h": 142,
        "min_att": 0.9, "max_att": 2.0
    }
]

for mb in minibosses:
    s = mb["stage"]
    content = f'''[gd_resource type="Resource" script_class="EnemyData" format=3 uid="{mb['uid']}"]

[ext_resource type="Script" path="res://scripts/enemy_data.gd" id="1_data"]
[ext_resource type="Texture2D" path="res://assets/enemies/mini_boss_stage{s}/mini_boss_stage{s}.png" id="2_tex"]

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
'''
    path = f'resources/enemies/mini_boss_stage{s}_data.tres'
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'Generated {path}')
