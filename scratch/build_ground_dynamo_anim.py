import numpy as np
from PIL import Image, ImageDraw
import os

def generate_dynamo_frames(base_img_path, is_edge_left=False, is_edge_right=False):
    base_img = Image.open(base_img_path).convert('RGBA')
    w, h = base_img.size
    base_arr = np.array(base_img, dtype=np.float32)

    frames = []

    r, g, b, a = base_arr[:, :, 0], base_arr[:, :, 1], base_arr[:, :, 2], base_arr[:, :, 3]
    solid_mask = a > 180

    y_coords = np.arange(h)[:, None]
    x_coords = np.arange(w)[None, :]
    
    # Calculate global X coordinates for seamless edge tiling
    if is_edge_left:
        x_global = x_coords
    elif is_edge_right:
        x_global = (x_coords + 1024 - 470) % 1024
    else:
        x_global = x_coords

    # Regions:
    beam_y_mask = (y_coords >= 74) & (y_coords <= 98) & solid_mask
    beam_core_mask = (y_coords >= 83) & (y_coords <= 87) & solid_mask
    outer_beam_mask = beam_y_mask & (~beam_core_mask)

    # Cyan circuit lines (outside beam)
    cyan_circuit_mask = (b > 160) & (g > 130) & (r < 160) & solid_mask & (~beam_y_mask)
    
    # Secondary conduit bus line around Y: 140 to 180
    sub_bus_mask = (y_coords >= 140) & (y_coords <= 180) & cyan_circuit_mask

    # Green CRT displays
    green_display_mask = (g > 140) & (r < 100) & (b < 190) & (y_coords > 200) & solid_mask

    # Copper coils
    copper_mask = (r > 150) & (g > 70) & (g < 170) & (b < 90) & (y_coords > 200) & solid_mask

    # Central reactor cyan rungs
    reactor_rung_mask = (b > 180) & (g > 150) & (r < 100) & (y_coords > 450) & solid_mask

    for f in range(4):
        frame_arr = base_arr.copy()
        phase = (float(f) / 4.0) * 2.0 * np.pi

        # --- A. Main high-voltage beam traveling energy surge ---
        wavelength = 256.0
        wave = np.sin(2.0 * np.pi * x_global / wavelength - phase)
        wave_fast = np.sin(4.0 * np.pi * x_global / wavelength - phase * 2.0)
        surge = 0.5 * (wave + 0.3 * wave_fast) # range approx -0.65 to +0.65

        global_boost = 0.0
        if f == 0:
            global_boost = 0.0
        elif f == 1:
            global_boost = 0.18
        elif f == 2:
            global_boost = 0.45 # Overload peak!
        elif f == 3:
            global_boost = 0.10

        # Modulate beam core
        core_intensity = np.clip(1.0 + surge * 0.35 + global_boost, 0.75, 1.6)
        for c in range(3):
            val = frame_arr[:, :, c]
            frame_arr[:, :, c] = np.where(beam_core_mask, np.clip(val * core_intensity, 0, 255), val)

        # Beam outer glow modulation: expand white/cyan
        glow_boost = np.clip(1.0 + surge * 0.4 + global_boost * 1.25, 0.75, 1.85)
        r_beam = frame_arr[:, :, 0]
        g_beam = frame_arr[:, :, 1]
        b_beam = frame_arr[:, :, 2]
        
        whiten = np.clip(surge + global_boost, 0.0, 1.0)
        frame_arr[:, :, 0] = np.where(outer_beam_mask, np.clip(r_beam * glow_boost + whiten * 85.0, 0, 255), r_beam)
        frame_arr[:, :, 1] = np.where(outer_beam_mask, np.clip(g_beam * glow_boost + whiten * 55.0, 0, 255), g_beam)
        frame_arr[:, :, 2] = np.where(outer_beam_mask, np.clip(b_beam * glow_boost + whiten * 45.0, 0, 255), b_beam)

        # --- B. Circuit traces animation ---
        circuit_pulse = np.sin(x_global / 40.0 - phase * 1.5 + y_coords / 25.0)
        c_boost = np.clip(0.85 + 0.35 * circuit_pulse + global_boost * 0.55, 0.6, 1.65)
        for c in range(3):
            frame_arr[:, :, c] = np.where(cyan_circuit_mask, np.clip(frame_arr[:, :, c] * c_boost, 0, 255), frame_arr[:, :, c])

        # Secondary bus line flash in frame 3 (dissipation)
        if f == 3:
            frame_arr[:, :, 0] = np.where(sub_bus_mask, np.clip(frame_arr[:, :, 0] * 1.35 + 20, 0, 255), frame_arr[:, :, 0])
            frame_arr[:, :, 1] = np.where(sub_bus_mask, np.clip(frame_arr[:, :, 1] * 1.35 + 40, 0, 255), frame_arr[:, :, 1])
            frame_arr[:, :, 2] = np.where(sub_bus_mask, np.clip(frame_arr[:, :, 2] * 1.35 + 50, 0, 255), frame_arr[:, :, 2])

        # --- C. Green CRT Terminal displays ---
        scanline_y = (phase / (2.0 * np.pi) * 80.0) % 50.0
        scan_dist = np.abs(np.fmod(y_coords, 50.0) - scanline_y)
        scan_pulse = np.exp(-scan_dist / 3.0) * 0.45

        glitch = 0.30 if f == 2 else 0.0
        disp_boost = 0.9 + scan_pulse + glitch
        frame_arr[:, :, 1] = np.where(green_display_mask, np.clip(frame_arr[:, :, 1] * disp_boost + glitch * 35.0, 0, 255), frame_arr[:, :, 1])
        frame_arr[:, :, 2] = np.where(green_display_mask, np.clip(frame_arr[:, :, 2] * disp_boost, 0, 255), frame_arr[:, :, 2])

        # --- D. Reactor rungs (vertical energy climb) ---
        rung_phase = np.sin((y_coords - 460.0) * 0.25 - phase * 2.0)
        rung_boost = np.clip(0.8 + 0.55 * rung_phase + global_boost * 0.65, 0.5, 1.85)
        for c in range(3):
            frame_arr[:, :, c] = np.where(reactor_rung_mask, np.clip(frame_arr[:, :, c] * rung_boost, 0, 255), frame_arr[:, :, c])

        # --- E. Copper coil thermal surge ---
        coil_pulse = 0.9 + 0.25 * np.sin(phase) + (0.35 if f == 2 else 0.0)
        frame_arr[:, :, 0] = np.where(copper_mask, np.clip(frame_arr[:, :, 0] * coil_pulse, 0, 255), frame_arr[:, :, 0])
        frame_arr[:, :, 1] = np.where(copper_mask, np.clip(frame_arr[:, :, 1] * (coil_pulse * 0.95), 0, 255), frame_arr[:, :, 1])

        # Preserve exact alpha
        frame_arr[:, :, 3] = base_arr[:, :, 3]

        img_out = Image.fromarray(np.clip(frame_arr, 0, 255).astype(np.uint8), mode='RGBA')
        draw = ImageDraw.Draw(img_out)

        # --- F. High-voltage lightning micro-arcs in Frame 2 (peak overload) ---
        if f == 2:
            np.random.seed(42)
            num_arcs = 14 if w > 500 else 7
            for _ in range(num_arcs):
                start_x = np.random.randint(20, w - 20)
                if base_arr[84, start_x, 3] > 200:
                    start_y = 84 + np.random.randint(-1, 2)
                    arc_len = np.random.randint(7, 18)
                    cur_x, cur_y = float(start_x), float(start_y)
                    direction = -1 if np.random.rand() > 0.5 else 1
                    for _ in range(arc_len):
                        next_x = cur_x + np.random.randint(-2, 3)
                        next_y = cur_y + direction * np.random.randint(1, 3)
                        if 72 <= next_y <= 104 and 0 <= next_x < w and base_arr[int(next_y), int(next_x), 3] > 200:
                            draw.line([(cur_x, cur_y), (next_x, next_y)], fill=(220, 255, 255, 240), width=1)
                            if np.random.rand() > 0.6:
                                draw.point((next_x, next_y), fill=(255, 255, 255, 255))
                            cur_x, cur_y = next_x, next_y

            # Micro-arcs on copper coil
            if not is_edge_left and not is_edge_right:
                for _ in range(3):
                    sx = np.random.randint(625, 650)
                    sy = np.random.randint(395, 435)
                    ex = sx + np.random.randint(-5, 6)
                    ey = sy + np.random.randint(-4, 5)
                    draw.line([(sx, sy), (ex, ey)], fill=(190, 240, 255, 235), width=1)

        frames.append(img_out)

    return frames

