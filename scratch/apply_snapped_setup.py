import re

def parse_rects(text):
    pattern = r'Rect2\(\s*([\d\.]+)\s*,\s*([\d\.]+)\s*,\s*([\d\.]+)\s*,\s*([\d\.]+)\s*\)'
    return [(float(m[0]), float(m[1]), float(m[2]), float(m[3])) for m in re.findall(pattern, text)]

with open('scripts/level_maps.gd', 'r', encoding='utf-8') as f:
    maps_code = f.read()

stages = {}
stage_blocks = re.split(r'\n\s*(\d):\s*\n', maps_code)
for i in range(1, len(stage_blocks), 2):
    s_num = int(stage_blocks[i])
    s_text = stage_blocks[i+1]
    g_match = re.search(r'data\["ground_segments"\]\s*=\s*\[(.*?)\]', s_text, re.DOTALL)
    p_match = re.search(r'data\["platforms"\]\s*=\s*\[(.*?)\]', s_text, re.DOTALL)
    grounds = parse_rects(g_match.group(1)) if g_match else []
    plats = parse_rects(p_match.group(1)) if p_match else []
    stages[s_num] = {'ground': grounds, 'platforms': plats}

def snap_coord(stage_num, x, y, y_offset):
    grounds = stages[stage_num]['ground']
    plats = stages[stage_num]['platforms']
    
    surfaces = []
    for gx, gy, gw, gh in grounds:
        if (gx + 12.0) <= x <= (gx + gw - 12.0):
            surfaces.append(('ground', gy, x))
    for px, py, pw, ph in plats:
        if (px + 8.0) <= x <= (px + pw - 8.0):
            surfaces.append(('platform', py, x))
            
    if surfaces:
        best = min(surfaces, key=lambda s: abs(y - s[1]))
        return (best[2], best[1] - y_offset)
        
    search_radius = 85.0
    nearby = []
    for gx, gy, gw, gh in grounds:
        clamped_x = max(gx + 20.0, min(gx + gw - 20.0, x))
        dist = abs(clamped_x - x)
        if dist <= search_radius:
            nearby.append(('ground', gy, clamped_x, dist))
    for px, py, pw, ph in plats:
        clamped_x = max(px + 15.0, min(px + pw - 15.0, x))
        dist = abs(clamped_x - x)
        if dist <= search_radius:
            nearby.append(('platform', py, clamped_x, dist))
            
    if nearby:
        best = min(nearby, key=lambda n: n[3]*0.4 + abs(y - n[1]))
        return (best[2], best[1] - y_offset)
    return None

with open('scripts/stage1.gd', 'r', encoding='utf-8') as f:
    stage1_code = f.read()

setup_match = re.search(r'func _setup_static_enemies\(\) -> void:(.*?)\nfunc _is_over_ground_or_platform', stage1_code, re.DOTALL)
if not setup_match:
    print('ERROR: could not find _setup_static_enemies block')
    exit(1)

setup_code = setup_match.group(1)

