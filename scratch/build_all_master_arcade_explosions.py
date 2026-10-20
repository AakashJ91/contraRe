import os
import math
import random
from PIL import Image

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

def build_all_themes():
    base_dir = "d:/GitHub/contraRe/assets/vfx/explosions"
    os.makedirs(base_dir, exist_ok=True)
    noise = ValueNoise2D(seed=999)
    
    THEMES = {
        "fiery": {
            "w": 96, "h": 96, "num_frames": 8, "base_scale": 1.0, "style": "fire",
            "outline": (16, 10, 20, 255),
            "smoke_dark": (35, 28, 40),
            "smoke_mid": (65, 55, 75),
            "smoke_light": (105, 95, 118),
            "crust": (140, 20, 15, 255),
            "red": (210, 45, 18, 255),
            "orange": (255, 120, 20, 255),
            "yellow": (255, 215, 60, 255),
            "white": (255, 255, 240, 255),
            "spark": (255, 210, 60, 255)
        },
        "electric": {
            "w": 96, "h": 96, "num_frames": 8, "base_scale": 1.0, "style": "electric",
            "outline": (10, 16, 28, 255),
            "smoke_dark": (20, 32, 55),
            "smoke_mid": (35, 60, 100),
            "smoke_light": (70, 115, 175),
            "crust": (15, 65, 180, 255),
            "red": (20, 120, 245, 255),
            "orange": (40, 190, 255, 255),
            "yellow": (160, 235, 255, 255),
            "white": (245, 255, 255, 255),
            "spark": (140, 230, 255, 255)
        },
        "alien": {
            "w": 96, "h": 96, "num_frames": 8, "base_scale": 1.05, "style": "bio",
            "outline": (14, 22, 12, 255),
            "smoke_dark": (25, 42, 22),
            "smoke_mid": (45, 75, 40),
            "smoke_light": (80, 128, 70),
            "crust": (30, 110, 25, 255),
            "red": (60, 175, 30, 255),
            "orange": (120, 235, 40, 255),
            "yellow": (210, 255, 100, 255),
            "white": (255, 255, 220, 255),
            "spark": (180, 255, 80, 255)
        },
        "nuclear": {
            "w": 112, "h": 112, "num_frames": 8, "base_scale": 1.25, "style": "supernova",
            "outline": (20, 12, 24, 255),
            "smoke_dark": (45, 32, 42),
            "smoke_mid": (80, 60, 78),
            "smoke_light": (130, 105, 128),
            "crust": (180, 30, 15, 255),
            "red": (255, 75, 20, 255),
            "orange": (255, 160, 35, 255),
            "yellow": (255, 240, 120, 255),
            "white": (255, 255, 255, 255),
            "spark": (255, 240, 140, 255)
        },
        "cryo": {
            "w": 96, "h": 96, "num_frames": 8, "base_scale": 1.0, "style": "frost",
            "outline": (12, 20, 30, 255),
            "smoke_dark": (25, 45, 65),
            "smoke_mid": (50, 85, 120),
            "smoke_light": (100, 150, 195),
            "crust": (25, 95, 175, 255),
            "red": (45, 155, 235, 255),
            "orange": (90, 205, 255, 255),
            "yellow": (190, 240, 255, 255),
            "white": (250, 255, 255, 255),
            "spark": (180, 240, 255, 255)
        },
        "magma": {
            "w": 96, "h": 96, "num_frames": 8, "base_scale": 1.05, "style": "magma",
            "outline": (22, 10, 12, 255),
            "smoke_dark": (40, 26, 28),
            "smoke_mid": (72, 48, 52),
            "smoke_light": (115, 82, 88),
            "crust": (160, 20, 12, 255),
            "red": (225, 40, 15, 255),
            "orange": (255, 105, 20, 255),
            "yellow": (255, 200, 50, 255),
            "white": (255, 255, 210, 255),
            "spark": (255, 150, 30, 255)
        },
        "mini_burst": {
            "w": 64, "h": 64, "num_frames": 6, "base_scale": 0.65, "style": "mini",
            "outline": (18, 12, 20, 255),
            "smoke_dark": (35, 30, 42),
            "smoke_mid": (68, 58, 76),
            "smoke_light": (110, 100, 120),
            "crust": (150, 25, 18, 255),
            "red": (220, 55, 20, 255),
            "orange": (255, 135, 25, 255),
            "yellow": (255, 225, 75, 255),
            "white": (255, 255, 240, 255),
            "spark": (255, 220, 80, 255)
        }
    }
    
    for theme_name, cfg in THEMES.items():
        theme_dir = os.path.join(base_dir, theme_name)
        os.makedirs(theme_dir, exist_ok=True)
        w, h = cfg["w"], cfg["h"]
        num_frames = cfg["num_frames"]
        scale = cfg["base_scale"]
        style = cfg["style"]
        cx, cy = w / 2.0, h / 2.0
        frames = []
        
        for f in range(num_frames):
            t = f / float(num_frames - 1)
            grid = [[0 for _ in range(w)] for _ in range(h)]
            alpha_grid = [[255 for _ in range(w)] for _ in range(h)]
            random.seed(400 + f * 47 + len(theme_name) * 31)
            
            # Center rises as smoke billows upward
            y_center = cy - (t * 14.0 * scale if t > 0.3 else 0.0)
            
            # Dynamic expansion curve
            if t < 0.2:
                base_r = (12.0 + t * 70.0) * scale
            elif t < 0.5:
                base_r = (26.0 + (t - 0.2) * 36.0) * scale
            else:
                base_r = (36.0 + (t - 0.5) * 8.0) * scale
                
            # Dissipation alpha for smoke in late frames
            smoke_alpha = int(clamp(255 * (1.0 - (t - 0.55) / 0.45), 40, 255)) if t > 0.55 else 255
            
            # Flying sparks / lightning arcs
            sparks = []
            num_sparks = int((6 + t * 14) * scale) if t < 0.6 else int((20 * (1.0 - t)) * scale)
            for _ in range(num_sparks):
                ang = random.uniform(0, math.tau)
                spd = base_r * random.uniform(1.06, 1.45)
                sparks.append((int(cx + math.cos(ang) * spd), int(y_center + math.sin(ang) * spd)))
            
            # Electric lightning bolts for electric theme
            lightning_arcs = []
            if style == "electric" and t < 0.65:
                num_arcs = 5 if t < 0.35 else 3
                for _ in range(num_arcs):
                    ang = random.uniform(0, math.tau)
                    r1 = base_r * 0.4
                    r2 = base_r * random.uniform(1.15, 1.5)
                    pts = []
                    steps = 5
                    for st in range(steps + 1):
                        cur_r = r1 + (r2 - r1) * (st / float(steps))
                        cur_ang = ang + random.uniform(-0.18, 0.18)
                        pts.append((cx + math.cos(cur_ang) * cur_r, y_center + math.sin(cur_ang) * cur_r))
                    lightning_arcs.append(pts)
            
            # Fill grid
            for y in range(h):
                for x in range(w):
                    dx = x - cx
                    dy = y - y_center
                    dist = math.hypot(dx, dy)
                    ang = math.atan2(dy, dx)
                    
                    # 2D fractal noise
                    n_sample = noise.fbm((x + f * 9.0) * 0.05, (y - f * 6.0) * 0.05, octaves=3)
                    
                    # Flame/shockwave spike lobes
                    spike_freq = 7.0 if style in ["electric", "frost"] else 5.0
                    spike = math.sin(ang * spike_freq + f * 1.4) * (5.0 * scale) + math.sin(ang * (spike_freq * 1.8)) * (3.0 * scale)
                    effective_r = base_r + (n_sample - 0.5) * (18.0 * scale) + spike * (1.0 - t * 0.35)
                    
                    if dist <= effective_r:
                        depth = (effective_r - dist) / effective_r # 0.0 to 1.0
                        int_noise = noise.fbm(x * 0.08, y * 0.08 + f * 0.25, octaves=3)
                        depth_mod = depth * 0.65 + int_noise * 0.48
                        
                        if t < 0.42:
                            # Full explosive bloom
                            if depth_mod > 0.74:
                                val = 8 # White
                            elif depth_mod > 0.54:
                                val = 7 # Yellow
                            elif depth_mod > 0.36:
                                val = 6 # Orange
                            elif depth_mod > 0.20:
                                val = 5 # Red
                            elif depth_mod > 0.08:
                                val = 4 # Crust
                            else:
                                val = 1 # Outline
                        elif t < 0.72:
                            # Volcanic/plasma smoke with burning crevices
                            is_fire = (int_noise > 0.46) and (depth > 0.22)
                            if is_fire:
                                val = 7 if depth_mod > 0.62 else 6
                            else:
                                if depth_mod > 0.52:
                                    val = 3 # Smoke light
                                elif depth_mod > 0.28:
                                    val = 2 # Smoke mid
                                else:
                                    val = 1 # Smoke dark
                            alpha_grid[y][x] = smoke_alpha
                        else:
                            # Cooling dissipating smoke clouds
                            if depth_mod > 0.48:
                                val = 3
                            elif depth_mod > 0.24:
                                val = 2
                            else:
                                val = 1
                            alpha_grid[y][x] = smoke_alpha
                            
                        grid[y][x] = val
            
            # Draw lightning arcs for electric
            for arc in lightning_arcs:
                for idx in range(len(arc) - 1):
                    p1, p2 = arc[idx], arc[idx + 1]
                    # Draw pixel line
                    lx0, ly0 = int(p1[0]), int(p1[1])
                    lx1, ly1 = int(p2[0]), int(p2[1])
                    for px, py in bresenham(lx0, ly0, lx1, ly1):
                        if 1 <= px < w - 1 and 1 <= py < h - 1:
                            grid[py][px] = 8 # White-hot electric arc
                            grid[py][px + 1] = 7 # Cyan glow
            
            # Draw flying sparks
            for sx, sy in sparks:
                if 1 <= sx < w - 1 and 1 <= sy < h - 1:
                    grid[sy][sx] = 7 if t < 0.45 else 6
                    if sx + 1 < w - 1:
                        grid[sy][sx + 1] = 6 if t < 0.45 else 5
            
            # Compute dark contour outline
            final_grid = [[grid[y][x] for x in range(w)] for y in range(h)]
            for y in range(1, h - 1):
                for x in range(1, w - 1):
                    if grid[y][x] == 0:
                        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                            if grid[y + dy][x + dx] > 1:
                                final_grid[y][x] = 0.5 # Outline
                                break
                                
            # Render frame image
            im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
            for y in range(h):
                for x in range(w):
                    v = final_grid[y][x]
                    a = alpha_grid[y][x]
                    col = None
                    if v == 0.5 or v == 1:
                        col = (cfg["outline"][0], cfg["outline"][1], cfg["outline"][2], a)
                    elif v == 2:
                        sm = cfg["smoke_dark"]
                        col = (sm[0], sm[1], sm[2], a)
                    elif v == 3:
                        sm = cfg["smoke_mid"]
                        col = (sm[0], sm[1], sm[2], a)
                    elif v == 4:
                        col = cfg["crust"]
                    elif v == 5:
                        col = cfg["red"]
                    elif v == 6:
                        col = cfg["orange"]
                    elif v == 7:
                        col = cfg["yellow"]
                    elif v == 8:
                        col = cfg["white"]
                        
                    if col is not None:
                        im.putpixel((x, y), col)
                        
            frame_path = os.path.join(theme_dir, f"frame_{f}.png")
            im.save(frame_path)
            frames.append(im)
            
        # Spritesheet
        sheet_w = w * num_frames
        sheet = Image.new("RGBA", (sheet_w, h), (0, 0, 0, 0))
        for i, frame in enumerate(frames):
            sheet.paste(frame, (i * w, 0))
        sheet_path = os.path.join(theme_dir, "sheet.png")
        sheet.save(sheet_path)
        print(f"Generated master theme '{theme_name}': {num_frames} frames ({sheet_w}x{h})")

def clamp(val, min_v, max_v):
    return max(min_v, min(max_v, val))

def bresenham(x0, y0, x1, y1):
    points = []
    dx = abs(x1 - x0)
    dy = abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx - dy
    while True:
        points.append((x0, y0))
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * err
        if e2 > -dy:
            err -= dy
            x0 += sx
        if e2 < dx:
            err += dx
            y0 += sy
    return points

if __name__ == "__main__":
    build_all_themes()
