import re
from collections import Counter

with open('scripts/level_maps.gd', 'r') as f:
    text = f.read()

# Match each stage block
blocks = re.findall(r'(\d+):\s*\n\s*data\["name"\]\s*=\s*"([^"]+)"(.*?)(?=\n\t\t\d+:|\n\tstatic func|\Z)', text, re.DOTALL)
for s_num, s_name, s_body in blocks:
    types = re.findall(r'"type":\s*PlatformType\.([A-Z_]+)', s_body)
    variants = re.findall(r'"variant":\s*"([^"]+)"', s_body)
    print(f"Stage {s_num}: {s_name}")
    print(f"  Types: {dict(Counter(types))}")
    print(f"  Variants: {dict(Counter(variants))}")