def process_stage_block(s_num, s_text):
    def replace_call(m):
        func_name = m.group(1)
        args_text = m.group(2)
        
        offset = 5.0
        if 'turret' in func_name: offset = 5.0
        elif 'sniper' in func_name: offset = 6.0
        elif 'grenadier' in func_name: offset = 8.0
        elif 'crawler' in func_name: offset = 6.0
        elif 'sensor' in func_name: offset = 12.0
        elif 'spore' in func_name: offset = 2.0
        elif 'eye' in func_name: offset = 14.0
        
        # Check if sensor dict
        if 'sensor' in func_name:
            def replace_sensor_dict(sdm):
                full_dict = sdm.group(0)
                vx = float(sdm.group(1))
                vy = float(sdm.group(2))
                wtype = sdm.group(3)
                res = snap_coord(s_num, vx, vy, offset)
                if res:
                    return f'{{"pos": Vector2({res[0]:.1f}, {res[1]:.1f}), "weapon": {wtype}}}'
                return ''
            new_args = re.sub(r'\{\s*"pos":\s*Vector2\(\s*([\d\.]+)\s*,\s*([\d\.]+)\s*\)\s*,\s*"weapon":\s*([\w\.]+)\s*\}', replace_sensor_dict, args_text)
            # Remove any empty commas
            new_args = re.sub(r',\s*,', ',', new_args)
            new_args = re.sub(r'\[\s*,', '[', new_args)
            new_args = re.sub(r',\s*\]', ']', new_args)
            return f'{func_name}([{new_args}])'

        # Regular Vector2 lists
        vec_matches = re.finditer(r'Vector2\(\s*([\d\.]+)\s*,\s*([\d\.]+)\s*\)', args_text)
        new_vecs = []
        for vm in vec_matches:
            x, y = float(vm.group(1)), float(vm.group(2))
            res = snap_coord(s_num, x, y, offset)
            if res:
                new_vecs.append(f'Vector2({res[0]:.1f}, {res[1]:.1f})')
            else:
                print(f'  Stage {s_num}: dropped unplaceable {func_name} at ({x}, {y})')
        return f'{func_name}([{", ".join(new_vecs)}])'
        
    return re.sub(r'(_spawn_\w+)\(\s*\[(.*?)\]\s*\)', replace_call, s_text, flags=re.DOTALL)

s_blocks = re.split(r'\n\s*(\d):\s*#', setup_code)
new_setup_parts = [s_blocks[0]]
for i in range(1, len(s_blocks), 2):
    s_num = int(s_blocks[i])
    s_text = s_blocks[i+1]
    proc_text = process_stage_block(s_num, s_text)
    new_setup_parts.append(f'\t\t{s_num}: #' + proc_text)

new_setup_code = '\n'.join(new_setup_parts)

