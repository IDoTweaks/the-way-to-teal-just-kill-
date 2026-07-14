extends CanvasLayer

const PURPLE = Color(0.62, 0.25, 1.0)
const TEXT = Color(0.86, 0.86, 0.88)
const DIM = Color(0.55, 0.55, 0.58)
const DANGER = Color(0.9, 0.25, 0.3)

const LEVELS = [
	["1", "dash goes flat, half strength"],
	["2", "no dash"],
	["3", "no slide, no slam"],
	["4", "no wall-jump"],
	["5", "jump height cut by 40%"],
	["6", "no air control"],
	["7", "speed cut by 40%"],
	["8", "no jump"],
	["9", "speed cut by 75%, you bleed out"],
	["10", "you die"],
]

@export var armTime : float = 1.2
var armed : bool = false
var btn : Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build()
	await get_tree().create_timer(armTime, true, false, true).timeout
	_arm()

func _build() -> void:
	var back = ColorRect.new()
	back.color = Color(0.02, 0.02, 0.03, 0.94)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var frame = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.05, 1)
	style.border_color = PURPLE
	style.set_border_width_all(2)
	style.set_content_margin_all(28)
	frame.add_theme_stylebox_override("panel", style)
	center.add_child(frame)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	frame.add_child(box)

	var title = Label.new()
	title.text = "PARALYSIS"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", PURPLE)
	box.add_child(title)

	var sub = Label.new()
	sub.text = "every hit from the snake adds a level. it does not wear off."
	sub.add_theme_font_size_override("font_size", 15)
	sub.add_theme_color_override("font_color", DIM)
	box.add_child(sub)

	box.add_child(_gap(14))

	for lvl in LEVELS:
		box.add_child(_row(lvl[0], lvl[1]))

	box.add_child(_gap(14))

	var cure = Label.new()
	cure.text = "a cure drop takes a level off. it costs health."
	cure.add_theme_font_size_override("font_size", 15)
	cure.add_theme_color_override("font_color", DIM)
	box.add_child(cure)

	box.add_child(_gap(10))

	btn = Button.new()
	btn.text = "READ IT"
	btn.disabled = true
	btn.custom_minimum_size = Vector2(0, 40)
	btn.add_theme_font_size_override("font_size", 18)
	box.add_child(btn)
	btn.pressed.connect(_dismiss)

func _gap(h : int) -> Control:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, h)
	return spacer

func _row(num : String, effect : String) -> Control:
	var last = int(num) >= LEVELS.size()
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	var lvl = Label.new()
	lvl.text = num
	lvl.custom_minimum_size = Vector2(34, 0)
	lvl.add_theme_font_size_override("font_size", 18)
	lvl.add_theme_color_override("font_color", DANGER if last else PURPLE)
	lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(lvl)

	var txt = Label.new()
	txt.text = effect
	txt.custom_minimum_size = Vector2(400, 0)
	txt.add_theme_font_size_override("font_size", 18)
	txt.add_theme_color_override("font_color", DANGER if last else TEXT)
	row.add_child(txt)
	return row

func _arm() -> void:
	if btn == null or !is_instance_valid(btn):
		return
	armed = true
	btn.disabled = false
	btn.text = "UNDERSTOOD"
	btn.grab_focus()

func _input(event : InputEvent) -> void:
	if event is InputEventKey:
		if armed and event.is_action_pressed("ui_accept"):
			return
		get_viewport().set_input_as_handled()

func _dismiss() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	queue_free()
