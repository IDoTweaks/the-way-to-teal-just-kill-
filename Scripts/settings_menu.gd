extends Control

# Shared settings menu used by BOTH the main menu and the in-game pause menu.
# Self contained: applies volume / display / resolution itself and just yells
# "closed" when you hit back so whoever opened it can hide it.

signal closed

@onready var volumeSlider : HSlider = $Center/Panel/Margin/VBox/VolumeSlider
@onready var displayOption : OptionButton = $Center/Panel/Margin/VBox/DisplayOption
@onready var resOption : OptionButton = $Center/Panel/Margin/VBox/ResOption
@onready var backBtn : Button = $Center/Panel/Margin/VBox/BackBtn

const RESOLUTIONS : Array[Vector2i] = [
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1280, 720),
	Vector2i(1152, 648),
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	volumeSlider.min_value = 0.0
	volumeSlider.max_value = 1.0
	volumeSlider.step = 0.01
	volumeSlider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	volumeSlider.value_changed.connect(_on_volume_changed)
	displayOption.item_selected.connect(_on_display_selected)
	resOption.item_selected.connect(_on_res_selected)
	backBtn.pressed.connect(_on_back_pressed)
	_syncResEnabled()

func open() -> void:
	volumeSlider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	_syncResEnabled()
	show()

func _on_volume_changed(value : float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value))
	AudioServer.set_bus_mute(0, value <= 0.001)

func _on_display_selected(index : int) -> void:
	match index:
		0:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	_syncResEnabled()

func _on_res_selected(index : int) -> void:
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		return
	if index >= 0 and index < RESOLUTIONS.size():
		var size = RESOLUTIONS[index]
		DisplayServer.window_set_size(size)
		var screen = DisplayServer.screen_get_size()
		DisplayServer.window_set_position((screen - size) / 2)

func _syncResEnabled() -> void:
	resOption.disabled = DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED

func _on_back_pressed() -> void:
	hide()
	closed.emit()
