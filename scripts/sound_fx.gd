extends Node

# Procedural 8-bit sound FX generator for Godot 4
var sfx_players: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_sounds()

func _init_sounds() -> void:
	sfx_players["shoot_rifle"] = _create_player(_generate_rifle_sound())
	sfx_players["shoot_spread"] = _create_player(_generate_spread_sound())
	sfx_players["shoot_laser"] = _create_player(_generate_laser_sound())
	sfx_players["jump"] = _create_player(_generate_jump_sound())
	sfx_players["explosion"] = _create_player(_generate_explosion_sound())
	sfx_players["hit"] = _create_player(_generate_hit_sound())
	sfx_players["powerup"] = _create_player(_generate_powerup_sound())
	sfx_players["player_death"] = _create_player(_generate_death_sound())
	sfx_players["boss_alarm"] = _create_player(_generate_boss_alarm())
	sfx_players["menu_cursor"] = _create_player(_generate_cursor_sound())
	sfx_players["menu_start"] = _create_player(_generate_start_sound())

func _create_player(stream: AudioStreamWAV) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = "Master"
	add_child(p)
	return p

func play(sfx_name: String) -> void:
	if sfx_players.has(sfx_name):
		var p: AudioStreamPlayer = sfx_players[sfx_name]
		if p.playing:
			p.seek(0.0)
		else:
			p.play()

# Generate 16-bit mono PCM wav data
func _create_wav(samples: PackedFloat32Array, sample_rate: int = 22050) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	
	var byte_array := PackedByteArray()
	byte_array.resize(samples.size() * 2)
	for i in range(samples.size()):
		var val: float = clampf(samples[i], -1.0, 1.0)
		var int_val: int = int(val * 32767.0)
		byte_array.encode_s16(i * 2, int_val)
	wav.data = byte_array
	return wav

# Standard Rifle: 800Hz to 200Hz pitch drop square wave
func _generate_rifle_sound() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.12
	var total_samples := int(rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(total_samples)
	var phase := 0.0
	
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var freq := lerpf(750.0, 180.0, t)
		phase += (freq * TAU) / float(rate)
		var env := 1.0 - t
		var wave := 1.0 if sin(phase) > 0.0 else -1.0
		samples[i] = wave * env * 0.4
	return _create_wav(samples, rate)

# Spread Gun: heavier multi-tone blast
func _generate_spread_sound() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.18
	var total_samples := int(rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(total_samples)
	var phase1 := 0.0
	var phase2 := 0.0
	
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var freq1 := lerpf(900.0, 120.0, t)
		var freq2 := lerpf(450.0, 80.0, t)
		phase1 += (freq1 * TAU) / float(rate)
		phase2 += (freq2 * TAU) / float(rate)
		var env := 1.0 - (t * t)
		var w1 := 1.0 if sin(phase1) > 0.0 else -1.0
		var w2 := 1.0 if sin(phase2) > 0.0 else -1.0
		var noise := randf_range(-0.2, 0.2)
		samples[i] = (w1 * 0.3 + w2 * 0.3 + noise) * env * 0.5
	return _create_wav(samples, rate)

# Laser: piercing frequency sweep
func _generate_laser_sound() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.2
	var total_samples := int(rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(total_samples)
	var phase := 0.0
	
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var freq := lerpf(1400.0, 300.0, t * t)
		phase += (freq * TAU) / float(rate)
		var env := 1.0 - t
		# Sawtooth wave approximation
		var wave := (fposmod(phase / TAU, 1.0) * 2.0) - 1.0
		samples[i] = wave * env * 0.45
	return _create_wav(samples, rate)

# Jump: upward pitch chirp
func _generate_jump_sound() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.15
	var total_samples := int(rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(total_samples)
	var phase := 0.0
	
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var freq := lerpf(180.0, 520.0, sqrt(t))
		phase += (freq * TAU) / float(rate)
		var env := 1.0 - t * 0.5
		var wave := 1.0 if sin(phase) > 0.0 else -1.0
		samples[i] = wave * env * 0.3
	return _create_wav(samples, rate)

# Explosion: noise burst with exponential fade
func _generate_explosion_sound() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.35
	var total_samples := int(rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(total_samples)
	
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var env := exp(-4.5 * t)
		var noise := randf_range(-1.0, 1.0)
		samples[i] = noise * env * 0.6
	return _create_wav(samples, rate)

# Hit: crisp impact pop
func _generate_hit_sound() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.08
	var total_samples := int(rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(total_samples)
	
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var env := 1.0 - t
		var wave := randf_range(-0.8, 0.8)
		samples[i] = wave * env * 0.4
	return _create_wav(samples, rate)

# Powerup: iconic arpeggio
func _generate_powerup_sound() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.32
	var total_samples := int(rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(total_samples)
	var notes := [523.25, 659.25, 783.99, 1046.5] # C5, E5, G5, C6
	var phase := 0.0
	
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var note_idx := clampi(int(t * 4.0), 0, 3)
		var freq: float = notes[note_idx]
		phase += (freq * TAU) / float(rate)
		var env := 1.0 - (fposmod(t * 4.0, 1.0) * 0.3)
		var wave := 1.0 if sin(phase) > 0.0 else -1.0
		samples[i] = wave * env * 0.35
	return _create_wav(samples, rate)

# Player death sound
func _generate_death_sound() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.45
	var total_samples := int(rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(total_samples)
	var phase := 0.0
	
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var freq := lerpf(400.0, 80.0, t)
		phase += (freq * TAU) / float(rate)
		var env := 1.0 - t
		var wave := (1.0 if sin(phase) > 0.0 else -1.0) * 0.6 + randf_range(-0.4, 0.4)
		samples[i] = wave * env * 0.4
	return _create_wav(samples, rate)

# Boss Warning Siren
func _generate_boss_alarm() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.5
	var total_samples := int(rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(total_samples)
	var phase := 0.0
	
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var freq := 880.0 if fposmod(t * 4.0, 1.0) < 0.5 else 440.0
		phase += (freq * TAU) / float(rate)
		var wave := 1.0 if sin(phase) > 0.0 else -1.0
		samples[i] = wave * 0.3
	return _create_wav(samples, rate)

# Menu Cursor Blip
func _generate_cursor_sound() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.06
	var total_samples := int(rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(total_samples)
	var phase := 0.0
	
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var freq := 580.0
		phase += (freq * TAU) / float(rate)
		var env := 1.0 - t
		var wave := 1.0 if sin(phase) > 0.0 else -1.0
		samples[i] = wave * env * 0.35
	return _create_wav(samples, rate)

# Menu Start / Confirm Jingle
func _generate_start_sound() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.4
	var total_samples := int(rate * duration)
	var samples := PackedFloat32Array()
	samples.resize(total_samples)
	var notes := [440.0, 554.37, 659.25, 880.0] # A4, C#5, E5, A5
	var phase := 0.0
	
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var idx := clampi(int(t * 4.0), 0, 3)
		var freq: float = notes[idx]
		phase += (freq * TAU) / float(rate)
		var env := 1.0 - (fposmod(t * 4.0, 1.0) * 0.4)
		var wave := 1.0 if sin(phase) > 0.0 else -1.0
		samples[i] = wave * env * 0.4
	return _create_wav(samples, rate)

