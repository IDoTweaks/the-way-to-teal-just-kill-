extends Control

@onready var stage1 = "res://Scenes/level1.tscn"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_join_game_btn_button_down() -> void:
	get_tree().change_scene_to_file(stage1)


func _on_quit_btn_button_down() -> void:
	get_tree().quit()


func _on_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0,linear_to_db(value))


func _on_res_option_butt_item_selected(index: int) -> void:
	if DisplayServer.window_get_mode() == DisplayServer.window_get_mode():
		if index == 0:
			DisplayServer.window_set_size(Vector2i(1920,1080))
			#DisplayServer.WINDOW_MODE_FULLSCREEN
			#DisplayServer.WINDOW_FLAG_BORDERLESS
		elif index == 1:
			DisplayServer.window_set_size(Vector2i(1600,900))
		elif index == 2:
			DisplayServer.window_set_size(Vector2i(1280,720))
		elif index == 3:
			DisplayServer.window_set_size(Vector2i(1152,648))


func _on_fs_option_butt_2_item_selected(index: int) -> void:
	if index == 0:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	elif index == 1:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,true)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif index == 2:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS,false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

var settingsOpen:bool = false
@onready var settingsCont =$UI/MainContainer/Settings
func _on_settings_btn_button_down() -> void:
	if settingsOpen:
		settingsCont.visible = false
		settingsOpen = false
	else:
		settingsCont.visible = true
		settingsOpen = true
	
