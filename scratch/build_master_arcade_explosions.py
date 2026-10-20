import math
import random
from PIL import Image

# Implementation of 2D Perlin / Value Noise with cubic Hermite interpolation
class ValueNoise2D:
    def __init__(self, seed=42):
        random.seed(seed)
        self.p = list(range(256))
        random.shuffle(self.p)
        self.p += self.p

    def _fade(self, t):
        return t * t * t * (t * (t * 6 - 15) + 10)

    def _lerp(self, a, b, t):
        return a + t * (b - a)

    def eval(self, x, y):
        xi = int(math.floor(x)) & 255
        yi = int(math.floor(y)) & 255
        xf = x - math.floor(x)
        yf = y - math.floor(y)

        u = self._fade(xf)
        v = self._fade(yf)

        aa = self.p[self.p[xi] + yi]
        ab = self.p[self.p[xi] + yi + 1]
        ba = self.p[self.p[xi + 1] + yi]
        bb = self.p[self.p[xi + 1] + yi + 1]

        v1 = self._lerp(aa / 255.0, ba / 255.0, u)
        v2 = self._lerp(ab / 255.0, bb / 255.0, u)
        return self._lerp(v1, v2, v)

    def fbm(self, x, y, octaves=4, lacunarity=2.0, gain=0.5):
        total = 0.0
        frequency = 1.0
        amplitude = 1.0
        max_val = 0.0
        for _ in range(octaves):
            total += self.eval(x * frequency, y * frequency) * amplitude
            max_val += amplitude
            frequency *= lacunarity
            amplitude *= gain
        return total / max_val

def render_master_explosion():
    w, h = 96, 96
    cx, cy = 48.0, 48.0
    noise = ValueNoise2D(seed=777)
    
    # Authentic 16-bit arcade color palettes
    PALETTES = {
        "fiery": {
            "outline": (16, 10, 20, 255),
            "smoke_dark": (35, 28, 40, 255),
            "smoke_mid": (65, 55, 75, 255),
            "smoke_light": (105, 95, 118, 255),
            "crust": (140, 20, 15, 255),
            "red": (210, 45, 18, 255),
            "orange": (255, 120, 20, 255),
            "yellow": (255, 215, 60, 255),
            "white": (255, 255, 240, 255),
            "sparks": (255, 230, 100, 255)
        }
    }
    
    pal = PALETTES["fiery"]
    frames = []
    
    for f in range(8):
        t = f / 7.0
        grid = [[0 for _ in range(w)] for _ in range(h)]
        random.seed(300 + f * 41)
        
        # Center of explosion rises as smoke billows
        y_center = cy - (t * 12.0 if t > 0.3 else 0.0)
        
        # Radius expands then stabilizes
        if t < 0.2:
            base_r = 14.0 + t * 75.0
        elif t < 0.5:
            base_r = 24.0 + (t - 0.2) * 35.0
        else:
            base_r = 34.0 + (t - 0.5) * 6.0
            
        # Generate flying fiery debris / sparks
        sparks = []
        num_sparks = int(6 + t * 14) if t < 0.6 else int(20 * (1.0 - t))
        for _ in range(num_sparks):
            ang = random.uniform(0, math.tau)
            spd = base_r * random.uniform(1.08, 1.48)
            sparks.append((int(cx + math.cos(ang) * spd), int(y_center + math.sin(ang) * spd)))
            
        for y in range(h):
            for x in range(w):
                dx = x - cx
                dy = y - y_center
                dist = math.hypot(dx, dy)
                ang = math.atan2(dy, dx)
                
                # Fractal noise displacement for organic flame perimeter
                # Angle-based turbulence + 2D spatial noise
                n_sample = noise.fbm((x + f * 12.0) * 0.05, (y - f * 8.0) * 0.05, octaves=3)
                
                # Sharp jagged flame spikes
                spike = math.sin(ang * 5.0 + f * 1.5) * 4.5 + math.sin(ang * 9.0) * 2.5
                effective_r = base_r + (n_sample - 0.5) * 18.0 + spike * (1.0 - t * 0.4)
                
                if dist <= effective_r:
                    # Inside the explosion cloud
                    depth = (effective_r - dist) / effective_r # 0.0 at edge, 1.0 at core
                    
                    # Internal structure noise (creates turbulent crevices and smoke bubbles)
                    int_noise = noise.fbm(x * 0.08, y * 0.08 + f * 0.3, octaves=3)
                    depth_mod = depth * 0.7 + int_noise * 0.45
                    
                    if t < 0.40:
                        # Full blazing explosion
                        if depth_mod > 0.75:
                            val = 8 # White core
                        elif depth_mod > 0.55:
                            val = 7 # Yellow
                        elif depth_mod > 0.38:
                            val = 6 # Orange
                        elif depth_mod > 0.22:
                            val = 5 # Red
                        elif depth_mod > 0.08:
                            val = 4 # Crust red
                        else:
                            val = 1 # Outline
                    elif t < 0.70:
                        # Breaking into smoke with incandescent lava seams
                        is_fire_pocket = (int_noise > 0.48) and (depth > 0.25)
                        if is_fire_pocket:
                            val = 7 if depth_mod > 0.65 else 6
                        else:
                            if depth_mod > 0.55:
                                val = 3 # Smoke light
                            elif depth_mod > 0.30:
                                val = 2 # Smoke mid
                            else:
                                val = 1 # Smoke dark / outline
                    else:
                        # Dissipating cooling smoke
                        if (x + y * 5) % 23 == 0 and depth > 0.3:
                            val = 6 # Tiny dying red spark
                        elif depth_mod > 0.50:
                            val = 3 # Smoke light
                        elif depth_mod > 0.25:
                            val = 2 # Smoke mid
                        else:
                            val = 1 # Smoke dark
                            
                    grid[y][x] = val
                    
        # Burn in sparks
        for sx, sy in sparks:
            if 1 <= sx < w - 1 and 1 <= sy < h - 1:
                grid[sy][sx] = 7 if t < 0.4 else 6
                grid[sy][sx + 1] = 6 if t < 0.4 else 5
                
        # Perimeter outline
        final_grid = [[grid[y][x] for x in range(w)] for y in range(h)]
        for y in range(1, h - 1):
            for x in range(1, w - 1):
                if grid[y][x] == 0:
                    for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                        if grid[y + dy][x + dx] > 1:
                            final_grid[y][x] = 0.5 # Outline
                            break
                            
        # Map to colors
        im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        c_map = {
            0.5: pal["outline"],
            1: pal["outline"],
            2: pal["smoke_dark"],
            3: pal["smoke_mid"],
            4: pal["crust"],
            5: pal["red"],
            6: pal["orange"],
            7: pal["yellow"],
            8: pal["white"]
        }
        
        for y in range(h):
            for x in range(w):
                v = final_grid[y][x]
                if v in c_map:
                    im.putpixel((x, y), c_map[v])
                    
        frames.append(im)
        im.save(f"d:/GitHub/contraRe/scratch/master_fire_frame_{f}.png")
        
    # Spritesheet
    sheet = Image.new("RGBA", (w * 8, h), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        sheet.paste(frame, (i * w, 0))
    sheet.save("d:/GitHub/contraRe/scratch/master_fire_sheet.png")
    print("Rendered master explosion frames!")

if __name__ == "__main__":
    render_master_explosion()
