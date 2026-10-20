import os

def generate_explosion_resources():
    out_dir = "d:/GitHub/contraRe/resources/vfx"
    os.makedirs(out_dir, exist_ok=True)
    
    resource_definitions = [
        {
            "filename": "explosion_arcade_fiery.tres",
            "uid": "uid://c_exp_res_fiery",
            "theme_folder": "fiery",
            "num_frames": 8,
            "explosion_name": "ARCADE INFERNO",
            "category": "Fiery",
            "scale_mult": 1.0,
            "duration": 0.52,
            "is_electric": "false",
            "is_alien": "false",
            "primary_color": "Color(1, 0.88, 0.35, 1)",
            "secondary_color": "Color(1, 0.45, 0.1, 1)",
            "shockwave_color": "Color(1, 0.85, 0.3, 0.85)",
            "shockwave_radius": 58.0,
            "shockwave_ring_count": 2,
            "shockwave_ring_width": 3.5,
            "debris_count": 8,
            "debris_speed_min": 90.0,
            "debris_speed_max": 240.0,
            "debris_color": "Color(1, 0.9, 0.7, 1)",
            "debris_gravity": 450.0,
            "sparks_count": 14,
            "sparks_speed_min": 70.0,
            "sparks_speed_max": 280.0,
            "sparks_color": "Color(1, 0.85, 0.25, 1)",
            "smoke_count": 6,
            "smoke_color": "Color(0.2, 0.18, 0.22, 0.75)",
            "smoke_buoyancy": 25.0,
            "screen_shake_intensity": 5.0,
            "screen_shake_duration": 0.25,
            "sfx_name": "explosion",
            "frame_size": "Vector2(96, 96)"
        },
        {
            "filename": "explosion_electric_tesla.tres",
            "uid": "uid://c_exp_res_electric",
            "theme_folder": "electric",
            "num_frames": 8,
            "explosion_name": "TESLA EMP DETONATION",
            "category": "Electric",
            "scale_mult": 1.05,
            "duration": 0.48,
            "is_electric": "true",
            "is_alien": "false",
            "primary_color": "Color(0.4, 0.92, 1.4, 1)",
            "secondary_color": "Color(0.1, 0.55, 1.0, 1)",
            "shockwave_color": "Color(0.25, 0.88, 1.0, 0.9)",
            "shockwave_radius": 64.0,
            "shockwave_ring_count": 3,
            "shockwave_ring_width": 2.8,
            "debris_count": 9,
            "debris_speed_min": 110.0,
            "debris_speed_max": 260.0,
            "debris_color": "Color(0.7, 0.9, 1.0, 1)",
            "debris_gravity": 380.0,
            "sparks_count": 18,
            "sparks_speed_min": 100.0,
            "sparks_speed_max": 320.0,
            "sparks_color": "Color(0.4, 0.95, 1.0, 1)",
            "smoke_count": 5,
            "smoke_color": "Color(0.15, 0.2, 0.3, 0.7)",
            "smoke_buoyancy": 20.0,
            "screen_shake_intensity": 5.5,
            "screen_shake_duration": 0.28,
            "sfx_name": "explosion",
            "frame_size": "Vector2(96, 96)"
        },
        {
            "filename": "explosion_alien_bio.tres",
            "uid": "uid://c_exp_res_alien",
            "theme_folder": "alien",
            "num_frames": 8,
            "explosion_name": "BIO-ACID RUPTURE",
            "category": "Alien",
            "scale_mult": 1.1,
            "duration": 0.54,
            "is_electric": "false",
            "is_alien": "true",
            "primary_color": "Color(0.55, 1.3, 0.35, 1)",
            "secondary_color": "Color(0.2, 0.8, 0.15, 1)",
            "shockwave_color": "Color(0.45, 1.0, 0.25, 0.85)",
            "shockwave_radius": 60.0,
            "shockwave_ring_count": 2,
            "shockwave_ring_width": 3.2,
            "debris_count": 10,
            "debris_speed_min": 80.0,
            "debris_speed_max": 220.0,
            "debris_color": "Color(0.65, 1.0, 0.4, 1)",
            "debris_gravity": 480.0,
            "sparks_count": 12,
            "sparks_speed_min": 60.0,
            "sparks_speed_max": 240.0,
            "sparks_color": "Color(0.8, 1.0, 0.3, 1)",
            "smoke_count": 7,
            "smoke_color": "Color(0.18, 0.25, 0.16, 0.78)",
            "smoke_buoyancy": 30.0,
            "screen_shake_intensity": 5.2,
            "screen_shake_duration": 0.26,
            "sfx_name": "explosion",
            "frame_size": "Vector2(96, 96)"
        },
        {
            "filename": "explosion_nuclear_mega.tres",
            "uid": "uid://c_exp_res_nuclear",
            "theme_folder": "nuclear",
            "num_frames": 8,
            "explosion_name": "THERMONUCLEAR SUPERNOVA",
            "category": "Nuclear",
            "scale_mult": 1.85,
            "duration": 0.75,
            "is_electric": "false",
            "is_alien": "false",
            "primary_color": "Color(1.3, 1.25, 0.9, 1)",
            "secondary_color": "Color(1.2, 0.6, 0.15, 1)",
            "shockwave_color": "Color(1.0, 0.92, 0.6, 0.95)",
            "shockwave_radius": 95.0,
            "shockwave_ring_count": 4,
            "shockwave_ring_width": 4.5,
            "debris_count": 16,
            "debris_speed_min": 140.0,
            "debris_speed_max": 360.0,
            "debris_color": "Color(1.0, 0.95, 0.75, 1)",
            "debris_gravity": 420.0,
            "sparks_count": 26,
            "sparks_speed_min": 110.0,
            "sparks_speed_max": 420.0,
            "sparks_color": "Color(1.0, 0.95, 0.4, 1)",
            "smoke_count": 10,
            "smoke_color": "Color(0.28, 0.22, 0.26, 0.85)",
            "smoke_buoyancy": 35.0,
            "screen_shake_intensity": 9.5,
            "screen_shake_duration": 0.45,
            "sfx_name": "explosion",
            "frame_size": "Vector2(112, 112)"
        },
        {
            "filename": "explosion_cryo_frost.tres",
            "uid": "uid://c_exp_res_cryo",
            "theme_folder": "cryo",
            "num_frames": 8,
            "explosion_name": "CRYO FROST SHATTER",
            "category": "Cryo",
            "scale_mult": 1.0,
            "duration": 0.50,
            "is_electric": "false",
            "is_alien": "false",
            "primary_color": "Color(0.8, 1.1, 1.4, 1)",
            "secondary_color": "Color(0.3, 0.75, 1.0, 1)",
            "shockwave_color": "Color(0.65, 0.92, 1.0, 0.85)",
            "shockwave_radius": 56.0,
            "shockwave_ring_count": 2,
            "shockwave_ring_width": 3.0,
            "debris_count": 9,
            "debris_speed_min": 85.0,
            "debris_speed_max": 230.0,
            "debris_color": "Color(0.85, 0.95, 1.0, 1)",
            "debris_gravity": 440.0,
            "sparks_count": 14,
            "sparks_speed_min": 75.0,
            "sparks_speed_max": 270.0,
            "sparks_color": "Color(0.7, 0.95, 1.0, 1)",
            "smoke_count": 6,
            "smoke_color": "Color(0.2, 0.28, 0.35, 0.72)",
            "smoke_buoyancy": 18.0,
            "screen_shake_intensity": 4.8,
            "screen_shake_duration": 0.22,
            "sfx_name": "explosion",
            "frame_size": "Vector2(96, 96)"
        },
        {
            "filename": "explosion_magma_volcanic.tres",
            "uid": "uid://c_exp_res_magma",
            "theme_folder": "magma",
            "num_frames": 8,
            "explosion_name": "VOLCANIC MAGMA ERUPTION",
            "category": "Magma",
            "scale_mult": 1.15,
            "duration": 0.56,
            "is_electric": "false",
            "is_alien": "false",
            "primary_color": "Color(1.2, 0.75, 0.2, 1)",
            "secondary_color": "Color(1.0, 0.25, 0.05, 1)",
            "shockwave_color": "Color(1.0, 0.55, 0.15, 0.88)",
            "shockwave_radius": 62.0,
            "shockwave_ring_count": 3,
            "shockwave_ring_width": 3.6,
            "debris_count": 11,
            "debris_speed_min": 95.0,
            "debris_speed_max": 260.0,
            "debris_color": "Color(1.0, 0.6, 0.2, 1)",
            "debris_gravity": 500.0,
            "sparks_count": 16,
            "sparks_speed_min": 80.0,
            "sparks_speed_max": 300.0,
            "sparks_color": "Color(1.0, 0.7, 0.15, 1)",
            "smoke_count": 7,
            "smoke_color": "Color(0.24, 0.16, 0.18, 0.8)",
            "smoke_buoyancy": 32.0,
            "screen_shake_intensity": 6.2,
            "screen_shake_duration": 0.30,
            "sfx_name": "explosion",
            "frame_size": "Vector2(96, 96)"
        },
        {
            "filename": "explosion_mini_impact.tres",
            "uid": "uid://c_exp_res_mini",
            "theme_folder": "mini_burst",
            "num_frames": 6,
            "explosion_name": "INCENDIARY BULLET BURST",
            "category": "Mini",
            "scale_mult": 0.55,
            "duration": 0.32,
            "is_electric": "false",
            "is_alien": "false",
            "primary_color": "Color(1.0, 0.9, 0.4, 1)",
            "secondary_color": "Color(1.0, 0.45, 0.1, 1)",
            "shockwave_color": "Color(1.0, 0.8, 0.3, 0.8)",
            "shockwave_radius": 32.0,
            "shockwave_ring_count": 1,
            "shockwave_ring_width": 2.2,
            "debris_count": 4,
            "debris_speed_min": 60.0,
            "debris_speed_max": 150.0,
            "debris_color": "Color(1.0, 0.9, 0.7, 1)",
            "debris_gravity": 360.0,
            "sparks_count": 8,
            "sparks_speed_min": 50.0,
            "sparks_speed_max": 180.0,
            "sparks_color": "Color(1.0, 0.85, 0.3, 1)",
            "smoke_count": 3,
            "smoke_color": "Color(0.2, 0.2, 0.25, 0.6)",
            "smoke_buoyancy": 18.0,
            "screen_shake_intensity": 2.0,
            "screen_shake_duration": 0.12,
            "sfx_name": "explosion",
            "frame_size": "Vector2(64, 64)"
        },
        {
            "filename": "explosion_default.tres",
            "uid": "uid://c_exp_res_default",
            "theme_folder": "fiery",
            "num_frames": 8,
            "explosion_name": "DEFAULT EXPLOSION",
            "category": "Fiery",
            "scale_mult": 1.0,
            "duration": 0.52,
            "is_electric": "false",
            "is_alien": "false",
            "primary_color": "Color(1, 0.88, 0.35, 1)",
            "secondary_color": "Color(1, 0.45, 0.1, 1)",
            "shockwave_color": "Color(1, 0.85, 0.3, 0.85)",
            "shockwave_radius": 58.0,
            "shockwave_ring_count": 2,
            "shockwave_ring_width": 3.5,
            "debris_count": 7,
            "debris_speed_min": 90.0,
            "debris_speed_max": 240.0,
            "debris_color": "Color(1, 1, 1, 1)",
            "debris_gravity": 450.0,
            "sparks_count": 12,
            "sparks_speed_min": 70.0,
            "sparks_speed_max": 280.0,
            "sparks_color": "Color(1, 0.85, 0.25, 1)",
            "smoke_count": 6,
            "smoke_color": "Color(0.2, 0.2, 0.25, 0.75)",
            "smoke_buoyancy": 25.0,
            "screen_shake_intensity": 5.0,
            "screen_shake_duration": 0.25,
            "sfx_name": "explosion",
            "frame_size": "Vector2(96, 96)"
        }
    ]
    
    for r in resource_definitions:
        lines = []
        lines.append(f'[gd_resource type="Resource" script_class="ExplosionVFXData" format=3 uid="{r["uid"]}"]')
        lines.append('')
        lines.append('[ext_resource type="Script" path="res://scripts/explosion_vfx_data.gd" id="1_data"]')
        
        # Frame ext resources
        frame_ids = []
        for f in range(r["num_frames"]):
            ext_id = f"{f + 2}_f{f}"
            frame_ids.append(f'ExtResource("{ext_id}")')
            tex_path = f'res://assets/vfx/explosions/{r["theme_folder"]}/frame_{f}.png'
            lines.append(f'[ext_resource type="Texture2D" path="{tex_path}" id="{ext_id}"]')
            
        lines.append('')
        lines.append('[resource]')
        lines.append('script = ExtResource("1_data")')
        lines.append(f'explosion_name = "{r["explosion_name"]}"')
        lines.append(f'category = "{r["category"]}"')
        lines.append(f'scale_mult = {r["scale_mult"]}')
        lines.append(f'duration = {r["duration"]}')
        lines.append(f'is_electric = {r["is_electric"]}')
        lines.append(f'is_alien = {r["is_alien"]}')
        lines.append(f'primary_color = {r["primary_color"]}')
        lines.append(f'secondary_color = {r["secondary_color"]}')
        lines.append(f'shockwave_color = {r["shockwave_color"]}')
        lines.append(f'shockwave_radius = {r["shockwave_radius"]}')
        lines.append(f'shockwave_ring_count = {r["shockwave_ring_count"]}')
        lines.append(f'shockwave_ring_width = {r["shockwave_ring_width"]}')
        lines.append(f'debris_count = {r["debris_count"]}')
        lines.append(f'debris_speed_min = {r["debris_speed_min"]}')
        lines.append(f'debris_speed_max = {r["debris_speed_max"]}')
        lines.append(f'debris_color = {r["debris_color"]}')
        lines.append(f'debris_gravity = {r["debris_gravity"]}')
        lines.append(f'sparks_count = {r["sparks_count"]}')
        lines.append(f'sparks_speed_min = {r["sparks_speed_min"]}')
        lines.append(f'sparks_speed_max = {r["sparks_speed_max"]}')
        lines.append(f'sparks_color = {r["sparks_color"]}')
        lines.append(f'smoke_count = {r["smoke_count"]}')
        lines.append(f'smoke_color = {r["smoke_color"]}')
        lines.append(f'smoke_buoyancy = {r["smoke_buoyancy"]}')
        lines.append(f'screen_shake_intensity = {r["screen_shake_intensity"]}')
        lines.append(f'screen_shake_duration = {r["screen_shake_duration"]}')
        lines.append(f'sfx_name = "{r["sfx_name"]}"')
        lines.append(f'explosion_frames = Array[Texture2D]([{", ".join(frame_ids)}])')
        lines.append(f'frame_size = {r["frame_size"]}')
        lines.append('')
        
        content = '\n'.join(lines)
        file_path = os.path.join(out_dir, r["filename"])
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Generated {file_path}")

if __name__ == "__main__":
    generate_explosion_resources()
