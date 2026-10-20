import os

os.makedirs('resources/enemies', exist_ok=True)

THEME_CONFIGS = [
    (1, "military", "MILITARY DEFENSE POD", "Color(1, 0.25, 0.15, 1)", "Color(1, 0.55, 0.2, 1)", "Color(1, 0.55, 0.12, 1)"),
    (2, "aqua", "AQUA HYDRO RIG SENSOR", "Color(0, 0.75, 0.95, 1)", "Color(0.25, 0.88, 1, 1)", "Color(0.15, 0.8, 1, 1)"),
    (3, "alien", "BIO-ORGANIC SPORE SENSOR", "Color(0.95, 0.65, 0.1, 1)", "Color(1, 0.85, 0.2, 1)", "Color(0.55, 0.95, 0.25, 1)"),
    (4, "cryo", "CRYO GLACIAL SCANNER", "Color(0.25, 0.75, 1, 1)", "Color(0.65, 0.9, 1, 1)", "Color(0.4, 0.85, 1, 1)"),
    (5, "magma", "MAGMA SMELTER SENSOR", "Color(1, 0.3, 0.1, 1)", "Color(1, 0.65, 0.15, 1)", "Color(1, 0.45, 0.1, 1)"),
    (6, "tesla", "TESLA DYNAMO COIL SENSOR", "Color(0.6, 0.3, 1, 1)", "Color(0.75, 0.5, 1, 1)", "Color(0.5, 0.35, 1, 1)"),
    (7, "stealth", "ORBITAL STEALTH SENSOR", "Color(0.9, 0.2, 0.5, 1)", "Color(1, 0.4, 0.7, 1)", "Color(0.8, 0.2, 0.7, 1)"),
    (8, "sanctum", "SANCTUM PSIONIC OVERSEER", "Color(1, 0.15, 0.4, 1)", "Color(1, 0.45, 0.6, 1)", "Color(1, 0.2, 0.45, 1)")
]

for stage_idx, theme_name, title, core_col, glow_col, thrust_col in THEME_CONFIGS:
    tres_content = f"""[gd_resource type="Resource" script_class="PowerupSensorData" load_steps=8 format=3 uid="uid://psensorstage{stage_idx}"]

[ext_resource type="Script" path="res://scripts/powerup_sensor_data.gd" id="1_data"]
[ext_resource type="Texture2D" path="res://assets/powerups/sensor/themes/{theme_name}/frame_0.png" id="2_f0"]
[ext_resource type="Texture2D" path="res://assets/powerups/sensor/themes/{theme_name}/frame_1.png" id="3_f1"]
[ext_resource type="Texture2D" path="res://assets/powerups/sensor/themes/{theme_name}/frame_2.png" id="4_f2"]
[ext_resource type="Texture2D" path="res://assets/powerups/sensor/themes/{theme_name}/frame_3.png" id="5_f3"]
[ext_resource type="Texture2D" path="res://assets/powerups/sensor/themes/{theme_name}/frame_4.png" id="6_f4"]
[ext_resource type="Texture2D" path="res://assets/powerups/sensor/themes/{theme_name}/frame_5.png" id="7_f5"]

[resource]
script = ExtResource("1_data")
sensor_name = "{title}"
max_health = 3.0
score_reward = 500
default_weapon = 1
frame_textures = Array[Texture2D]([ExtResource("2_f0"), ExtResource("3_f1"), ExtResource("4_f2"), ExtResource("5_f3"), ExtResource("6_f4"), ExtResource("7_f5")])
animation_fps = 7.0
sprite_size = Vector2(40, 48)
core_color = {core_col}
pulse_glow_color = {glow_col}
thruster_color = {thrust_col}
hover_amplitude = 6.5
hover_speed = 3.2
theme_tag = "{theme_name}"
"""
    fpath = f'resources/enemies/powerup_sensor_stage{stage_idx}.tres'
    with open(fpath, 'w', encoding='utf-8') as f:
        f.write(tres_content)
    print(f'Wrote {fpath}')

# Write default powerup_sensor_data.tres pointing to military (stage 1)
default_path = 'resources/enemies/powerup_sensor_data.tres'
with open('resources/enemies/powerup_sensor_stage1.tres', 'r', encoding='utf-8') as src:
    content = src.read().replace('uid://psensorstage1', 'uid://psensordata001')
with open(default_path, 'w', encoding='utf-8') as dst:
    dst.write(content)
print(f'Wrote default {default_path}')
