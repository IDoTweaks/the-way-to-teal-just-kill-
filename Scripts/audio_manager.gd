extends Node

const SFX_DIR := "res://Audio/sfx/"
const CUSTOM_MUSIC_DIR := "user://custom_music/"
const CUSTOM_MUSIC_CFG := "user://custom_music.cfg"

var _sfx : Dictionary = {}
var _pool : Array[AudioStreamPlayer] = []
var _poolSize := 16
var _next := 0
var _music : AudioStreamPlayer

var _musicMenu : AudioStream = preload("res://Audio/music/music_menu.ogg")
var _musicBoss : AudioStream = preload("res://Audio/music/music_boss.ogg")
var _musicLevels : Array[AudioStream] = [
	preload("res://Audio/music/music_level1.ogg"),
	preload("res://Audio/music/music_level2.ogg"),
	preload("res://Audio/music/music_level3.ogg"),
	preload("res://Audio/music/music_level4.ogg"),
	preload("res://Audio/music/music_level5.ogg"),
	preload("res://Audio/music/music_level6.ogg"),
	preload("res://Audio/music/music_level7.ogg"),
	preload("res://Audio/music/music_level8.ogg"),
	preload("res://Audio/music/music_level9.ogg"),
]
var _musicOverrides : Dictionary = {}
var _musicNames : Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for name in ["rifle", "shotgun", "enemy_hit", "enemy_death", "player_hurt",
			"jump", "dash", "walljump", "slam", "footstep1", "footstep2",
			"ui_hover", "ui_click", "win", "lose", "boing"]:
		_sfx[name] = load(SFX_DIR + name + ".wav")
	for i in _poolSize:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	_music.finished.connect(_on_music_finished)
	_loadCustomMusic()
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node : Node) -> void:
	if node is BaseButton:
		node.mouse_entered.connect(func(): play("ui_hover", 1.0, -7.0))
		node.pressed.connect(func(): play("ui_click", 1.0, -3.0))
		node.mouse_entered.connect(_juiceIn.bind(node))
		node.mouse_exited.connect(_juiceOut.bind(node))
		node.button_down.connect(_juiceSquash.bind(node))
		node.button_up.connect(_juiceIn.bind(node))

func _juicePivot(node : Control) -> void:
	node.pivot_offset = node.size / 2.0

func _juiceTo(node : Control, target : Vector2, time : float, trans : int, ease_t : int) -> void:
	if not is_instance_valid(node) or node.disabled:
		return
	_juicePivot(node)
	if node.has_meta("_juiceTw"):
		var old = node.get_meta("_juiceTw")
		if old != null and is_instance_valid(old):
			old.kill()
	var tw
	tw = node.create_tween()
	tw.set_trans(trans).set_ease(ease_t)
	tw.tween_property(node, "scale", target, time)
	node.set_meta("_juiceTw", tw)

func _juiceIn(node : Control) -> void:
	_juiceTo(node, Vector2(1.09, 1.09), 0.22, Tween.TRANS_ELASTIC, Tween.EASE_OUT)

func _juiceOut(node : Control) -> void:
	_juiceTo(node, Vector2.ONE, 0.18, Tween.TRANS_BACK, Tween.EASE_OUT)

func _juiceSquash(node : Control) -> void:
	_juiceTo(node, Vector2(0.93, 0.86), 0.07, Tween.TRANS_QUAD, Tween.EASE_OUT)

func play(name : String, pitch : float = 1.0, vol_db : float = 0.0) -> void:
	var stream = _sfx.get(name)
	if stream == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % _poolSize
	p.stream = stream
	p.pitch_scale = pitch * randf_range(0.95, 1.05)
	p.volume_db = vol_db
	p.play()

func footstep() -> void:
	play("footstep1" if randf() < 0.5 else "footstep2", randf_range(0.9, 1.1), -10.0)

func play_music(stream : AudioStream) -> void:
	if stream == null:
		return
	if _music.stream == stream and _music.playing:
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_music.stream = stream
	_music.play()

func music_for_level(idx : int) -> void:
	if _musicOverrides.has(idx):
		play_music(_musicOverrides[idx])
		return
	if idx == 0:
		play_music(_musicMenu)
	elif Global._isBoss(idx):
		play_music(_musicBoss)
	else:
		play_music(_musicLevels[idx - 1])

func _on_music_finished() -> void:
	if _music.stream != null:
		_music.play()

func load_music_file(path : String) -> AudioStream:
	match path.get_extension().to_lower():
		"ogg":
			return AudioStreamOggVorbis.load_from_file(path)
		"mp3":
			return AudioStreamMP3.load_from_file(path)
		"wav":
			return AudioStreamWAV.load_from_file(path)
	return null

func music_label(idx : int) -> String:
	return _musicNames.get(idx, "")

func assign_music(idx : int, srcPath : String) -> bool:
	var stream := load_music_file(srcPath)
	if stream == null:
		return false
	var bytes := FileAccess.get_file_as_bytes(srcPath)
	if bytes.is_empty():
		return false
	DirAccess.make_dir_recursive_absolute(CUSTOM_MUSIC_DIR)
	_removeCustomFile(idx)
	var ext := srcPath.get_extension().to_lower()
	var dest := CUSTOM_MUSIC_DIR + "level_%d.%s" % [idx, ext]
	var f := FileAccess.open(dest, FileAccess.WRITE)
	if f == null:
		return false
	f.store_buffer(bytes)
	f.close()
	_musicOverrides[idx] = stream
	_musicNames[idx] = srcPath.get_file()
	var cfg := ConfigFile.new()
	cfg.load(CUSTOM_MUSIC_CFG)
	cfg.set_value("files", str(idx), dest)
	cfg.set_value("names", str(idx), srcPath.get_file())
	cfg.save(CUSTOM_MUSIC_CFG)
	return true

func clear_music(idx : int) -> void:
	_musicOverrides.erase(idx)
	_musicNames.erase(idx)
	_removeCustomFile(idx)
	var cfg := ConfigFile.new()
	if cfg.load(CUSTOM_MUSIC_CFG) == OK:
		if cfg.has_section_key("files", str(idx)):
			cfg.erase_section_key("files", str(idx))
		if cfg.has_section_key("names", str(idx)):
			cfg.erase_section_key("names", str(idx))
		cfg.save(CUSTOM_MUSIC_CFG)

func _removeCustomFile(idx : int) -> void:
	for ext in ["ogg", "mp3", "wav"]:
		var p := CUSTOM_MUSIC_DIR + "level_%d.%s" % [idx, ext]
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)

func _loadCustomMusic() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CUSTOM_MUSIC_CFG) != OK:
		return
	if not cfg.has_section("files"):
		return
	for key in cfg.get_section_keys("files"):
		var path : String = cfg.get_value("files", key)
		if not FileAccess.file_exists(path):
			continue
		var stream := load_music_file(path)
		if stream == null:
			continue
		var idx := int(key)
		_musicOverrides[idx] = stream
		if cfg.has_section_key("names", key):
			_musicNames[idx] = cfg.get_value("names", key)
		else:
			_musicNames[idx] = path.get_file()