# Now assemble full replacement for _setup_static_enemies through _spawn_bio_eyes
new_implementation = f"""func _setup_static_enemies() -> void:{new_setup_code}

func _find_valid_surface_at(pos: Vector2, y_offset: float = 0.0) -> Vector2:
	var best_surf_y: float = -99999.0
	var best_surf_x: float = pos.x
	var min_gap: float = 99999.0
	var found_direct: bool = false
	
	# 1. Check if pos.x directly overlaps a platform or ground segment
	for p in platforms:
		var pr: Rect2 = p.get("rect", Rect2())
		if pos.x >= pr.position.x + 8.0 and pos.x <= pr.end.x - 8.0:
			var gap: float = absf(pr.position.y - pos.y)
			if not found_direct or gap < min_gap:
				found_direct = true
				min_gap = gap
				best_surf_y = pr.position.y
				best_surf_x = pos.x
				
	for g in ground_segments:
		if pos.x >= g.position.x + 12.0 and pos.x <= g.end.x - 12.0:
			var gap: float = absf(g.position.y - pos.y)
			if not found_direct or gap < min_gap:
				found_direct = true
				min_gap = gap
				best_surf_y = g.position.y
				best_surf_x = pos.x
				
	if found_direct:
		return Vector2(best_surf_x, best_surf_y - y_offset)
		
	# 2. If pos.x is near a chasm or edge gap, search within 85px for a solid surface
	var search_radius := 85.0
	var best_score := 99999.0
	
	for p in platforms:
		var pr: Rect2 = p.get("rect", Rect2())
		var clamped_x := clampf(pos.x, pr.position.x + 12.0, pr.end.x - 12.0)
		var x_dist := absf(clamped_x - pos.x)
		if x_dist <= search_radius:
			var score := x_dist * 0.4 + absf(pr.position.y - pos.y)
			if score < best_score:
				best_score = score
				best_surf_y = pr.position.y
				best_surf_x = clamped_x
				
	for g in ground_segments:
		var clamped_x := clampf(pos.x, g.position.x + 16.0, g.end.x - 16.0)
		var x_dist := absf(clamped_x - pos.x)
		if x_dist <= search_radius:
			var score := x_dist * 0.4 + absf(g.position.y - pos.y)
			if score < best_score:
				best_score = score
				best_surf_y = g.position.y
				best_surf_x = clamped_x
				
	if best_surf_y > -90000.0:
		return Vector2(best_surf_x, best_surf_y - y_offset)
		
	# Over empty abyss or chasm with no valid platform/ground
	return Vector2.ZERO

func _is_over_ground_or_platform(pos_x: float) -> bool:
	for g in ground_segments:
		if pos_x >= g.position.x - 10.0 and pos_x <= g.end.x + 10.0:
			return true
	for p in platforms:
		var pr: Rect2 = p.get("rect", Rect2())
		if pos_x >= pr.position.x - 8.0 and pos_x <= pr.end.x + 8.0:
			return true
	return false

func _spawn_turrets(positions: Array[Vector2]) -> void:
	if turret_scene == null: return
	for pos in positions:
		var valid_pos := _find_valid_surface_at(pos, 5.0)
		if valid_pos != Vector2.ZERO and valid_pos.x < BOSS_TRIGGER_X - 100.0:
			var t = turret_scene.instantiate()
			t.global_position = valid_pos
			add_child(t)

func _get_ground_or_platform_y(pos_x: float, default_y: float) -> float:
	var valid := _find_valid_surface_at(Vector2(pos_x, default_y), 6.0)
	return valid.y if valid != Vector2.ZERO else default_y

func _spawn_snipers(positions: Array[Vector2]) -> void:
	if sniper_scene == null: return
	for pos in positions:
		var valid_pos := _find_valid_surface_at(pos, 6.0)
		if valid_pos != Vector2.ZERO and valid_pos.x < BOSS_TRIGGER_X - 100.0:
			var s = sniper_scene.instantiate()
			s.global_position = valid_pos
			add_child(s)

func _spawn_grenadiers(positions: Array[Vector2]) -> void:
	if grenadier_scene == null: return
	for pos in positions:
		var valid_pos := _find_valid_surface_at(pos, 8.0)
		if valid_pos != Vector2.ZERO and valid_pos.x < BOSS_TRIGGER_X - 120.0:
			var gr = grenadier_scene.instantiate()
			gr.global_position = valid_pos
			add_child(gr)

func _spawn_crawlers(positions: Array[Vector2]) -> void:
	if crawler_scene == null: return
	for pos in positions:
		var valid_pos := _find_valid_surface_at(pos, 6.0)
		if valid_pos != Vector2.ZERO and valid_pos.x < BOSS_TRIGGER_X - 150.0:
			var cr = crawler_scene.instantiate()
			cr.global_position = valid_pos
			add_child(cr)

func _spawn_sensors(sensor_pods: Array[Dictionary]) -> void:
	if sensor_scene == null: return
	for pod_info in sensor_pods:
		var pos: Vector2 = pod_info["pos"]
		var valid_pos := _find_valid_surface_at(pos, 12.0)
		if valid_pos != Vector2.ZERO and valid_pos.x < BOSS_TRIGGER_X - 150.0:
			var pod = sensor_scene.instantiate()
			pod.global_position = valid_pos
			pod.weapon_type = pod_info["weapon"]
			add_child(pod)

func _spawn_spore_pods(positions: Array[Vector2]) -> void:
	if spore_pod_script == null: return
	for pos in positions:
		var valid_pos := _find_valid_surface_at(pos, 2.0)
		if valid_pos != Vector2.ZERO and valid_pos.x < BOSS_TRIGGER_X - 120.0:
			var pod = spore_pod_script.new()
			pod.global_position = valid_pos
			add_child(pod)

func _spawn_bio_eyes(positions: Array[Vector2]) -> void:
	if bio_eye_script == null: return
	for pos in positions:
		var valid_pos := _find_valid_surface_at(pos, 14.0)
		if valid_pos != Vector2.ZERO and valid_pos.x < BOSS_TRIGGER_X - 120.0:
			var eye = bio_eye_script.new()
			eye.global_position = valid_pos
			add_child(eye)"""

# Also update _spawn_soldier_wave()
old_soldier_wave_match = re.search(r'func _spawn_soldier_wave\(\) -> void:.*?\nfunc _spawn_drone_wave', stage1_code, re.DOTALL)
if not old_soldier_wave_match:
    print('ERROR: could not find _spawn_soldier_wave')
    exit(1)

