extends Control

@onready var stage1 = "res://Scenes/level1.tscn"

var settingsOpen:bool = false
@onready var settingsCont = $UI/MainContainer/Settings
@onready var stageSelect = $UI/MainContainer/StageSelect
@onready var title = $UI/MainContainer/Title
@onready var title2 = $UI/MainContainer/Title2
@onready var tagline = $UI/MainContainer/Tagline
@onready var menuButtons = $UI/MainContainer/MenuButtons
var _t = 0.0
var _baseTitleRot = 0.0
var _baseTitle2Rot = 0.0
var _baseTagRot = 0.0
var _baseBtnRot = 0.0
var musicOpen : bool = false
var musicOverlay : ColorRect
var musicSelectedLevel : int = 0
var musicRows : Array = []
var musicStatus : Label
var funkyTheme = preload("res://UI/funkyTheme.tres")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Audio.music_for_level(0)
	settingsCont.closed.connect(_on_settings_closed)
	stageSelect.closed.connect(_on_stage_closed)
	_baseTitleRot = title.rotation
	_baseTitle2Rot = title2.rotation
	_baseTagRot = tagline.rotation
	_baseBtnRot = menuButtons.rotation
	_buildMusicOverlay()
	get_window().files_dropped.connect(_onFilesDropped)
	if Global.menuTourPending:
		Global.menuTourPending = false
		_startMenuTour.call_deferred()
	elif not Global.tutorialComplete:
		Global._goToTutorial.call_deferred()

func _process(delta: float) -> void:
	_t += delta
	title.rotation = _baseTitleRot + sin(_t * 1.4) * 0.03
	title.scale = Vector2.ONE * (1.0 + sin(_t * 2.2) * 0.02)
	title2.rotation = _baseTitle2Rot + sin(_t * 2.0 + 1.0) * 0.05
	tagline.rotation = _baseTagRot + sin(_t * 1.7 + 0.5) * 0.04
	menuButtons.rotation = _baseBtnRot + sin(_t * 1.1 + 2.0) * 0.02


func _on_join_game_btn_button_down() -> void:
	stageSelect.open()


func _on_tutorial_btn_button_down() -> void:
	Global._goToTutorial()


func _on_endless_btn_button_down() -> void:
	Global._goToEndless(randi())


func _on_stage_closed() -> void:
	pass


func _on_quit_btn_button_down() -> void:
	get_tree().quit()


func _on_settings_btn_button_down() -> void:
	if settingsOpen:
		settingsCont.visible = false
		settingsOpen = false
	else:
		settingsCont.open()
		settingsOpen = true


func _on_settings_closed() -> void:
	settingsOpen = false


func _on_music_btn_button_down() -> void:
	musicOpen = true
	musicOverlay.visible = true
	musicStatus.text = "selected: %s - drag a song into the window" % _levelName(musicSelectedLevel)
	_refreshMusicRows()


func _onMusicBack() -> void:
	musicOpen = false
	musicOverlay.visible = false


func _onFilesDropped(files : PackedStringArray) -> void:
	if not musicOpen or files.is_empty():
		return
	var src : String = files[0]
	if Audio.assign_music(musicSelectedLevel, src):
		musicStatus.text = "%s  <-  %s" % [_levelName(musicSelectedLevel), src.get_file()]
		if musicSelectedLevel == 0:
			Audio.music_for_level(0)
	else:
		musicStatus.text = "couldn't load %s  (use .ogg .mp3 .wav)" % src.get_file()
	_refreshMusicRows()


func _onSelectMusicLevel(idx : int) -> void:
	musicSelectedLevel = idx
	musicStatus.text = "selected: %s - drag a song into the window" % _levelName(idx)
	_refreshMusicRows()


func _onClearMusicLevel(idx : int) -> void:
	Audio.clear_music(idx)
	if idx == 0:
		Audio.music_for_level(0)
	musicStatus.text = "%s reset to default" % _levelName(idx)
	_refreshMusicRows()


func _levelName(idx : int) -> String:
	if idx == 0:
		return "MAIN MENU"
	elif idx == Global.levels.size() - 1:
		return "BOSS"
	return "LEVEL %d" % idx


func _refreshMusicRows() -> void:
	for r in musicRows:
		var idx : int = r["idx"]
		var sel : bool = idx == musicSelectedLevel
		r["name"].modulate = Color(0.1, 1, 0.5, 1) if sel else Color(0.75, 0.85, 0.85, 1)
		var lbl : String = Audio.music_label(idx)
		if lbl == "":
			r["song"].text = "default"
			r["song"].modulate = Color(0.45, 0.6, 0.6, 1)
			r["clear"].visible = false
		else:
			r["song"].text = "> " + lbl
			r["song"].modulate = Color(0, 0.85, 0.78, 1)
			r["clear"].visible = true


