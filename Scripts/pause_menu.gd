extends CanvasLayer

var isPaused : bool = false

@onready var root : Control = $Root
@onready var buttons : Control = $Root/Center/Buttons
@onready var settings = $Root/SettingsMenu

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false
	settings.visible = false
	$Root/Center/Buttons/ResumeBtn.pressed.connect(_resume)
	$Root/Center/Buttons/SettingsBtn.pressed.connect(_on_settings)
	$Root/Center/Buttons/MenuBtn.pressed.connect(_on_menu)
	$Root/Center/Buttons/QuitBtn.pressed.connect(_on_quit)
	settings.closed.connect(_on_settings_closed)

func _input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if isPaused and settings.visible:
			_on_settings_closed()
		elif isPaused:
			_resume()
		else:
			_pause()
		get_viewport().set_input_as_handled()

func _pause() -> void:
	isPaused = true
	get_tree().paused = true
	root.visible = true
	settings.visible = false
	buttons.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _resume() -> void:
	isPaused = false
	get_tree().paused = false
	root.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_settings() -> void:
	buttons.visible = false
	settings.open()

func _on_settings_closed() -> void:
	settings.visible = false
	buttons.visible = true

func _on_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Global._goToLevel(0)

func _on_quit() -> void:
	get_tree().paused = false
	get_tree().quit()