new_soldier_wave = """func _spawn_soldier_wave() -> void:
	if soldier_scene == null or camera == null or player == null or not is_instance_valid(player):
		return
	
	var player_x := player.global_position.x
	
	# Cap maximum simultaneous active foot soldiers to 4
	var active_soldiers: int = 0
	for node in get_tree().get_nodes_in_group("foot_soldiers"):
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			active_soldiers += 1
	if active_soldiers >= 4:
		soldier_spawn_timer = 1.0
		return
	
	var cam_x := camera.global_position.x
	
	# Find all valid ground segments within or near camera view
	var valid_ground_segs: Array[Rect2] = []
	for g in ground_segments:
		if g.end.x >= cam_x - 520.0 and g.position.x <= cam_x + 520.0:
			if g.size.x >= 140.0:
				valid_ground_segs.append(g)
	
	# If player is over a pure bottomless abyss or high platform route with no ground below, do not spawn foot soldiers in air!
	if valid_ground_segs.is_empty():
		soldier_spawn_timer = 1.5
		return
	
	# Determine spawn direction: 85% spawn ahead running left, 15% spawn behind running right
	var spawn_from_right: bool = randf() > 0.15
	var target_seg: Rect2 = Rect2()
	var initial_facing: int = -1
	
	if spawn_from_right:
		for g in valid_ground_segs:
			if g.end.x > player_x + 80.0:
				target_seg = g
				break
		if target_seg.size.x == 0.0:
			target_seg = valid_ground_segs.back()
		initial_facing = -1
	else:
		for g in valid_ground_segs:
			if g.position.x < player_x - 80.0:
				target_seg = g
				break
		if target_seg.size.x == 0.0:
			target_seg = valid_ground_segs.front()
		initial_facing = 1
		
	if target_seg.size.x == 0.0:
		soldier_spawn_timer = 1.5
		return
	
	# Clamp spawn_x securely inside the target ground segment (away from pit edges)
	var spawn_x: float
	if initial_facing == -1: # Spawning on right, running left
		var ideal_x := cam_x + 460.0
		spawn_x = clampf(ideal_x, target_seg.position.x + 35.0, target_seg.end.x - 30.0)
	else: # Spawning on left, running right
		var ideal_x := cam_x - 460.0
		spawn_x = clampf(ideal_x, target_seg.position.x + 30.0, target_seg.end.x - 35.0)
	
	var spawn_y: float = target_seg.position.y - 18.0
	
	var s: Node2D
	if Global.current_stage == 3 and crawler_scene != null:
		s = crawler_scene.instantiate()
		s.facing_dir = initial_facing
		s.global_position = Vector2(spawn_x, spawn_y)
		s.add_to_group("foot_soldiers")
	elif Global.current_stage == 8 and crawler_scene != null and randf() < 0.65:
		s = crawler_scene.instantiate()
		s.facing_dir = initial_facing
		s.global_position = Vector2(spawn_x, spawn_y)
		s.add_to_group("foot_soldiers")
	else:
		s = soldier_scene.instantiate()
		s.facing_dir = initial_facing
		s.global_position = Vector2(spawn_x, spawn_y)
	add_child(s)"""

# Apply both replacements
old_block_match = re.search(r'func _setup_static_enemies\(\) -> void:.*?\nfunc _setup_animated_bg_props', stage1_code, re.DOTALL)
if not old_block_match:
    print('ERROR: could not find old static enemies to bg props block')
    exit(1)

stage1_code = stage1_code[:old_block_match.start()] + new_implementation + "\n\nfunc _setup_animated_bg_props" + stage1_code[old_block_match.end():]

old_soldier_wave_match = re.search(r'func _spawn_soldier_wave\(\) -> void:.*?\nfunc _spawn_drone_wave', stage1_code, re.DOTALL)
stage1_code = stage1_code[:old_soldier_wave_match.start()] + new_soldier_wave + "\n\nfunc _spawn_drone_wave" + stage1_code[old_soldier_wave_match.end():]

with open('scripts/stage1.gd', 'w', encoding='utf-8') as f:
    f.write(stage1_code)

print('Successfully updated scripts/stage1.gd with resilient surface snapping and fixed enemy positions!')