func _buildMusicOverlay() -> void:
	musicOverlay = ColorRect.new()
	musicOverlay.color = Color(0.01, 0.02, 0.03, 0.95)
	musicOverlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	musicOverlay.visible = false
	$UI.add_child(musicOverlay)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	box.theme = funkyTheme
	musicOverlay.add_child(box)

	var header := Label.new()
	header.text = "CUSTOM MUSIC"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.theme_type_variation = "Display"
	header.add_theme_constant_override("outline_size", 16)
	box.add_child(header)

	var sub := Label.new()
	sub.text = "pick a level, then drag a song (.ogg / .mp3 / .wav) into the window"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.theme_type_variation = "Small"
	box.add_child(sub)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	rows.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(rows)

	musicRows.clear()
	for idx in Global.levels.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)

		var nameBtn := Button.new()
		nameBtn.text = _levelName(idx)
		nameBtn.custom_minimum_size = Vector2(280, 50)
		nameBtn.pressed.connect(_onSelectMusicLevel.bind(idx))
		row.add_child(nameBtn)

		var song := Label.new()
		song.custom_minimum_size = Vector2(440, 0)
		song.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		song.theme_type_variation = "Accent"
		song.clip_text = true
		row.add_child(song)

		var clearBtn := Button.new()
		clearBtn.text = "RESET"
		clearBtn.custom_minimum_size = Vector2(120, 50)
		clearBtn.theme_type_variation = "SmallBtn"
		clearBtn.pressed.connect(_onClearMusicLevel.bind(idx))
		row.add_child(clearBtn)

		rows.add_child(row)
		musicRows.append({"idx": idx, "name": nameBtn, "song": song, "clear": clearBtn})

	musicStatus = Label.new()
	musicStatus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	musicStatus.theme_type_variation = "Small"
	box.add_child(musicStatus)

	var back := Button.new()
	back.text = "BACK"
	back.custom_minimum_size = Vector2(300, 60)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.theme_type_variation = "BigBtn"
	back.pressed.connect(_onMusicBack)
	box.add_child(back)

	musicStatus.text = "selected: %s - drag a song into the window" % _levelName(musicSelectedLevel)
	_refreshMusicRows()



func _btn(name : String) -> Callable:
	return func(): return menuButtons.get_node_or_null(name)

func _tab(i : int) -> Callable:
	return func(): return settingsCont._tabBtns[i] if i < settingsCont._tabBtns.size() else null

func _startMenuTour() -> void:
	var tour = CanvasLayer.new()
	tour.set_script(load("res://Scripts/menu_tour.gd"))
	add_child(tour)
	tour.finished.connect(_onMenuTourDone)
	tour.start([
		{"text": "Nice work! This is the main menu. Let's have a quick look around.", "target": func(): return null},
		{"text": "PLAY takes you to the level select, where you pick a stage and see your best score and time.", "target": _btn("JoinGameBtn")},
		{"text": "TUTORIAL replays the course you just finished, any time you want.", "target": _btn("TutorialBtn")},
		{"text": "ENDLESS drops you into randomly generated rooms that get harder every time. It only ends when you die.", "target": _btn("EndlessBtn")},
		{"text": "MUSIC lets you drop your own songs in - pick a level, then drag an audio file onto the window.", "target": _btn("MusicBtn")},
		{"text": "SETTINGS is where everything is tuned. Let's open it.", "target": _btn("SettingsBtn")},
		{"text": "AUDIO: master, music and SFX volume.", "target": _tab(0),
			"before": func(): _openSettingsForTour(0)},
		{"text": "DISPLAY: window mode, resolution, field of view, and screen shake if the motion bothers you.", "target": _tab(1),
			"before": func(): settingsCont._showTab(1)},
		{"text": "GRAPHICS: if the game runs badly, drop RENDER SCALE first - it's the biggest speed-up.", "target": _tab(2),
			"before": func(): settingsCont._showTab(2)},
		{"text": "CONTROLS: mouse sensitivity, invert Y, and hold-vs-toggle for scope and slide.", "target": _tab(3),
			"before": func(): settingsCont._showTab(3)},
		{"text": "KEYBINDS: click any bind and press a new key. Nothing can end up unbound - it swaps instead.", "target": _tab(4),
			"before": func(): settingsCont._showTab(4)},
		{"text": "Changes apply straight away, but they are only kept when you press SAVE. Leaving discards them.", "target": func(): return settingsCont.saveBtn,
			"before": func(): settingsCont._showTab(0)},
		{"text": "That's the tour. Ready to play?", "target": _btn("JoinGameBtn"),
			"before": func(): _closeSettingsForTour()},
	])

func _openSettingsForTour(tab : int) -> void:
	settingsCont.open()
	settingsOpen = true
	settingsCont._showTab(tab)

func _closeSettingsForTour() -> void:
	settingsCont.hide()
	settingsOpen = false

func _onMenuTourDone() -> void:
	_closeSettingsForTour()
	stageSelect.open()
