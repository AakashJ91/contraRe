for path in ['scripts/level_maps.gd', 'scratch/build_situational_level_maps.py']:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    new_content = content.replace('PlatformType.HIGH_PERCH"', 'PlatformType.HIGH_PERCH')
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f'Updated {path}')
