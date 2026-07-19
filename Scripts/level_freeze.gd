extends CanvasLayer

var frozen = false
var pauseMenu
var lbl : Label
var pulseTween : Tween

func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	pauseMenu = get_parent().get_node_or_null("PauseMenu")
	lbl = Label.new()
	var ls = LabelSettings.new()
	ls.font = load("res://Fonts/LilitaOne.tres")
	ls.font_size = 52
	ls.font_color = Color(1.0, 0.99, 0.94)
	ls.outline_size = 16
	ls.outline_color = Color(0.031, 0.133, 0.149)
	ls.shadow_size = 8
	ls.shadow_color = Color(0.031, 0.133, 0.149, 0.35)
	ls.shadow_offset = Vector2(0, 6)
	lbl.label_settings = ls
	lbl.text = "PRESS ANYTHING TO GO"
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.pivot_offset = lbl.get_minimum_size() * 0.5
	lbl.position.y += 180
	add_child(lbl)
	_freeze.call_deferred()

func _freeze():
	frozen = true
	get_tree().paused = true
	pulseTween = create_tween()
	pulseTween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	pulseTween.set_loops()
	pulseTween.set_trans(Tween.TRANS_SINE)
	pulseTween.tween_property(lbl, "scale", Vector2(1.08, 1.08), 0.55)
	pulseTween.tween_property(lbl, "scale", Vector2.ONE, 0.55)

func _menuOpen() -> bool:
	return pauseMenu != null and pauseMenu.isPaused

func _process(_delta: float) -> void:
	if frozen and !_menuOpen() and !get_tree().paused:
		get_tree().paused = true

func _input(event: InputEvent) -> void:
	if !frozen or _menuOpen():
		return
	if event.is_action_pressed("ui_cancel"):
		return
	if (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
		_go()
		get_viewport().set_input_as_handled()

func _go():
	frozen = false
	get_tree().paused = false
	if pulseTween:
		pulseTween.kill()
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "scale", Vector2(1.6, 1.6), 0.18)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(queue_free)
