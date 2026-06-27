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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Audio.music_for_level(0)
	settingsCont.closed.connect(_on_settings_closed)
	stageSelect.closed.connect(_on_stage_closed)
	_baseTitleRot = title.rotation
	_baseTitle2Rot = title2.rotation
	_baseTagRot = tagline.rotation
	_baseBtnRot = menuButtons.rotation

func _process(delta: float) -> void:
	_t += delta
	title.rotation = _baseTitleRot + sin(_t * 1.4) * 0.03
	title.scale = Vector2.ONE * (1.0 + sin(_t * 2.2) * 0.02)
	title2.rotation = _baseTitle2Rot + sin(_t * 2.0 + 1.0) * 0.05
	tagline.rotation = _baseTagRot + sin(_t * 1.7 + 0.5) * 0.04
	menuButtons.rotation = _baseBtnRot + sin(_t * 1.1 + 2.0) * 0.02


func _on_join_game_btn_button_down() -> void:
	stageSelect.open()


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
