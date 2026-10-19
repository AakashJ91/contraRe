with open('scratch/build_situational_level_maps.py', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for idx, line in enumerate(lines):
    if 'PlatformType.HIGH_PERCH"' in line:
        print(f'{idx+1}: {repr(line)}')