def build_all_assets():
    targets = [
        ('assets/tiles/ground_dynamo.png', 'ground_dynamo', False, False),
        ('assets/tiles/ground_dynamo_edge_left.png', 'ground_dynamo_edge_left', True, False),
        ('assets/tiles/ground_dynamo_edge_right.png', 'ground_dynamo_edge_right', False, True),
    ]

    for src_path, prefix, is_left, is_right in targets:
        print(f"Processing {src_path}...")
        frames = generate_dynamo_frames(src_path, is_left, is_right)
        w, h = frames[0].size

        # Save individual frames
        for i, frame in enumerate(frames):
            out_name = f"assets/tiles/{prefix}_{i}.png"
            frame.save(out_name)
            print(f"  Saved {out_name} ({w}x{h})")

        # Save horizontal strip
        strip = Image.new('RGBA', (w * 4, h))
        for i, frame in enumerate(frames):
            strip.paste(frame, (i * w, 0))
        strip_path = f"assets/tiles/{prefix}_strip.png"
        strip.save(strip_path)
        print(f"  Saved {strip_path} ({w*4}x{h})")

        # Update base image to frame 0
        frames[0].save(src_path)
        print(f"  Updated base {src_path}")

if __name__ == '__main__':
    build_all_assets()
    print("All ground dynamo assets generated successfully!")
