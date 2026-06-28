extends Node

const SFX_DIR := "res://Audio/sfx/"

var _sfx : Dictionary = {}
var _pool : Array[AudioStreamPlayer] = []
var _poolSize := 16
var _next := 0
var _music : AudioStreamPlayer

var _musicMenu : AudioStream = preload("res://Audio/music/music_menu.ogg")
var _musicLevel : AudioStream = preload("res://Audio/music/music_level.ogg")
var _musicBoss : AudioStream = preload("res://Audio/music/music_boss.ogg")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for name in ["rifle", "shotgun", "enemy_hit", "enemy_death", "player_hurt",
			"jump", "dash", "walljump", "slam", "footstep1", "footstep2",
			"pickup", "ui_hover", "ui_click", "win", "lose"]:
		_sfx[name] = load(SFX_DIR + name + ".wav")
	for i in _poolSize:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node : Node) -> void:
	if node is BaseButton:
		node.mouse_entered.connect(func(): play("ui_hover", 1.0, -7.0))
		node.pressed.connect(func(): play("ui_click", 1.0, -3.0))

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
	if idx == 0:
		play_music(_musicMenu)
	elif idx == Global.levels.size() - 1:
		play_music(_musicBoss)
	else:
		play_music(_musicLevel)
