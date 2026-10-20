import os

tres_content = '''[gd_resource type="Resource" script_class="ExplosionVFXData" format=3 uid="uid://c_exp_big_explosion"]

[ext_resource type="Script" path="res://scripts/explosion_vfx_data.gd" id="1_data"]
'''
for i in range(15):
    tres_content += f'[ext_resource type="Texture2D" path="res://assets/vfx/effect/big_explosion/frame_{i}.png" id="{i+2}_f{i}"]\n'

frames_arr = ', '.join([f'ExtResource("{i+2}_f{i}")' for i in range(15)])

tres_content += f'''
[resource]
script = ExtResource("1_data")
explosion_name = "BIG APOCALYPSE EXPLOSION"
category = "Nuclear"
scale_mult = 1.0
duration = 0.85
is_electric = false
is_alien = false
primary_color = Color(1, 1, 1, 1)
secondary_color = Color(1, 0.7, 0.2, 1)
shockwave_color = Color(1.0, 0.92, 0.6, 0.95)
shockwave_radius = 110.0
shockwave_ring_count = 3
shockwave_ring_width = 4.0
debris_count = 18
debris_speed_min = 120.0
debris_speed_max = 340.0
debris_color = Color(1.0, 0.92, 0.7, 1)
debris_gravity = 420.0
sparks_count = 28
sparks_speed_min = 100.0
sparks_speed_max = 380.0
sparks_color = Color(1.0, 0.9, 0.35, 1)
smoke_count = 12
smoke_color = Color(0.25, 0.22, 0.28, 0.85)
smoke_buoyancy = 35.0
screen_shake_intensity = 16.0
screen_shake_duration = 0.65
sfx_name = "boss_defeat"
explosion_frames = Array[Texture2D]([{frames_arr}])
frame_size = Vector2(192, 192)
'''

with open('resources/vfx/explosion_big.tres', 'w') as f:
    f.write(tres_content)

with open('resources/vfx/explosion_nuclear_mega.tres', 'w') as f:
    f.write(tres_content.replace('uid://c_exp_big_explosion', 'uid://c_exp_res_nuclear'))

print('Successfully generated resources/vfx/explosion_big.tres and updated explosion_nuclear_mega.tres')
