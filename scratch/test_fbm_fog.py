import numpy as np
from PIL import Image
import math

# Generate multi-octave fractal noise simulation of the canyon fog
width = 240
height = 420

def generate_noise_grid(w, h, scale):
    np.random.seed(42)
    # Generate smooth bicubic/bilinear noise
    grid_w = max(2, int(w / scale))
    grid_h = max(2, int(h / scale))
    rand_grid = np.random.rand(grid_h, grid_w)
    im = Image.fromarray((rand_grid * 255).astype(np.uint8)).resize((w, h), Image.Resampling.BICUBIC)
    return np.array(im, dtype=np.float32) / 255.0

# Generate 3 octaves
oct1 = generate_noise_grid(width, height, 60.0)
oct2 = generate_noise_grid(width, height, 30.0)
oct3 = generate_noise_grid(width, height, 15.0)

fbm = oct1 * 0.52 + oct2 * 0.33 + oct3 * 0.15

# Vertical gradient envelope: dense at bottom (y=height-1), rising up and feathering out at top (y=0)
out_img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
out_data = np.zeros((height, width, 4), dtype=np.uint8)

for y in range(height):
    v_norm = y / float(height) # 0 at top, 1 at bottom
    # Vertical envelope: dense at bottom, feather at top
    v_mask = math.pow(v_norm, 1.4) * math.sin(v_norm * 3.14159 * 0.85 + 0.15)
    v_mask = max(0.0, min(1.0, v_mask * 1.5))
    
    for x in range(width):
        h_norm = x / float(width) # 0 at left, 1 at right
        # Horizontal edge feather
        h_mask = math.sin(h_norm * 3.14159)
        h_mask = math.pow(h_mask, 0.6)
        
        n_val = fbm[y, x]
        density = (n_val * 1.4 - 0.2) * v_mask * h_mask
        density = max(0.0, min(1.0, density))
        
        # Color: deep mist (175, 205, 235) to bright plume crest (235, 245, 255)
        r = int(175 + density * 60)
        g = int(205 + density * 40)
        b = int(235 + density * 20)
        a = int(density * 180) # max alpha ~0.70
        
        out_data[y, x] = [r, g, b, a]

out_img = Image.fromarray(out_data, "RGBA")
out_img.save("scratch/test_fbm_fog_plume.png")
print("Saved FBM Fog Plume test to scratch/test_fbm_fog_plume.png")
