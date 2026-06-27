extends Control

@onready var stage1 = "res://Scenes/level1.tscn"

var settingsOpen:bool = false
@onready var settingsCont = $UI/MainContainer/Settings
@onready var stageSelect = $UI/MainContainer/StageSelect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Audio.music_for_level(0)
	settingsCont.closed.connect(_on_settings_closed)
	stageSelect.closed.connect(_on_stage_closed)


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
