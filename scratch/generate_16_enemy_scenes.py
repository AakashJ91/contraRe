import os

scenes_info = [
    {
        "id": "guerrilla_gunner",
        "shape": 'sub_resource type="CapsuleShape2D" id="CapsuleShape2D_1"]\nradius = 9.0\nheight = 32.0',
        "shape_node": '<node name="CollisionShape2D" type="CollisionShape2D" parent="."]\nposition = Vector2(0, -2)\nshape = SubResource("CapsuleShape2D_1")'
    },
    {
        "id": "flame_trooper",
        "shape": 'sub_resource type="RectangleShape2D" id="RectangleShape2D_1"]\nsize = Vector2(24.0, 36.0)',
        "shape_node": '<node name="CollisionShape2D" type="CollisionShape2D" parent="."]\nposition = Vector2(0, -2)\nshape = SubResource("RectangleShape2D_1")'
    },
    {
        "id": "scuba_commando",
        "shape": 'sub_resource type="CapsuleShape2D" id="CapsuleShape2D_1"]\nradius = 8.0\nheight = 30.0',
        "shape_node": '<node name="CollisionShape2D" type="CollisionShape2D" parent="."]\nposition = Vector2(0, -2)\nshape = SubResource("CapsuleShape2D_1")'
    },
    {
        "id": "torpedo_drone",
        "shape": 'sub_resource type="CircleShape2D" id="CircleShape2D_1"]\nradius = 14.0',
        "shape_node": '<node name="CollisionShape2D" type="CollisionShape2D" parent="."]\nposition = Vector2(0, 0)\nshape = SubResource("CircleShape2D_1")'
    },
    {
        "id": "acid_spitter",
        "shape": 'sub_resource type="RectangleShape2D" id="RectangleShape2D_1"]\nsize = Vector2(30.0, 24.0)',
        "shape_node": '<node name="CollisionShape2D" type="CollisionShape2D" parent="."]\nposition = Vector2(0, 0)\nshape = SubResource("RectangleShape2D_1")'
    },
    {
        "id": "ceiling_stalker",
        "shape": 'sub_resource type="RectangleShape2D" id="RectangleShape2D_1"]\nsize = Vector2(26.0, 22.0)',
        "shape_node": '<node name="CollisionShape2D" type="CollisionShape2D" parent="."]\nposition = Vector2(0, 0)\nshape = SubResource("RectangleShape2D_1")'
    },
    {
        "id": "cryo_trooper",
        "shape": 'sub_resource type="CapsuleShape2D" id="CapsuleShape2D_1"]\nradius = 9.0\nheight = 34.0',
        "shape_node": '<node name="CollisionShape2D" type="CollisionShape2D" parent="."]\nposition = Vector2(0, -2)\nshape = SubResource("CapsuleShape2D_1")'
    },
    {
        "id": "sled_raider",
        "shape": 'sub_resource type="RectangleShape2D" id="RectangleShape2D_1"]\nsize = Vector2(36.0, 22.0)',
        "shape_node": '<node name="CollisionShape2D" type="CollisionShape2D" parent="."]\nposition = Vector2(0, 2)\nshape = SubResource("RectangleShape2D_1")'
    },
    {
        "id": "slag_mech",
        "shape": 'sub_resource type="RectangleShape2D" id="RectangleShape2D_1"]\nsize = Vector2(34.0, 42.0)',
        "shape_node": '<node name="CollisionShape2D" type="CollisionShape2D" parent="."]\nposition = Vector2(0, -2)\nshape = SubResource("RectangleShape2D_1")'
    },
    {
        "id": "conveyor_droid",
        "shape": 'sub_resource type="CircleShape2D" id="CircleShape2D_1"]\nradius = 13.0',
        "shape_node": '<node name="CollisionShape2D" type="CollisionShape2D" parent="."]\nposition = Vector2(0, 0)\nshape = SubResource("CircleShape2D_1")'
    },
    {
        "id": "tesla_trooper",
        "shape": 'sub_resource type="CapsuleShape2D" id="CapsuleShape2D_1"]\nradius = 9.0\nheight = 34.0',
        "shape_node": '<node name="CollisionShape2D" type="CollisionShape2D" parent="."]\nposition = Vector2(0, -2)\nshape = SubResource("CapsuleShape2D_1")'
    },
    {
        "id": "spark_drone",
        "shape": 'sub_resource type="CircleShape2D" id="CircleShape2D_1"]\nradius = 14.0',
        "shape_node": '<node name="CollisionShape2D" type="CollisionShape2D" parent="."]\nposition = Vector2(0, 0)\nshape = SubResource("CircleShape2D_1")'
    },
    {
        "id": "jetpack_marine",
        "shape": 'sub_resource type="CapsuleShape2D" id="CapsuleShape2D_1"]\nradius = 9.0\nheight = 32.0',
        "shape_node": '<node name="CollisionShape2D" type="CollisionShape2D" parent="."]\nposition = Vector2(0, 0)\nshape = SubResource("CapsuleShape2D_1")'
    },
    {
        "id": "rail_turret",
        "shape": 'sub_resource type="RectangleShape2D" id="RectangleShape2D_1"]\nsize = Vector2(28.0, 28.0)',
        "shape_node": '<node name="CollisionShape2D" type="CollisionShape2D" parent="."]\nposition = Vector2(0, 0)\nshape = SubResource("RectangleShape2D_1")'
    },
    {
        "id": "tentacle_whipper",
        "shape": 'sub_resource type="RectangleShape2D" id="RectangleShape2D_1"]\nsize = Vector2(26.0, 36.0)',
        "shape_node": '<node name="CollisionShape2D" type="CollisionShape2D" parent="."]\nposition = Vector2(0, -10)\nshape = SubResource("RectangleShape2D_1")'
    },
    {
        "id": "psychic_orb",
        "shape": 'sub_resource type="CircleShape2D" id="CircleShape2D_1"]\nradius = 16.0',
        "shape_node": '<node name="CollisionShape2D" type="CollisionShape2D" parent="."]\nposition = Vector2(0, 0)\nshape = SubResource("CircleShape2D_1")'
    }
]

out_dir = "scenes"
os.makedirs(out_dir, exist_ok=True)

for sc in scenes_info:
    enemy_id = sc["id"]
    pascal_name = "".join([part.capitalize() for part in enemy_id.split("_")])
    tscn_content = f"""[gd_scene load_steps=3 format=3 uid="uid://cscene{enemy_id[:10]}001"]

[ext_resource type="Script" path="res://scripts/enemy_{enemy_id}.gd" id="1_{enemy_id}"]

[{sc["shape"]}

[node name="Enemy{pascal_name}" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 2
script = ExtResource("1_{enemy_id}")

{sc["shape_node"]}
"""
    fname = f"{out_dir}/enemy_{enemy_id}.tscn"
    with open(fname, "w", encoding="utf-8") as f:
        f.write(tscn_content)
    print(f"Generated {fname}")
