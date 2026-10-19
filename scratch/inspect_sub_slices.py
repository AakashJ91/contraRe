from PIL import Image

def inspect_texture(name):
    im = Image.open(f'assets/tiles/ground_{name}.png')
    w, h = im.size
    print(f"\n=== {name.upper()} (w={w}, h={h}) ===")
    
    # Let's inspect rows down the image to find where surface details end
    # Surface details usually have distinct colors (grass green, hazard yellow, ice white/cyan, etc.)
    # Let's look at average RGB for rows
    for y_pct in range(10, 90, 5):
        y = int(h * (y_pct / 100.0))
        # sample middle horizontal strip
        colors = [im.getpixel((x, y)) for x in range(0, w, 16)]
        avg_r = sum(c[0] for c in colors) / len(colors)
        avg_g = sum(c[1] for c in colors) / len(colors)
        avg_b = sum(c[2] for c in colors) / len(colors)
        print(f"  {y_pct}% (y={y}): RGB=({avg_r:.1f}, {avg_g:.1f}, {avg_b:.1f})")

for name in ['waterfall', 'hive', 'tundra', 'refinery']:
    inspect_texture(name)
